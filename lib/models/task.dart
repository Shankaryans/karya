import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

part 'task.g.dart';

enum TaskPriority { low, medium, high }

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final DateTime dueDate;

  @HiveField(8)
  final String startTime; // "HH:mm"

  @HiveField(9)
  final String endTime; // "HH:mm"

  @HiveField(4)
  final bool isCompleted;

  @HiveField(5)
  final String priority; // 'low', 'medium', 'high'

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? updatedAt;

  Task({
    String? id,
    required this.title,
    this.description,
    required this.dueDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    this.isCompleted = false,
    this.priority = 'medium',
    DateTime? createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4(),
       startTime = _timeOfDayToString(
         startTime ?? const TimeOfDay(hour: 9, minute: 0),
       ),
       endTime = _timeOfDayToString(
         endTime ?? const TimeOfDay(hour: 10, minute: 0),
       ),
       createdAt = createdAt ?? DateTime.now();

  // Convert TimeOfDay to String
  static String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Convert String to TimeOfDay
  static TimeOfDay _stringToTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Getter to return TimeOfDay
  TimeOfDay getStartTime() => _stringToTimeOfDay(startTime);
  TimeOfDay getEndTime() => _stringToTimeOfDay(endTime);

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isCompleted,
    String? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      startTime: startTime ?? getStartTime(),
      endTime: endTime ?? getEndTime(),
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Task(id: $id, title: $title, priority: $priority, start:$startTime end:$endTime)';
}
