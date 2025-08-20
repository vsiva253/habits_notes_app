import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/habit.dart';
import '../data/models/note.dart';
import '../data/models/user.dart' as app_user;

class HiveService {
  static const String userBoxName = 'userBox';
  
  // User-specific box names - will be created dynamically
  static String _getHabitsBoxName(String userId) => 'habits_$userId';
  static String _getNotesBoxName(String userId) => 'notes_$userId';

  static late Box<app_user.User> _userBox;
  
  // Dynamic boxes for each user
  static final Map<String, Box<Habit>> _habitsBoxes = {};
  static final Map<String, Box<Note>> _notesBoxes = {};

  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(app_user.UserAdapter());
    
    // Open user box
    _userBox = await Hive.openBox<app_user.User>(userBoxName);
    
    // IMPORTANT: Clear any existing global data to prevent data leakage
    await _clearLegacyGlobalData();
  }

  // Clear any existing global data from the old system
  static Future<void> _clearLegacyGlobalData() async {
    try {
      // Try to open and clear the old global boxes if they exist
      if (await Hive.boxExists('habitsBox')) {
        final oldHabitsBox = await Hive.openBox('habitsBox');
        await oldHabitsBox.clear();
        await oldHabitsBox.close();
        await Hive.deleteBoxFromDisk('habitsBox');
        print('[HiveService] Cleared legacy global habitsBox');
      }
      
      if (await Hive.boxExists('notesBox')) {
        final oldNotesBox = await Hive.openBox('notesBox');
        await oldNotesBox.clear();
        await oldNotesBox.close();
        await Hive.deleteBoxFromDisk('notesBox');
        print('[HiveService] Cleared legacy global notesBox');
      }
    } catch (e) {
      print('[HiveService] Error clearing legacy data: $e');
    }
  }

  // Get or create user-specific boxes
  static Future<Box<Habit>> _getHabitsBox(String userId) async {
    if (!_habitsBoxes.containsKey(userId)) {
      final boxName = _getHabitsBoxName(userId);
      _habitsBoxes[userId] = await Hive.openBox<Habit>(boxName);
    }
    return _habitsBoxes[userId]!;
  }

  static Future<Box<Note>> _getNotesBox(String userId) async {
    if (!_notesBoxes.containsKey(userId)) {
      final boxName = _getNotesBoxName(userId);
      _notesBoxes[userId] = await Hive.openBox<Note>(boxName);
    }
    return _notesBoxes[userId]!;
  }

  // Habit operations - now user-specific
  static Future<void> saveHabit(String userId, Habit habit) async {
    final box = await _getHabitsBox(userId);
    await box.put(habit.id, habit);
  }

  static Future<void> saveHabits(String userId, List<Habit> habits) async {
    final box = await _getHabitsBox(userId);
    final Map<String, Habit> habitMap = {
      for (final habit in habits) habit.id: habit
    };
    await box.putAll(habitMap);
  }

  static Future<Habit?> getHabit(String userId, String id) async {
    final box = await _getHabitsBox(userId);
    return box.get(id);
  }

  static Future<List<Habit>> getAllHabits(String userId) async {
    final box = await _getHabitsBox(userId);
    return box.values.toList();
  }

  static Future<void> deleteHabit(String userId, String id) async {
    final box = await _getHabitsBox(userId);
    await box.delete(id);
  }

  static Future<void> clearHabits(String userId) async {
    final box = await _getHabitsBox(userId);
    await box.clear();
  }

  // Note operations - now user-specific
  static Future<void> saveNote(String userId, Note note) async {
    final box = await _getNotesBox(userId);
    await box.put(note.id, note);
  }

  static Future<void> saveNotes(String userId, List<Note> notes) async {
    final box = await _getNotesBox(userId);
    final Map<String, Note> noteMap = {
      for (final note in notes) note.id: note
    };
    await box.putAll(noteMap);
  }

  static Future<Note?> getNote(String userId, String id) async {
    final box = await _getNotesBox(userId);
    return box.get(id);
  }

  static Future<List<Note>> getNotesForHabit(String userId, String habitId) async {
    final box = await _getNotesBox(userId);
    final notes = box.values
        .where((note) => note.habitId == habitId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  static Future<List<Note>> getAllNotes(String userId) async {
    final box = await _getNotesBox(userId);
    return box.values.toList();
  }

  static Future<void> deleteNote(String userId, String id) async {
    final box = await _getNotesBox(userId);
    await box.delete(id);
  }

  static Future<void> clearNotes(String userId) async {
    final box = await _getNotesBox(userId);
    await box.clear();
  }

  // User operations
  static Future<void> saveUser(app_user.User user) async {
    await _userBox.put('current_user', user);
  }

  static app_user.User? getCurrentUser() {
    return _userBox.get('current_user');
  }

  static Future<void> clearUser() async {
    await _userBox.clear();
  }

  // Clear all user data when signing out
  static Future<void> clearAllUserData(String userId) async {
    // Clear user-specific data
    await clearHabits(userId);
    await clearNotes(userId);
    
    // Close and remove user-specific boxes
    if (_habitsBoxes.containsKey(userId)) {
      await _habitsBoxes[userId]!.close();
      _habitsBoxes.remove(userId);
    }
    
    if (_notesBoxes.containsKey(userId)) {
      await _notesBoxes[userId]!.close();
      _notesBoxes.remove(userId);
    }
    
    // Clear current user
    await clearUser();
  }

  // Utility methods - now user-specific
  static Future<bool> hasData(String userId) async {
    final habitsBox = await _getHabitsBox(userId);
    final notesBox = await _getNotesBox(userId);
    return habitsBox.isNotEmpty || notesBox.isNotEmpty;
  }

  static Future<int> getHabitsCount(String userId) async {
    final box = await _getHabitsBox(userId);
    return box.length;
  }

  static Future<int> getNotesCount(String userId) async {
    final box = await _getNotesBox(userId);
    return box.length;
  }

  static Future<void> close() async {
    // Close all user-specific boxes
    for (final box in _habitsBoxes.values) {
      await box.close();
    }
    for (final box in _notesBoxes.values) {
      await box.close();
    }
    
    // Clear the maps
    _habitsBoxes.clear();
    _notesBoxes.clear();
    
    // Close user box
    await _userBox.close();
  }
}
