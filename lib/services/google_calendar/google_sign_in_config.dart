import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;

/// OAuth wiring for Google Calendar (Android / iOS).
///
/// Bloom does **not** ship a hardcoded client ID.
/// Without `google-services.json`, Android requires a **Web** OAuth client ID
/// passed as [serverClientId] (never the Android client ID).
///
/// Build example:
/// ```bash
/// flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=123-abc.apps.googleusercontent.com
/// ```
///
/// See `docs/google_calendar_oauth.md` for Cloud Console steps (package + SHA-1).
class GoogleSignInConfig {
  GoogleSignInConfig._();

  /// Web client ID from Google Cloud Console → Credentials → OAuth 2.0 Client IDs
  /// (type **Web application**). Empty if not provided at build time.
  static const String serverClientIdFromEnvironment = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// Package / applicationId used by this app (must match Android OAuth client).
  static const String androidApplicationId = 'com.example.bloom';

  /// Narrow scopes: events write + calendar list read.
  static const List<String> calendarScopes = [
    gcal.CalendarApi.calendarEventsScope,
    gcal.CalendarApi.calendarReadonlyScope,
  ];

  static String? get resolvedServerClientId {
    final value = serverClientIdFromEnvironment.trim();
    return value.isEmpty ? null : value;
  }

  static bool get hasServerClientId => resolvedServerClientId != null;

  static GoogleSignIn createSignIn() {
    final serverClientId = resolvedServerClientId;
    if (kDebugMode) {
      debugPrint(
        '[Bloom GCal] GoogleSignIn init '
        'applicationId=$androidApplicationId '
        'serverClientId=${serverClientId == null ? "MISSING" : "SET"} '
        'scopes=${calendarScopes.length}',
      );
      if (serverClientId == null) {
        debugPrint(
          '[Bloom GCal] NOTE: GOOGLE_SERVER_CLIENT_ID not set. '
          'Account picker can still open; Calendar API access may fail '
          'until a Web OAuth client ID is provided. '
          'See docs/google_calendar_oauth.md',
        );
      }
    }
    // Pass null serverClientId when unset — do not invent a placeholder.
    // Account selection must still be attempted via GoogleSignIn.signIn().
    return GoogleSignIn(
      serverClientId: serverClientId,
      scopes: calendarScopes,
    );
  }
}
