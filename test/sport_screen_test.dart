import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/screens/sport/sport_screen.dart';
import 'package:bloom/services/sport_activity_service.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/services/workout_session_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    WorkoutSessionService.resetForTesting();
    tempDir = await Directory.systemTemp.createTemp('bloom_sport_ui_');
    await StorageService.initForTesting(tempDir.path);
    await SportActivityService.ensureDefaults();
  });

  tearDown(() async {
    await StorageService.closeForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('SportScreen affiche le catalogue d’exercices', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SportScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Sport'), findsOneWidget);
    expect(find.text('Mes sports'), findsOneWidget);
    expect(find.text('Sac de sport'), findsOneWidget);
    expect(find.text('Musculation'), findsWidgets);
    expect(find.text('Traction'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Pompes'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Pompes'), findsOneWidget);
  });
}
