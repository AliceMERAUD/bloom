import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/sport_activity.dart';
import '../models/task.dart';
import 'bloom_refresh.dart';
import 'reminder_service.dart';
import 'settings_service.dart';
import 'sport_activity_service.dart';
import 'sport_bag_service.dart';
import 'storage_service.dart';

/// Business logic for daily-life tasks (local-only).
class TaskService {
  static List<BloomTask> getTasks() => StorageService.getAllTasks();

  static List<BloomTask> getPendingTasks() =>
      getTasks().where((t) => t.isPending).toList();

  static List<BloomTask> getCompletedTasks() =>
      getTasks().where((t) => t.completed).toList();

  static List<BloomTask> getDueTodayPending() =>
      getPendingTasks().where((t) => t.isDueToday || t.isOverdue).toList();

  static int overdueCount() =>
      getPendingTasks().where((t) => t.isOverdue).length;

  static int dueTodayCount() =>
      getPendingTasks().where((t) => t.isDueToday && !t.isOverdue).length;

  static int completedTodayCount() {
    final now = DateTime.now();
    return getCompletedTasks().where((t) {
      final at = t.completedAt;
      if (at == null) return false;
      return at.year == now.year && at.month == now.month && at.day == now.day;
    }).length;
  }

  static BloomTask? getById(String id) => StorageService.getTask(id);

