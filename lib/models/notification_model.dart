import 'package:uuid/uuid.dart';

enum NotificationType { preStart, taskStart, taskEnd, taskCompleted, taskPending }

class TaskNotification {
  final String id;
  final String taskId;
  final String taskTitle;
  final String message;
  final NotificationType type;
  final DateTime timestamp;

  TaskNotification({
    String? id,
    required this.taskId,
    required this.taskTitle,
    required this.message,
    required this.type,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'Notification($type: $message)';
}
