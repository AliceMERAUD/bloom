import 'package:flutter/material.dart';

import '../../models/puzzle/puzzle.dart';
import '../../models/puzzle/puzzle_models.dart';
import '../../models/puzzle/puzzle_scene.dart';
import '../../services/bloom_refresh.dart';
import '../../services/puzzle_catalog.dart';
import '../../services/puzzle_progress_service.dart';
import '../../widgets/puzzle/puzzle_character_widget.dart';
import '../../widgets/puzzle/puzzle_constraint_feedback.dart';
import '../../widgets/puzzle/puzzle_scene_board.dart';

class PuzzlePlayScreen extends StatefulWidget {
  final String puzzleId;

  const PuzzlePlayScreen({
    super.key,
    required this.puzzleId,
  });

  @override
  State<PuzzlePlayScreen> createState() => PuzzlePlayScreenState();
}

class PuzzlePlayScreenState extends State<PuzzlePlayScreen> {
  /// When true, skips Hive writes (widget tests).
  @visibleForTesting
  static bool suppressPersistence = false;

  late Puzzle puzzle;
  late PuzzlePlacement placement;
  String? selectedCharacterId;
  PuzzleValidationResult? lastResult;
  bool solved = false;
  int _hintLevel = 0;

  @override
  void initState() {
    super.initState();
    puzzle = PuzzleCatalog.byId(widget.puzzleId);
    final saved = PuzzleProgressService.load().placements[widget.puzzleId];
    placement = saved ?? const PuzzlePlacement();
  }

  void _schedulePersist() {
    if (suppressPersistence) return;
    PuzzleProgressService.savePlacement(puzzle.id, placement);
  }

  void _selectCharacter(String characterId) {
    setState(() {
      selectedCharacterId =
          selectedCharacterId == characterId ? null : characterId;
      lastResult = null;
    });
  }

  /// Exposed for widget tests (avoids flaky hit-testing with animated trays).
  @visibleForTesting
  void debugSelectCharacter(String characterId) => _selectCharacter(characterId);

  @visibleForTesting
  void debugTapSeat(int index) => _tapSeat(index);

  @visibleForTesting
  void debugVerify({bool showSuccessDialog = true}) =>
      _verify(showSuccessDialog: showSuccessDialog);

  @visibleForTesting
  void debugReset() => _reset();

  void _tapSeat(int index) {
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
      _schedulePersist();
      return;
    }

    if (occupant != null) {
      setState(() {
        placement = placement.swap(selectedCharacterId!, occupant);
        selectedCharacterId = null;
        lastResult = null;
        solved = false;
      });
      _schedulePersist();
      return;
    }

    setState(() {
      placement = placement.place(selectedCharacterId!, index);
      selectedCharacterId = null;
      lastResult = null;
      solved = false;
    });
    _schedulePersist();
  }

  void _reset() {
    setState(() {
      placement = const PuzzlePlacement();
      selectedCharacterId = null;
      lastResult = null;
      solved = false;
      _hintLevel = 0;
    });
    if (!suppressPersistence) {
      PuzzleProgressService.clearPlacement(puzzle.id);
    }
  }

  void _showHint() {
    final message =
        PuzzleHintService.describeHint(puzzle, placement, _hintLevel);

    if (_hintLevel >= 2) {
      final revealed =
          PuzzleHintService.applyRevealHint(puzzle, placement);
      if (revealed != null) {
        setState(() {
          placement = revealed;
          selectedCharacterId = null;
          lastResult = null;
          solved = false;
        });
        _schedulePersist();
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    setState(() {
      _hintLevel = (_hintLevel + 1) % 3;
    });
  }

  void _verify({bool showSuccessDialog = true}) {
    final result = PuzzleValidator.validate(
      puzzle: puzzle,
      placement: placement,
    );

    setState(() {
      lastResult = result;
      solved = result.isSolved;
    });

    if (result.isSolved) {
      if (!suppressPersistence) {
        PuzzleProgressService.markCompleted(puzzle.id);
        BloomRefresh.notify();
      }
      if (!mounted || !showSuccessDialog) return;
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Bravo !'),
            content: const Text(
              'Toutes les contraintes sont respectées. Tu peux passer au suivant.',
            ),
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
    } else {
      if (!mounted) return;
      final failed = result.failedConstraints;
      final text = failed.isEmpty
          ? 'Incorrect'
          : failed.map((c) => c.description).join('\n');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text)),
      );
    }
  }

  void _nextPuzzle() {
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PuzzlePlayScreen(puzzleId: next.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = PuzzleProgressService.load();
    final puzzleIndex = PuzzleCatalog.indexOf(puzzle.id) + 1;
    final unplaced = puzzle.characters
        .where((c) => placement.indexOf(c.id) == null)
        .toList();
    final scene = PuzzleSceneTheme.forScenario(puzzle.scenario);
    final canGoNext = solved || progress.isCompleted(puzzle.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(puzzle.title),
        actions: [
          IconButton(
            tooltip: 'Indice',
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: solved ? null : _showHint,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '$puzzleIndex / ${PuzzleCatalog.all.length}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Chip(
                    label: Text(puzzle.difficulty.label),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    avatar: Icon(scene.motifIcon, size: 16),
                    label: Text(scene.title),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                puzzle.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: PuzzleSceneBoard(
                  puzzle: puzzle,
                  placement: placement,
                  selectedCharacterId: selectedCharacterId,
                  onTapSeat: _tapSeat,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  unplaced.isEmpty
                      ? 'Tous les personnages sont placés'
                      : 'Personnages à placer',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(
              height: 108,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ...unplaced.map(
                    (character) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: PuzzleCharacterWidget(
                        character: character,
                        pose: CharacterPose.walking,
                        selected: selectedCharacterId == character.id,
                        size: 44,
                        onTap: () => _selectCharacter(character.id),
                      ),
                    ),
                  ),
                  ...puzzle.characters
                      .where((c) => placement.indexOf(c.id) != null)
                      .map(
                        (character) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: PuzzleCharacterWidget(
                            character: character,
                            pose: CharacterPose.sitting,
                            placed: true,
                            selected: selectedCharacterId == character.id,
                            size: 44,
                            onTap: () => _selectCharacter(character.id),
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Touche un personnage puis une place. '
                'Retouche pour retirer ou échanger.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: PuzzleConstraintFeedback(
                  puzzle: puzzle,
                  result: lastResult,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
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
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: canGoNext ? _nextPuzzle : null,
                      child: const Text('Puzzle suivant'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
