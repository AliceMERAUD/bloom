import 'package:flutter/material.dart';

import '../../models/puzzle/puzzle.dart';
import '../../models/puzzle/puzzle_models.dart';
import '../../services/puzzle_catalog.dart';
import '../../services/puzzle_progress_service.dart';

class PuzzlePlayScreen extends StatefulWidget {
  final String puzzleId;

  const PuzzlePlayScreen({
    super.key,
    required this.puzzleId,
  });

  @override
  State<PuzzlePlayScreen> createState() => _PuzzlePlayScreenState();
}

class _PuzzlePlayScreenState extends State<PuzzlePlayScreen> {
  late Puzzle puzzle;
  late PuzzlePlacement placement;
  String? selectedCharacterId;
  PuzzleValidationResult? lastResult;
  bool solved = false;

  @override
  void initState() {
    super.initState();
    puzzle = PuzzleCatalog.byId(widget.puzzleId);
    final saved = PuzzleProgressService.load().placements[widget.puzzleId];
    placement = saved ?? const PuzzlePlacement();
  }

  Future<void> _persist() async {
    await PuzzleProgressService.savePlacement(puzzle.id, placement);
  }

  void _selectCharacter(String characterId) {
    setState(() {
      selectedCharacterId = selectedCharacterId == characterId
          ? null
          : characterId;
      lastResult = null;
    });
  }

  Future<void> _tapSeat(int index) async {
    final occupant = placement.characterAt(index);

    if (selectedCharacterId == null) {
      if (occupant != null) {
        setState(() => selectedCharacterId = occupant);
      }
      return;
    }

    if (occupant == selectedCharacterId) {
      setState(() {
        placement = placement.remove(selectedCharacterId!);
        selectedCharacterId = null;
        lastResult = null;
        solved = false;
      });
      await _persist();
      return;
    }

    if (occupant != null) {
      setState(() {
        placement = placement.swap(selectedCharacterId!, occupant);
        selectedCharacterId = null;
        lastResult = null;
        solved = false;
      });
      await _persist();
      return;
    }

    setState(() {
      placement = placement.place(selectedCharacterId!, index);
      selectedCharacterId = null;
      lastResult = null;
      solved = false;
    });
    await _persist();
  }

  Future<void> _reset() async {
    setState(() {
      placement = const PuzzlePlacement();
      selectedCharacterId = null;
      lastResult = null;
      solved = false;
    });
    await PuzzleProgressService.clearPlacement(puzzle.id);
  }

  Future<void> _verify() async {
    final result = PuzzleValidator.validate(
      puzzle: puzzle,
      placement: placement,
    );

    setState(() {
      lastResult = result;
      solved = result.isSolved;
    });

    if (result.isSolved) {
      await PuzzleProgressService.markCompleted(puzzle.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Bravo !'),
            content: const Text('Toutes les contraintes sont respectées.'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Continuer'),
              ),
            ],
          );
        },
      );
    } else if (!result.isComplete) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Place tous les personnages avant de valider.'),
        ),
      );
    }
  }

  Future<void> _nextPuzzle() async {
    final index = PuzzleCatalog.indexOf(puzzle.id);
    if (index < 0 || index >= PuzzleCatalog.all.length - 1) {
      Navigator.pop(context);
      return;
    }

    final next = PuzzleCatalog.all[index + 1];
    final progress = PuzzleProgressService.load();
    if (!progress.isUnlocked(next.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Termine ce puzzle pour débloquer le suivant.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PuzzlePlayScreen(puzzleId: next.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unplaced = puzzle.characters
        .where((c) => placement.indexOf(c.id) == null)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(puzzle.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            puzzle.difficulty.label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(puzzle.description),
          const SizedBox(height: 8),
          Text(
            'Scénario : ${puzzle.scenario}',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 20),
          const Text(
            'Places',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _SeatsRow(
            puzzle: puzzle,
            placement: placement,
            selectedCharacterId: selectedCharacterId,
            onTapSeat: _tapSeat,
          ),
          const SizedBox(height: 8),
          const Text(
            'Touche un personnage puis une place. '
            'Retouche une place occupée pour échanger ou retirer.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 20),
          const Text(
            'Personnages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...unplaced.map((character) {
                final selected = selectedCharacterId == character.id;
                return ChoiceChip(
                  label: Text(character.name),
                  selected: selected,
                  avatar: CircleAvatar(
                    child: Text(
                      character.name.isEmpty
                          ? '?'
                          : character.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  onSelected: (_) => _selectCharacter(character.id),
                );
              }),
              ...puzzle.characters
                  .where((c) => placement.indexOf(c.id) != null)
                  .map((character) {
                final selected = selectedCharacterId == character.id;
                return FilterChip(
                  label: Text(
                    '${character.name} · ${placement.indexOf(character.id)! + 1}',
                  ),
                  selected: selected,
                  onSelected: (_) => _selectCharacter(character.id),
                );
              }),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Contraintes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ..._constraintTiles(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Réinitialiser'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _verify,
                  child: const Text('Vérifier'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: solved ||
                      PuzzleProgressService.load().isCompleted(puzzle.id)
                  ? _nextPuzzle
                  : null,
              child: const Text('Puzzle suivant'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _constraintTiles() {
    final checks = lastResult?.checks;
    return puzzle.constraints.asMap().entries.map((entry) {
      final constraint = entry.value;
      final check = checks
          ?.where((c) => c.constraint.id == constraint.id)
          .firstOrNull;

      IconData icon = Icons.circle_outlined;
      Color? color;
      if (check != null) {
        if (!check.evaluable) {
          icon = Icons.help_outline;
          color = Colors.grey;
        } else if (check.satisfied) {
          icon = Icons.check_circle;
          color = Colors.green;
        } else {
          icon = Icons.cancel;
          color = Colors.redAccent;
        }
      }

      return Card(
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(_describe(constraint.description)),
        ),
      );
    }).toList();
  }

  String _describe(String raw) {
    var text = raw;
    for (final character in puzzle.characters) {
      text = text.replaceAll(character.id, character.name);
    }
    return text;
  }
}

class _SeatsRow extends StatelessWidget {
  final Puzzle puzzle;
  final PuzzlePlacement placement;
  final String? selectedCharacterId;
  final Future<void> Function(int index) onTapSeat;

  const _SeatsRow({
    required this.puzzle,
    required this.placement,
    required this.selectedCharacterId,
    required this.onTapSeat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: puzzle.positions.map((position) {
        final characterId = placement.characterAt(position.index);
        final character = characterId == null
            ? null
            : puzzle.characterById(characterId);
        final highlight = characterId != null &&
            characterId == selectedCharacterId;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AspectRatio(
              aspectRatio: 0.75,
              child: InkWell(
                onTap: () => onTapSeat(position.index),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: highlight
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                      width: highlight ? 2.5 : 1,
                    ),
                    color: highlight
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        position.label ?? '${position.index + 1}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                        CircleAvatar(
                        radius: 16,
                        child: Text(
                          character == null
                              ? '·'
                              : character.name.isEmpty
                                  ? '?'
                                  : character.name[0].toUpperCase(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        character?.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
