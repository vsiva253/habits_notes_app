import 'package:flutter/foundation.dart';
import '../data/models/habit.dart';

class HabitSummary {
  final int totalHabits;
  final int completedToday;
  final double completionRate;
  final int averageStreak;
  final int bestStreak;

  const HabitSummary({
    required this.totalHabits,
    required this.completedToday,
    required this.completionRate,
    required this.averageStreak,
    required this.bestStreak,
  });
}

class AnalyticsService {
  static Future<HabitSummary> generateSummary(List<Habit> habits) async {
    return await compute(_generateSummaryIsolate, habits);
  }

  static HabitSummary _generateSummaryIsolate(List<Habit> habits) {
    if (habits.isEmpty) {
      return const HabitSummary(
        totalHabits: 0,
        completedToday: 0,
        completionRate: 0.0,
        averageStreak: 0,
        bestStreak: 0,
      );
    }

    final totalHabits = habits.length;
    final completedToday = habits.where((habit) => habit.isCompletedToday).length;
    final completionRate = completedToday / totalHabits;

    final streaks = habits.map((habit) => habit.currentStreak).toList();
    final averageStreak = streaks.reduce((a, b) => a + b) / streaks.length;
    final bestStreak = streaks.reduce((a, b) => a > b ? a : b);

    return HabitSummary(
      totalHabits: totalHabits,
      completedToday: completedToday,
      completionRate: completionRate,
      averageStreak: averageStreak.round(),
      bestStreak: bestStreak,
    );
  }

  static Future<Map<String, dynamic>> generateDetailedAnalytics(List<Habit> habits) async {
    return await compute(_generateDetailedAnalyticsIsolate, habits);
  }

  static Map<String, dynamic> _generateDetailedAnalyticsIsolate(List<Habit> habits) {
    if (habits.isEmpty) {
      return {
        'weeklyData': List.generate(7, (index) => 0),
        'habitPerformance': <String, Map<String, dynamic>>{},
        'trends': <String, dynamic>{},
      };
    }

    // Generate 7-day completion data
    final now = DateTime.now();
    final weeklyData = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final dateOnly = DateTime(date.year, date.month, date.day);
      
      int completedCount = 0;
      for (final habit in habits) {
        if (habit.completionHistory.any((completionDate) {
          final completionDateOnly = DateTime(
            completionDate.year,
            completionDate.month,
            completionDate.day,
          );
          return completionDateOnly.isAtSameMomentAs(dateOnly);
        })) {
          completedCount++;
        }
      }
      return completedCount;
    });

    // Generate habit performance data
    final habitPerformance = <String, Map<String, dynamic>>{};
    for (final habit in habits) {
      habitPerformance[habit.id] = {
        'title': habit.title,
        'color': habit.color,
        'streak': habit.currentStreak,
        'totalCompletions': habit.completionHistory.length,
        'completionRate': habit.completionHistory.length / 30, // Assuming 30 days
      };
    }

    // Generate trends
    final totalCompletions = habits.fold<int>(
      0,
      (sum, habit) => sum + habit.completionHistory.length,
    );
    final averageCompletions = totalCompletions / habits.length;

    return {
      'weeklyData': weeklyData,
      'habitPerformance': habitPerformance,
      'trends': {
        'totalCompletions': totalCompletions,
        'averageCompletions': averageCompletions.round(),
        'mostActiveDay': _findMostActiveDay(habits),
      },
    };
  }

  static String _findMostActiveDay(List<Habit> habits) {
    final dayCounts = <int, int>{};
    
    for (final habit in habits) {
      for (final completionDate in habit.completionHistory) {
        final weekday = completionDate.weekday;
        dayCounts[weekday] = (dayCounts[weekday] ?? 0) + 1;
      }
    }

    if (dayCounts.isEmpty) return 'Monday';

    final mostActiveDay = dayCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return weekdays[mostActiveDay - 1];
  }
}
