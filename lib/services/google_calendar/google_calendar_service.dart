import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/google_calendar.dart';
import '../../models/task.dart';
import '../bloom_refresh.dart';
import '../settings_service.dart';
import '../storage_service.dart';
import 'fake_google_calendar_backend.dart';
import 'google_calendar_backend.dart';
import 'live_google_calendar_backend.dart';

/// Facade: UI → Google Calendar. No parallel Bloom calendar store.
class GoogleCalendarService {
  GoogleCalendarService._();

  static GoogleCalendarBackend _backend = LiveGoogleCalendarBackend();
  static FakeGoogleCalendarBackend? _fakeForTests;

  /// Inject fake backend for unit tests.
  @visibleForTesting
  static void useFakeBackend([FakeGoogleCalendarBackend? fake]) {
    _fakeForTests = fake ?? FakeGoogleCalendarBackend();
    _backend = _fakeForTests!;
  }

  @visibleForTesting
  static void useLiveBackend() {
    _fakeForTests = null;
    _backend = LiveGoogleCalendarBackend();
  }

  @visibleForTesting
  static FakeGoogleCalendarBackend? get fakeOrNull => _fakeForTests;

  static GoogleCalendarPrefs get prefs =>
      SettingsService.current.googleCalendar;

  static Future<bool> get isConnected async => _backend.isSignedIn;

  static Future<String?> get accountEmail async =>
      (await _backend.signedInEmail) ?? prefs.accountEmail;

  static Future<bool> connect() async {
    final email = await _backend.signIn();
    if (email == null) return false;

    var calendars = <GoogleCalendarInfo>[];
    try {
      calendars = await _backend.listCalendars();
    } catch (_) {
      // Still mark connected; user can retry listing.
    }

    GoogleCalendarInfo? selected;
    if (prefs.selectedCalendarId != null) {
      for (final c in calendars) {
        if (c.id == prefs.selectedCalendarId) {
          selected = c;
          break;
        }
      }
    }
    if (selected == null) {
      for (final c in calendars) {
        if (c.primary) {
          selected = c;
          break;
        }
      }
    }
    if (selected == null && calendars.isNotEmpty) {
      selected = calendars.first;
    }

    await SettingsService.update(
      (s) => s.copyWith(
        googleCalendar: GoogleCalendarPrefs(
          accountEmail: email,
          selectedCalendarId: selected?.id ?? prefs.selectedCalendarId,
          selectedCalendarName: selected?.summary ?? prefs.selectedCalendarName,
        ),
      ),
    );
    BloomRefresh.notify();
    return true;
  }

  static Future<void> disconnect() async {
    await _backend.signOut();
    await SettingsService.update(
      (s) => s.copyWith(
        googleCalendar: s.googleCalendar.copyWith(
          clearAccount: true,
          clearCalendar: true,
        ),
      ),
    );
    BloomRefresh.notify();
  }

  static Future<List<GoogleCalendarInfo>> listCalendars() =>
      _backend.listCalendars();

  static Future<void> selectCalendar(GoogleCalendarInfo calendar) async {
    await SettingsService.update(
      (s) => s.copyWith(
        googleCalendar: s.googleCalendar.copyWith(
          selectedCalendarId: calendar.id,
          selectedCalendarName: calendar.summary,
        ),
      ),
    );
    BloomRefresh.notify();
  }

  static bool taskCanSync(BloomTask task) => task.dueDate != null;

  static String? recurrenceRuleFor(TaskRecurrence recurrence) {
    switch (recurrence) {
      case TaskRecurrence.none:
        return null;
      case TaskRecurrence.daily:
        return 'RRULE:FREQ=DAILY';
      case TaskRecurrence.weekly:
        return 'RRULE:FREQ=WEEKLY';
    }
  }

  static BloomCalendarEventDraft draftFromTask(BloomTask task) {
    final day = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );
    final hasTime = task.dueTime != null;
    final start = hasTime
        ? DateTime(
            day.year,
            day.month,
            day.day,
            task.dueTime!.hour,
            task.dueTime!.minute,
          )
        : day;
    final end = hasTime
        ? start.add(const Duration(minutes: 45))
        : day.add(const Duration(days: 1));

    final buffer = StringBuffer('Créé depuis Bloom');
    if (task.description != null && task.description!.trim().isNotEmpty) {
      buffer.writeln();
      buffer.write(task.description!.trim());
    }
    if (task.sportId != null) {
      buffer.writeln();
      buffer.write('Sport lié (Bloom)');
    }

    return BloomCalendarEventDraft(
      title: task.title,
      description: buffer.toString(),
      start: start,
      end: end,
      allDay: !hasTime,
      recurrenceRule: recurrenceRuleFor(task.recurrence),
    );
  }

  static Future<String> _requireCalendarId() async {
    final id = prefs.selectedCalendarId;
    if (id == null || id.isEmpty) {
      throw const GoogleCalendarException(
        'Choisis un calendrier Google dans les paramètres.',
      );
    }
    return id;
  }

  /// Creates a Calendar event and returns its id. Does not save the task.
  static Future<String> createEventForTask(BloomTask task) async {
    if (!taskCanSync(task)) {
      throw const GoogleCalendarException(
        'Ajoute une date à la tâche avant de l’envoyer à Google Calendar.',
      );
    }
    if (task.googleCalendarEventId != null) {
      throw const GoogleCalendarException(
        'Cet événement existe déjà dans Google Calendar.',
      );
    }
    final calendarId = await _requireCalendarId();
    return _backend.createEvent(
      calendarId: calendarId,
      draft: draftFromTask(task),
    );
  }

  static Future<void> updateEventForTask(BloomTask task) async {
    final eventId = task.googleCalendarEventId;
    if (eventId == null) {
      throw const GoogleCalendarException(
        'Aucun événement Google associé à cette tâche.',
      );
    }
    if (!taskCanSync(task)) {
      throw const GoogleCalendarException(
        'La tâche doit avoir une date pour mettre à jour Google Calendar.',
      );
    }
    final calendarId = await _requireCalendarId();
    await _backend.updateEvent(
      calendarId: calendarId,
      eventId: eventId,
      draft: draftFromTask(task),
    );
  }

  static Future<void> deleteEventForTask(BloomTask task) async {
    final eventId = task.googleCalendarEventId;
    if (eventId == null) return;
    final calendarId = await _requireCalendarId();
    try {
      await _backend.deleteEvent(calendarId: calendarId, eventId: eventId);
    } on GoogleCalendarException {
      rethrow;
    }
  }

  /// Persist event id on task after create.
  static Future<BloomTask> linkTaskEvent(BloomTask task, String eventId) async {
    final linked = task.copyWith(googleCalendarEventId: eventId);
    await StorageService.saveTask(linked);
    BloomRefresh.notify();
    return linked;
  }

  static Future<BloomTask> unlinkTaskEvent(BloomTask task) async {
    final cleared = task.copyWith(clearGoogleCalendarEventId: true);
    await StorageService.saveTask(cleared);
    BloomRefresh.notify();
    return cleared;
  }

  static Future<bool> openGoogleCalendarApp() async {
    final candidates = <Uri>[
      Uri.parse('content://com.android.calendar/time'),
      Uri.parse('https://calendar.google.com/calendar/r'),
    ];
    for (final uri in candidates) {
      try {
        if (await canLaunchUrl(uri)) {
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (ok) return true;
        }
      } catch (_) {}
    }
    try {
      return await launchUrl(
        Uri.parse('https://calendar.google.com/calendar/r'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
