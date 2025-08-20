import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../../services/firebase_service.dart';
import '../../services/hive_service.dart';

class HabitRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = const Uuid();

  // Create a new habit
  Future<Habit> createHabit({
    required String title,
    required String color,
    required String userId,
  }) async {
    final now = DateTime.now();
    final habit = Habit(
      id: _uuid.v4(),
      title: title,
      color: color,
      createdAt: now,
      updatedAt: now,
      completionHistory: [],
    );

    // Save to local storage first (offline-first)
    await HiveService.saveHabit(userId, habit);

    // Kick off remote save without blocking the caller.
    // Any error will be logged and later reconciled by SyncService.
    _firebaseService.createHabit(userId, habit).catchError((e) {
      print('Failed to save habit to remote: $e');
    });

    return habit;
  }

  // Update an existing habit
  Future<void> updateHabit(Habit habit, String userId) async {
    final updatedHabit = habit.copyWith(updatedAt: DateTime.now());
    
    // Update local storage first
    await HiveService.saveHabit(userId, updatedHabit);
    
    // Try to update remote
    try {
      await _firebaseService.updateHabit(userId, updatedHabit);
    } catch (e) {
      print('Failed to update habit on remote: $e');
    }
  }

  // Delete a habit
  Future<void> deleteHabit(String habitId, String userId) async {
    // Delete from local storage first
    await HiveService.deleteHabit(userId, habitId);
    
    // Try to delete from remote
    try {
      await _firebaseService.deleteHabit(userId, habitId);
    } catch (e) {
      print('Failed to delete habit from remote: $e');
    }
  }

  // Toggle today's completion for a habit
  Future<void> toggleTodayCompletion(Habit habit, String userId) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    List<DateTime> newCompletionHistory = List.from(habit.completionHistory);
    
    if (habit.isCompletedToday) {
      // Remove today's completion
      newCompletionHistory.removeWhere((date) {
        final completionDate = DateTime(date.year, date.month, date.day);
        return completionDate.isAtSameMomentAs(todayDate);
      });
    } else {
      // Add today's completion
      newCompletionHistory.add(today);
    }
    
    final updatedHabit = habit.copyWith(
      completionHistory: newCompletionHistory,
      updatedAt: DateTime.now(),
    );
    
    await updateHabit(updatedHabit, userId);
  }

  // Get all habits from local storage
  Future<List<Habit>> getAllHabits(String userId) async {
    return await HiveService.getAllHabits(userId);
  }

  // Get a specific habit by ID
  Future<Habit?> getHabit(String userId, String id) async {
    return await HiveService.getHabit(userId, id);
  }

  // Get habits stream from remote (for real-time updates)
  Stream<List<Habit>> getHabitsStream(String userId) {
    return _firebaseService.getHabitsStream(userId);
  }

  // Search habits by title
  Future<List<Habit>> searchHabits(String userId, String query) async {
    final allHabits = await getAllHabits(userId);
    if (query.isEmpty) return allHabits;
    
    return allHabits
        .where((habit) => 
            habit.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Get habits completed today
  Future<List<Habit>> getHabitsCompletedToday(String userId) async {
    final allHabits = await getAllHabits(userId);
    return allHabits.where((habit) => habit.isCompletedToday).toList();
  }

  // Get habits with active streaks
  Future<List<Habit>> getHabitsWithStreaks(String userId) async {
    final allHabits = await getAllHabits(userId);
    return allHabits
        .where((habit) => habit.currentStreak > 0)
        .toList()
      ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
  }
}