  static Future<BloomTask> addTask({
    required String title,
    String? description,
    TaskCategory category = TaskCategory.other,
    TaskPriority priority = TaskPriority.normal,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    TaskRecurrence recurrence = TaskRecurrence.none,
    bool reminderEnabled = false,
    int reminderMinutesBefore = 0,
    String? sportId,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final reminderId =
        reminderEnabled ? ReminderService.notificationIdForTask(id) : null;

    final task = BloomTask(
      id: id,
      title: title.trim(),
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      category: category,
      createdAt: DateTime.now(),
      dueDate: dueDate == null
          ? null
          : DateTime(dueDate.year, dueDate.month, dueDate.day),
      dueTime: dueTime,
      priority: priority,
      recurrence: recurrence,
      reminderEnabled: reminderEnabled,
      reminderId: reminderId,
      reminderMinutesBefore: reminderMinutesBefore,
      sportId: sportId,
    );

    await StorageService.saveTask(task);
    await _syncReminder(task);
    BloomRefresh.notify();
    return task;
  }

  static Future<BloomTask> updateTask(BloomTask task) async {
    final previous = StorageService.getTask(task.id);
    if (previous?.reminderId != null &&
        previous!.reminderId != task.reminderId) {
      await ReminderService.cancelId(previous.reminderId!);
    }

    var updated = task;
    if (task.reminderEnabled) {
      updated = task.copyWith(
        reminderId: ReminderService.notificationIdForTask(task.id),
      );
    } else {
      if (task.reminderId != null) {
        await ReminderService.cancelId(task.reminderId!);
      }
      updated = task.copyWith(clearReminderId: true, reminderEnabled: false);
    }

    await StorageService.saveTask(updated);
    await _syncReminder(updated);
    BloomRefresh.notify();
    return updated;
  }

  static Future<void> deleteTask(String id) async {
    final task = StorageService.getTask(id);
    if (task?.reminderId != null) {
      await ReminderService.cancelId(task!.reminderId!);
    }
    await StorageService.deleteTask(id);
    BloomRefresh.notify();
  }

  /// Marks complete and creates the next occurrence for recurring tasks once.
  static Future<BloomTask> completeTask(String id) async {
    final task = StorageService.getTask(id);
    if (task == null) {
      throw StateError('Tâche introuvable');
    }
    if (task.completed) return task;

    if (task.reminderId != null) {
      await ReminderService.cancelId(task.reminderId!);
    }

    var completed = task.copyWith(
      completed: true,
      completedAt: DateTime.now(),
      reminderEnabled: false,
      clearReminderId: true,
    );

    if (task.recurrence != TaskRecurrence.none &&
        task.nextOccurrenceId == null) {
      final next = _buildNextOccurrence(task);
      await StorageService.saveTask(next);
      await _syncReminder(next);
      completed = completed.copyWith(nextOccurrenceId: next.id);
    }

    await StorageService.saveTask(completed);
    BloomRefresh.notify();
    return completed;
  }

  static Future<BloomTask> reopenTask(String id) async {
    final task = StorageService.getTask(id);
    if (task == null) {
      throw StateError('Tâche introuvable');
    }
    if (!task.completed) return task;

    final reopened = task.copyWith(
      completed: false,
      clearCompletedAt: true,
    );
    await StorageService.saveTask(reopened);
    BloomRefresh.notify();
    return reopened;
  }

  /// Exposed for tests: next due date after completing [task].
  static DateTime nextDueDateAfter(BloomTask task, {DateTime? from}) {
    final base = from ?? task.dueDate ?? DateTime.now();
    final day = DateTime(base.year, base.month, base.day);
    switch (task.recurrence) {
      case TaskRecurrence.daily:
        return day.add(const Duration(days: 1));
      case TaskRecurrence.weekly:
        return day.add(const Duration(days: 7));
      case TaskRecurrence.none:
        return day;
    }
  }

  static BloomTask _buildNextOccurrence(BloomTask completed) {
    final id = '${DateTime.now().microsecondsSinceEpoch}_next';
    final due = nextDueDateAfter(completed);
    final reminderEnabled = completed.reminderEnabled;
    return BloomTask(
      id: id,
      title: completed.title,
      description: completed.description,
      category: completed.category,
      createdAt: DateTime.now(),
      dueDate: due,
      dueTime: completed.dueTime,
      priority: completed.priority,
      recurrence: completed.recurrence,
      reminderEnabled: reminderEnabled,
      reminderId: reminderEnabled
          ? ReminderService.notificationIdForTask(id)
          : null,
      reminderMinutesBefore: completed.reminderMinutesBefore,
      sportId: completed.sportId,
    );
  }

  static Future<void> _syncReminder(BloomTask task) async {
    final settings = SettingsService.current;
    if (!task.reminderEnabled ||
        task.completed ||
        task.reminderId == null ||
        !settings.notificationsEnabled) {
      if (task.reminderId != null &&
          (!task.reminderEnabled || task.completed)) {
        await ReminderService.cancelId(task.reminderId!);
      }
      return;
    }

    final when = _reminderDateTime(task);
    if (when == null || when.isBefore(DateTime.now())) {
      return;
    }

    final copy = _notificationCopy(task);
    await ReminderService.scheduleAt(
      id: task.reminderId!,
      title: copy.$1,
      body: copy.$2,
      when: when,
    );
  }

  /// Pure helper for tests: title + body for a task reminder.
  static (String, String) notificationCopyFor(BloomTask task) =>
      _notificationCopy(task);

  static (String, String) _notificationCopy(BloomTask task) {
    SportActivity? sport;
    if (task.sportId != null) {
      sport = SportActivityService.getById(task.sportId!);
    }

    final hasBag = task.sportId != null &&
        SportBagService.checklistFor(task.sportId).isNotEmpty;

    if (sport != null || task.category == TaskCategory.sport) {
      final name = sport?.name ?? task.title;
      final title = 'Bloom — Sport';
      final lead = task.reminderMinutesBefore > 0
          ? 'dans ${task.reminderMinutesBefore} min'
          : 'c’est l’heure';
      final body = hasBag
          ? '🏊 $name $lead — pense à ton sac !'
          : '🏊 C’est bientôt l’heure de $name !';
      return (title, body);
    }

    return ('Bloom — Tâche', task.title);
  }

  static DateTime? _reminderDateTime(BloomTask task) {
    if (task.dueDate == null) return null;
    final hour = task.dueTime?.hour ?? 9;
    final minute = task.dueTime?.minute ?? 0;
    final due = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
      hour,
      minute,
    );
    return due.subtract(Duration(minutes: task.reminderMinutesBefore));
  }

  /// Exposed for unit tests.
  static DateTime? reminderFireAt(BloomTask task) => _reminderDateTime(task);

  /// Reschedule reminders for all pending tasks (after settings change).
  static Future<void> rescheduleAllReminders(AppSettings settings) async {
    for (final task in getPendingTasks()) {
      if (!task.reminderEnabled || task.reminderId == null) continue;
      if (!settings.notificationsEnabled) {
        await ReminderService.cancelId(task.reminderId!);
        continue;
      }
      await _syncReminder(task);
    }
  }
}
