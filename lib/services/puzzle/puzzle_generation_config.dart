import '../../models/puzzle/puzzle_models.dart';

/// Tunable generation parameters for a difficulty tier.
class PuzzleGenerationConfig {
  final PuzzleDifficulty difficulty;
  final int minSeats;
  final int maxSeats;
  final int minConstraints;
  final int maxConstraints;
  final int maxHints;
  final int minDifficultyScore;

  const PuzzleGenerationConfig({
    required this.difficulty,
    required this.minSeats,
    required this.maxSeats,
    required this.minConstraints,
    required this.maxConstraints,
    required this.maxHints,
    required this.minDifficultyScore,
  });

  static const easy = PuzzleGenerationConfig(
    difficulty: PuzzleDifficulty.easy,
    minSeats: 4,
    maxSeats: 5,
    minConstraints: 2,
    maxConstraints: 4,
    maxHints: 2,
    minDifficultyScore: 8,
  );

  static const medium = PuzzleGenerationConfig(
    difficulty: PuzzleDifficulty.medium,
    minSeats: 5,
    maxSeats: 7,
    minConstraints: 4,
    maxConstraints: 6,
    maxHints: 2,
    minDifficultyScore: 16,
  );

  static const hard = PuzzleGenerationConfig(
    difficulty: PuzzleDifficulty.hard,
    minSeats: 6,
    maxSeats: 8,
    minConstraints: 6,
    maxConstraints: 9,
    maxHints: 1,
    minDifficultyScore: 24,
  );

  static const veryHard = PuzzleGenerationConfig(
    difficulty: PuzzleDifficulty.veryHard,
    minSeats: 7,
    maxSeats: 9,
    minConstraints: 7,
    maxConstraints: 11,
    maxHints: 0,
    minDifficultyScore: 32,
  );

  static PuzzleGenerationConfig forDifficulty(PuzzleDifficulty d) {
    switch (d) {
      case PuzzleDifficulty.easy:
        return easy;
      case PuzzleDifficulty.medium:
        return medium;
      case PuzzleDifficulty.hard:
        return hard;
      case PuzzleDifficulty.veryHard:
        return veryHard;
    }
  }

  /// Player level 1..N → tier (smooth progression).
  static PuzzleGenerationConfig forPlayerLevel(int level) {
    final clamped = level.clamp(1, 16);
    if (clamped <= 3) return easy;
    if (clamped <= 7) return medium;
    if (clamped <= 12) return hard;
    return veryHard;
  }

  /// Prefer seat count that grows slowly with level.
  int seatCountForLevel(int level, int Function(int min, int max) pick) {
    final span = maxSeats - minSeats;
    final t = ((level - 1) % 5) / 4.0;
    final target = minSeats + (span * t).round();
    final lo = target.clamp(minSeats, maxSeats);
    final hi = (target + 1).clamp(minSeats, maxSeats);
    return pick(lo, hi);
  }
}

class PuzzleGeneratorLimits {
  static const int maxGeneratedPuzzles = 20;
  static const int maxPuzzleHistory = 100;
  static const int maxGenerationAttempts = 80;
  static const int readyQueueSize = 3;
}
