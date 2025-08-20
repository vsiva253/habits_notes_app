import 'package:flutter_test/flutter_test.dart';
import 'package:habits_notes_app/services/analytics_service.dart';
import 'package:habits_notes_app/data/models/habit.dart';

void main() {
  group('AnalyticsService Tests', () {
    test('generateSummary returns correct analytics for empty habits list', () async {
      final summary = await AnalyticsService.generateSummary([]);

      expect(summary.totalHabits, 0);
      expect(summary.completedToday, 0);
      expect(summary.completionRate, 0.0);
      expect(summary.averageStreak, 0);
      expect(summary.bestStreak, 0);
    });

    test('generateSummary calculates correct metrics for habits with data', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      
      final habits = [
        Habit(
          id: '1',
          title: 'Exercise',
          color: 'red',
          createdAt: yesterday,
          updatedAt: today,
          completionHistory: [today, yesterday], // 2-day streak, completed today
        ),
        Habit(
          id: '2',
          title: 'Read',
          color: 'blue',
          createdAt: yesterday,
          updatedAt: yesterday,
          completionHistory: [yesterday], // 1-day streak, not completed today
        ),
      ];

      final summary = await AnalyticsService.generateSummary(habits);

      expect(summary.totalHabits, 2);
      expect(summary.completedToday, 1);
      expect(summary.completionRate, 0.5);
      expect(summary.averageStreak, 2); // (2 + 1) / 2 = 1.5, rounded to 2
      expect(summary.bestStreak, 2);
    });
  });
}
