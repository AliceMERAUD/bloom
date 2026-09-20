import '../../models/google_calendar.dart';

/// Pluggable backend so tests can run without Google OAuth.
abstract class GoogleCalendarBackend {
  Future<bool> get isSignedIn;

  Future<String?> get signedInEmail;

  Future<String?> signIn();

  Future<void> signOut();

  Future<List<GoogleCalendarInfo>> listCalendars();

  Future<String> createEvent({
    required String calendarId,
    required BloomCalendarEventDraft draft,
  });

  Future<void> updateEvent({
    required String calendarId,
    required String eventId,
    required BloomCalendarEventDraft draft,
  });

  Future<void> deleteEvent({
    required String calendarId,
    required String eventId,
  });
}
