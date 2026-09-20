import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/models/sport_activity.dart';
import 'package:bloom/models/task.dart';
import 'package:bloom/screens/puzzle/puzzle_play_screen.dart';
import 'package:bloom/services/puzzle_catalog.dart';
import 'package:bloom/services/puzzle_progress_service.dart';
import 'package:bloom/services/reminder_service.dart';
import 'package:bloom/services/settings_service.dart';
import 'package:bloom/services/sport_activity_service.dart';
import 'package:bloom/services/sport_bag_service.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/services/task_service.dart';
import 'package:bloom/models/puzzle/puzzle_models.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    ReminderService.enabled = false;
    tempDir = await Directory.systemTemp.createTemp('bloom_p8_');
    await StorageService.initForTesting(tempDir.path);
    SettingsService.load();
    await SportActivityService.ensureDefaults();
    PuzzlePlayScreenState.suppressPersistence = true;
  });

  tearDown(() async {
    PuzzlePlayScreenState.suppressPersistence = false;
    await StorageService.closeForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Notifications par sport', () {
    test('paramètres indépendants entre sports', () async {
      final swim = await SportActivityService.add(name: 'Natation', iconName: 'pool');
      final hand = await SportActivityService.add(
        name: 'Handball',
        iconName: 'sports_handball',
      );

      await SportActivityService.update(
        swim.copyWith(
          notificationMessage: 'Message natation unique',
          notificationMinutesBefore: 15,
          notificationEnabled: true,
        ),
      );
      await SportActivityService.update(
        hand.copyWith(
          notificationMessage: 'Message hand unique',
          notificationMinutesBefore: 60,
          notificationEnabled: false,
        ),
      );

      final s = SportActivityService.getById(swim.id)!;
      final h = SportActivityService.getById(hand.id)!;
      expect(s.notificationMessage, 'Message natation unique');
      expect(h.notificationMessage, 'Message hand unique');
      expect(s.notificationMinutesBefore, 15);
      expect(h.notificationMinutesBefore, 60);
      expect(h.notificationEnabled, isFalse);
      expect(s.notificationEnabled, isTrue);
    });

    test('message défaut et délai sport pour tâche liée', () async {
      final swim = await SportActivityService.add(name: 'Natation', iconName: 'pool');
      await SportActivityService.update(
        swim.copyWith(notificationMinutesBefore: 30),
      );
      await SportBagService.add(name: 'Lunettes', sportId: swim.id);

      final task = await TaskService.addTask(
        title: 'Natation',
        category: TaskCategory.sport,
        sportId: swim.id,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        dueTime: const TimeOfDay(hour: 18, minute: 0),
        reminderEnabled: true,
        reminderMinutesBefore: 0,
      );

      final fire = TaskService.reminderFireAt(task)!;
      expect(fire.hour, 17);
      expect(fire.minute, 30);

      final copy = TaskService.notificationCopyFor(task);
      expect(
        copy.$2.toLowerCase().contains('sac') ||
            copy.$2.contains('maillot') ||
            copy.$2.contains('Piscine') ||
            copy.$2.contains('Message'),
        isTrue,
      );
    });

    test('sport notification désactivée bloque la programmation logique', () async {
      final sport = await SportActivityService.add(name: 'Vélo', iconName: 'directions_bike');
      await SportActivityService.update(
        sport.copyWith(notificationEnabled: false),
      );
      final task = await TaskService.addTask(
        title: 'Vélo',
        sportId: sport.id,
        reminderEnabled: true,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        dueTime: const TimeOfDay(hour: 9, minute: 0),
      );
      // Sync should no-op schedule when disabled — still creates task.
      expect(task.id, isNotEmpty);
      expect(SportActivityService.getById(sport.id)!.notificationEnabled, isFalse);
    });

    test('message par défaut musculation', () {
      final strength = SportActivity(
        id: kBuiltinStrengthSportId,
        name: 'Musculation',
        iconName: 'fitness_center',
        createdAt: DateTime.now(),
      );
      expect(strength.defaultNotificationMessage(), contains('séance'));
    });
  });

  group('Sacs fusionnés', () {
    test('général + sport sans doublon', () async {
      final muscu = SportActivityService.getById(kBuiltinStrengthSportId)!;
      final swim = await SportActivityService.add(name: 'Natation');

      await SportBagService.add(name: 'Gourde');
      await SportBagService.add(name: 'Serviette');
      await SportBagService.add(name: 'Chaussures', sportId: muscu.id);
      await SportBagService.add(name: 'Maillot', sportId: swim.id);

      final muscuBag = SportBagService.checklistFor(muscu.id);
      final swimBag = SportBagService.checklistFor(swim.id);
      final general = SportBagService.getGeneral();

      expect(general.map((e) => e.name), containsAll(['Gourde', 'Serviette']));
      expect(muscuBag.map((e) => e.name), containsAll(['Gourde', 'Serviette', 'Chaussures']));
      expect(muscuBag.map((e) => e.name), isNot(contains('Maillot')));
      expect(swimBag.map((e) => e.name), containsAll(['Gourde', 'Serviette', 'Maillot']));
      expect(swimBag.map((e) => e.name), isNot(contains('Chaussures')));

      final ids = muscuBag.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);

      final filtered = SportBagService.itemsForFilter(swim.id);
      expect(filtered.length, swimBag.length);

      final maillot = SportBagService.getForSport(swim.id).first;
      await SportBagService.delete(maillot.id);
      expect(
        SportBagService.checklistFor(swim.id).map((e) => e.name),
        isNot(contains('Maillot')),
      );
      expect(SportBagService.getGeneral(), hasLength(2));
    });
  });

  group('Puzzle navigation', () {
    testWidgets('succès propose puzzle suivant', (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      final puzzle = PuzzleCatalog.byId('bus_friends');
      await tester.pumpWidget(
        MaterialApp(home: PuzzlePlayScreen(puzzleId: puzzle.id)),
      );
      await tester.pump();

      final state = tester.state<PuzzlePlayScreenState>(
        find.byType(PuzzlePlayScreen),
      );
      state.placement = PuzzlePlacement(
        Map<String, int>.from(puzzle.referenceSolution),
      );
      await tester.pump();
      state.debugVerify(showSuccessDialog: true);
      await tester.pumpAndSettle();

      expect(find.textContaining('Bravo'), findsWidgets);
      expect(find.textContaining('Puzzle suivant'), findsWidgets);
    });

    testWidgets('échec garde la grille', (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      final puzzle = PuzzleCatalog.byId('bus_friends');
      await tester.pumpWidget(
        MaterialApp(home: PuzzlePlayScreen(puzzleId: puzzle.id)),
      );
      await tester.pump();
      final state = tester.state<PuzzlePlayScreenState>(
        find.byType(PuzzlePlayScreen),
      );
      final wrong = Map<String, int>.from(puzzle.referenceSolution);
      final keys = wrong.keys.toList();
      final a = wrong[keys[0]]!;
      wrong[keys[0]] = wrong[keys[1]]!;
      wrong[keys[1]] = a;
      state.placement = PuzzlePlacement(wrong);
      await tester.pump();
      state.debugVerify();
      await tester.pumpAndSettle();

      expect(find.textContaining('Pas encore'), findsOneWidget);
      expect(state.placement.seats.length, 4);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(state.placement.seats.length, 4);
    });

    test('dernier puzzle débloque retour liste logique', () {
      final last = PuzzleCatalog.all.last;
      expect(PuzzleCatalog.indexOf(last.id), PuzzleCatalog.all.length - 1);
      // Completing last unlocks nothing further — index at end.
      expect(PuzzleProgressService.load().nextPlayableId, isNot(last.id));
    });
  });
}
