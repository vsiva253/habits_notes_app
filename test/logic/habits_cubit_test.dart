// import 'package:flutter_test/flutter_test.dart';
// import 'package:bloc_test/bloc_test.dart';
// import 'package:mockito/mockito.dart';
// import 'package:mockito/annotations.dart';
// import 'package:habits_notes_app/logic/habits_cubit.dart';
// import 'package:habits_notes_app/data/repositories/habit_repository.dart';
// import 'package:habits_notes_app/data/models/habit.dart';
// import 'package:habits_notes_app/services/analytics_service.dart';

// import 'habits_cubit_test.mocks.dart';

// @GenerateMocks([HabitRepository])
// void main() {
//   group('HabitsCubit Tests', () {
//     late HabitsCubit habitsCubit;
//     late MockHabitRepository mockRepository;
//     const String testUserId = 'test-user-id';

//     setUp(() {
//       mockRepository = MockHabitRepository();
//       habitsCubit = HabitsCubit();
//       // Note: In a real implementation, you'd inject the repository
//     });

//     tearDown(() {
//       habitsCubit.close();
//     });

//     group('loadHabits', () {
//       final testHabits = [
//         Habit(
//           id: '1',
//           title: 'Exercise',
//           color: '#FF5722',
//           createdAt: DateTime(2024, 1, 1),
//           updatedAt: DateTime(2024, 1, 1),
//           completionHistory: [],
//         ),
//         Habit(
//           id: '2',
//           title: 'Read',
//           color: '#2196F3',
//           createdAt: DateTime(2024, 1, 2),
//           updatedAt: DateTime(2024, 1, 2),
//           completionHistory: [DateTime.now()],
//         ),
//       ];

//       blocTest<HabitsCubit, HabitsState>(
//         'emits [HabitsLoading, HabitsLoaded] when loadHabits succeeds',
//         build: () {
//           when(mockRepository.getAllHabits(testUserId))
//               .thenAnswer((_) async => testHabits);
//           return habitsCubit;
//         },
//         act: (cubit) => cubit.loadHabits(testUserId),
//         expect: () => [
//           HabitsLoading(),
//           isA<HabitsLoaded>()
//               .having((state) => state.habits.length, 'habits length', 2)
//               .having((state) => state.filteredHabits.length, 'filtered habits length', 2),
//         ],
//       );

//       blocTest<HabitsCubit, HabitsState>(
//         'emits [HabitsLoading, HabitsError] when loadHabits fails',
//         build: () {
//           when(mockRepository.getAllHabits(testUserId))
//               .thenThrow(Exception('Failed to load habits'));
//           return habitsCubit;
//         },
//         act: (cubit) => cubit.loadHabits(testUserId),
//         expect: () => [
//           HabitsLoading(),
//           isA<HabitsError>()
//               .having((state) => state.message, 'error message', contains('Failed to load habits')),
//         ],
//       );

//       blocTest<HabitsCubit, HabitsState>(
//         'sorts habits correctly with completed habits at bottom',
//         build: () {
//           when(mockRepository.getAllHabits(testUserId))
//               .thenAnswer((_) async => testHabits);
//           return habitsCubit;
//         },
//         act: (cubit) => cubit.loadHabits(testUserId),
//         verify: (cubit) {
//           final state = cubit.state as HabitsLoaded;
//           // Completed habit (Read) should be at bottom
//           expect(state.habits.last.title, 'Read');
//           // Incomplete habit (Exercise) should be at top
//           expect(state.habits.first.title, 'Exercise');
//         },
//       );
//     });

//     group('createHabit', () {
//       const title = 'New Habit';
//       const color = '#4CAF50';

//       final newHabit = Habit(
//         id: 'new-id',
//         title: title,
//         color: color,
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//         completionHistory: [],
//       );

//       blocTest<HabitsCubit, HabitsState>(
//         'adds new habit to existing habits when createHabit succeeds',
//         build: () {
//           when(mockRepository.createHabit(
//             title: title,
//             color: color,
//             userId: testUserId,
//           )).thenAnswer((_) async => newHabit);
//           return habitsCubit;
//         },
//         seed: () => const HabitsLoaded(habits: [], filteredHabits: []),
//         act: (cubit) => cubit.createHabit(
//           title: title,
//           color: color,
//           userId: testUserId,
//         ),
//         expect: () => [
//           isA<HabitsLoaded>()
//               .having((state) => state.habits.length, 'habits length', 1)
//               .having((state) => state.habits.first.title, 'first habit title', title),
//         ],
//       );

//       blocTest<HabitsCubit, HabitsState>(
//         'emits HabitsError when createHabit fails',
//         build: () {
//           when(mockRepository.createHabit(
//             title: title,
//             color: color,
//             userId: testUserId,
//           )).thenThrow(Exception('Failed to create habit'));
//           return habitsCubit;
//         },
//         seed: () => const HabitsLoaded(habits: [], filteredHabits: []),
//         act: (cubit) => cubit.createHabit(
//           title: title,
//           color: color,
//           userId: testUserId,
//         ),
//         expect: () => [
//           isA<HabitsError>()
//               .having((state) => state.message, 'error message', contains('Failed to create habit')),
//         ],
//       );
//     });

//     group('updateHabit', () {
//       final originalHabit = Habit(
//         id: 'update-id',
//         title: 'Original Title',
//         color: '#FF5722',
//         createdAt: DateTime(2024, 1, 1),
//         updatedAt: DateTime(2024, 1, 1),
//         completionHistory: [],
//       );

