import 'package:flutter/foundation.dart';

/// Non-secret Google Calendar preferences (safe to export).
/// OAuth tokens stay with [GoogleSignIn] / secure channel — never here.
class GoogleCalendarPrefs {
  final String? accountEmail;
  final String? selectedCalendarId;
  final String? selectedCalendarName;

  const GoogleCalendarPrefs({
    this.accountEmail,
    this.selectedCalendarId,
    this.selectedCalendarName,
  });

  bool get hasSelectedCalendar =>
      selectedCalendarId != null && selectedCalendarId!.isNotEmpty;

  GoogleCalendarPrefs copyWith({
    String? accountEmail,
    String? selectedCalendarId,
    String? selectedCalendarName,
    bool clearAccount = false,
    bool clearCalendar = false,
  }) {
    return GoogleCalendarPrefs(
      accountEmail: clearAccount ? null : (accountEmail ?? this.accountEmail),
      selectedCalendarId: clearCalendar
          ? null
          : (selectedCalendarId ?? this.selectedCalendarId),
      selectedCalendarName: clearCalendar
          ? null
          : (selectedCalendarName ?? this.selectedCalendarName),
    );
  }

  Map<String, dynamic> toMap() => {
        'accountEmail': accountEmail,
        'selectedCalendarId': selectedCalendarId,
        'selectedCalendarName': selectedCalendarName,
      };

  factory GoogleCalendarPrefs.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const GoogleCalendarPrefs();
    final data = Map<String, dynamic>.from(map);
    return GoogleCalendarPrefs(
      accountEmail: data['accountEmail'] as String?,
      selectedCalendarId: data['selectedCalendarId'] as String?,
      selectedCalendarName: data['selectedCalendarName'] as String?,
    );
  }

  @override
  String toString() =>
      'GoogleCalendarPrefs(email: $accountEmail, cal: $selectedCalendarName)';
}

@immutable
class GoogleCalendarInfo {
  final String id;
  final String summary;
  final bool primary;

  const GoogleCalendarInfo({
    required this.id,
    required this.summary,
    this.primary = false,
  });
}

@immutable
class BloomCalendarEventDraft {
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final bool allDay;
  final String? recurrenceRule;

  const BloomCalendarEventDraft({
    required this.title,
    required this.start,
    required this.end,
    this.description,
    this.allDay = false,
    this.recurrenceRule,
  });
}

/// User-facing failures (never expose stack traces in UI).
class GoogleCalendarException implements Exception {
  final String message;
  final Object? cause;

  const GoogleCalendarException(this.message, [this.cause]);

  @override
  String toString() => message;
}
