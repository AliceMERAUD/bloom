import 'package:flutter/material.dart';

import 'app/app.dart';
import 'services/reminder_service.dart';
import 'services/settings_service.dart';
import 'services/sport_activity_service.dart';
import 'services/storage_service.dart';
import 'services/workout_session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService.init();
  await SportActivityService.ensureDefaults();
  SettingsService.load();
  await WorkoutSessionService.restoreFromStorage();
  await ReminderService.init();
  await ReminderService.syncFromSettings(SettingsService.current);

  runApp(const BloomApp());
}
