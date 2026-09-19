import 'package:flutter/material.dart';

import '../../models/puzzle/puzzle.dart';
import '../../models/puzzle/puzzle_models.dart';
import '../../services/puzzle_catalog.dart';
import '../../services/puzzle_progress_service.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzle'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (nextId != null)
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Continuer'),
                subtitle: Text(PuzzleCatalog.byId(nextId).title),
                onTap: () => _openPuzzle(PuzzleCatalog.byId(nextId)),
              ),
            ),
          const SizedBox(height: 12),
          ...puzzles.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final puzzle = entry.value;
            final unlocked = progress.isUnlocked(puzzle.id);
            final completed = progress.isCompleted(puzzle.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    completed
                        ? '✓'
                        : unlocked
                            ? '$index'
                            : '🔒',
                  ),
                ),
                title: Text(
                  puzzle.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: unlocked ? null : Colors.grey,
                  ),
                ),
                subtitle: Text(
                  '${puzzle.difficulty.label} • ${puzzle.scenario}',
                ),
                trailing: unlocked
                    ? const Icon(Icons.chevron_right)
                    : null,
                onTap: unlocked ? () => _openPuzzle(puzzle) : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}
