import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/models/wellbeing_entry.dart';
import 'package:bloom/models/wellbeing_enums.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/services/wellbeing_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bloom_wellbeing_');
    await StorageService.initForTesting(tempDir.path);
  });

  tearDown(() async {
    await StorageService.closeForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('WellbeingEntry model', () {
    test('création et sérialisation round-trip', () {
      final entry = WellbeingEntry(
        id: '2026-03-01',
        date: DateTime(2026, 3, 1),
        mood: Mood.good,
        energy: Energy.medium,
        pain: Pain.mild,
        bleeding: Bleeding.light,
        symptoms: const [Symptom.cramps, Symptom.fatigue],
        note: 'Journée douce',
        periodMarker: PeriodMarker.start,
      );

      final restored = WellbeingEntry.fromMap(entry.toMap());

      expect(restored.id, '2026-03-01');
      expect(restored.date, DateTime(2026, 3, 1));
      expect(restored.mood, Mood.good);
      expect(restored.energy, Energy.medium);
      expect(restored.pain, Pain.mild);
      expect(restored.bleeding, Bleeding.light);
      expect(restored.symptoms, [Symptom.cramps, Symptom.fatigue]);
      expect(restored.note, 'Journée douce');
      expect(restored.periodMarker, PeriodMarker.start);
    });

    test('dateKey normalise la date', () {
      expect(
        WellbeingEntry.dateKey(DateTime(2026, 9, 5, 18, 30)),
        '2026-09-05',
      );
    });
  });

  group('Persistence', () {
    test('sauvegarde, récupération, modification, suppression', () async {
      final saved = await WellbeingService.saveEntry(
        WellbeingEntry(
          id: 'tmp',
          date: DateTime(2026, 4, 10),
          mood: Mood.neutral,
          energy: Energy.low,
        ),
      );

      expect(saved.id, '2026-04-10');
      expect(
        WellbeingService.getEntryForDate(DateTime(2026, 4, 10))?.mood,
        Mood.neutral,
      );

      await WellbeingService.saveEntry(
        saved.copyWith(mood: Mood.veryGood, note: 'Mieux'),
      );

      final updated = WellbeingService.getEntryForDate(DateTime(2026, 4, 10));
      expect(updated?.mood, Mood.veryGood);
      expect(updated?.note, 'Mieux');

      await WellbeingService.deleteEntry('2026-04-10');
      expect(WellbeingService.getEntryForDate(DateTime(2026, 4, 10)), isNull);
    });

    test('symptômes optionnels et journée sans symptôme', () async {
      await WellbeingService.saveEntry(
        WellbeingEntry(
          id: 'x',
          date: DateTime(2026, 5, 1),
          mood: Mood.good,
          symptoms: const [],
        ),
      );

      final entry = WellbeingService.getEntryForDate(DateTime(2026, 5, 1));
      expect(entry?.symptoms, isEmpty);

      await WellbeingService.saveEntry(
        entry!.copyWith(symptoms: const [Symptom.headache, Symptom.nausea]),
      );

      expect(
        WellbeingService.getEntryForDate(DateTime(2026, 5, 1))?.symptoms,
        [Symptom.headache, Symptom.nausea],
      );
    });
  });

  group('Cycle', () {
    test('début et fin de période + durée', () async {
      await WellbeingService.startPeriod(DateTime(2026, 6, 1));
      await WellbeingService.endPeriod(DateTime(2026, 6, 5));

      final periods = WellbeingService.getPeriods();
      expect(periods, hasLength(1));
      expect(periods.first.start, DateTime(2026, 6, 1));
      expect(periods.first.end, DateTime(2026, 6, 5));
      expect(periods.first.durationDays, 5);
      expect(periods.first.isOngoing, isFalse);
    });

    test('période en cours sans fin', () async {
      await WellbeingService.startPeriod(DateTime(2026, 7, 10));

      final current = WellbeingService.getCurrentPeriod();
      expect(current, isNotNull);
      expect(current!.isOngoing, isTrue);
      expect(current.durationDays, isNull);
      expect(WellbeingService.cycleStatusLabel(), contains('en cours'));
    });
  });
}
