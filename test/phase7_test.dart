import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/models/puzzle/puzzle.dart';
import 'package:bloom/models/puzzle/puzzle_constraint.dart';
import 'package:bloom/models/puzzle/puzzle_geometry.dart';
import 'package:bloom/models/puzzle/puzzle_models.dart';
import 'package:bloom/models/sport_activity.dart';
import 'package:bloom/models/task.dart';
import 'package:bloom/services/bloom_refresh.dart';
import 'package:bloom/services/dashboard_service.dart';
import 'package:bloom/services/data_export_service.dart';
import 'package:bloom/services/puzzle_catalog.dart';
import 'package:bloom/services/reminder_service.dart';
import 'package:bloom/services/settings_service.dart';
import 'package:bloom/services/sport_activity_service.dart';
import 'package:bloom/services/sport_bag_service.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/services/task_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    ReminderService.enabled = false;
    tempDir = await Directory.systemTemp.createTemp('bloom_p7_');
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

  group('SportActivity + sac', () {
    test('musculation builtin et CRUD sport custom', () async {
      expect(
        SportActivityService.getById(kBuiltinStrengthSportId)?.builtin,
        isTrue,
      );

      final swim = await SportActivityService.add(
        name: 'Natation',
        iconName: 'pool',
      );
      expect(SportActivityService.getAll(), hasLength(2));

      await SportActivityService.update(swim.copyWith(name: 'Nage'));
      expect(SportActivityService.getById(swim.id)?.name, 'Nage');

      expect(
        () => SportActivityService.delete(kBuiltinStrengthSportId),
        throwsStateError,
      );

      await SportActivityService.delete(swim.id);
      expect(SportActivityService.getAll(), hasLength(1));
    });

    test('sac général + par sport', () async {
      final sport = await SportActivityService.add(name: 'Handball');
      await SportBagService.add(name: 'Gourde');
      await SportBagService.add(name: 'Maillot', sportId: sport.id);

      expect(SportBagService.getGeneral(), hasLength(1));
      expect(SportBagService.checklistFor(sport.id), hasLength(2));

      final gourde = SportBagService.getGeneral().first;
      await SportBagService.toggleChecked(gourde.id);
      expect(StorageService.getBagItem(gourde.id)?.checked, isTrue);
    });
  });

  group('Tasks ↔ Sport + rappels', () {
    test('sportId et lead time rappel', () async {
      final sport = await SportActivityService.add(
        name: 'Natation',
        iconName: 'pool',
      );
      await SportBagService.add(name: 'Bonnet', sportId: sport.id);

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final task = await TaskService.addTask(
        title: 'Natation',
        category: TaskCategory.sport,
        sportId: sport.id,
        dueDate: tomorrow,
        dueTime: const TimeOfDay(hour: 18, minute: 0),
        reminderEnabled: true,
        reminderMinutesBefore: 30,
      );

      expect(task.sportId, sport.id);
      final fire = TaskService.reminderFireAt(task)!;
      expect(fire.hour, 17);
      expect(fire.minute, 30);

      final copy = TaskService.notificationCopyFor(task);
      expect(copy.$1, contains('Sport'));
      expect(copy.$2, contains('sac'));
    });

    test('notifications désactivées ne bloquent pas la création', () async {
      await SettingsService.save(
        SettingsService.current.copyWith(notificationsEnabled: false),
      );
      final task = await TaskService.addTask(
        title: 'Courses',
        reminderEnabled: true,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        dueTime: const TimeOfDay(hour: 10, minute: 0),
      );
      expect(task.id, isNotEmpty);
    });
  });

  group('Dashboard refresh + stats', () {
    test('BloomRefresh bump et compteurs tasks', () async {
      final before = BloomRefresh.version.value;
      await TaskService.addTask(
        title: 'Retard',
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(BloomRefresh.version.value, greaterThan(before));

      final snap = DashboardService.load();
      expect(snap.overdueTaskCount, greaterThanOrEqualTo(1));
      expect(snap.pendingTaskCount, greaterThanOrEqualTo(1));
    });
  });

  group('Puzzle geometry', () {
    test('grille ascii et nearObject', () {
      final geo = PuzzleGeometry.fromAscii(layout: const ['W.', 'D.']);
      expect(geo.seats, hasLength(2));
      expect(geo.objectIndices('window'), isNotEmpty);
      // seats at (0,1) and (1,1) — same column, adjacent rows
      expect(geo.areAdjacent(0, 1), isTrue);

      final near = NearObjectConstraint(
        id: '1',
        characterId: 'alice',
        objectId: 'window',
      );
      expect(
        near.isSatisfied(
          const PuzzlePlacement({'alice': 0}),
          geo,
        ),
        isTrue,
      );
    });

    test('tous les puzzles 2.0 ont une solution unique', () {
      for (final p in PuzzleCatalog.all) {
        expect(p.geometry, isNotNull, reason: p.id);
        expect(PuzzleValidator.countSolutions(p), 1, reason: p.id);
      }
    });

    test('indices progressifs', () {
      final puzzle = PuzzleCatalog.byId('bus_friends');
      final hint0 = PuzzleHintService.describeHint(
        puzzle,
        const PuzzlePlacement(),
        0,
      );
      expect(hint0, contains('Indice'));
    });
  });

  group('Export v2', () {
    test('exporte sports et importe v1 sans sports', () async {
      await SportActivityService.add(name: 'Vélo');
      final json = DataExportService.exportJson();
      expect(json, contains('sportActivities'));
      expect(DataExportService.formatVersion, 2);

      const v1 = '''
{
  "version": 1,
  "exportedAt": "2026-01-01T00:00:00.000",
  "app": "bloom",
  "sport": {"sessions": [], "sets": []},
  "wellbeing": {"entries": []},
  "puzzle": {"completedIds": [], "placements": {}},
  "tasks": {"items": []},
  "settings": {}
}
''';
      await DataExportService.importAndReplace(v1);
      await SportActivityService.ensureDefaults();
      expect(SportActivityService.getById(kBuiltinStrengthSportId), isNotNull);
    });
  });
}
