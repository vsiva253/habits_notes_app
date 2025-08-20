import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../../services/firebase_service.dart';
import '../../services/hive_service.dart';

class NoteRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = const Uuid();

  // Create a new note
  Future<Note> createNote({
    required String text,
    required String habitId,
    required String userId,
  }) async {
    final note = Note(
      id: _uuid.v4(),
      habitId: habitId,
      text: text,
      createdAt: DateTime.now(),
    );

    // Save to local storage first (offline-first)
    await HiveService.saveNote(userId, note);
    
    // Try to save to remote (will sync later if fails)
    try {
      await _firebaseService.createNote(userId, note);
    } catch (e) {
      // Log error but don't fail - data is saved locally
      print('Failed to save note to remote: $e');
    }

    return note;
  }

  // Update an existing note
  Future<void> updateNote(Note note, String userId) async {
    // Update local storage first
    await HiveService.saveNote(userId, note);
    
    // Try to update remote
    try {
      await _firebaseService.updateNote(userId, note);
    } catch (e) {
      print('Failed to update note on remote: $e');
    }
  }

  // Delete a note
  Future<void> deleteNote(String noteId, String userId) async {
    // Delete from local storage first
    await HiveService.deleteNote(userId, noteId);
    
    // Try to delete from remote
    try {
      await _firebaseService.deleteNote(userId, noteId);
    } catch (e) {
      print('Failed to delete note from remote: $e');
    }
  }

  // Get all notes for a specific habit from local storage
  Future<List<Note>> getNotesForHabit(String userId, String habitId) async {
    return await HiveService.getNotesForHabit(userId, habitId);
  }

  // Get a specific note by ID
  Future<Note?> getNote(String userId, String id) async {
    return await HiveService.getNote(userId, id);
  }

  // Get notes stream from remote (for real-time updates)
  Stream<List<Note>> getNotesStream(String userId, String habitId) {
    return _firebaseService.getNotesStream(userId, habitId);
  }

  // Get all notes from local storage
  Future<List<Note>> getAllNotes(String userId) async {
    return await HiveService.getAllNotes(userId);
  }

  // Search notes by text content
  Future<List<Note>> searchNotes(String userId, String query, {String? habitId}) async {
    final notes = habitId != null 
        ? await getNotesForHabit(userId, habitId)
        : await getAllNotes(userId);
    
    if (query.isEmpty) return notes;
    
    return notes
        .where((note) => 
            note.text.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Get recent notes (last 10)
  Future<List<Note>> getRecentNotes(String userId, {int limit = 10}) async {
    final allNotes = await getAllNotes(userId);
    allNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allNotes.take(limit).toList();
  }

  // Get notes count for a habit
  Future<int> getNotesCountForHabit(String userId, String habitId) async {
    final notes = await getNotesForHabit(userId, habitId);
    return notes.length;
  }
}
