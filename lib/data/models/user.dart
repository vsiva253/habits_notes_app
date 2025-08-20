import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'user.g.dart';

@HiveType(typeId: 2)
class User extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? email,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, email, createdAt];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
