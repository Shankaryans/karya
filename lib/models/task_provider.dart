import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'task.dart';
import '../services/notification_service.dart';
import '../providers/notification_provider.dart';
import 'dart:async';
import 'notification_model.dart';

/// Repository for task persistence using Hive
class TaskRepository {
  static const String _boxName = 'tasks_box';

  /// Initialize Hive and get the box
  static Future<Box<Task>> _getBox() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskAdapter());
    }
    return await Hive.openBox<Task>(_boxName);
  }

  /// Get all tasks
  static Future<List<Task>> getAllTasks() async {
    final box = await _getBox();
    return box.values.toList();
  }

  /// Add a new task
  static Future<void> addTask(Task task) async {
    final box = await _getBox();
    await box.put(task.id, task);
  }

  /// Update an existing task
  static Future<void> updateTask(Task task) async {
    final box = await _getBox();
    await box.put(task.id, task);
  }

  /// Delete a task by ID
  static Future<void> deleteTask(String taskId) async {
    final box = await _getBox();
    await box.delete(taskId);
  }

  /// Check if a date has tasks
  static Future<bool> hasTasksOnDate(DateTime date) async {
    final box = await _getBox();
    final dateOnly = DateTime(date.year, date.month, date.day);
    return box.values.any((task) {
      final taskDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      return taskDate.isAtSameMomentAs(dateOnly);
    });
  }

  /// Get all dates with tasks
  static Future<Set<DateTime>> getDatesWithTasks() async {
    final box = await _getBox();
    final dates = <DateTime>{};
    for (var task in box.values) {
      dates.add(
        DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day),
      );
    }
    return dates;
  }

  /// Clear all tasks
  static Future<void> clearAllTasks() async {
    final box = await _getBox();
    await box.clear();
  }
}

enum TaskStatusFilter { all, completed, pending, incomplete }

