import '../../models/puzzle/puzzle.dart';
import '../puzzle_catalog.dart';
import 'generated_puzzle_catalog_service.dart';
import 'puzzle_difficulty_service.dart';
import 'puzzle_generation_config.dart';
import 'puzzle_generator_service.dart';
import 'puzzle_history_service.dart';

/// Resolves static + generated puzzles and orchestrates on-demand generation.
class PuzzleRepository {
  static Puzzle? byId(String id) {
    final staticIndex = PuzzleCatalog.indexOf(id);
    if (staticIndex >= 0) return PuzzleCatalog.all[staticIndex];
    return GeneratedPuzzleCatalogService.load().byId(id);
  }

  static bool isGenerated(String id) => id.startsWith('gen_');

  /// Next puzzle to play: unfinished static first, else latest/ready generated.
  static Puzzle? nextPlayable({required Set<String> completedIds}) {
    for (final p in PuzzleCatalog.all) {
      if (!completedIds.contains(p.id)) return p;
    }
    return GeneratedPuzzleCatalogService.latest();
  }

  /// Generate and persist a puzzle for the player's current level.
  /// Falls back to a static catalog puzzle if generation fails.
  static Future<Puzzle> ensureNextGenerated({int? seed}) async {
    final difficulty = PuzzleDifficultyService.load();
    final config = difficulty.config;
    final forbidden = GeneratedPuzzleCatalogService.signatures();
    final generator = PuzzleGeneratorService(seed: seed);

    final puzzle = generator.generate(
      config: config,
      playerLevel: difficulty.level,
      forbiddenSignatures: forbidden,
    );

    if (puzzle != null) {
      final titled = Puzzle(
        id: puzzle.id,
        title: 'Puzzle #${difficulty.puzzleOrdinal}',
        description: puzzle.description,
        scenario: puzzle.scenario,
        difficulty: puzzle.difficulty,
        characters: puzzle.characters,
        positions: puzzle.positions,
        constraints: puzzle.constraints,
        referenceSolution: puzzle.referenceSolution,
        geometry: puzzle.geometry,
      );
      final evicted = await GeneratedPuzzleCatalogService.add(titled);
      if (evicted != null) {
        await PuzzleHistoryService.ensureRetained(evicted);
      }
      return titled;
    }

    // Fallback: reuse a static puzzle matching the tier when possible.
    final tier = config.difficulty;
    final fallback = PuzzleCatalog.all.firstWhere(
      (p) => p.difficulty == tier,
      orElse: () => PuzzleCatalog.all.first,
    );
    return fallback;
  }

  /// Pre-fill up to [PuzzleGeneratorLimits.readyQueueSize] ready puzzles.
  static Future<void> warmReadyQueue({int? seed}) async {
    final catalog = GeneratedPuzzleCatalogService.load();
    var need =
        PuzzleGeneratorLimits.readyQueueSize - catalog.length.clamp(0, 3);
    if (need <= 0) return;
    for (var i = 0; i < need; i++) {
      await ensureNextGenerated(seed: seed == null ? null : seed + i);
    }
  }
}
