import '../storage_service.dart';
import 'puzzle_generation_config.dart';

/// Per-puzzle history entry (survives catalog eviction).
class PuzzleHistoryEntry {
  final String puzzleId;
  final bool completed;
  final int attempts;
  final int? bestTimeMs;
  final int hintsUsed;
  final String difficulty;
  final DateTime updatedAt;
  final bool generated;

  const PuzzleHistoryEntry({
    required this.puzzleId,
    this.completed = false,
    this.attempts = 0,
    this.bestTimeMs,
    this.hintsUsed = 0,
    this.difficulty = 'easy',
    required this.updatedAt,
    this.generated = false,
  });

  PuzzleHistoryEntry copyWith({
    bool? completed,
    int? attempts,
    int? bestTimeMs,
    int? hintsUsed,
    String? difficulty,
    DateTime? updatedAt,
    bool? generated,
  }) {
    return PuzzleHistoryEntry(
      puzzleId: puzzleId,
      completed: completed ?? this.completed,
      attempts: attempts ?? this.attempts,
      bestTimeMs: bestTimeMs ?? this.bestTimeMs,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      difficulty: difficulty ?? this.difficulty,
      updatedAt: updatedAt ?? this.updatedAt,
      generated: generated ?? this.generated,
    );
  }

  Map<String, dynamic> toMap() => {
        'puzzleId': puzzleId,
        'completed': completed,
        'attempts': attempts,
        'bestTimeMs': bestTimeMs,
        'hintsUsed': hintsUsed,
        'difficulty': difficulty,
        'updatedAt': updatedAt.toIso8601String(),
        'generated': generated,
      };

  factory PuzzleHistoryEntry.fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    return PuzzleHistoryEntry(
      puzzleId: data['puzzleId'] as String,
      completed: data['completed'] as bool? ?? false,
      attempts: (data['attempts'] as num?)?.toInt() ?? 0,
      bestTimeMs: (data['bestTimeMs'] as num?)?.toInt(),
      hintsUsed: (data['hintsUsed'] as num?)?.toInt() ?? 0,
      difficulty: data['difficulty'] as String? ?? 'easy',
      updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      generated: data['generated'] as bool? ?? false,
    );
  }
}

class PuzzleHistoryStats {
  final int totalCompleted;
  final int totalFailed;
  final int bestDifficultyLevel;
  final int currentStreak;
  final int longestStreak;

  const PuzzleHistoryStats({
    this.totalCompleted = 0,
    this.totalFailed = 0,
    this.bestDifficultyLevel = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  PuzzleHistoryStats copyWith({
    int? totalCompleted,
    int? totalFailed,
    int? bestDifficultyLevel,
    int? currentStreak,
    int? longestStreak,
  }) {
    return PuzzleHistoryStats(
      totalCompleted: totalCompleted ?? this.totalCompleted,
      totalFailed: totalFailed ?? this.totalFailed,
      bestDifficultyLevel:
          bestDifficultyLevel ?? this.bestDifficultyLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }

  Map<String, dynamic> toMap() => {
        'totalCompleted': totalCompleted,
        'totalFailed': totalFailed,
        'bestDifficultyLevel': bestDifficultyLevel,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
      };

  factory PuzzleHistoryStats.fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    return PuzzleHistoryStats(
      totalCompleted: (data['totalCompleted'] as num?)?.toInt() ?? 0,
      totalFailed: (data['totalFailed'] as num?)?.toInt() ?? 0,
      bestDifficultyLevel:
          (data['bestDifficultyLevel'] as num?)?.toInt() ?? 1,
      currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (data['longestStreak'] as num?)?.toInt() ?? 0,
    );
  }
}

class PuzzleHistoryStore {
  final List<PuzzleHistoryEntry> entries;
  final PuzzleHistoryStats stats;

  const PuzzleHistoryStore({
    this.entries = const [],
    this.stats = const PuzzleHistoryStats(),
  });

  PuzzleHistoryEntry? entryFor(String puzzleId) {
    for (final e in entries) {
      if (e.puzzleId == puzzleId) return e;
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
        'entries': entries.map((e) => e.toMap()).toList(),
        'stats': stats.toMap(),
      };

  factory PuzzleHistoryStore.fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    final raw = List<dynamic>.from(data['entries'] as List? ?? const []);
    return PuzzleHistoryStore(
      entries: raw.map((e) => PuzzleHistoryEntry.fromMap(e as Map)).toList(),
      stats: data['stats'] is Map
          ? PuzzleHistoryStats.fromMap(data['stats'] as Map)
          : const PuzzleHistoryStats(),
    );
  }
}

class PuzzleHistoryService {
  static PuzzleHistoryStore load() {
    return StorageService.getPuzzleHistory() ?? const PuzzleHistoryStore();
  }

  static Future<void> save(PuzzleHistoryStore store) {
    return StorageService.savePuzzleHistory(store);
  }

  static Future<PuzzleHistoryStore> recordAttempt({
    required String puzzleId,
    required bool success,
    required String difficulty,
    int hintsUsed = 0,
    int? timeMs,
    bool generated = false,
    int playerLevel = 1,
  }) async {
    final store = load();
    final existing = store.entryFor(puzzleId);
    final updatedEntry = (existing ??
            PuzzleHistoryEntry(
              puzzleId: puzzleId,
              updatedAt: DateTime.now(),
              generated: generated,
              difficulty: difficulty,
            ))
        .copyWith(
          completed: success ? true : existing?.completed ?? false,
          attempts: (existing?.attempts ?? 0) + 1,
          hintsUsed: hintsUsed,
          bestTimeMs: timeMs == null
              ? existing?.bestTimeMs
              : (existing?.bestTimeMs == null
                  ? timeMs
                  : (timeMs < existing!.bestTimeMs! ? timeMs : existing.bestTimeMs)),
          difficulty: difficulty,
          updatedAt: DateTime.now(),
          generated: generated,
        );

    final entries = List<PuzzleHistoryEntry>.from(store.entries);
    final idx = entries.indexWhere((e) => e.puzzleId == puzzleId);
    if (idx >= 0) {
      entries[idx] = updatedEntry;
    } else {
      entries.add(updatedEntry);
    }

    // Trim oldest detailed entries beyond limit (keep stats).
    entries.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    while (entries.length > PuzzleGeneratorLimits.maxPuzzleHistory) {
      entries.removeAt(0);
    }

    var stats = store.stats;
    if (success) {
      final streak = store.stats.currentStreak + 1;
      stats = stats.copyWith(
        totalCompleted: stats.totalCompleted + 1,
        currentStreak: streak,
        longestStreak:
            streak > stats.longestStreak ? streak : stats.longestStreak,
        bestDifficultyLevel: playerLevel > stats.bestDifficultyLevel
            ? playerLevel
            : stats.bestDifficultyLevel,
      );
    } else {
      stats = stats.copyWith(
        totalFailed: stats.totalFailed + 1,
        currentStreak: 0,
      );
    }

    final next = PuzzleHistoryStore(entries: entries, stats: stats);
    await save(next);
    return next;
  }

  /// Ensures an entry remains after catalog eviction.
  static Future<void> ensureRetained(String puzzleId) async {
    final store = load();
    if (store.entryFor(puzzleId) != null) return;
    final entries = List<PuzzleHistoryEntry>.from(store.entries)
      ..add(
        PuzzleHistoryEntry(
          puzzleId: puzzleId,
          updatedAt: DateTime.now(),
          generated: true,
        ),
      );
    await save(PuzzleHistoryStore(entries: entries, stats: store.stats));
  }
}
