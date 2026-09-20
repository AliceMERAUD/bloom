import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;

/// OAuth wiring for Google Calendar (Android / iOS).
///
/// Bloom does **not** ship a hardcoded client ID.
///
/// Account picker: `GoogleSignIn.signIn()` is always attempted (no local
/// pre-block). Calendar scopes are requested **after** account selection via
/// [requestScopes].
///
/// Without `google-services.json`, Android typically also needs a **Web**
/// OAuth client ID as [serverClientId] (same Cloud project as the Android
/// client). Pass it at build time — never invent a value in source:
/// ```bash
/// flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=….apps.googleusercontent.com
/// ```
///
/// See `docs/google_calendar_oauth.md`.
class GoogleSignInConfig {
  GoogleSignInConfig._();

  static const String serverClientIdFromEnvironment = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static const String androidApplicationId = 'com.example.bloom';

  /// Strict Calendar scopes only (never wellbeing / Drive / etc.).
  static const List<String> calendarScopes = [
    gcal.CalendarApi.calendarEventsScope,
    gcal.CalendarApi.calendarReadonlyScope,
  ];

  static String? get resolvedServerClientId {
    final value = serverClientIdFromEnvironment.trim();
    return value.isEmpty ? null : value;
  }

  static bool get hasServerClientId => resolvedServerClientId != null;

  /// Builds [GoogleSignIn] for the account-picker phase.
  ///
  /// Calendar scopes are intentionally **empty** here so Google can present
  /// the account chooser first; [calendarScopes] are requested afterward.
  static GoogleSignIn createSignIn() {
    final serverClientId = resolvedServerClientId;
    if (kDebugMode) {
      debugPrint(
        '[Bloom GCal] GoogleSignIn init '
        'applicationId=$androidApplicationId '
        'serverClientId=${serverClientId == null ? "MISSING" : "SET"} '
        'initialScopes=0 (Calendar via requestScopes after picker)',
      );
    }
    return GoogleSignIn(
      serverClientId: serverClientId,
      scopes: const <String>[],
    );
  }
}
