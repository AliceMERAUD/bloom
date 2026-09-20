import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/models/app_settings.dart';
import 'package:bloom/models/google_calendar.dart';
import 'package:bloom/models/task.dart';
import 'package:bloom/services/google_calendar/google_sign_in_config.dart';
import 'package:bloom/services/google_calendar/fake_google_calendar_backend.dart';
import 'package:bloom/services/google_calendar/google_calendar_service.dart';
import 'package:bloom/services/settings_service.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/services/task_service.dart';

void main() {
  late Directory tempDir;
  late FakeGoogleCalendarBackend fake;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bloom_gcal_');
    await StorageService.initForTesting(tempDir.path);
    SettingsService.load();
    fake = FakeGoogleCalendarBackend();
    GoogleCalendarService.useFakeBackend(fake);
  });

  tearDown(() async {
    GoogleCalendarService.useLiveBackend();
    await StorageService.closeForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('GoogleSignInConfig', () {
    test('scopes Calendar étroits et package Android documenté', () {
      expect(GoogleSignInConfig.androidApplicationId, 'com.example.bloom');
      expect(GoogleSignInConfig.calendarScopes, hasLength(2));
      expect(
        GoogleSignInConfig.calendarScopes.any((s) => s.contains('calendar')),
        isTrue,
      );
    });
  });

  group('GoogleCalendarService', () {
    test('connect / disconnect et sélection calendrier', () async {
      expect(await GoogleCalendarService.isConnected, isFalse);

      final ok = await GoogleCalendarService.connect();
      expect(ok, isTrue);
      expect(await GoogleCalendarService.isConnected, isTrue);
      expect(SettingsService.current.googleCalendar.accountEmail, isNotNull);
      expect(
        SettingsService.current.googleCalendar.selectedCalendarId,
        'primary',
      );

      final calendars = await GoogleCalendarService.listCalendars();
      expect(calendars, isNotEmpty);
      await GoogleCalendarService.selectCalendar(calendars.last);
      expect(
        SettingsService.current.googleCalendar.selectedCalendarId,
        calendars.last.id,
      );

      await GoogleCalendarService.disconnect();
      expect(await GoogleCalendarService.isConnected, isFalse);
      expect(SettingsService.current.googleCalendar.accountEmail, isNull);
    });

    test('création sans doublon + mise à jour + suppression', () async {
      await GoogleCalendarService.connect();

      final task = await TaskService.addTask(
        title: 'Sac de sport',
        dueDate: DateTime(2026, 9, 25),
        dueTime: const TimeOfDay(hour: 17, minute: 30),
        category: TaskCategory.sport,
      );

      expect(GoogleCalendarService.taskCanSync(task), isTrue);
      final eventId = await GoogleCalendarService.createEventForTask(task);
      expect(eventId, isNotEmpty);
      expect(fake.events.containsKey(eventId), isTrue);

      final linked = await GoogleCalendarService.linkTaskEvent(task, eventId);
      expect(linked.googleCalendarEventId, eventId);

      expect(
        () => GoogleCalendarService.createEventForTask(linked),
        throwsA(isA<GoogleCalendarException>()),
      );

      final moved = linked.copyWith(
        dueTime: const TimeOfDay(hour: 18, minute: 30),
      );
      await StorageService.saveTask(moved);
      await GoogleCalendarService.updateEventForTask(moved);
      expect(fake.events[eventId]!.start.hour, 18);

      await GoogleCalendarService.deleteEventForTask(moved);
      expect(fake.events.containsKey(eventId), isFalse);
      await GoogleCalendarService.unlinkTaskEvent(moved);
      expect(
        StorageService.getTask(moved.id)!.googleCalendarEventId,
        isNull,
      );
    });

    test('tâche sans date non synchronisable', () async {
      final task = await TaskService.addTask(title: 'Sans date');
      expect(GoogleCalendarService.taskCanSync(task), isFalse);
      await GoogleCalendarService.connect();
      expect(
        () => GoogleCalendarService.createEventForTask(task),
        throwsA(isA<GoogleCalendarException>()),
      );
    });

    test('récurrence mappe une RRULE unique (pas de doublons)', () {
      expect(
        GoogleCalendarService.recurrenceRuleFor(TaskRecurrence.daily),
        'RRULE:FREQ=DAILY',
      );
      expect(
        GoogleCalendarService.recurrenceRuleFor(TaskRecurrence.weekly),
        'RRULE:FREQ=WEEKLY',
      );
      expect(
        GoogleCalendarService.recurrenceRuleFor(TaskRecurrence.none),
        isNull,
      );

      final draft = GoogleCalendarService.draftFromTask(
        BloomTask(
          id: '1',
          title: 'Daily',
          createdAt: DateTime.now(),
          dueDate: DateTime(2026, 9, 25),
          dueTime: const TimeOfDay(hour: 9, minute: 0),
          recurrence: TaskRecurrence.daily,
        ),
      );
      expect(draft.recurrenceRule, 'RRULE:FREQ=DAILY');
    });

    test('erreur réseau compréhensible', () async {
      await GoogleCalendarService.connect();
      fake.failNext = true;
      final task = await TaskService.addTask(
        title: 'Fail',
        dueDate: DateTime(2026, 9, 26),
        dueTime: const TimeOfDay(hour: 10, minute: 0),
      );
      expect(
        () => GoogleCalendarService.createEventForTask(task),
        throwsA(
          isA<GoogleCalendarException>().having(
            (e) => e.message,
            'message',
            contains('Impossible'),
          ),
        ),
      );
    });

    test('export settings sans tokens', () {
      final settings = const AppSettings(
        googleCalendar: GoogleCalendarPrefs(
          accountEmail: 'a@b.c',
          selectedCalendarId: 'primary',
          selectedCalendarName: 'Principal',
        ),
      );
      final map = settings.toMap();
      final encoded = map.toString();
      expect(encoded.contains('token'), isFalse);
      expect(encoded.contains('secret'), isFalse);
      expect(map['googleCalendar'], isA<Map>());
    });

    test('ancienne tâche sans googleCalendarEventId reste compatible', () {
      final task = BloomTask.fromMap({
        'id': 'legacy',
        'title': 'Legacy',
        'category': 'other',
        'createdAt': DateTime.now().toIso8601String(),
        'completed': false,
        'priority': 'normal',
        'recurrence': 'none',
        'reminderEnabled': false,
        'reminderMinutesBefore': 0,
      });
      expect(task.googleCalendarEventId, isNull);
    });
  });
}
