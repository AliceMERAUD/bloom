import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:bloom/models/workout_set.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/services/workout_session_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bloom_hive_');
    await StorageService.initForTesting(tempDir.path);
  });

  tearDown(() async {
    await StorageService.closeForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('saveWorkoutSet et lecture typée', () async {
    final id = await StorageService.saveWorkoutSet(
      const WorkoutSet(
        exerciseId: 'pull_up',
        repetitions: 8,
        weight: 5,
      ),
    );

    final sets = StorageService.getWorkoutSets();

    expect(sets, hasLength(1));
    expect(sets.first.id, id);
    expect(sets.first.exerciseId, 'pull_up');
    expect(sets.first.repetitions, 8);
    expect(sets.first.weight, 5);
    expect(sets.first.date, isNotNull);
  });

  test('createWorkoutSession enregistre startedAt sans endedAt', () async {
    final id = await StorageService.createWorkoutSession();
    final session = await StorageService.getSession(id);

    expect(session, isNotNull);
    expect(session!.isOpen, isTrue);
    expect(session.endedAt, isNull);
    expect(session.startedAt, isNotNull);
  });

  test('endWorkoutSession clôture la séance en base', () async {
    final id = await StorageService.createWorkoutSession();

    await StorageService.endWorkoutSession(id);

    final session = await StorageService.getSession(id);

    expect(session, isNotNull);
    expect(session!.isOpen, isFalse);
    expect(session.endedAt, isNotNull);
    expect(
      session.endedAt!.isAfter(session.startedAt) ||
          session.endedAt!.isAtSameMomentAs(session.startedAt),
      isTrue,
    );
  });

  test('endSession du service clôture et réinitialise la session courante',
      () async {
    await WorkoutSessionService.startSession();
    final sessionId = WorkoutSessionService.currentSessionId;

    expect(sessionId, isNotNull);

    await WorkoutSessionService.addSet(
      const WorkoutSet(
        exerciseId: 'push_up',
        repetitions: 10,
      ),
    );

    await WorkoutSessionService.endSession();

    expect(WorkoutSessionService.currentSessionId, isNull);

    final session = await StorageService.getSession(sessionId!);
    expect(session!.endedAt, isNotNull);
    expect(session.setIds, hasLength(1));
  });

  test('lit les anciennes sessions sans startedAt/endedAt', () async {
    final box = Hive.box(StorageService.workoutSessionBoxName);
    const legacyId = 'legacy_session';

    await box.put(legacyId, {
      'id': legacyId,
      'date': '2024-01-15T10:30:00.000',
      'setIds': <String>[],
    });

    final session = await StorageService.getSession(legacyId);

    expect(session, isNotNull);
    expect(session!.id, legacyId);
    expect(session.startedAt, DateTime.parse('2024-01-15T10:30:00.000'));
    expect(session.endedAt, isNull);
    expect(session.isOpen, isTrue);
  });

  test('lit les anciennes séries Map sans casser le format', () async {
    final box = Hive.box(StorageService.workoutBoxName);
    const legacyId = 'legacy_set';

    await box.put(legacyId, {
      'id': legacyId,
      'exerciseId': 'lat_pulldown',
      'repetitions': 12,
      'weight': 40.0,
      'assistance': null,
      'durationSeconds': null,
      'date': '2024-02-01T08:00:00.000',
    });

    final sets = await StorageService.getSetsForExercise('lat_pulldown');

    expect(sets, hasLength(1));
    expect(sets.first.id, legacyId);
    expect(sets.first.repetitions, 12);
    expect(sets.first.weight, 40.0);
  });
}
