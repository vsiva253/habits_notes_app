import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
class Habit extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String color;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  @HiveField(5)
  final List<DateTime> completionHistory;

  const Habit({
    required this.id,
    required this.title,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    required this.completionHistory,
  });

  Habit copyWith({
    String? id,
    String? title,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<DateTime>? completionHistory,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completionHistory: completionHistory ?? this.completionHistory,
    );
  }

  bool get isCompletedToday {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return completionHistory.any((date) {
      final completionDate = DateTime(date.year, date.month, date.day);
      return completionDate.isAtSameMomentAs(todayDate);
    });
  }

  double get todayProgress {
    return isCompletedToday ? 1.0 : 0.0;
  }

  int get currentStreak {
    if (completionHistory.isEmpty) return 0;
    
    final sortedDates = List<DateTime>.from(completionHistory)
      ..sort((a, b) => b.compareTo(a));
    
    int streak = 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    for (int i = 0; i < sortedDates.length; i++) {
      final completionDate = DateTime(
        sortedDates[i].year,
        sortedDates[i].month,
        sortedDates[i].day,
      );
      
      if (i == 0) {
        if (completionDate.isAtSameMomentAs(todayDate)) {
          streak = 1;
        } else if (completionDate.isAtSameMomentAs(
          todayDate.subtract(const Duration(days: 1)),
        )) {
          streak = 1;
        } else {
          break;
        }
      } else {
        final previousDate = DateTime(
          sortedDates[i - 1].year,
          sortedDates[i - 1].month,
          sortedDates[i - 1].day,
        );
        
        if (previousDate.difference(completionDate).inDays == 1) {
          streak++;
        } else {
          break;
        }
      }
    }
    
    return streak;
  }

  @override
  List<Object?> get props => [id, title, color, createdAt, updatedAt, completionHistory];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completionHistory': completionHistory
          .map((date) => date.toIso8601String())
          .toList(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      color: json['color'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completionHistory: (json['completionHistory'] as List<dynamic>)
          .map((date) => DateTime.parse(date as String))
          .toList(),
    );
  }
}
