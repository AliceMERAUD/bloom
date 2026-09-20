import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/googleapis_auth.dart';

import '../../models/google_calendar.dart';
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
      // Never log tokens — only exception type / sanitized message.
      debugPrint('[Bloom GCal] $message (${error.runtimeType}: ${_sanitize(error)})');
    }
  }

  String _sanitize(Object error) {
    final raw = error.toString();
    // Strip anything that looks like a bearer / long opaque token.
    return raw
        .replaceAll(RegExp(r'ya29\.[A-Za-z0-9._\-]+'), '[redacted]')
        .replaceAll(RegExp(r'1//[A-Za-z0-9_\-]+'), '[redacted]');
  }

  Future<AuthClient> _client() async {
    final client = await _signIn.authenticatedClient();
    if (client == null) {
      _log('authenticatedClient returned null (token unavailable)');
      throw const GoogleCalendarException(
        'Session Google expirée ou token indisponible.\n'
        'Reconnecte Google Calendar dans les paramètres.',
      );
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
      _log('signIn started');
      final account = await _signIn.signIn();
      if (account == null) {
        _log('signIn cancelled by user');
        throw const GoogleCalendarException('Connexion Google annulée.');
      }
      _log('signIn success for account (email kept out of logs)');
      return account.email;
    } on GoogleCalendarException {
      rethrow;
    } on PlatformException catch (e) {
      _log('signIn PlatformException code=${e.code}', e);
      throw GoogleCalendarException(_mapPlatformSignInError(e), e);
    } catch (e) {
      _log('signIn unexpected error', e);
      throw GoogleCalendarException(_mapGenericSignInError(e), e);
    }
  }

  String _mapPlatformSignInError(PlatformException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    final details = '${e.details ?? ''}'.toLowerCase();
    final blob = '$code $message $details';

    if (code.contains('canceled') ||
        code.contains('cancelled') ||
        blob.contains('sign_in_canceled') ||
        blob.contains('sign_in_cancelled')) {
      return 'Connexion Google annulée.';
    }

    // CommonStatusCodes.DEVELOPER_ERROR = 10
    if (blob.contains('apiexception: 10') ||
        blob.contains('statuscode=10') ||
        blob.contains('developer_error')) {
      return 'La configuration Google de Bloom semble incorrecte.\n'
          'Vérifie la configuration OAuth Android '
          '(package ${GoogleSignInConfig.androidApplicationId}, SHA-1 debug, '
          'client Web / GOOGLE_SERVER_CLIENT_ID).';
    }

    // NETWORK_ERROR = 7
    if (blob.contains('apiexception: 7') ||
        blob.contains('network_error') ||
        blob.contains('network')) {
      return 'Connexion Google impossible.\n'
          'Vérifie ta connexion Internet et réessaie.';
    }

    // SIGN_IN_REQUIRED / SIGN_IN_FAILED
    if (blob.contains('sign_in_failed') || blob.contains('sign_in_required')) {
      if (!GoogleSignInConfig.hasServerClientId) {
        return 'La configuration Google de Bloom semble incorrecte.\n'
            'Ajoute un client OAuth Web (GOOGLE_SERVER_CLIENT_ID) '
            'et enregistre le SHA-1 debug — voir docs/google_calendar_oauth.md.';
      }
      return 'Connexion Google impossible.\n'
          'Vérifie ta connexion Internet et la configuration Google de Bloom.';
    }

    return 'Connexion Google impossible.\n'
        'Vérifie ta connexion Internet et la configuration Google de Bloom.';
  }

  String _mapGenericSignInError(Object e) {
    final blob = e.toString().toLowerCase();
    if (blob.contains('apiexception: 10') || blob.contains('developer_error')) {
      return 'La configuration Google de Bloom semble incorrecte.\n'
          'Vérifie la configuration OAuth Android.';
    }
    if (blob.contains('socket') ||
        blob.contains('network') ||
        blob.contains('failed host lookup')) {
      return 'Connexion Google impossible.\n'
          'Vérifie ta connexion Internet et réessaie.';
    }
    if (!GoogleSignInConfig.hasServerClientId) {
      return 'La configuration Google de Bloom semble incorrecte.\n'
          'Vérifie la configuration OAuth Android '
          '(voir docs/google_calendar_oauth.md).';
    }
    return 'Impossible de se connecter à Google Calendar.\n'
        'Vérifie ta connexion Internet et la configuration Google de Bloom.';
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
