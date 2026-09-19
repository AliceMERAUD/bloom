import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';

/// Local-only reminders via [flutter_local_notifications].
///
/// No server, no push. Scheduling is daily at the configured local time.
/// Tests can leave [enabled] false so no plugin calls are made.
class ReminderService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool enabled = true;

  static const _sportId = 1001;
  static const _wellbeingId = 1002;
  static const _puzzleId = 1003;

  static Future<void> init() async {
    if (!enabled || _initialized) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.local);
    } catch (_) {
      // Fallback: keep default UTC; daily times still relative enough for V1.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  /// Requests Android 13+ notification permission. Never throws.
  static Future<bool> requestPermission() async {
    if (!enabled) return false;
    try {
      await init();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    } catch (e) {
      debugPrint('Reminder permission: $e');
      return false;
    }
  }

  static Future<void> syncFromSettings(AppSettings settings) async {
    if (!enabled) return;
    try {
      await init();
      await cancelAll();
      if (!settings.notificationsEnabled) return;

      if (settings.sportReminders) {
        await _scheduleDaily(
          id: _sportId,
          title: 'Bloom — Sport',
          body: 'C’est l’heure de ta séance !',
          hour: settings.reminderHour,
          minute: settings.reminderMinute,
        );
      }
      if (settings.wellbeingReminders) {
        await _scheduleDaily(
          id: _wellbeingId,
          title: 'Bloom — Bien-être',
          body: 'Comment vas-tu aujourd’hui ?',
          hour: settings.reminderHour,
          minute: settings.reminderMinute,
        );
      }
      if (settings.puzzleReminders) {
        await _scheduleDaily(
          id: _puzzleId,
          title: 'Bloom — Puzzle',
          body: 'Ton puzzle du jour t’attend !',
          hour: settings.reminderHour,
          minute: settings.reminderMinute,
        );
      }
    } catch (e) {
      debugPrint('Reminder sync: $e');
    }
  }

  static Future<void> cancelAll() async {
    if (!enabled) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  static Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final android = AndroidNotificationDetails(
      'bloom_reminders',
      'Rappels Bloom',
      channelDescription: 'Rappels locaux Sport, Bien-être et Puzzle',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    final details = NotificationDetails(android: android);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
