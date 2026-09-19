import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:bloom/models/workout_set.dart';
import 'package:bloom/services/progression_service.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/services/workout_session_plan_service.dart';
import 'package:bloom/services/workout_session_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bloom_phase1_');
    await StorageService.initForTesting(tempDir.path);
    WorkoutSessionService.resetForTesting();
  });

  tearDown(() async {
    WorkoutSessionService.resetForTesting();
    await StorageService.closeForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('création d’une séance', () async {
    final result = await WorkoutSessionService.startSession();

    expect(result.outcome, StartSessionOutcome.created);
    expect(WorkoutSessionService.hasOpenSession, isTrue);

    final session = await StorageService.getSession(result.sessionId);
    expect(session, isNotNull);
    expect(session!.isOpen, isTrue);
    expect(session.endedAt, isNull);
  });

  test('ajout de séries à une séance', () async {
    final started = await WorkoutSessionService.startSession();

    await WorkoutSessionService.addSet(
      const WorkoutSet(exerciseId: 'pull_up', repetitions: 8),
    );
    await WorkoutSessionService.addSet(
      const WorkoutSet(exerciseId: 'push_up', repetitions: 12),
    );

    final sets = await StorageService.getSessionSets(started.sessionId);
    expect(sets, hasLength(2));
    expect(sets.map((set) => set.exerciseId), ['pull_up', 'push_up']);
  });

  test('clôture d’une séance', () async {
    final started = await WorkoutSessionService.startSession();
    await WorkoutSessionService.addSet(
      const WorkoutSet(exerciseId: 'pull_up', repetitions: 5),
    );

    await WorkoutSessionService.endSession();

    expect(WorkoutSessionService.hasOpenSession, isFalse);
    final session = await StorageService.getSession(started.sessionId);
    expect(session!.endedAt, isNotNull);
    expect(session.isOpen, isFalse);
  });

  test('récupération d’une séance avec ses séries', () async {
    final started = await WorkoutSessionService.startSession();
    await WorkoutSessionService.addSet(
      const WorkoutSet(
        exerciseId: 'pull_up_assisted',
        repetitions: 8,
        assistance: 20,
      ),
    );

    final session = await StorageService.getSession(started.sessionId);
    final sets = await StorageService.getSessionSets(started.sessionId);

    expect(session!.setIds, hasLength(1));
    expect(sets.single.assistance, 20);
  });

  test('progression conserve les heuristiques actuelles', () async {
    await StorageService.saveWorkoutSet(
      const WorkoutSet(
        exerciseId: 'pull_up_assisted',
        repetitions: 8,
        assistance: 25,
      ),
    );
    await StorageService.saveWorkoutSet(
      const WorkoutSet(
        exerciseId: 'pull_up_assisted',
        repetitions: 9,
        assistance: 25,
      ),
    );

    final plan = await ProgressionService.generateNextWorkout(
      'pull_up_assisted',
    );

    expect(plan.sets, 4);
    expect(plan.repetitions, 8);
    expect(plan.assistance, 22.5);
  });

  test('séance déjà ouverte : conflict puis forceNew', () async {
    final first = await WorkoutSessionService.startSession();
    final conflict = await WorkoutSessionService.startSession();

    expect(conflict.outcome, StartSessionOutcome.conflict);
    expect(conflict.sessionId, first.sessionId);

    final forced = await WorkoutSessionService.startSession(forceNew: true);
    expect(forced.outcome, StartSessionOutcome.created);
    expect(forced.sessionId, isNot(first.sessionId));

    final closed = await StorageService.getSession(first.sessionId);
    expect(closed!.endedAt, isNotNull);
  });

  test('restoreFromStorage reprend la séance Hive ouverte', () async {
    final started = await WorkoutSessionService.startSession();
    WorkoutSessionService.resetForTesting();
    expect(WorkoutSessionService.hasOpenSession, isFalse);

    final restored = await WorkoutSessionService.restoreFromStorage();
    expect(restored, started.sessionId);
    expect(WorkoutSessionService.hasOpenSession, isTrue);
  });

  test('plan de séance configurable par exerciseIds', () async {
    final plan = await WorkoutSessionPlanService.generateNextSession(
      exerciseIds: ['pull_up', 'push_up'],
    );

    expect(plan.exercises, hasLength(2));
    expect(
      plan.exercises.map((item) => item.exerciseId).toList(),
      ['pull_up', 'push_up'],
    );
  });

  test('historique Hive liste les séances', () async {
    await WorkoutSessionService.startSession();
    await WorkoutSessionService.addSet(
      const WorkoutSet(exerciseId: 'push_up', repetitions: 10),
    );
    await WorkoutSessionService.endSession();

    final sessions = StorageService.getAllSessions();
    expect(sessions, isNotEmpty);
    expect(sessions.first.isOpen, isFalse);
  });

  test('lit encore le format legacy de session', () async {
    final box = Hive.box(StorageService.workoutSessionBoxName);
    await box.put('legacy', {
      'id': 'legacy',
      'date': '2024-01-15T10:30:00.000',
      'setIds': <String>[],
    });

    final session = await StorageService.getSession('legacy');
    expect(session!.startedAt, DateTime.parse('2024-01-15T10:30:00.000'));
    expect(session.isOpen, isTrue);
  });
}
