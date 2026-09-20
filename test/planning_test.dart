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

      // Chronological: session 09:00, laundry 15:00, swim 18:30, period last.
      expect(events.first.kind, PlanningEventKind.workoutSession);
      expect(events[1].title, 'Lessive');
      expect(events[2].title, 'Natation');
      expect(events.last.kind, PlanningEventKind.period);
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
      final dayEvents = PlanningService.eventsForDay(nextDay)
          .where((e) => e.title == 'Daily')
          .toList();
      expect(dayEvents, hasLength(1));

      final weekEnd = today.add(const Duration(days: 14));
      final range = PlanningService.eventsInRange(today, weekEnd)
          .where((e) => e.title == 'Daily' && !e.completed)
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
    testWidgets('PlanningScreen modes Jour / Semaine / Mois', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PlanningScreen()));
      await tester.pump();

      expect(find.text('Planning'), findsOneWidget);
      expect(find.text('Jour'), findsOneWidget);
      expect(find.text('Aujourd’hui'), findsOneWidget);

      await tester.tap(find.text('Semaine'));
      await tester.pumpAndSettle();
      expect(find.text('L'), findsWidgets);

      await tester.tap(find.text('Mois'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sport'), findsWidgets);
    });

    testWidgets('MainShell expose Planning et menu Plus', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainShell()));
      await tester.pump();

      expect(find.text('Planning'), findsWidgets);
      expect(find.text('Plus'), findsOneWidget);
      expect(find.text('Accueil'), findsOneWidget);

      await tester.tap(find.text('Planning').last);
      await tester.pumpAndSettle();
      expect(find.byType(PlanningScreen), findsOneWidget);

      await tester.tap(find.text('Plus'));
      await tester.pumpAndSettle();
      expect(find.text('Tasks'), findsWidgets);
      expect(find.text('Puzzle'), findsWidgets);
    });
  });
}
