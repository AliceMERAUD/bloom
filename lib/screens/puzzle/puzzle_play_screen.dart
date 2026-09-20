import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/puzzle/puzzle.dart';
import '../../models/puzzle/puzzle_models.dart';
import '../../models/puzzle/puzzle_scene.dart';
import '../../services/bloom_refresh.dart';
import '../../services/puzzle/puzzle_difficulty_service.dart';
import '../../services/puzzle/puzzle_generation_config.dart';
import '../../services/puzzle/puzzle_history_service.dart';
import '../../services/puzzle/puzzle_repository.dart';
import '../../services/puzzle_catalog.dart';
import '../../services/puzzle_progress_service.dart';
import '../../widgets/common/bloom_widgets.dart';
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

class PuzzlePlayScreenState extends State<PuzzlePlayScreen>
    with SingleTickerProviderStateMixin {
  /// When true, skips Hive writes (widget tests).
  @visibleForTesting
  static bool suppressPersistence = false;

  late Puzzle puzzle;
  late PuzzlePlacement placement;
  String? selectedCharacterId;
  PuzzleValidationResult? lastResult;
  bool solved = false;
  bool _loadingNext = false;
  int _hintLevel = 0;
  int hintsUsed = 0;
  late final AnimationController _verifyPulse;
  late final int _maxHints;

  @override
  void initState() {
    super.initState();
    puzzle = PuzzleRepository.byId(widget.puzzleId) ??
        PuzzleCatalog.byId(widget.puzzleId);
    final saved = PuzzleProgressService.load().placements[widget.puzzleId];
    placement = saved ?? const PuzzlePlacement();
    _maxHints =
        PuzzleGenerationConfig.forDifficulty(puzzle.difficulty).maxHints;
    _verifyPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _verifyPulse.dispose();
    super.dispose();
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

  @visibleForTesting
  void debugSelectCharacter(String characterId) => _selectCharacter(characterId);

  @visibleForTesting
  void debugTapSeat(int index) => _tapSeat(index);

  @visibleForTesting
  void debugVerify({bool showSuccessDialog = true}) =>
      _verify(showSuccessDialog: showSuccessDialog);

  @visibleForTesting
  void debugReset() => _reset();

  @visibleForTesting
  void debugNextPuzzle() => _nextPuzzle();

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
      hintsUsed = 0;
    });
    if (!suppressPersistence) {
      PuzzleProgressService.clearPlacement(puzzle.id);
    }
  }

  void _showHint() {
    if (_maxHints <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun indice à ce niveau de difficulté.')),
      );
      return;
    }
    if (hintsUsed >= _maxHints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Indices épuisés ($_maxHints max).')),
      );
      return;
    }

    final message =
        PuzzleHintService.describeHint(puzzle, placement, _hintLevel);

    if (_hintLevel >= 2) {
      final revealed = PuzzleHintService.applyRevealHint(puzzle, placement);
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
      hintsUsed += 1;
      _hintLevel = (_hintLevel + 1) % 3;
    });
  }

  Future<void> _verify({bool showSuccessDialog = true}) async {
    await _verifyPulse.reverse();
    await _verifyPulse.forward();

    final result = PuzzleValidator.validate(
      puzzle: puzzle,
      placement: placement,
    );

    setState(() {
      lastResult = result;
      solved = result.isSolved;
    });

    if (result.isSolved) {
      PlayerDifficultyState? difficulty;
      if (!suppressPersistence) {
        await PuzzleProgressService.markCompleted(puzzle.id);
        difficulty = await PuzzleDifficultyService.recordWin();
        await PuzzleHistoryService.recordAttempt(
          puzzleId: puzzle.id,
          success: true,
          difficulty: puzzle.difficulty.name,
          hintsUsed: hintsUsed,
          generated: PuzzleRepository.isGenerated(puzzle.id),
          playerLevel: difficulty.level,
        );
        BloomRefresh.notify();
      }
      if (!mounted || !showSuccessDialog) return;
      await _showSuccessSheet(difficulty ?? PuzzleDifficultyService.load());
    } else if (!result.isComplete) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Place tous les personnages avant de valider.'),
        ),
      );
    } else {
      if (!suppressPersistence) {
        await PuzzleDifficultyService.recordLoss();
        await PuzzleHistoryService.recordAttempt(
          puzzleId: puzzle.id,
          success: false,
          difficulty: puzzle.difficulty.name,
          hintsUsed: hintsUsed,
          generated: PuzzleRepository.isGenerated(puzzle.id),
          playerLevel: PuzzleDifficultyService.load().level,
        );
      }
      if (!mounted) return;
      await _showFailureSheet(result);
    }
  }

  Future<void> _showSuccessSheet(PlayerDifficultyState difficulty) async {
    final index = PuzzleCatalog.indexOf(puzzle.id);
    final isGenerated = PuzzleRepository.isGenerated(puzzle.id);
    final isLastStatic =
        !isGenerated && index >= PuzzleCatalog.all.length - 1;
    final progress = PuzzleProgressService.load();
    final completed = progress.completedIds.length;
    final stars = '⭐' * difficulty.config.difficulty.starCount;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 42)),
              const SizedBox(height: 8),
              Text(
                isLastStatic
                    ? 'Bravo ! Puzzles classiques terminés'
                    : 'Bravo !',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: BloomTheme.puzzle,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isLastStatic
                    ? 'La suite : puzzles adaptatifs générés pour toi.'
                    : 'Toutes les contraintes sont respectées.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  BloomBadge(
                    label: 'Niveau ${difficulty.level}',
                    color: BloomTheme.puzzle,
                  ),
                  BloomBadge(
                    label: 'Difficulté $stars',
                    color: BloomTheme.accentGreen,
                  ),
                  BloomBadge(
                    label: hintsUsed == 0
                        ? 'Sans indice'
                        : '$hintsUsed indice(s)',
                    color: BloomTheme.accentGreen,
                  ),
                  if (!isGenerated)
                    BloomBadge(
                      label:
                          'Classiques $completed / ${PuzzleCatalog.all.length}',
                      color: BloomTheme.puzzle,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: BloomTheme.puzzle,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _nextPuzzle();
                  },
                  child: const Text('Puzzle suivant →'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Rester ici'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showFailureSheet(PuzzleValidationResult result) async {
    final failed = result.failedConstraints;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🤔 Pas encore !',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                failed.isEmpty
                    ? 'La disposition n’est pas correcte.'
                    : '${failed.length} contrainte(s) ne sont pas respectées.',
              ),
              if (failed.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...failed.take(4).map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(_humanize(c.description))),
                          ],
                        ),
                      ),
                    ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Continuer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _humanize(String raw) {
    var text = raw;
    for (final character in puzzle.characters) {
      text = text.replaceAll(character.id, character.name);
    }
    return text;
  }

  Future<void> _nextPuzzle() async {
    if (_loadingNext) return;
    final progress = PuzzleProgressService.load();
    final index = PuzzleCatalog.indexOf(puzzle.id);

    late final Puzzle next;
    if (index >= 0 && index < PuzzleCatalog.all.length - 1) {
      final candidate = PuzzleCatalog.all[index + 1];
      if (!progress.isUnlocked(candidate.id) && !solved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Termine ce puzzle pour débloquer le suivant.'),
          ),
        );
        return;
      }
      next = candidate;
    } else {
      setState(() => _loadingNext = true);
      try {
        if (!suppressPersistence) {
          next = await PuzzleRepository.ensureNextGenerated();
        } else {
          next = PuzzleCatalog.all.first;
        }
      } finally {
        if (mounted) setState(() => _loadingNext = false);
      }
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PuzzlePlayScreen(puzzleId: next.id),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = PuzzleProgressService.load();
    final staticIndex = PuzzleCatalog.indexOf(puzzle.id);
    final isGenerated = PuzzleRepository.isGenerated(puzzle.id);
    final playerLevel = PuzzleDifficultyService.load().level;
    final puzzleLabel = isGenerated
        ? 'Adaptatif · Niv. $playerLevel'
        : '${staticIndex + 1} / ${PuzzleCatalog.all.length}';
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
            onPressed: solved || _maxHints <= 0 ? null : _showHint,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: BloomBadge(
                label: puzzleLabel,
                color: BloomTheme.puzzle,
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
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  BloomBadge(
                    label: puzzle.difficulty.label,
                    color: BloomTheme.puzzle,
                  ),
                  BloomBadge(
                    label: scene.title,
                    color: scene.accentColor,
                  ),
                  BloomBadge(
                    label: hintsUsed == 0
                        ? 'Indices : 0'
                        : 'Indices : $hintsUsed',
                    color: BloomTheme.accentGreen,
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: PuzzleSceneBoard(
                    key: ValueKey(placement.seats.toString()),
                    puzzle: puzzle,
                    placement: placement,
                    selectedCharacterId: selectedCharacterId,
                    onTapSeat: _tapSeat,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  unplaced.isEmpty
                      ? '✨ Tous les personnages sont placés'
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
                        child: ScaleTransition(
                          scale: _verifyPulse,
                          child: FilledButton(
                            onPressed: _verify,
                            child: const Text('Vérifier'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (canGoNext) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: _loadingNext ? null : _nextPuzzle,
                        child: Text(
                          _loadingNext
                              ? 'Génération…'
                              : 'Puzzle suivant →',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
