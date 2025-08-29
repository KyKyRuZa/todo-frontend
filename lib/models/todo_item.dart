import 'package:flutter/material.dart';

class TodoItem {
  final int id;
  final String title;
  final String time; // Добавлено поле time
  final bool isCompleted;
  final DateTime? createdAt;
  final DateTime? completedAt;

  TodoItem({
    required this.id,
    required this.title,
    required this.time,
    required this.isCompleted,
    this.createdAt,
    this.completedAt,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      title: json['title'],
      time: json['time'] ?? '', // Убедитесь, что поле time обрабатывается
      isCompleted: json['completed'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'time': time, // Добавлено поле time
      'completed': isCompleted,
      'createdAt': createdAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