/// Provider for managing task state
class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  Set<DateTime> _datesWithTasks = {};

  // Filters
  TaskStatusFilter _statusFilter = TaskStatusFilter.all;
  String _priorityFilter = 'all';

  // Notification tracking
  Timer? _notificationTimer;
  final Set<String> _notifiedStart = {};
  final Set<String> _notifiedEnd = {};
  final Set<String> _notifiedPreStart = {};
  final Map<String, DateTime?> _snoozedUntil = {};
  NotificationProvider? _notificationProvider;

  TaskProvider({NotificationProvider? notificationProvider}) {
    _notificationProvider = notificationProvider;
    _initializeTasks();
  }

  // Getters
  List<Task> get tasks => _filteredTasks;
  DateTime get selectedDate => _selectedDate;
  String get searchQuery => _searchQuery;
  Set<DateTime> get datesWithTasks => _datesWithTasks;
  TaskStatusFilter get statusFilter => _statusFilter;
  String get priorityFilter => _priorityFilter;

  // Task Statistics Getters
  int get total => _filteredTasks.length;
  int get completed => _filteredTasks.where((task) => task.isCompleted).length;
  int get pending => _filteredTasks.where((task) => !task.isCompleted).length;
  int get incomplete => _filteredTasks.where((task) => _isOverdue(task)).length;
  int get highPriority => _filteredTasks
      .where((task) => task.priority.toLowerCase() == 'high')
      .length;
  int get middlePriority => _filteredTasks
      .where((task) => task.priority.toLowerCase() == 'medium')
      .length;
  int get lowPriority => _filteredTasks
      .where((task) => task.priority.toLowerCase() == 'low')
      .length;

  // Filter setters
  void setStatusFilter(TaskStatusFilter filter) {
    _statusFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void setPriorityFilter(String priority) {
    _priorityFilter = priority.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  /// Initialize tasks from persistent storage
  Future<void> _initializeTasks() async {
    _tasks = await TaskRepository.getAllTasks();
    _datesWithTasks = await TaskRepository.getDatesWithTasks();
    _applyFilters();
    _startNotificationTimer();
    notifyListeners();
  }

  void _startNotificationTimer() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkNotifications(),
    );
  }

  void _checkNotifications() {
    final now = DateTime.now();

    for (final task in _tasks) {
      final snoozeUntil = _snoozedUntil[task.id];
      if (snoozeUntil != null && now.isBefore(snoozeUntil)) continue;

      final startDT = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
        task.getStartTime().hour,
        task.getStartTime().minute,
      );
      final endDT = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
        task.getEndTime().hour,
        task.getEndTime().minute,
      );

      // Pre-notification: 10 minutes before task starts
      final preStartDT = startDT.subtract(const Duration(minutes: 10));
      if (!_notifiedPreStart.contains(task.id)) {
        final diffPreStart = now.difference(preStartDT).inSeconds;
        if (diffPreStart >= 0 && diffPreStart < 60) {
          _notifiedPreStart.add(task.id);
          _addTaskNotification(
            task,
            NotificationType.preStart,
            '${task.title} starts in 10 minutes',
          );
          NotificationService.instance.showTaskAlert(
            task,
            isStart: true,
            isPreNotification: true,
            onSnooze: () => snoozeTask(task.id, minutes: 10),
            onStop: () => stopNotificationsForTask(task.id, forStart: true),
          );
        }
      }

      // Task start alert
      if (!_notifiedStart.contains(task.id)) {
        final diffStart = now.difference(startDT).inSeconds;
        if (diffStart >= 0 && diffStart < 60) {
          _notifiedStart.add(task.id);
          _addTaskNotification(
            task,
            NotificationType.taskStart,
            '${task.title} has started',
          );
          NotificationService.instance.showTaskAlert(
            task,
            isStart: true,
            isPreNotification: false,
            onSnooze: () => snoozeTask(task.id, minutes: 10),
            onStop: () => stopNotificationsForTask(task.id, forStart: true),
          );
        }
      }

      // Task end alert
      if (!_notifiedEnd.contains(task.id)) {
        final diffEnd = now.difference(endDT).inSeconds;
        if (diffEnd >= 0 && diffEnd < 60) {
          _notifiedEnd.add(task.id);
          _addTaskNotification(
            task,
            NotificationType.taskEnd,
            '${task.title} has ended',
          );
          NotificationService.instance.showTaskAlert(
            task,
            isStart: false,
            isPreNotification: false,
            onSnooze: () => snoozeTask(task.id, minutes: 10),
            onStop: () => stopNotificationsForTask(task.id, forStart: false),
          );
        }
      }
    }
  }

  void _addTaskNotification(Task task, NotificationType type, String message) {
    _notificationProvider?.addNotification(
      TaskNotification(
        taskId: task.id,
        taskTitle: task.title,
        message: message,
        type: type,
      ),
    );
  }

  /// Snooze a task by adding [minutes] to both start and end times
  Future<void> snoozeTask(String taskId, {int minutes = 10}) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return;
    final task = _tasks[index];

    final startDT = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
      task.getStartTime().hour,
      task.getStartTime().minute,
    ).add(Duration(minutes: minutes));
    final endDT = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
      task.getEndTime().hour,
      task.getEndTime().minute,
    ).add(Duration(minutes: minutes));

    final newStart = TimeOfDay(hour: startDT.hour, minute: startDT.minute);
    final newEnd = TimeOfDay(hour: endDT.hour, minute: endDT.minute);

    final updated = task.copyWith(
      startTime: newStart,
      endTime: newEnd,
      updatedAt: DateTime.now(),
    );
    await TaskRepository.updateTask(updated);

    _tasks[index] = updated;
    _snoozedUntil[taskId] = DateTime.now().add(Duration(minutes: minutes));
    _notifiedPreStart.remove(taskId);
    _notifiedStart.remove(taskId);
    _notifiedEnd.remove(taskId);
    _applyFilters();
    notifyListeners();
  }

  void stopNotificationsForTask(String taskId, {bool forStart = true}) {
    if (forStart) {
      _notifiedPreStart.add(taskId);
      _notifiedStart.add(taskId);
    } else {
      _notifiedEnd.add(taskId);
    }
    NotificationService.instance.stopRingtone(taskId);
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    final dateOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    _filteredTasks = _tasks.where((task) {
      final taskDateOnly = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );

      if (!taskDateOnly.isAtSameMomentAs(dateOnly)) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final matches =
            task.title.toLowerCase().contains(_searchQuery) ||
            (task.description?.toLowerCase().contains(_searchQuery) ?? false);
        if (!matches) return false;
      }

      if (_statusFilter == TaskStatusFilter.completed && !task.isCompleted) {
        return false;
      }
      if (_statusFilter == TaskStatusFilter.pending && task.isCompleted) {
        return false;
      }
      if (_statusFilter == TaskStatusFilter.incomplete) {
        if (!_isOverdue(task)) return false;
      }

      if (_priorityFilter != 'all' &&
          task.priority.toLowerCase() != _priorityFilter) {
        return false;
      }

      return true;
    }).toList();

    _filteredTasks.sort((a, b) {
      // Order: running -> coming -> incomplete (overdue) -> not-completed -> completed
      final aRun = _isRunning(a);
      final bRun = _isRunning(b);
      if (aRun != bRun) return aRun ? -1 : 1;

      final aComing = _isComing(a);
      final bComing = _isComing(b);
      if (aComing != bComing) return aComing ? -1 : 1;

      final aOver = _isOverdue(a);
      final bOver = _isOverdue(b);
      if (aOver != bOver) return aOver ? -1 : 1;

      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
      final priorityCompare = (priorityOrder[a.priority] ?? 2).compareTo(
        priorityOrder[b.priority] ?? 2,
      );
      if (priorityCompare != 0) return priorityCompare;

      return a.createdAt.compareTo(b.createdAt);
    });
  }

  Future<void> addTask({
    required String title,
    String? description,
    required DateTime dueDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String priority = 'medium',
  }) async {
    final task = Task(
      title: title,
      description: description,
      dueDate: dueDate,
      startTime: startTime ?? const TimeOfDay(hour: 9, minute: 0),
      endTime: endTime ?? const TimeOfDay(hour: 10, minute: 0),
      priority: priority,
    );

    await TaskRepository.addTask(task);
    _tasks.add(task);
    _datesWithTasks.add(DateTime(dueDate.year, dueDate.month, dueDate.day));
    _applyFilters();
    notifyListeners();
  }

  /// Return task by id or null
  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Whether the task is overdue (past end time and not completed)
  bool _isOverdue(Task task) {
    if (task.isCompleted) return false;
    final endDT = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
      task.getEndTime().hour,
      task.getEndTime().minute,
    );
    return DateTime.now().isAfter(endDT);
  }

  /// Whether the task is currently running (now between start and end)
  bool _isRunning(Task task) {
    if (task.isCompleted) return false;
    final now = DateTime.now();
    final startDT = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
      task.getStartTime().hour,
      task.getStartTime().minute,
    );
    final endDT = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
      task.getEndTime().hour,
      task.getEndTime().minute,
    );
    return (now.isAfter(startDT) || now.isAtSameMomentAs(startDT)) &&
        now.isBefore(endDT);
  }

  /// Whether the task is coming soon (start within next 60 minutes)
  bool _isComing(Task task) {
    if (task.isCompleted) return false;
    final now = DateTime.now();
    final startDT = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
      task.getStartTime().hour,
      task.getStartTime().minute,
    );
    final diff = startDT.difference(now);
    return diff.inSeconds > 0 && diff.inMinutes <= 60;
  }

  /// Check if a given date has any overdue tasks
  bool hasOverdueOnDate(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _tasks.any((task) {
      final taskDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      return taskDate.isAtSameMomentAs(dateOnly) && _isOverdue(task);
    });
  }

  /// Return tasks for a specific date (date-only comparison)
  List<Task> tasksOnDate(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _tasks.where((task) {
      final taskDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      return taskDate.isAtSameMomentAs(dateOnly);
    }).toList();
  }

  /// Whether all tasks on [day] are completed. Returns false if no tasks.
  bool allCompletedOnDate(DateTime day) {
    final list = tasksOnDate(day);
    if (list.isEmpty) return false;
    return list.every((t) => t.isCompleted);
  }

  /// Return available time slots on [day] for a given [duration].
  /// The working window defaults to 08:00-18:00.
  List<List<TimeOfDay>> availableSlots(
    DateTime day,
    Duration duration, {
    TimeOfDay workStart = const TimeOfDay(hour: 8, minute: 0),
    TimeOfDay workEnd = const TimeOfDay(hour: 18, minute: 0),
  }) {
    final tasks = tasksOnDate(
      day,
    ).map((t) => [t.getStartTime(), t.getEndTime()]).toList();

    // Convert to DateTime ranges
    DateTime toDT(TimeOfDay tod) =>
        DateTime(day.year, day.month, day.day, tod.hour, tod.minute);

    final ranges = tasks
        .map((r) => [toDT(r[0] as TimeOfDay), toDT(r[1] as TimeOfDay)])
        .toList();

    // Sort by start
    ranges.sort((a, b) => a[0].compareTo(b[0]));

    final workStartDT = toDT(workStart);
    final workEndDT = toDT(workEnd);

    final slots = <List<TimeOfDay>>[];

    DateTime cursor = workStartDT;

    for (final r in ranges) {
      final start = r[0];
      final end = r[1];
      if (end.isBefore(workStartDT) || start.isAfter(workEndDT)) {
        // outside working window
        continue;
      }

      final segStart = start.isBefore(workStartDT) ? workStartDT : start;
      if (segStart.isAfter(cursor)) {
        final gap = segStart.difference(cursor);
        if (gap >= duration) {
          slots.add([
            TimeOfDay(hour: cursor.hour, minute: cursor.minute),
            TimeOfDay(
              hour: cursor.add(duration).hour,
              minute: cursor.add(duration).minute,
            ),
          ]);
        }
      }

      if (end.isAfter(cursor)) cursor = end;
      if (cursor.isAfter(workEndDT)) break;
    }

    // Tail gap
    if (workEndDT.isAfter(cursor)) {
      final gap = workEndDT.difference(cursor);
      if (gap >= duration) {
        slots.add([
          TimeOfDay(hour: cursor.hour, minute: cursor.minute),
          TimeOfDay(
            hour: cursor.add(duration).hour,
            minute: cursor.add(duration).minute,
          ),
        ]);
      }
    }

    return slots;
  }

  /// Return available hourly slots on [day] (24 slots 0:00-1:00 .. 23:00-24:00)
  /// Subtracts booked task intervals and returns the remaining fragments
  /// as pairs of TimeOfDay.
  List<List<TimeOfDay>> availableHourlySlots(DateTime day) {
    // Build merged booked intervals for the day
    DateTime toDT(TimeOfDay tod) =>
        DateTime(day.year, day.month, day.day, tod.hour, tod.minute);

    final intervals = tasksOnDate(day).map((t) {
      final s = toDT(t.getStartTime());
      final e = toDT(t.getEndTime());
      return [s, e];
    }).toList();

    if (intervals.isEmpty) {
      // whole day is free: return all full-hour slots
      return List.generate(
        24,
        (i) => [
          TimeOfDay(hour: i, minute: 0),
          TimeOfDay(hour: (i + 1) % 24, minute: 0),
        ],
      );
    }

    intervals.sort((a, b) => (a[0] as DateTime).compareTo(b[0] as DateTime));
    // merge overlaps
    final merged = <List<DateTime>>[];
    for (final it in intervals) {
      final s = it[0] as DateTime;
      final e = it[1] as DateTime;
      if (merged.isEmpty) {
        merged.add([s, e]);
      } else {
        final last = merged.last;
        if (s.isBefore(last[1]) || s.isAtSameMomentAs(last[1])) {
          // overlap
          if (e.isAfter(last[1])) last[1] = e;
        } else {
          merged.add([s, e]);
        }
      }
    }

    final slots = <List<TimeOfDay>>[];
    for (int hour = 0; hour < 24; hour++) {
      final blockStart = DateTime(day.year, day.month, day.day, hour, 0);
      final blockEnd = DateTime(
        day.year,
        day.month,
        day.day,
        (hour + 1) % 24,
        0,
      );

      DateTime cursor = blockStart;
      // iterate merged bookings and subtract overlaps within this block
      for (final m in merged) {
        final mStart = m[0];
        final mEnd = m[1];
        if (mEnd.isBefore(blockStart) || mStart.isAfter(blockEnd)) continue;

        final segStart = mStart.isBefore(blockStart) ? blockStart : mStart;
        final segEnd = mEnd.isAfter(blockEnd) ? blockEnd : mEnd;

        if (segStart.isAfter(cursor)) {
          slots.add([
            TimeOfDay(hour: cursor.hour, minute: cursor.minute),
            TimeOfDay(hour: segStart.hour, minute: segStart.minute),
          ]);
        }

        // move cursor past the booked segment
        if (segEnd.isAfter(cursor)) cursor = segEnd;
        if (cursor.isAtSameMomentAs(blockEnd) || cursor.isAfter(blockEnd))
          break;
      }

      // tail
      if (cursor.isBefore(blockEnd)) {
        slots.add([
          TimeOfDay(hour: cursor.hour, minute: cursor.minute),
          TimeOfDay(hour: blockEnd.hour, minute: blockEnd.minute),
        ]);
      }
    }

    // Remove any zero-length slots
    slots.removeWhere(
      (s) => s[0].hour == s[1].hour && s[0].minute == s[1].minute,
    );
    return slots;
  }

  Future<void> updateTask(Task task) async {
    final updatedTask = task.copyWith(updatedAt: DateTime.now());
    await TaskRepository.updateTask(updatedTask);

    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = updatedTask;
    }
    _snoozedUntil.remove(task.id);
    _notifiedPreStart.remove(task.id);
    _notifiedStart.remove(task.id);
    _notifiedEnd.remove(task.id);
    _applyFilters();
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    await TaskRepository.deleteTask(taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    _snoozedUntil.remove(taskId);
    _notifiedPreStart.remove(taskId);
    _notifiedStart.remove(taskId);
    _notifiedEnd.remove(taskId);
    _datesWithTasks = await TaskRepository.getDatesWithTasks();
    _applyFilters();
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updated);
  }
}
