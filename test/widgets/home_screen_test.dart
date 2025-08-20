import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habits_notes_app/ui/widgets/habit_card.dart';
import 'package:habits_notes_app/data/models/habit.dart';

// Simple test cubit that doesn't depend on Firebase
class TestHabitsCubit extends Cubit<List<Habit>> {
  TestHabitsCubit() : super([]);

  void loadHabits(List<Habit> habits) {
    emit(habits);
  }
}

void main() {
  group('BLoC Widget Test', () {
    testWidgets('BlocBuilder displays habits when cubit state changes', (WidgetTester tester) async {
      // Arrange
      final testHabits = [
        Habit(
          id: '1',
          title: 'Exercise',
          color: 'red',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          completionHistory: [],
        ),
        Habit(
          id: '2',
          title: 'Read Books',
          color: 'blue',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          completionHistory: [DateTime.now()],
        ),
      ];

      final testCubit = TestHabitsCubit();

      // Create a widget that uses BlocBuilder
      Widget testWidget = MaterialApp(
        home: Scaffold(
          body: BlocProvider<TestHabitsCubit>(
            create: (_) => testCubit,
            child: BlocBuilder<TestHabitsCubit, List<Habit>>(
              builder: (context, habits) {
                if (habits.isEmpty) {
                  return const Text('No habits');
                }
                return Column(
                  children: habits.map((habit) => 
                    HabitCard(
                      key: Key(habit.id),
                      habit: habit,
                      onTap: () {},
                      onToggleCompletion: () {},
                    )
                  ).toList(),
                );
              },
            ),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(testWidget);
      
      // Initially should show "No habits"
      expect(find.text('No habits'), findsOneWidget);

      // Load habits via cubit
      testCubit.loadHabits(testHabits);
      await tester.pump();

      // Assert - habits should now be displayed
      expect(find.text('Exercise'), findsOneWidget);
      expect(find.text('Read Books'), findsOneWidget);
      expect(find.text('No habits'), findsNothing);

      // Cleanup
      testCubit.close();
    });
  });
}
