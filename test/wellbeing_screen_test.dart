import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/screens/wellbeing/wellbeing_screen.dart';
import 'package:bloom/services/storage_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bloom_wb_ui_');
    await StorageService.initForTesting(tempDir.path);
  });

  tearDown(() async {
    await StorageService.closeForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('WellbeingScreen s’ouvre avec actions principales', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WellbeingScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Bien-être'), findsOneWidget);
    expect(find.textContaining('Ajouter ma journée'), findsOneWidget);
    expect(find.text('Début des règles'), findsOneWidget);
  });
}
