import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/googleapis_auth.dart';

import '../../models/google_calendar.dart';
import '../../models/google_oauth_failure.dart';
import 'google_calendar_backend.dart';
import 'google_sign_in_config.dart';

/// Live Google Calendar API via Google Sign-In.
///
/// Requires Google Cloud OAuth configured for
/// [GoogleSignInConfig.androidApplicationId] + debug/release SHA-1,
/// and a Web client ID as `GOOGLE_SERVER_CLIENT_ID` (or `google-services.json`).
class LiveGoogleCalendarBackend implements GoogleCalendarBackend {
  LiveGoogleCalendarBackend({GoogleSignIn? signIn})
      : _signIn = signIn ?? GoogleSignInConfig.createSignIn();

  final GoogleSignIn _signIn;

  void _log(String message, [Object? error]) {
    if (!kDebugMode) return;
    if (error == null) {
      debugPrint('[Bloom GCal] $message');
    } else {
      debugPrint(
        '[Bloom GCal] $message (${error.runtimeType}: ${_sanitize(error)})',
      );
    }
  }

  String _sanitize(Object error) {
    final raw = error.toString();
    return raw
        .replaceAll(RegExp(r'ya29\.[A-Za-z0-9._\-]+'), '[redacted]')
        .replaceAll(RegExp(r'1//[A-Za-z0-9_\-]+'), '[redacted]');
  }

  Never _throwKind(GoogleOAuthFailureKind kind, [Object? cause]) {
    _log('failure kind=${kind.name} (${kind.debugLabel})', cause);
    throw GoogleCalendarException.fromFailure(
      GoogleOAuthFailure.fromKind(kind),
      cause,
    );
  }

  Future<AuthClient> _client() async {
    final client = await _signIn.authenticatedClient();
    if (client == null) {
      _log('authenticatedClient returned null (token unavailable)');
      if (!GoogleSignInConfig.hasServerClientId) {
        _throwKind(GoogleOAuthFailureKind.serverClientIdMissing);
      }
      _throwKind(GoogleOAuthFailureKind.tokenUnavailable);
    }
    return client;
  }

  Future<gcal.CalendarApi> _api() async => gcal.CalendarApi(await _client());

  @override
  Future<bool> get isSignedIn async {
    try {
      return _signIn.currentUser != null || await _signIn.isSignedIn();
    } catch (e) {
      _log('isSignedIn failed', e);
      return false;
    }
  }

  @override
  Future<String?> get signedInEmail async => _signIn.currentUser?.email;

  @override
  Future<String?> signIn() async {
    try {
      // Never block before the account picker — missing Web client ID is
      // diagnosed after Google Sign-In / when Calendar tokens are needed.
      _log(
        'signIn started '
        '(serverClientId=${GoogleSignInConfig.hasServerClientId ? "SET" : "MISSING"})',
      );
      final account = await _signIn.signIn();
      if (account == null) {
        _log('signIn cancelled by user');
        _throwKind(GoogleOAuthFailureKind.cancelled);
      }
      _log('signIn success for account (email kept out of logs)');
      return account.email;
    } on GoogleCalendarException {
      rethrow;
    } on PlatformException catch (e) {
      _log('signIn PlatformException code=${e.code}', e);
      _throwKind(_classifyPlatform(e), e);
    } catch (e) {
      _log('signIn unexpected error', e);
      _throwKind(_classifyGeneric(e), e);
    }
  }

  GoogleOAuthFailureKind _classifyPlatform(PlatformException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    final details = '${e.details ?? ''}'.toLowerCase();
    final blob = '$code $message $details';

    if (code.contains('canceled') ||
        code.contains('cancelled') ||
        blob.contains('sign_in_canceled') ||
        blob.contains('sign_in_cancelled')) {
      return GoogleOAuthFailureKind.cancelled;
    }

    if (blob.contains('apiexception: 10') ||
        blob.contains('statuscode=10') ||
        blob.contains('developer_error')) {
      return GoogleOAuthFailureKind.oauthAndroidMisconfigured;
    }

    if (blob.contains('apiexception: 7') ||
        blob.contains('network_error') ||
        (blob.contains('network') && !blob.contains('developer'))) {
      return GoogleOAuthFailureKind.network;
    }

    if (blob.contains('access_denied') ||
        blob.contains('permission') ||
        blob.contains('consent')) {
      return GoogleOAuthFailureKind.permissionDenied;
    }

    if (blob.contains('sign_in_failed') || blob.contains('sign_in_required')) {
      if (!GoogleSignInConfig.hasServerClientId) {
        return GoogleOAuthFailureKind.serverClientIdMissing;
      }
      return GoogleOAuthFailureKind.oauthAndroidMisconfigured;
    }

    return GoogleOAuthFailureKind.unknown;
  }

  GoogleOAuthFailureKind _classifyGeneric(Object e) {
    final blob = e.toString().toLowerCase();
    if (blob.contains('apiexception: 10') || blob.contains('developer_error')) {
      return GoogleOAuthFailureKind.oauthAndroidMisconfigured;
    }
    if (blob.contains('socket') ||
        blob.contains('network') ||
        blob.contains('failed host lookup')) {
      return GoogleOAuthFailureKind.network;
    }
    if (!GoogleSignInConfig.hasServerClientId) {
      return GoogleOAuthFailureKind.serverClientIdMissing;
    }
    return GoogleOAuthFailureKind.unknown;
  }

  @override
  Future<void> signOut() async {
    try {
      _log('disconnect');
      await _signIn.disconnect();
    } catch (e) {
      _log('disconnect failed, falling back to signOut', e);
      await _signIn.signOut();
    }
  }

  @override
  Future<List<GoogleCalendarInfo>> listCalendars() async {
    try {
      _log('listCalendars');
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
      _log('listCalendars failed', e);
      throw GoogleCalendarException(
        'Impossible de charger tes calendriers Google.',
        e,
        _classifyGeneric(e),
      );
    }
  }

  gcal.Event _toEvent(BloomCalendarEventDraft draft) {
    final event = gcal.Event()
      ..summary = draft.title
      ..description = draft.description;

    if (draft.allDay) {
      final day =
          DateTime(draft.start.year, draft.start.month, draft.start.day);
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
      _log('createEvent');
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
      _log('createEvent failed', e);
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
      _log('updateEvent');
      final api = await _api();
      await api.events.update(_toEvent(draft), calendarId, eventId);
    } on GoogleCalendarException {
      rethrow;
    } catch (e) {
      _log('updateEvent failed', e);
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
      _log('deleteEvent');
      final api = await _api();
      await api.events.delete(calendarId, eventId);
    } on GoogleCalendarException {
      rethrow;
    } catch (e) {
      _log('deleteEvent failed', e);
      throw GoogleCalendarException(
        'Impossible de supprimer l’événement Google Calendar.',
        e,
      );
    }
  }
}
