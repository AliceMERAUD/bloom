import 'package:flutter/material.dart';

/// Local app preferences (theme, reminders). Persisted in Hive.
class AppSettings {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool sportReminders;
  final bool wellbeingReminders;
  final bool puzzleReminders;
  final int reminderHour;
  final int reminderMinute;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = false,
    this.sportReminders = true,
    this.wellbeingReminders = true,
    this.puzzleReminders = false,
    this.reminderHour = 9,
    this.reminderMinute = 0,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? sportReminders,
    bool? wellbeingReminders,
    bool? puzzleReminders,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      sportReminders: sportReminders ?? this.sportReminders,
      wellbeingReminders: wellbeingReminders ?? this.wellbeingReminders,
      puzzleReminders: puzzleReminders ?? this.puzzleReminders,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }

  Map<String, dynamic> toMap() => {
        'themeMode': themeMode.name,
        'notificationsEnabled': notificationsEnabled,
        'sportReminders': sportReminders,
        'wellbeingReminders': wellbeingReminders,
        'puzzleReminders': puzzleReminders,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
      };

  factory AppSettings.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const AppSettings();
    final data = Map<String, dynamic>.from(map);
    return AppSettings(
      themeMode: _themeModeFromName(data['themeMode'] as String?),
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? false,
      sportReminders: data['sportReminders'] as bool? ?? true,
      wellbeingReminders: data['wellbeingReminders'] as bool? ?? true,
      puzzleReminders: data['puzzleReminders'] as bool? ?? false,
      reminderHour: (data['reminderHour'] as num?)?.toInt() ?? 9,
      reminderMinute: (data['reminderMinute'] as num?)?.toInt() ?? 0,
    );
  }

  static ThemeMode _themeModeFromName(String? name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String get reminderTimeLabel {
    final h = reminderHour.toString().padLeft(2, '0');
    final m = reminderMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
