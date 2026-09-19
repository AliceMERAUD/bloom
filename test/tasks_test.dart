import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/models/task.dart';
import 'package:bloom/services/data_export_service.dart';
import 'package:bloom/services/reminder_service.dart';
import 'package:bloom/services/settings_service.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/services/task_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    ReminderService.enabled = false;
    tempDir = await Directory.systemTemp.createTemp('bloom_tasks_');
    await StorageService.initForTesting(tempDir.path);
    SettingsService.load();
  });

  tearDown(() async {
    await StorageService.closeForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('création, modification, complétion, réouverture, suppression', () async {
    final created = await TaskService.addTask(
      title: 'Ranger ma chambre',
      category: TaskCategory.room,
      priority: TaskPriority.high,
      dueDate: DateTime.now(),
    );
    expect(created.title, 'Ranger ma chambre');
    expect(created.completed, isFalse);
    expect(TaskService.getPendingTasks(), hasLength(1));

    final updated = await TaskService.updateTask(
      created.copyWith(title: 'Ranger la chambre'),
    );
    expect(updated.title, 'Ranger la chambre');

    final done = await TaskService.completeTask(updated.id);
    expect(done.completed, isTrue);
    expect(done.completedAt, isNotNull);
    expect(TaskService.getPendingTasks(), isEmpty);

    final reopened = await TaskService.reopenTask(updated.id);
    expect(reopened.completed, isFalse);
    expect(reopened.completedAt, isNull);

    await TaskService.deleteTask(updated.id);
    expect(TaskService.getTasks(), isEmpty);
  });

  test('tâche en retard et échéance', () async {
    final overdue = await TaskService.addTask(
      title: 'Poubelles',
      category: TaskCategory.trash,
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
    );
    expect(overdue.isOverdue, isTrue);

    final today = await TaskService.addTask(
      title: 'Courses',
      category: TaskCategory.shopping,
      dueDate: DateTime.now(),
    );
    expect(today.isDueToday, isTrue);
  });

  test('récurrence quotidienne crée une seule prochaine occurrence', () async {
    final task = await TaskService.addTask(
      title: 'Lessive',
      category: TaskCategory.laundry,
      recurrence: TaskRecurrence.daily,
      dueDate: DateTime(2026, 1, 10),
    );

    final first = await TaskService.completeTask(task.id);
    expect(first.nextOccurrenceId, isNotNull);

    final pending = TaskService.getPendingTasks();
    expect(pending, hasLength(1));
    expect(pending.first.dueDate, DateTime(2026, 1, 11));
    expect(pending.first.recurrence, TaskRecurrence.daily);

    await TaskService.completeTask(task.id);
    expect(
      TaskService.getPendingTasks().where((t) => t.title == 'Lessive'),
      hasLength(1),
    );
  });

  test('récurrence hebdomadaire avance de 7 jours', () async {
    final task = await TaskService.addTask(
      title: 'Sortir les poubelles',
      category: TaskCategory.trash,
      recurrence: TaskRecurrence.weekly,
      dueDate: DateTime(2026, 3, 1),
    );
    await TaskService.completeTask(task.id);
    final next = TaskService.getPendingTasks().single;
    expect(next.dueDate, DateTime(2026, 3, 8));
  });

  test('persistence Hive round-trip', () async {
    await TaskService.addTask(
      title: 'Nettoyer',
      category: TaskCategory.cleaning,
    );
    final loaded = StorageService.getAllTasks();
    expect(loaded, hasLength(1));
    expect(loaded.first.category, TaskCategory.cleaning);
  });

  test('export/import inclut tasks et reste compatible sans tasks', () async {
    await TaskService.addTask(title: 'Perso', category: TaskCategory.personal);
    final json = DataExportService.exportJson();
    expect(json, contains('"tasks"'));

    await StorageService.clearAllUserData(keepSettings: false);
    SettingsService.load();
    expect(TaskService.getTasks(), isEmpty);

    await DataExportService.importAndReplace(json);
    expect(TaskService.getTasks().single.title, 'Perso');

    const legacy = '''
{
  "version": 1,
  "app": "bloom",
  "sport": {"sessions": [], "sets": []},
  "wellbeing": {"entries": []},
  "puzzle": {"completedIds": [], "selectedPuzzleId": null, "placements": {}},
  "settings": {}
}
''';
    await DataExportService.importAndReplace(legacy);
    expect(TaskService.getTasks(), isEmpty);
  });

  test('notificationIdForTask est stable', () {
    final a = ReminderService.notificationIdForTask('abc');
    final b = ReminderService.notificationIdForTask('abc');
    expect(a, b);
    expect(a >= ReminderService.taskIdBase, isTrue);
  });
}
