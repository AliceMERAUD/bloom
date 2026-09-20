import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';

/// Local-only reminders via [flutter_local_notifications].
///
/// Module reminders use ids 1001–1003. Task reminders use ids >= 2000.
/// Tests can leave [enabled] false so no plugin calls are made.
class ReminderService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool enabled = true;

  static const sportId = 1001;
  static const wellbeingId = 1002;
  static const puzzleId = 1003;
  static const taskIdBase = 2000;
  static const channelId = 'bloom_reminders';

  static int notificationIdForTask(String taskId) =>
      taskIdBase + (taskId.hashCode.abs() % 800000);

  static Future<void> init() async {
    if (!enabled || _initialized) return;

    tz_data.initializeTimeZones();
    await _configureLocalTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    await _ensureAndroidChannel();
    _initialized = true;
  }

  static Future<void> _configureLocalTimeZone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final name = info.identifier;
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('Reminder timezone fallback: $e');
      try {
        tz.setLocalLocation(tz.getLocation('Europe/Paris'));
      } catch (_) {
        // Keep default UTC.
      }
    }
  }

  static Future<void> _ensureAndroidChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        'Rappels Bloom',
        description: 'Rappels locaux Sport, Bien-être, Puzzle et Tasks',
        importance: Importance.high,
      ),
    );
  }

  /// Requests Android 13+ notification permission. Never throws.
  static Future<bool> requestPermission() async {
    if (!enabled) return false;
    try {
      await init();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      // Best-effort exact alarms (Android 12+).
      try {
        await android?.requestExactAlarmsPermission();
      } catch (_) {}
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
      await cancelId(sportId);
      await cancelId(wellbeingId);
      await cancelId(puzzleId);

      if (!settings.notificationsEnabled) return;

      if (settings.sportReminders) {
        await _scheduleDaily(
          id: sportId,
          title: 'Bloom — Sport',
          body: 'C’est l’heure de ta séance ! Pense à ton sac 🎒',
          hour: settings.reminderHour,
          minute: settings.reminderMinute,
        );
      }
      if (settings.wellbeingReminders) {
        await _scheduleDaily(
          id: wellbeingId,
          title: 'Bloom — Bien-être',
          body: 'Comment vas-tu aujourd’hui ?',
          hour: settings.reminderHour,
          minute: settings.reminderMinute,
        );
      }
      if (settings.puzzleReminders) {
        await _scheduleDaily(
          id: puzzleId,
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

  static Future<void> cancelId(int id) async {
    if (!enabled) return;
    try {
      await init();
      await _plugin.cancel(id);
    } catch (_) {}
  }

  static Future<void> cancelAll() async {
    if (!enabled) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// One-shot local notification at [when].
  static Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!enabled) return;
    try {
      await init();
      await _plugin.cancel(id);
      if (when.isBefore(DateTime.now())) return;

      const android = AndroidNotificationDetails(
        channelId,
        'Rappels Bloom',
        channelDescription: 'Rappels locaux Bloom',
        importance: Importance.high,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: android);
      final scheduled = tz.TZDateTime.from(when, tz.local);

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Reminder scheduleAt exact failed, fallback inexact: $e');
      try {
        const android = AndroidNotificationDetails(
          channelId,
          'Rappels Bloom',
          channelDescription: 'Rappels locaux Bloom',
          importance: Importance.high,
          priority: Priority.high,
        );
        const details = NotificationDetails(android: android);
        final scheduled = tz.TZDateTime.from(when, tz.local);
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e2) {
        debugPrint('Reminder scheduleAt: $e2');
      }
    }
  }

  static Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    const android = AndroidNotificationDetails(
      channelId,
      'Rappels Bloom',
      channelDescription: 'Rappels locaux Sport, Bien-être et Puzzle',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: android);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
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
