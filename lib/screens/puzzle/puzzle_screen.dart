import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/puzzle/puzzle.dart';
import '../../models/puzzle/puzzle_models.dart';
import '../../models/puzzle/puzzle_scene.dart';
import '../../services/puzzle/generated_puzzle_catalog_service.dart';
import '../../services/puzzle/puzzle_difficulty_service.dart';
import '../../services/puzzle/puzzle_repository.dart';
import '../../services/puzzle_catalog.dart';
import '../../services/puzzle_progress_service.dart';
import '../../widgets/common/bloom_widgets.dart';
import 'puzzle_play_screen.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  PuzzleProgress progress = const PuzzleProgress();
  PlayerDifficultyState difficulty = const PlayerDifficultyState();
  List<Puzzle> generated = const [];
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      progress = PuzzleProgressService.load();
      difficulty = PuzzleDifficultyService.load();
      generated = GeneratedPuzzleCatalogService.load().puzzles;
    });
  }

  Future<void> _openPuzzle(Puzzle puzzle) async {
    if (!progress.isUnlocked(puzzle.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Termine le puzzle précédent d’abord.')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PuzzlePlayScreen(puzzleId: puzzle.id),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _playAdaptive() async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final existing = GeneratedPuzzleCatalogService.latest();
      final puzzle =
          existing ?? await PuzzleRepository.ensureNextGenerated();
      if (!mounted) return;
      await _openPuzzle(puzzle);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final puzzles = PuzzleCatalog.all;
    final nextId = progress.nextPlayableId;
    final done = progress.completedIds
        .where((id) => PuzzleCatalog.indexOf(id) >= 0)
        .length;
    final stars = '⭐' * difficulty.config.difficulty.starCount;
    final allStaticDone = done >= puzzles.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzle'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BloomCard(
            accent: BloomTheme.puzzle,
            child: Row(
              children: [
                const Text('🧩', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Niveau ${difficulty.level} · $stars',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        allStaticDone
                            ? 'Puzzles adaptatifs · difficulté progressive'
                            : '$done / ${puzzles.length} classiques terminés',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BloomCard(
            accent: BloomTheme.puzzle,
            onTap: _generating ? null : _playAdaptive,
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: BloomTheme.puzzle,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _generating
                            ? 'Génération…'
                            : 'Puzzle adaptatif',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${difficulty.config.difficulty.label} · '
                        '${difficulty.config.minSeats}–${difficulty.config.maxSeats} positions',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (_generating)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.chevron_right),
              ],
            ),
          ),
          if (nextId != null && !allStaticDone) ...[
            const SizedBox(height: 12),
            BloomCard(
              accent: BloomTheme.puzzle,
              onTap: () => _openPuzzle(PuzzleCatalog.byId(nextId)),
              child: Row(
                children: [
                  Icon(Icons.play_circle_fill, color: BloomTheme.puzzle),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Continuer',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(PuzzleCatalog.byId(nextId).title),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
          if (generated.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Récents générés',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...generated.reversed.take(5).map((puzzle) {
              final scene = PuzzleSceneTheme.forScenario(puzzle.scenario);
              final completed = progress.isCompleted(puzzle.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BloomCard(
                  accent: BloomTheme.puzzle,
                  onTap: () => _openPuzzle(puzzle),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            scene.accentColor.withValues(alpha: 0.35),
                        child: completed
                            ? const Icon(Icons.check, color: Colors.black87)
                            : const Icon(Icons.auto_awesome, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              puzzle.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              children: [
                                BloomBadge(
                                  label:
                                      '${'⭐' * puzzle.difficulty.starCount} ${puzzle.difficulty.label}',
                                  color: BloomTheme.puzzle,
                                ),
                                BloomBadge(
                                  label: '${puzzle.seatCount} positions',
                                  color: scene.accentColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
          Text(
            'Puzzles classiques',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...puzzles.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final puzzle = entry.value;
            final unlocked = progress.isUnlocked(puzzle.id);
            final completed = progress.isCompleted(puzzle.id);
            final scene = PuzzleSceneTheme.forScenario(puzzle.scenario);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BloomCard(
                accent: BloomTheme.puzzle,
                onTap: unlocked ? () => _openPuzzle(puzzle) : null,
                color: unlocked
                    ? null
                    : Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          scene.accentColor.withValues(alpha: 0.35),
                      child: completed
                          ? const Icon(Icons.check, color: Colors.black87)
                          : unlocked
                              ? Text(
                                  '$index',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                )
                              : const Icon(Icons.lock_outline, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🧩 Puzzle $index',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          Text(
                            puzzle.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: unlocked ? null : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: [
                              BloomBadge(
                                label: '⭐ ${puzzle.difficulty.label}',
                                color: BloomTheme.puzzle,
                              ),
                              BloomBadge(
                                label: scene.title,
                                color: scene.accentColor,
                              ),
                              if (completed)
                                const BloomBadge(
                                  label: '✓ Terminé',
                                  color: BloomTheme.accentGreen,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (unlocked) const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
