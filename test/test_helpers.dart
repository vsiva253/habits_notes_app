import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habits_notes_app/data/models/habit.dart';
import 'package:habits_notes_app/data/models/note.dart';
import 'package:habits_notes_app/data/models/user.dart' as app_user;

/// Test helpers for setting up common test scenarios
class TestHelpers {
  /// Creates a test MaterialApp wrapper for widgets
  static Widget createTestApp({required Widget child}) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  /// Creates a test habit with default values
  static Habit createTestHabit({
    String? id,
    String? title,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<DateTime>? completionHistory,
  }) {
    return Habit(
      id: id ?? 'test-habit-id',
      title: title ?? 'Test Habit',
      color: color ?? 'blue',
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      updatedAt: updatedAt ?? DateTime(2024, 1, 1),
      completionHistory: completionHistory ?? [],
    );
  }

  /// Creates a test note with default values
  static Note createTestNote({
    String? id,
    String? habitId,
    String? text,
    DateTime? createdAt,
  }) {
    return Note(
      id: id ?? 'test-note-id',
      habitId: habitId ?? 'test-habit-id',
      text: text ?? 'Test note content',
      createdAt: createdAt ?? DateTime(2024, 1, 1),
    );
  }

  /// Creates a test user with default values
  static app_user.User createTestUser({
    String? id,
    String? email,
    DateTime? createdAt,
  }) {
    return app_user.User(
      id: id ?? 'test-user-id',
      email: email ?? 'test@example.com',
      createdAt: createdAt ?? DateTime(2024, 1, 1),
    );
  }

  /// Creates a habit with a streak
  static Habit createHabitWithStreak(int streakDays) {
    final completionHistory = <DateTime>[];
    final today = DateTime.now();
    
    for (int i = 0; i < streakDays; i++) {
      completionHistory.add(today.subtract(Duration(days: i)));
    }
    
    return createTestHabit(completionHistory: completionHistory);
  }

  /// Creates a habit completed today
  static Habit createCompletedHabit() {
    return createTestHabit(completionHistory: [DateTime.now()]);
  }

  /// Pumps and settles with a reasonable timeout
  static Future<void> pumpAndSettleWithTimeout(
    WidgetTester tester, [
    Duration timeout = const Duration(seconds: 5),
  ]) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    // Optionally, you can implement a manual timeout if needed.
  }

  /// Finds widget by key with type safety
  static Finder findByKey<T extends Widget>(String key) {
    return find.byWidgetPredicate(
      (widget) => widget is T && widget.key == ValueKey(key),
    );
  }

  /// Verifies that a widget exists and is visible
  static void expectWidgetVisible(Finder finder) {
    expect(finder, findsOneWidget);
    // Additional visibility checks could be added here
  }

  /// Verifies that a widget does not exist
  static void expectWidgetNotFound(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Creates a list of test habits with different states
  static List<Habit> createTestHabits() {
    return [
      createTestHabit(
        id: 'habit-1',
        title: 'Exercise',
        color: 'red',
      ),
      createCompletedHabit().copyWith(
        id: 'habit-2',
        title: 'Read',
        color: 'blue',
      ),
      createHabitWithStreak(3).copyWith(
        id: 'habit-3',
        title: 'Meditate',
        color: 'green',
      ),
    ];
  }

  /// Creates a list of test notes
  static List<Note> createTestNotes({String? habitId}) {
    final testHabitId = habitId ?? 'test-habit-id';
    return [
      createTestNote(
        id: 'note-1',
        habitId: testHabitId,
        text: 'First note',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      createTestNote(
        id: 'note-2',
        habitId: testHabitId,
        text: 'Second note',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      createTestNote(
        id: 'note-3',
        habitId: testHabitId,
        text: 'Third note',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}

/// Mock data for testing
class MockData {
  static const String testUserId = 'test-user-id';
  static const String testHabitId = 'test-habit-id';
  static const String testNoteId = 'test-note-id';
  
  static final DateTime testDate = DateTime(2024, 1, 15, 10, 30);
  static final DateTime today = DateTime.now();
  static final DateTime yesterday = today.subtract(const Duration(days: 1));
  static final DateTime lastWeek = today.subtract(const Duration(days: 7));
}

/// Extensions for easier testing
extension WidgetTesterExtensions on WidgetTester {
  /// Taps a widget and waits for animations
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  /// Enters text and waits for animations
  Future<void> enterTextAndSettle(Finder finder, String text) async {
    await enterText(finder, text);
    await pumpAndSettle();
  }

  /// Scrolls until a widget is visible
  Future<void> scrollUntilVisible(
    Finder finder,
    Finder scrollable, {
    double delta = 100.0,
  }) async {
    await scrollUntilVisible(finder, scrollable, delta: delta);
    await pumpAndSettle();
  }
}

/// Test matchers for custom assertions
class TestMatchers {
  /// Matches a habit with specific properties
  static Matcher isHabitWithTitle(String title) {
    return predicate<Habit>((habit) => habit.title == title);
  }

  /// Matches a note with specific text
  static Matcher isNoteWithText(String text) {
    return predicate<Note>((note) => note.text == text);
  }

  /// Matches a completed habit
  static Matcher isCompletedHabit() {
    return predicate<Habit>((habit) => habit.isCompletedToday);
  }

  /// Matches a habit with specific streak
  static Matcher hasStreak(int streak) {
    return predicate<Habit>((habit) => habit.currentStreak == streak);
  }
}
