import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/puzzle/puzzle.dart';
import '../../models/puzzle/puzzle_models.dart';
import '../../models/puzzle/puzzle_scene.dart';
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

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      progress = PuzzleProgressService.load();
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

  @override
  Widget build(BuildContext context) {
    final puzzles = PuzzleCatalog.all;
    final nextId = progress.nextPlayableId;
    final done = progress.completedIds.length;

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
                        '$done / ${puzzles.length} terminés',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        done == puzzles.length
                            ? 'Tous les puzzles sont terminés !'
                            : 'Continue ta série de raisonnements',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (nextId != null && done < puzzles.length) ...[
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
          const SizedBox(height: 16),
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
