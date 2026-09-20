import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/googleapis_auth.dart';

import '../../models/google_calendar.dart';
import 'google_calendar_backend.dart';

/// Live Google Calendar API via Google Sign-In.
///
/// Requires a Google Cloud OAuth client configured for
/// `com.example.bloom` (or your release applicationId) and SHA-1.
class LiveGoogleCalendarBackend implements GoogleCalendarBackend {
  LiveGoogleCalendarBackend({GoogleSignIn? signIn})
      : _signIn = signIn ??
            GoogleSignIn(
              scopes: const [
                gcal.CalendarApi.calendarEventsScope,
                gcal.CalendarApi.calendarReadonlyScope,
              ],
            );

  final GoogleSignIn _signIn;

  Future<AuthClient> _client() async {
    final client = await _signIn.authenticatedClient();
    if (client == null) {
      throw const GoogleCalendarException(
        'Session Google expirée. Reconnecte Google Calendar dans les paramètres.',
      );
    }
    return client;
  }

  Future<gcal.CalendarApi> _api() async => gcal.CalendarApi(await _client());

  @override
  Future<bool> get isSignedIn async {
    try {
      return _signIn.currentUser != null || await _signIn.isSignedIn();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> get signedInEmail async => _signIn.currentUser?.email;

  @override
  Future<String?> signIn() async {
    try {
      final account = await _signIn.signIn();
      if (account == null) {
        throw const GoogleCalendarException(
          'Connexion Google annulée.',
        );
      }
      return account.email;
    } on GoogleCalendarException {
      rethrow;
    } catch (e) {
      throw GoogleCalendarException(
        'Impossible de se connecter à Google Calendar.\n'
        'Vérifie la configuration OAuth / le réseau.',
        e,
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _signIn.disconnect();
    } catch (_) {
      await _signIn.signOut();
    }
  }

  @override
  Future<List<GoogleCalendarInfo>> listCalendars() async {
    try {
      final api = await _api();
      final list = await api.calendarList.list();
      final items = list.items ?? const <gcal.CalendarListEntry>[];
      return items
          .where((c) => c.id != null)
          .map(
            (c) => GoogleCalendarInfo(
              id: c.id!,
              summary: c.summary ?? c.id!,
              primary: c.primary ?? false,
            ),
          )
          .toList();
    } on GoogleCalendarException {
      rethrow;
    } catch (e) {
      throw GoogleCalendarException(
        'Impossible de charger tes calendriers Google.',
        e,
      );
    }
  }

  gcal.Event _toEvent(BloomCalendarEventDraft draft) {
    final event = gcal.Event()
      ..summary = draft.title
      ..description = draft.description;

    if (draft.allDay) {
      final day = DateTime(draft.start.year, draft.start.month, draft.start.day);
      final endDay = DateTime(draft.end.year, draft.end.month, draft.end.day);
      event.start = gcal.EventDateTime(date: day);
      event.end = gcal.EventDateTime(date: endDay);
    } else {
      event.start = gcal.EventDateTime(
        dateTime: draft.start.toUtc(),
        timeZone: 'UTC',
      );
      event.end = gcal.EventDateTime(
        dateTime: draft.end.toUtc(),
        timeZone: 'UTC',
      );
    }

    if (draft.recurrenceRule != null && draft.recurrenceRule!.isNotEmpty) {
      event.recurrence = [draft.recurrenceRule!];
    }
    return event;
  }

  @override
  Future<String> createEvent({
    required String calendarId,
    required BloomCalendarEventDraft draft,
  }) async {
    try {
      final api = await _api();
      final created = await api.events.insert(_toEvent(draft), calendarId);
      final id = created.id;
      if (id == null || id.isEmpty) {
        throw const GoogleCalendarException(
          'Google Calendar n’a pas renvoyé d’identifiant d’événement.',
        );
      }
      return id;
    } on GoogleCalendarException {
      rethrow;
    } catch (e) {
      throw GoogleCalendarException(
        'Impossible d’ajouter l’événement à Google Calendar.\n'
        'Vérifie ta connexion puis réessaie.',
        e,
      );
    }
  }

  @override
  Future<void> updateEvent({
    required String calendarId,
    required String eventId,
    required BloomCalendarEventDraft draft,
  }) async {
    try {
      final api = await _api();
      await api.events.update(_toEvent(draft), calendarId, eventId);
    } on GoogleCalendarException {
      rethrow;
    } catch (e) {
      throw GoogleCalendarException(
        'Impossible de mettre à jour l’événement Google Calendar.',
        e,
      );
    }
  }

  @override
  Future<void> deleteEvent({
    required String calendarId,
    required String eventId,
  }) async {
    try {
      final api = await _api();
      await api.events.delete(calendarId, eventId);
    } on GoogleCalendarException {
      rethrow;
    } catch (e) {
      throw GoogleCalendarException(
        'Impossible de supprimer l’événement Google Calendar.',
        e,
      );
    }
  }
}
