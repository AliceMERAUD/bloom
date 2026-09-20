import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/app/app.dart';
import 'package:bloom/services/reminder_service.dart';
import 'package:bloom/services/settings_service.dart';
import 'package:bloom/services/storage_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    ReminderService.enabled = false;
    tempDir = await Directory.systemTemp.createTemp('bloom_widget_');
    await StorageService.initForTesting(tempDir.path);
    SettingsService.load();
  });

  tearDown(() async {
    await StorageService.closeForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('Bloom démarre correctement', (WidgetTester tester) async {
    await tester.pumpWidget(const BloomApp());
    await tester.pump();

    expect(find.text('Bloom'), findsWidgets);
    expect(find.text('Sport'), findsWidgets);
    expect(find.text('Bien-être'), findsWidgets);
    expect(find.text('Planning'), findsWidgets);
    expect(find.text('Plus'), findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);
  });
}
