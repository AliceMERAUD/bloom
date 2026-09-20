import '../../models/google_calendar.dart';
import 'google_calendar_backend.dart';

/// In-memory backend for unit/widget tests (no network / no Google SDK).
class FakeGoogleCalendarBackend implements GoogleCalendarBackend {
  bool _signedIn = false;
  String? _email;
  final Map<String, GoogleCalendarInfo> calendars = {
    'primary': const GoogleCalendarInfo(
      id: 'primary',
      summary: 'Principal',
      primary: true,
    ),
    'sport': const GoogleCalendarInfo(
      id: 'sport',
      summary: 'Sport',
    ),
  };
  final Map<String, BloomCalendarEventDraft> events = {};
  int _seq = 0;
  bool failNext = false;

  void reset() {
    _signedIn = false;
    _email = null;
    events.clear();
    _seq = 0;
    failNext = false;
  }

  void forceSignedIn({String email = 'bloom@test.local'}) {
    _signedIn = true;
    _email = email;
  }

  void _maybeFail() {
    if (failNext) {
      failNext = false;
      throw const GoogleCalendarException(
        'Impossible d’ajouter l’événement à Google Calendar.\n'
        'Vérifie ta connexion puis réessaie.',
      );
    }
  }

  @override
  Future<bool> get isSignedIn async => _signedIn;

  @override
  Future<String?> get signedInEmail async => _email;

  @override
  Future<String?> signIn() async {
    _maybeFail();
    _signedIn = true;
    _email = 'bloom@test.local';
    return _email;
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
    _email = null;
  }

  @override
  Future<List<GoogleCalendarInfo>> listCalendars() async {
    if (!_signedIn) {
      throw const GoogleCalendarException('Connecte Google Calendar d’abord.');
    }
    return calendars.values.toList();
  }

  @override
  Future<String> createEvent({
    required String calendarId,
    required BloomCalendarEventDraft draft,
  }) async {
    if (!_signedIn) {
      throw const GoogleCalendarException('Connecte Google Calendar d’abord.');
    }
    _maybeFail();
    final id = 'evt_${++_seq}';
    events[id] = draft;
    return id;
  }

  @override
  Future<void> updateEvent({
    required String calendarId,
    required String eventId,
    required BloomCalendarEventDraft draft,
  }) async {
    if (!_signedIn) {
      throw const GoogleCalendarException('Connecte Google Calendar d’abord.');
    }
    _maybeFail();
    if (!events.containsKey(eventId)) {
      throw const GoogleCalendarException(
        'Événement introuvable dans Google Calendar.',
      );
    }
    events[eventId] = draft;
  }

  @override
  Future<void> deleteEvent({
    required String calendarId,
    required String eventId,
  }) async {
    if (!_signedIn) {
      throw const GoogleCalendarException('Connecte Google Calendar d’abord.');
    }
    _maybeFail();
    events.remove(eventId);
  }
}
