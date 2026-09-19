import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/screens/puzzle/puzzle_screen.dart';
import 'package:bloom/services/storage_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bloom_puzzle_ui_');
    await StorageService.initForTesting(tempDir.path);
  });

  tearDown(() async {
    await StorageService.closeForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('PuzzleScreen liste les puzzles', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PuzzleScreen()),
    );
    await tester.pump();

    expect(find.text('Puzzle'), findsOneWidget);
    expect(find.text('Les amis dans le bus'), findsWidgets);
  });
}
