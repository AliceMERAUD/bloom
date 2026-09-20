import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/screens/shell/main_shell.dart';
import 'package:bloom/screens/tasks/tasks_screen.dart';
import 'package:bloom/services/reminder_service.dart';
import 'package:bloom/services/settings_service.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/services/task_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    ReminderService.enabled = false;
    tempDir = await Directory.systemTemp.createTemp('bloom_tasks_ui_');
    await StorageService.initForTesting(tempDir.path);
    SettingsService.load();
  });

  tearDown(() async {
    await StorageService.closeForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('TasksScreen état vide et liste', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TasksScreen()));
    await tester.pump();

    expect(find.text('Rien à faire pour le moment'), findsOneWidget);

    await tester.runAsync(() async {
      await TaskService.addTask(title: 'Faire les courses');
    });
    await tester.pumpWidget(
      const MaterialApp(home: TasksScreen(key: ValueKey('reload'))),
    );
    await tester.pump();
    expect(find.text('Faire les courses'), findsOneWidget);
  });

  testWidgets('filtre terminées', (tester) async {
    await tester.runAsync(() async {
      await TaskService.addTask(title: 'A faire');
      final done = await TaskService.addTask(title: 'Deja fait');
      await TaskService.completeTask(done.id);
    });

    await tester.pumpWidget(const MaterialApp(home: TasksScreen()));
    await tester.pump();
    expect(find.text('A faire'), findsOneWidget);

    await tester.tap(find.text('Terminées'));
    await tester.pump();
    expect(find.text('Deja fait'), findsOneWidget);
    expect(find.text('A faire'), findsNothing);
  });

  testWidgets('MainShell expose Tasks', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pump();
    expect(find.text('Tasks'), findsWidgets);
    await tester.tap(find.text('Tasks').last);
    await tester.pump();
    expect(find.byType(TasksScreen), findsOneWidget);
    expect(find.text('Les petites choses à faire 🌱'), findsOneWidget);
  });
}
