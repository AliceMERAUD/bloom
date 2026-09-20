import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/app/app.dart';
import 'package:bloom/models/app_settings.dart';
import 'package:bloom/models/wellbeing_entry.dart';
import 'package:bloom/models/wellbeing_enums.dart';
import 'package:bloom/screens/shell/main_shell.dart';
import 'package:bloom/services/dashboard_service.dart';
import 'package:bloom/services/data_export_service.dart';
import 'package:bloom/services/puzzle_progress_service.dart';
import 'package:bloom/services/reminder_service.dart';
import 'package:bloom/services/settings_service.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/services/wellbeing_service.dart';
import 'package:bloom/services/workout_session_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    ReminderService.enabled = false;
    tempDir = await Directory.systemTemp.createTemp('bloom_core_');
    await StorageService.initForTesting(tempDir.path);
    SettingsService.load();
    WorkoutSessionService.resetForTesting();
  });

  tearDown(() async {
    await StorageService.closeForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('Bloom démarre sur le dashboard avec navigation', (tester) async {
    await tester.pumpWidget(const BloomApp());
    await tester.pump();

    expect(find.text('Bloom'), findsWidgets);
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Sport'), findsWidgets);
    expect(find.text('Bien-être'), findsWidgets);
    expect(find.text('Planning'), findsWidgets);
    expect(find.text('Plus'), findsOneWidget);
    expect(find.text('Bonjour'), findsOneWidget);
  });

  testWidgets('navigation bas vers Planning / Sport / Bien-être / Plus', (tester) async {
    await tester.pumpWidget(const BloomApp());
    await tester.pump();

    await tester.tap(find.text('Planning').last);
    await tester.pump();
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Mes tâches'), findsOneWidget);

    await tester.tap(find.text('Sport').last);
    await tester.pump();

    await tester.tap(find.text('Bien-être').last);
    await tester.pump();

    await tester.tap(find.text('Plus'));
    await tester.pump();
    expect(find.text('Puzzle'), findsWidgets);
    expect(find.text('Paramètres'), findsWidgets);

    // Dismiss Plus sheet.
    Navigator.of(tester.element(find.text('Puzzle').first)).pop();
    await tester.pump();

    await tester.tap(find.text('Accueil'));
    await tester.pump();
    expect(find.text('Bonjour'), findsOneWidget);
    expect(find.byTooltip('Paramètres'), findsOneWidget);
  });

  test('Dashboard affiche états vides sans données', () {
    final snap = DashboardService.load();
    expect(snap.closedSessionCount, 0);
    expect(snap.todayEntry, isNull);
    expect(snap.puzzleCompleted, 0);
    expect(snap.hasSportHistory, isFalse);
    expect(snap.pendingTaskCount, 0);
    expect(snap.completedTasksToday, 0);
  });

  test('Dashboard reflète Sport, Wellbeing et Puzzle réels', () async {
    await WorkoutSessionService.startSession();
    await WorkoutSessionService.endSession();

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
    expect(snap.closedSessionCount, 1);
    expect(snap.todayEntry?.mood, Mood.good);
    expect(snap.puzzleCompleted, 1);
    expect(snap.puzzleTotal, 15);
  });

  test('Settings thème et notifications persistent', () async {
    await SettingsService.save(
      const AppSettings(
        themeMode: ThemeMode.dark,
        notificationsEnabled: true,
        sportReminders: false,
        reminderHour: 18,
        reminderMinute: 30,
      ),
    );

    SettingsService.load();
    final s = SettingsService.current;
    expect(s.themeMode, ThemeMode.dark);
    expect(s.notificationsEnabled, isTrue);
    expect(s.sportReminders, isFalse);
    expect(s.reminderHour, 18);
    expect(s.reminderMinute, 30);
    expect(s.reminderTimeLabel, '18:30');
  });

  test('Export JSON versionné contient les modules', () async {
    await PuzzleProgressService.markCompleted('bus_friends');
    final map = DataExportService.buildExportMap(
      exportedAt: DateTime.utc(2026, 1, 1),
    );
    expect(map['version'], 2);
    expect(map['app'], 'bloom');
    expect(map['sport'], isA<Map>());
    expect(map['sportActivities'], isA<Map>());
    expect(map['sportBag'], isA<Map>());
    expect(map['wellbeing'], isA<Map>());
    expect(map['puzzle'], isA<Map>());
    expect(map['settings'], isA<Map>());

    final json = DataExportService.exportJson();
    expect(json, contains('"version": 2'));
  });

  test('Import valide remplace les données', () async {
    await PuzzleProgressService.markCompleted('bus_friends');
    final json = DataExportService.exportJson();

    await StorageService.clearAllUserData(keepSettings: false);
    SettingsService.load();
    expect(PuzzleProgressService.load().completedIds, isEmpty);

    await DataExportService.importAndReplace(json);
    expect(PuzzleProgressService.load().completedIds, contains('bus_friends'));
  });

  test('Import refuse JSON invalide et version inconnue', () {
    expect(
      () => DataExportService.parseImport('{not json'),
      throwsA(isA<DataExportException>()),
    );
    expect(
      () => DataExportService.parseImport('{"version": 99, "app": "bloom"}'),
      throwsA(isA<DataExportException>()),
    );
    expect(
      () => DataExportService.parseImport('{"version": 1, "app": "other"}'),
      throwsA(isA<DataExportException>()),
    );
  });

  test('Suppression efface modules et conserve settings si demandé', () async {
    await SettingsService.save(
      const AppSettings(themeMode: ThemeMode.light),
    );
    await PuzzleProgressService.markCompleted('bus_friends');

    await StorageService.clearAllUserData(keepSettings: true);
    expect(PuzzleProgressService.load().completedIds, isEmpty);
    expect(StorageService.getAppSettings().themeMode, ThemeMode.light);
  });

  testWidgets('changement de thème via SettingsService met à jour l’app',
      (tester) async {
    await tester.pumpWidget(const BloomApp());
    await tester.pump();

    SettingsService.notifier.value =
        SettingsService.current.copyWith(themeMode: ThemeMode.dark);
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
