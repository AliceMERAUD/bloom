import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/models/task.dart';
import 'package:bloom/models/wellbeing_entry.dart';
import 'package:bloom/models/wellbeing_enums.dart';
import 'package:bloom/models/workout_set.dart';
import 'package:bloom/services/dashboard_service.dart';
import 'package:bloom/services/puzzle_progress_service.dart';
import 'package:bloom/services/reminder_service.dart';
import 'package:bloom/services/settings_service.dart';
import 'package:bloom/services/sport_activity_service.dart';
import 'package:bloom/services/sport_bag_service.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/services/task_service.dart';
import 'package:bloom/services/wellbeing_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    ReminderService.enabled = false;
    tempDir = await Directory.systemTemp.createTemp('bloom_p9_');
    await StorageService.initForTesting(tempDir.path);
    SettingsService.load();
    await SportActivityService.ensureDefaults();
  });

  tearDown(() async {
    await StorageService.closeForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Dashboard Aujourd’hui', () {
    test('agrège tâches, sport, wellbeing, puzzle', () async {
      await TaskService.addTask(
        title: 'Retard',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      await TaskService.addTask(
        title: 'Aujourd’hui',
        dueDate: DateTime.now(),
      );
      final swim = await SportActivityService.add(name: 'Natation', iconName: 'pool');
      await TaskService.addTask(
        title: 'Natation',
        category: TaskCategory.sport,
        sportId: swim.id,
        dueDate: DateTime.now(),
        dueTime: const TimeOfDay(hour: 18, minute: 30),
      );
      await WellbeingService.saveEntry(
        WellbeingEntry(
          id: WellbeingEntry.dateKey(DateTime.now()),
          date: DateTime.now(),
          mood: Mood.good,
          energy: Energy.medium,
        ),
      );
      await PuzzleProgressService.markCompleted('bus_friends');

      final snap = DashboardService.load();
      expect(snap.overdueTaskCount, greaterThanOrEqualTo(1));
      expect(snap.dueTodayTaskCount, greaterThanOrEqualTo(1));
      expect(snap.nextSportTask, isNotNull);
      expect(snap.nextSportName, 'Natation');
      expect(snap.hasWellbeingToday, isTrue);
      expect(snap.puzzleCompleted, greaterThanOrEqualTo(1));
      expect(snap.motivationalLine, isNotEmpty);
      expect(snap.periodCount, greaterThanOrEqualTo(0));
    });

    test('états vides sans données inventées', () {
      final snap = DashboardService.load();
      expect(snap.pendingTaskCount, 0);
      expect(snap.nextSportTask, isNull);
      expect(snap.todayEntry, isNull);
      expect(snap.tractionProgress?.hasData, isFalse);
    });
  });

  group('Traction summary', () {
    test('calcule assistance précédente → récente', () async {
      await StorageService.saveWorkoutSet(
        WorkoutSet(
          exerciseId: 'pull_up_assisted',
          repetitions: 5,
          assistance: 45,
          date: DateTime(2026, 1, 1),
        ),
      );
      await StorageService.saveWorkoutSet(
        WorkoutSet(
          exerciseId: 'pull_up_assisted',
          repetitions: 5,
          assistance: 40,
          date: DateTime(2026, 1, 8),
        ),
      );
      final snap = DashboardService.load();
      expect(snap.tractionProgress?.hasData, isTrue);
      expect(snap.tractionProgress?.previousAssistance, 45);
      expect(snap.tractionProgress?.latestAssistance, 40);
    });
  });

  group('Tasks récurrence', () {
    test('quotidienne crée une seule occurrence', () async {
      final task = await TaskService.addTask(
        title: 'Daily',
        recurrence: TaskRecurrence.daily,
        dueDate: DateTime(2026, 3, 1),
      );
      await TaskService.completeTask(task.id);
      await TaskService.completeTask(task.id);
      final pending = TaskService.getPendingTasks()
          .where((t) => t.title == 'Daily')
          .toList();
      expect(pending, hasLength(1));
      expect(pending.first.dueDate, DateTime(2026, 3, 2));
    });

    test('hebdomadaire +7 jours sans doublon', () async {
      final task = await TaskService.addTask(
        title: 'Weekly',
        recurrence: TaskRecurrence.weekly,
        dueDate: DateTime(2026, 3, 1),
      );
      await TaskService.completeTask(task.id);
      final next = TaskService.getPendingTasks()
          .where((t) => t.title == 'Weekly')
          .single;
      expect(next.dueDate, DateTime(2026, 3, 8));
      final done = TaskService.getById(task.id)!;
      expect(done.nextOccurrenceId, next.id);
      await TaskService.completeTask(task.id);
      expect(
        TaskService.getPendingTasks().where((t) => t.title == 'Weekly'),
        hasLength(1),
      );
    });

    test('suppression annule sans régénérer', () async {
      final task = await TaskService.addTask(
        title: 'Gone',
        recurrence: TaskRecurrence.daily,
        dueDate: DateTime.now(),
        reminderEnabled: true,
      );
      await TaskService.deleteTask(task.id);
      expect(TaskService.getById(task.id), isNull);
      expect(TaskService.getTasks().where((t) => t.title == 'Gone'), isEmpty);
    });
  });

  group('Sac prêt', () {
    test('compteur checked / total', () async {
      await SportBagService.add(name: 'Gourde');
      await SportBagService.add(name: 'Serviette');
      final items = SportBagService.checklistFor(null);
      expect(items, hasLength(2));
      await SportBagService.toggleChecked(items.first.id);
      final after = SportBagService.checklistFor(null);
      expect(after.where((i) => i.checked), hasLength(1));
    });
  });
}
