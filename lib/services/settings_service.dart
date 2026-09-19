import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import 'reminder_service.dart';
import 'storage_service.dart';

/// Loads/saves [AppSettings] and notifies the UI via [notifier].
class SettingsService {
  static final ValueNotifier<AppSettings> notifier =
      ValueNotifier(const AppSettings());

  static AppSettings get current => notifier.value;

  static void load() {
    notifier.value = StorageService.getAppSettings();
  }

  static Future<void> save(AppSettings settings) async {
    await StorageService.saveAppSettings(settings);
    notifier.value = settings;
    if (ReminderService.enabled) {
      await ReminderService.syncFromSettings(settings);
    }
  }

  static Future<void> update(AppSettings Function(AppSettings) transform) {
    return save(transform(current));
  }
}
