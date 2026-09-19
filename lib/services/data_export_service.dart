import 'dart:convert';

import '../models/app_settings.dart';
import '../models/wellbeing_entry.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';
import 'puzzle_progress_service.dart';
import 'settings_service.dart';
import 'storage_service.dart';
import 'workout_session_service.dart';

class DataExportException implements Exception {
  final String message;
  const DataExportException(this.message);

  @override
  String toString() => message;
}

/// Versioned local JSON backup of Bloom user data.
///
/// Choice: plain JSON (no extra DB) so users can inspect / archive files.
class DataExportService {
  static const int formatVersion = 1;

  static Map<String, dynamic> buildExportMap({
    DateTime? exportedAt,
  }) {
    final sets = StorageService.getWorkoutSets();
    final sessions = StorageService.getAllSessions();
    final wellbeing = StorageService.getAllWellbeingEntries();
    final puzzle = PuzzleProgressService.load();
    final settings = SettingsService.current;

    return {
      'version': formatVersion,
      'exportedAt': (exportedAt ?? DateTime.now()).toIso8601String(),
      'app': 'bloom',
      'sport': {
        'sessions': sessions.map((s) => s.toMap()).toList(),
        'sets': sets
            .map(
              (s) => s.toMap(
                id: s.id ?? 'unknown',
                date: s.date ?? DateTime.now(),
              ),
            )
            .toList(),
      },
      'wellbeing': {
        'entries': wellbeing.map((e) => e.toMap()).toList(),
      },
      'puzzle': puzzle.toMap(),
      'settings': settings.toMap(),
    };
  }

  static String exportJson({DateTime? exportedAt}) {
    return const JsonEncoder.withIndent('  ').convert(
      buildExportMap(exportedAt: exportedAt),
    );
  }

  /// Validates and returns the parsed map, or throws [DataExportException].
  static Map<String, dynamic> parseImport(String raw) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const DataExportException('Fichier JSON invalide.');
    }

    if (decoded is! Map) {
      throw const DataExportException('Format d’export Bloom invalide.');
    }

    final data = Map<String, dynamic>.from(decoded);
    final version = data['version'];
    if (version is! num) {
      throw const DataExportException('Version d’export manquante.');
    }
    if (version.toInt() != formatVersion) {
      throw DataExportException(
        'Version d’export non supportée (${version.toInt()}).',
      );
    }
    if (data['app'] != null && data['app'] != 'bloom') {
      throw const DataExportException('Ce fichier ne vient pas de Bloom.');
    }
    return data;
  }

  /// Replaces all Bloom user data with the import payload.
  static Future<void> importAndReplace(String raw) async {
    final data = parseImport(raw);

    await StorageService.clearAllUserData(keepSettings: false);

    final sport = Map<String, dynamic>.from(data['sport'] as Map? ?? {});
    final setList = List<dynamic>.from(sport['sets'] as List? ?? []);
    for (final item in setList) {
      final map = Map<String, dynamic>.from(item as Map);
      final set = WorkoutSet.fromMap(map);
      final id = set.id ?? DateTime.now().microsecondsSinceEpoch.toString();
      final date = set.date ?? DateTime.now();
      await StorageService.putWorkoutSetRaw(
        id,
        set.toMap(id: id, date: date),
      );
    }

    final sessionList = List<dynamic>.from(sport['sessions'] as List? ?? []);
    for (final item in sessionList) {
      final map = Map<String, dynamic>.from(item as Map);
      final session = WorkoutSession.fromMap(map);
      await StorageService.putWorkoutSessionRaw(session.id, session.toMap());
    }

    final wellbeing = Map<String, dynamic>.from(data['wellbeing'] as Map? ?? {});
    final entries = List<dynamic>.from(wellbeing['entries'] as List? ?? []);
    for (final item in entries) {
      final entry = WellbeingEntry.fromMap(item as Map);
      await StorageService.saveWellbeingEntry(entry);
    }

    if (data['puzzle'] is Map) {
      final progress = PuzzleProgress.fromMap(data['puzzle'] as Map);
      await PuzzleProgressService.save(progress);
    }

    if (data['settings'] is Map) {
      final settings = AppSettings.fromMap(data['settings'] as Map);
      await SettingsService.save(settings);
    }

    WorkoutSessionService.resetForTesting();
    await WorkoutSessionService.restoreFromStorage();
  }
}
