import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/models/planning_event.dart';
import 'package:bloom/models/task.dart';
import 'package:bloom/models/wellbeing_entry.dart';
import 'package:bloom/models/wellbeing_enums.dart';
import 'package:bloom/models/workout_session.dart';
import 'package:bloom/screens/planning/planning_screen.dart';
import 'package:bloom/screens/shell/main_shell.dart';
import 'package:bloom/services/planning_service.dart';
import 'package:bloom/services/sport_activity_service.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/services/task_service.dart';
import 'package:bloom/services/wellbeing_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bloom_planning_');
    await StorageService.initForTesting(tempDir.path);
  });

  tearDown(() async {
    await StorageService.closeForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  DateTime day(int y, int m, int d) => DateTime(y, m, d);

  group('PlanningService sources', () {
    test('agrège tâches, séances et règles sans doublons', () async {
      final today = day(2026, 9, 21);

      await TaskService.addTask(
        title: 'Lessive',
        dueDate: today,
        dueTime: const TimeOfDay(hour: 15, minute: 0),
        category: TaskCategory.laundry,
      );
      await TaskService.addTask(
        title: 'Sans date',
        category: TaskCategory.other,
      );

      final sport = await SportActivityService.add(
        name: 'Natation',
        iconName: 'pool',
      );
      await TaskService.addTask(
        title: 'Séance piscine',
        dueDate: today,
        dueTime: const TimeOfDay(hour: 18, minute: 30),
        category: TaskCategory.sport,
        sportId: sport.id,
      );

      await StorageService.putWorkoutSessionRaw(
        's1',
        WorkoutSession(
          id: 's1',
          startedAt: DateTime(2026, 9, 21, 9, 0),
          endedAt: DateTime(2026, 9, 21, 10, 0),
          setIds: const [],
        ).toMap(),
      );

      await WellbeingService.saveEntry(
        WellbeingEntry(
          id: 'w1',
          date: today,
          bleeding: Bleeding.light,
          periodMarker: PeriodMarker.start,
        ),
      );

      final events = PlanningService.eventsForDay(today);
      expect(events.where((e) => e.kind == PlanningEventKind.task), hasLength(1));
      expect(
        events.where((e) => e.kind == PlanningEventKind.sportActivity),
        hasLength(1),
      );
      expect(
        events.where((e) => e.kind == PlanningEventKind.workoutSession),
        hasLength(1),
      );
      expect(
        events.where((e) => e.kind == PlanningEventKind.period),
        hasLength(1),
      );
      expect(events.any((e) => e.title == 'Sans date'), isFalse);

      final agenda = PlanningService.agendaEventsForDay(today);
      expect(agenda.any((e) => e.kind == PlanningEventKind.task), isFalse);
      expect(agenda.any((e) => e.kind == PlanningEventKind.period), isTrue);

      final tasks = PlanningService.tasksInRange(today, today);
      expect(tasks.map((t) => t.title), containsAll(['Lessive', 'Séance piscine']));
      expect(tasks.any((t) => t.title == 'Sans date'), isFalse);
      expect(PlanningService.tasksWithoutDueDate().single.title, 'Sans date');
    });

    test('récurrence quotidienne : une occurrence active, pas de doublon',
        () async {
      final today = PlanningEvent.dayOnly(DateTime.now());
      final created = await TaskService.addTask(
        title: 'Daily',
        dueDate: today,
        recurrence: TaskRecurrence.daily,
      );
      await TaskService.completeTask(created.id);

      final pending = TaskService.getPendingTasks()
          .where((t) => t.title == 'Daily')
          .toList();
      expect(pending, hasLength(1));

      final nextDay = PlanningEvent.dayOnly(pending.single.dueDate!);
      final dayTasks = PlanningService.tasksInRange(nextDay, nextDay)
          .where((t) => t.title == 'Daily' && !t.completed)
          .toList();
      expect(dayTasks, hasLength(1));

      final weekEnd = today.add(const Duration(days: 14));
      final range = PlanningService.tasksInRange(today, weekEnd)
          .where((t) => t.title == 'Daily' && !t.completed)
          .toList();
      expect(range, hasLength(1));
    });

    test('marqueurs semaine / mois', () async {
      final start = day(2026, 9, 21);
      await TaskService.addTask(title: 'A', dueDate: start);
      await WellbeingService.saveEntry(
        WellbeingEntry(
          id: 'p',
          date: start.add(const Duration(days: 1)),
          bleeding: Bleeding.medium,
        ),
      );
      await StorageService.putWorkoutSessionRaw(
        'sess',
        WorkoutSession(
          id: 'sess',
          startedAt: start.add(const Duration(days: 2)),
          endedAt: start.add(const Duration(days: 2, hours: 1)),
          setIds: const [],
        ).toMap(),
      );

      final markers = PlanningService.markersInRange(
        start,
        start.add(const Duration(days: 6)),
      );
      expect(markers[start]!.hasTask, isTrue);
      expect(markers[start.add(const Duration(days: 1))]!.hasPeriod, isTrue);
      expect(markers[start.add(const Duration(days: 2))]!.hasSport, isTrue);
    });
  });

  group('Planning UI', () {
    testWidgets('PlanningScreen modes + Mes tâches', (tester) async {
      final today = PlanningEvent.dayOnly(DateTime.now());
      await tester.runAsync(() async {
        await TaskService.addTask(title: 'Courses', dueDate: today);
      });

      await tester.pumpWidget(const MaterialApp(home: PlanningScreen()));
      await tester.pump();

      expect(find.text('Planning'), findsOneWidget);
      expect(find.text('Mes tâches'), findsOneWidget);
      expect(find.text('Courses'), findsOneWidget);

      await tester.tap(find.text('Semaine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Tâches de la semaine'), findsOneWidget);

      final monthStart = DateTime(today.year, today.month, 1);
      final monthEnd = DateTime(today.year, today.month + 1, 0);
      expect(
        PlanningService.tasksInRange(monthStart, monthEnd)
            .any((t) => t.title == 'Courses'),
        isTrue,
      );
    });

    testWidgets('MainShell Planning sans onglet Tasks séparé', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainShell()));
      await tester.pump();

      expect(find.text('Planning'), findsWidgets);
      expect(find.text('Plus'), findsOneWidget);

      await tester.tap(find.text('Planning').last);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(PlanningScreen), findsOneWidget);
      expect(find.text('Mes tâches'), findsOneWidget);

      await tester.tap(find.text('Plus'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Puzzle'), findsWidgets);
      expect(find.text('Tasks'), findsNothing);
    });
  });
}
