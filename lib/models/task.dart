import 'package:flutter/material.dart';

enum TaskCategory {
  room,
  laundry,
  trash,
  shopping,
  cleaning,
  personal,
  other,
}

extension TaskCategoryX on TaskCategory {
  String get label {
    switch (this) {
      case TaskCategory.room:
        return 'Chambre';
      case TaskCategory.laundry:
        return 'Lessive';
      case TaskCategory.trash:
        return 'Poubelles';
      case TaskCategory.shopping:
        return 'Courses';
      case TaskCategory.cleaning:
        return 'Nettoyage';
      case TaskCategory.personal:
        return 'Personnel';
      case TaskCategory.other:
        return 'Autre';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskCategory.room:
        return Icons.bed_outlined;
      case TaskCategory.laundry:
        return Icons.local_laundry_service_outlined;
      case TaskCategory.trash:
        return Icons.delete_outline;
      case TaskCategory.shopping:
        return Icons.shopping_cart_outlined;
      case TaskCategory.cleaning:
        return Icons.cleaning_services_outlined;
      case TaskCategory.personal:
        return Icons.spa_outlined;
      case TaskCategory.other:
        return Icons.push_pin_outlined;
    }
  }

  static TaskCategory fromName(String? name) {
    for (final value in TaskCategory.values) {
      if (value.name == name) return value;
    }
    return TaskCategory.other;
  }
}

enum TaskPriority {
  low,
  normal,
  high,
}

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Basse';
      case TaskPriority.normal:
        return 'Normale';
      case TaskPriority.high:
        return 'Haute';
    }
  }

  static TaskPriority fromName(String? name) {
    for (final value in TaskPriority.values) {
      if (value.name == name) return value;
    }
    return TaskPriority.normal;
  }
}

enum TaskRecurrence {
  none,
  daily,
  weekly,
}

extension TaskRecurrenceX on TaskRecurrence {
  String get label {
    switch (this) {
      case TaskRecurrence.none:
        return 'Aucune';
      case TaskRecurrence.daily:
        return 'Quotidienne';
      case TaskRecurrence.weekly:
        return 'Hebdomadaire';
    }
  }

  static TaskRecurrence fromName(String? name) {
    for (final value in TaskRecurrence.values) {
      if (value.name == name) return value;
    }
    return TaskRecurrence.none;
  }
}

class BloomTask {
  final String id;
  final String title;
  final String? description;
  final TaskCategory category;
  final DateTime createdAt;
  final DateTime? dueDate;
  final TimeOfDay? dueTime;
  final bool completed;
  final DateTime? completedAt;
  final TaskPriority priority;
  final TaskRecurrence recurrence;
  final bool reminderEnabled;
  final int? reminderId;

  /// Links a completed recurring task to the next occurrence (avoids duplicates).
  final String? nextOccurrenceId;

  const BloomTask({
    required this.id,
    required this.title,
    this.description,
    this.category = TaskCategory.other,
    required this.createdAt,
    this.dueDate,
    this.dueTime,
    this.completed = false,
    this.completedAt,
    this.priority = TaskPriority.normal,
    this.recurrence = TaskRecurrence.none,
    this.reminderEnabled = false,
    this.reminderId,
    this.nextOccurrenceId,
  });

  bool get isPending => !completed;

  bool get isOverdue {
    if (completed || dueDate == null) return false;
    final now = DateTime.now();
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final today = DateTime(now.year, now.month, now.day);
    if (due.isBefore(today)) return true;
    if (due.isAtSameMomentAs(today) && dueTime != null) {
      final dueMinutes = dueTime!.hour * 60 + dueTime!.minute;
      final nowMinutes = now.hour * 60 + now.minute;
      return nowMinutes > dueMinutes;
    }
    return false;
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  BloomTask copyWith({
    String? id,
    String? title,
    String? description,
    TaskCategory? category,
    DateTime? createdAt,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    bool? completed,
    DateTime? completedAt,
    TaskPriority? priority,
    TaskRecurrence? recurrence,
    bool? reminderEnabled,
    int? reminderId,
    String? nextOccurrenceId,
    bool clearDescription = false,
    bool clearDueDate = false,
    bool clearDueTime = false,
    bool clearCompletedAt = false,
    bool clearReminderId = false,
    bool clearNextOccurrenceId = false,
  }) {
    return BloomTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      dueTime: clearDueTime ? null : (dueTime ?? this.dueTime),
      completed: completed ?? this.completed,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      priority: priority ?? this.priority,
      recurrence: recurrence ?? this.recurrence,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderId: clearReminderId ? null : (reminderId ?? this.reminderId),
      nextOccurrenceId: clearNextOccurrenceId
          ? null
          : (nextOccurrenceId ?? this.nextOccurrenceId),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'dueTimeHour': dueTime?.hour,
        'dueTimeMinute': dueTime?.minute,
        'completed': completed,
        'completedAt': completedAt?.toIso8601String(),
        'priority': priority.name,
        'recurrence': recurrence.name,
        'reminderEnabled': reminderEnabled,
        'reminderId': reminderId,
        'nextOccurrenceId': nextOccurrenceId,
      };

  factory BloomTask.fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    final hour = (data['dueTimeHour'] as num?)?.toInt();
    final minute = (data['dueTimeMinute'] as num?)?.toInt();
    return BloomTask(
      id: data['id'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      category: TaskCategoryX.fromName(data['category'] as String?),
      createdAt: DateTime.parse(data['createdAt'] as String),
      dueDate: data['dueDate'] == null
          ? null
          : DateTime.tryParse(data['dueDate'] as String),
      dueTime: hour == null || minute == null
          ? null
          : TimeOfDay(hour: hour, minute: minute),
      completed: data['completed'] as bool? ?? false,
      completedAt: data['completedAt'] == null
          ? null
          : DateTime.tryParse(data['completedAt'] as String),
      priority: TaskPriorityX.fromName(data['priority'] as String?),
      recurrence: TaskRecurrenceX.fromName(data['recurrence'] as String?),
      reminderEnabled: data['reminderEnabled'] as bool? ?? false,
      reminderId: (data['reminderId'] as num?)?.toInt(),
      nextOccurrenceId: data['nextOccurrenceId'] as String?,
    );
  }
}
