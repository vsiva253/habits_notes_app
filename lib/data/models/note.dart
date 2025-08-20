import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'note.g.dart';

@HiveType(typeId: 1)
class Note extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String habitId;

  @HiveField(2)
  final String text;

  @HiveField(3)
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.habitId,
    required this.text,
    required this.createdAt,
  });

  Note copyWith({
    String? id,
    String? habitId,
    String? text,
    DateTime? createdAt,
  }) {
    return Note(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, habitId, text, createdAt];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
