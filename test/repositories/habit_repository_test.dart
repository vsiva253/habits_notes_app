// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/mockito.dart';
// import 'package:mockito/annotations.dart';
// import 'package:habits_notes_app/data/repositories/habit_repository.dart';
// import 'package:habits_notes_app/data/models/habit.dart';
// import 'package:habits_notes_app/services/firebase_service.dart';
// import 'package:habits_notes_app/services/hive_service.dart';

// import 'habit_repository_test.mocks.dart';

// @GenerateMocks([FirebaseService])
// void main() {
//   group('HabitRepository Tests', () {
//     late HabitRepository repository;
//     late MockFirebaseService mockFirebaseService;
//     const String testUserId = 'test-user-id';

//     setUp(() {
//       repository = HabitRepository();
//       mockFirebaseService = MockFirebaseService();
//       // Note: In a real test, you'd need to mock HiveService as well
//       // For now, we'll focus on testing the repository logic
//     });

//     group('createHabit', () {
//       test('should create habit with correct properties', () async {
//         const title = 'Test Habit';
//         const color = '#FF5722';

//         final habit = await repository.createHabit(
//           title: title,
//           color: color,
//           userId: testUserId,
//         );

//         expect(habit.title, title);
//         expect(habit.color, color);
//         expect(habit.id, isNotEmpty);
//         expect(habit.completionHistory, isEmpty);
//         expect(habit.createdAt, isA<DateTime>());
//         expect(habit.updatedAt, isA<DateTime>());
//       });

//       test('should generate unique IDs for different habits', () async {
//         final habit1 = await repository.createHabit(
//           title: 'Habit 1',
//           color: '#FF5722',
//           userId: testUserId,
//         );

//         final habit2 = await repository.createHabit(
//           title: 'Habit 2',
//           color: '#2196F3',
//           userId: testUserId,
//         );

//         expect(habit1.id, isNot(equals(habit2.id)));
//       });
//     });

//     group('toggleTodayCompletion', () {
//       late Habit testHabit;

//       setUp(() {
//         testHabit = Habit(
//           id: 'test-id',
//           title: 'Test Habit',
//           color: '#FF5722',
//           createdAt: DateTime.now(),
//           updatedAt: DateTime.now(),
//           completionHistory: [],
//         );
//       });

//       test('should add completion when habit is not completed today', () async {
//         expect(testHabit.isCompletedToday, false);

//         await repository.toggleTodayCompletion(testHabit, testUserId);

//         // In a real test, you'd verify the habit was saved with today's completion
//         // This would require mocking HiveService
//       });

//       test('should remove completion when habit is completed today', () async {
//         final today = DateTime.now();
//         final completedHabit = testHabit.copyWith(
//           completionHistory: [today],
//         );

//         expect(completedHabit.isCompletedToday, true);

//         await repository.toggleTodayCompletion(completedHabit, testUserId);

//         // In a real test, you'd verify the completion was removed
//       });

//       test('should preserve other completions when toggling today', () async {
//         final yesterday = DateTime.now().subtract(const Duration(days: 1));
//         final habitWithHistory = testHabit.copyWith(
//           completionHistory: [yesterday],
//         );

//         await repository.toggleTodayCompletion(habitWithHistory, testUserId);

//         // In a real test, you'd verify yesterday's completion is preserved
//       });
//     });

//     group('searchHabits', () {
//       test('should return empty list for empty query', () async {
//         // This test would require mocking HiveService.getAllHabits
//         // to return a list of test habits
//       });

//       test('should filter habits by title case-insensitively', () async {
//         // This test would require mocking HiveService.getAllHabits
//         // and verifying the filtering logic
//       });
//     });

//     group('getHabitsCompletedToday', () {
//       test('should return only habits completed today', () async {
//         // This test would require mocking HiveService.getAllHabits
//         // and verifying only today's completed habits are returned
//       });
//     });

//     group('getHabitsWithStreaks', () {
//       test('should return habits with active streaks sorted by streak length', () async {
//         // This test would require mocking HiveService.getAllHabits
//         // and verifying streak filtering and sorting
//       });
//     });
//   });
// }