//       final updatedHabit = originalHabit.copyWith(
//         title: 'Updated Title',
//         updatedAt: DateTime.now(),
//       );

//       blocTest<HabitsCubit, HabitsState>(
//         'updates habit in the list when updateHabit succeeds',
//         build: () {
//           when(mockRepository.updateHabit(updatedHabit, testUserId))
//               .thenAnswer((_) async {});
//           return habitsCubit;
//         },
//         seed: () => HabitsLoaded(
//           habits: [originalHabit],
//           filteredHabits: [originalHabit],
//         ),
//         act: (cubit) => cubit.updateHabit(updatedHabit, testUserId),
//         expect: () => [
//           isA<HabitsLoaded>()
//               .having((state) => state.habits.first.title, 'updated title', 'Updated Title'),
//         ],
//       );
//     });

//     group('deleteHabit', () {
//       final habitToDelete = Habit(
//         id: 'delete-id',
//         title: 'Delete Me',
//         color: '#FF5722',
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//         completionHistory: [],
//       );

//       blocTest<HabitsCubit, HabitsState>(
//         'removes habit from list when deleteHabit succeeds',
//         build: () {
//           when(mockRepository.deleteHabit('delete-id', testUserId))
//               .thenAnswer((_) async {});
//           return habitsCubit;
//         },
//         seed: () => HabitsLoaded(
//           habits: [habitToDelete],
//           filteredHabits: [habitToDelete],
//         ),
//         act: (cubit) => cubit.deleteHabit('delete-id', testUserId),
//         expect: () => [
//           isA<HabitsLoaded>()
//               .having((state) => state.habits, 'habits', isEmpty)
//               .having((state) => state.filteredHabits, 'filtered habits', isEmpty),
//         ],
//       );
//     });

//     group('searchHabits', () {
//       final habits = [
//         Habit(
//           id: '1',
//           title: 'Exercise',
//           color: '#FF5722',
//           createdAt: DateTime.now(),
//           updatedAt: DateTime.now(),
//           completionHistory: [],
//         ),
//         Habit(
//           id: '2',
//           title: 'Read Books',
//           color: '#2196F3',
//           createdAt: DateTime.now(),
//           updatedAt: DateTime.now(),
//           completionHistory: [],
//         ),
//       ];

//       blocTest<HabitsCubit, HabitsState>(
//         'filters habits based on search query',
//         build: () {
//           when(mockRepository.searchHabits(testUserId, 'read'))
//               .thenAnswer((_) async => [habits[1]]);
//           return habitsCubit;
//         },
//         seed: () => HabitsLoaded(habits: habits, filteredHabits: habits),
//         act: (cubit) => cubit.searchHabits('read', testUserId),
//         expect: () => [
//           isA<HabitsLoaded>()
//               .having((state) => state.filteredHabits.length, 'filtered count', 1)
//               .having((state) => state.filteredHabits.first.title, 'filtered title', 'Read Books')
//               .having((state) => state.searchQuery, 'search query', 'read'),
//         ],
//       );

//       blocTest<HabitsCubit, HabitsState>(
//         'shows all habits when search query is empty',
//         build: () {
//           when(mockRepository.searchHabits(testUserId, ''))
//               .thenAnswer((_) async => habits);
//           return habitsCubit;
//         },
//         seed: () => HabitsLoaded(
//           habits: habits,
//           filteredHabits: [habits[1]], // Previously filtered
//           searchQuery: 'read',
//         ),
//         act: (cubit) => cubit.searchHabits('', testUserId),
//         expect: () => [
//           isA<HabitsLoaded>()
//               .having((state) => state.filteredHabits.length, 'filtered count', 2)
//               .having((state) => state.searchQuery, 'search query', ''),
//         ],
//       );
//     });

//     group('toggleHabitCompletion', () {
//       final habit = Habit(
//         id: 'toggle-id',
//         title: 'Toggle Habit',
//         color: '#FF5722',
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//         completionHistory: [],
//       );

//       blocTest<HabitsCubit, HabitsState>(
//         'reloads habits after toggling completion',
//         build: () {
//           when(mockRepository.toggleTodayCompletion(habit, testUserId))
//               .thenAnswer((_) async {});
//           when(mockRepository.getAllHabits(testUserId))
//               .thenAnswer((_) async => [habit]);
//           return habitsCubit;
//         },
//         act: (cubit) => cubit.toggleHabitCompletion(habit, testUserId),
//         expect: () => [
//           HabitsLoading(),
//           isA<HabitsLoaded>(),
//         ],
//       );
//     });

//     group('state management', () {
//       test('initial state is HabitsInitial', () {
//         expect(habitsCubit.state, isA<HabitsInitial>());
//       });

//       test('HabitsLoaded copyWith works correctly', () {
//         const originalState = HabitsLoaded(
//           habits: [],
//           filteredHabits: [],
//           searchQuery: 'test',
//         );

//         final newHabits = [
//           Habit(
//             id: '1',
//             title: 'New Habit',
//             color: '#FF5722',
//             createdAt: DateTime.now(),
//             updatedAt: DateTime.now(),
//             completionHistory: [],
//           ),
//         ];

//         final newState = originalState.copyWith(habits: newHabits);

//         expect(newState.habits, newHabits);
//         expect(newState.filteredHabits, originalState.filteredHabits);
//         expect(newState.searchQuery, originalState.searchQuery);
//       });
//     });
//   });
// }
