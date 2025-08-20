import 'dart:async';
import '../data/models/habit.dart';
import '../data/models/note.dart';

import 'firebase_service.dart';
import 'hive_service.dart';

enum SyncStatus { idle, syncing, completed, error }

class SyncService {
  final FirebaseService _firebaseService = FirebaseService();
  
  final StreamController<SyncStatus> _syncStatusController = 
      StreamController<SyncStatus>.broadcast();
  
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  SyncStatus _currentStatus = SyncStatus.idle;
  
  SyncStatus get currentStatus => _currentStatus;

  Future<void> syncData(String userId) async {
    if (_currentStatus == SyncStatus.syncing) return;
    
    _updateStatus(SyncStatus.syncing);
    
    try {
      // Perform two-way sync
      await _performTwoWaySync(userId);
      _updateStatus(SyncStatus.completed);
      
      // Reset to idle after a delay
      Timer(const Duration(seconds: 2), () {
        if (_currentStatus == SyncStatus.completed) {
          _updateStatus(SyncStatus.idle);
        }
      });
    } catch (e) {
      _updateStatus(SyncStatus.error);
      rethrow;
    }
  }

  Future<void> _performTwoWaySync(String userId) async {
    // Get local and remote data
    final localHabits = await HiveService.getAllHabits(userId);
    final localNotes = await HiveService.getAllNotes(userId);
    
    // Fetch remote data
    final remoteHabits = await _firebaseService.getHabits(userId);
    
    // Get all notes by fetching notes for each habit
    final List<Note> remoteNotes = [];
    for (final habit in remoteHabits) {
      try {
        final habitNotes = await _firebaseService.getNotes(userId, habit.id);
        remoteNotes.addAll(habitNotes);
      } catch (e) {
        print('Failed to fetch notes for habit ${habit.id}: $e');
      }
    }
    
    // Merge and resolve conflicts
    final mergedHabits = _mergeHabits(localHabits, remoteHabits);
    final mergedNotes = _mergeNotes(localNotes, remoteNotes);
    
    // Update local storage
    await HiveService.saveHabits(userId, mergedHabits);
    await HiveService.saveNotes(userId, mergedNotes);
    
    // Push merged data to remote
    await _firebaseService.batchSyncHabits(userId, mergedHabits);
    await _firebaseService.batchSyncNotes(userId, mergedNotes);
  }

  Future<void> fetchAllRemote(String userId) async {
    if (_currentStatus == SyncStatus.syncing) return;
    _updateStatus(SyncStatus.syncing);
    try {
      // Fetch remote habits
      final remoteHabits = await _firebaseService.getHabits(userId);
      
      // Fetch all notes for those habits
      final List<Note> remoteNotes = [];
      for (final habit in remoteHabits) {
        try {
          final habitNotes = await _firebaseService.getNotes(userId, habit.id);
          remoteNotes.addAll(habitNotes);
        } catch (e) {
          print('Failed to fetch notes for habit ${habit.id}: $e');
        }
      }
      
      // Save directly to local
      await HiveService.saveHabits(userId, remoteHabits);
      await HiveService.saveNotes(userId, remoteNotes);
      
      _updateStatus(SyncStatus.completed);
      
      // Reset to idle after a short delay
      Timer(const Duration(seconds: 2), () {
        if (_currentStatus == SyncStatus.completed) {
          _updateStatus(SyncStatus.idle);
        }
      });
    } catch (e) {
      _updateStatus(SyncStatus.error);
      rethrow;
    }
  }

  List<Habit> _mergeHabits(List<Habit> local, List<Habit> remote) {
    final merged = <Habit>[];
    final allIds = <String>{};
    
    // Add all IDs to set
    allIds.addAll(local.map((h) => h.id));
    allIds.addAll(remote.map((h) => h.id));
    
    for (final id in allIds) {
      final localHabit = local.where((h) => h.id == id).firstOrNull;
      final remoteHabit = remote.where((h) => h.id == id).firstOrNull;
      
      if (localHabit != null && remoteHabit != null) {
        // Conflict resolution: last-write-wins based on updatedAt
        merged.add(localHabit.updatedAt.isAfter(remoteHabit.updatedAt) 
            ? localHabit 
            : remoteHabit);
      } else if (localHabit != null) {
        merged.add(localHabit);
      } else if (remoteHabit != null) {
        merged.add(remoteHabit);
      }
    }
    
    return merged;
  }

  List<Note> _mergeNotes(List<Note> local, List<Note> remote) {
    final merged = <Note>[];
    final allIds = <String>{};
    
    // Add all IDs to set
    allIds.addAll(local.map((n) => n.id));
    allIds.addAll(remote.map((n) => n.id));
    
    for (final id in allIds) {
      final localNote = local.where((n) => n.id == id).firstOrNull;
      final remoteNote = remote.where((n) => n.id == id).firstOrNull;
      
      if (localNote != null && remoteNote != null) {
        // Conflict resolution: last-write-wins based on createdAt
        merged.add(localNote.createdAt.isAfter(remoteNote.createdAt) 
            ? localNote 
            : remoteNote);
      } else if (localNote != null) {
        merged.add(localNote);
      } else if (remoteNote != null) {
        merged.add(remoteNote);
      }
    }
    
    return merged;
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _syncStatusController.add(status);
  }

  Future<void> dispose() async {
    await _syncStatusController.close();
  }
}
