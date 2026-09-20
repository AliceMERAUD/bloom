import 'puzzle_generation_config.dart';
import '../storage_service.dart';

/// Player adaptive difficulty (level 1..16, soft floors/ceilings).
class PlayerDifficultyState {
  final int level;
  final int winStreak;
  final int lossStreak;
  final int totalWins;
  final int totalLosses;
  final int bestLevel;
  final int puzzleOrdinal;

  const PlayerDifficultyState({
    this.level = 1,
    this.winStreak = 0,
    this.lossStreak = 0,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.bestLevel = 1,
    this.puzzleOrdinal = 1,
  });

  PuzzleGenerationConfig get config =>
      PuzzleGenerationConfig.forPlayerLevel(level);

  PlayerDifficultyState copyWith({
    int? level,
    int? winStreak,
    int? lossStreak,
    int? totalWins,
    int? totalLosses,
    int? bestLevel,
    int? puzzleOrdinal,
  }) {
    return PlayerDifficultyState(
      level: level ?? this.level,
      winStreak: winStreak ?? this.winStreak,
      lossStreak: lossStreak ?? this.lossStreak,
      totalWins: totalWins ?? this.totalWins,
      totalLosses: totalLosses ?? this.totalLosses,
      bestLevel: bestLevel ?? this.bestLevel,
      puzzleOrdinal: puzzleOrdinal ?? this.puzzleOrdinal,
    );
  }

  Map<String, dynamic> toMap() => {
        'level': level,
        'winStreak': winStreak,
        'lossStreak': lossStreak,
        'totalWins': totalWins,
        'totalLosses': totalLosses,
        'bestLevel': bestLevel,
        'puzzleOrdinal': puzzleOrdinal,
      };

  factory PlayerDifficultyState.fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    return PlayerDifficultyState(
      level: (data['level'] as num?)?.toInt() ?? 1,
      winStreak: (data['winStreak'] as num?)?.toInt() ?? 0,
      lossStreak: (data['lossStreak'] as num?)?.toInt() ?? 0,
      totalWins: (data['totalWins'] as num?)?.toInt() ?? 0,
      totalLosses: (data['totalLosses'] as num?)?.toInt() ?? 0,
      bestLevel: (data['bestLevel'] as num?)?.toInt() ?? 1,
      puzzleOrdinal: (data['puzzleOrdinal'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Configurable progressive difficulty — never jumps brutally.
class PuzzleDifficultyService {
  static const int minLevel = 1;
  static const int maxLevel = 16;
  static const int winsToLevelUp = 2;
  static const int lossesToLevelDown = 2;

  static PlayerDifficultyState load() {
    return StorageService.getPlayerDifficulty() ??
        const PlayerDifficultyState();
  }

  static Future<void> save(PlayerDifficultyState state) {
    return StorageService.savePlayerDifficulty(state);
  }

  /// After a successful solve — gentle upward pressure.
  static Future<PlayerDifficultyState> recordWin() async {
    final current = load();
    final streak = current.winStreak + 1;
    var level = current.level;
    if (streak >= winsToLevelUp) {
      level = (level + 1).clamp(minLevel, maxLevel);
    } else if (streak >= 1 && current.level < maxLevel) {
      // Half-step: every win after first in streak can bump every 3rd alone.
      if (streak % 3 == 0) {
        level = (level + 1).clamp(minLevel, maxLevel);
      }
    }
    final next = current.copyWith(
      level: level,
      winStreak: streak >= winsToLevelUp ? 0 : streak,
      lossStreak: 0,
      totalWins: current.totalWins + 1,
      bestLevel: level > current.bestLevel ? level : current.bestLevel,
      puzzleOrdinal: current.puzzleOrdinal + 1,
    );
    await save(next);
    return next;
  }

  /// After a failed validation — mild or no drop.
  static Future<PlayerDifficultyState> recordLoss() async {
    final current = load();
    final losses = current.lossStreak + 1;
    var level = current.level;
    if (losses >= lossesToLevelDown) {
      level = (level - 1).clamp(minLevel, maxLevel);
    }
    final next = current.copyWith(
      level: level,
      lossStreak: losses >= lossesToLevelDown ? 0 : losses,
      winStreak: 0,
      totalLosses: current.totalLosses + 1,
    );
    await save(next);
    return next;
  }
}
