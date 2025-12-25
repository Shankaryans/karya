import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final List<TaskNotification> _notifications = [];

  List<TaskNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.length;

  /// Add a new notification
  void addNotification(TaskNotification notification) {
    _notifications.insert(0, notification); // Most recent first
    notifyListeners();
  }

  /// Remove notification by id (mark as read)
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
