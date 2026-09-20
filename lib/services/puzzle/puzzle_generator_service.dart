import 'dart:math';

import '../../models/puzzle/puzzle.dart';
import '../../models/puzzle/puzzle_constraint.dart';
import '../../models/puzzle/puzzle_models.dart';
import 'puzzle_generation_config.dart';

/// Procedural puzzle generator (solution-first, then constraints + uniqueness).
class PuzzleGeneratorService {
  PuzzleGeneratorService({int? seed}) : _random = Random(seed);

  final Random _random;
  int _idCounter = 0;

  static const _names = [
    'Alice',
    'Bob',
    'Claire',
    'David',
    'Emma',
    'Félix',
    'Gina',
    'Hugo',
    'Iris',
    'Jules',
  ];

  static const _scenariosBySize = <int, List<String>>{
    4: ['bus', 'mariage', 'salle_attente', 'bureau', 'parc'],
    5: ['bus', 'mariage', 'cinema', 'cafe', 'diner', 'salle_attente'],
    6: ['bus', 'bureau', 'train', 'bibliotheque'],
    7: ['train', 'bureau', 'diner'],
    8: ['train', 'diner'],
    9: ['train'],
    10: ['train'],
  };

  /// Returns a unique valid puzzle or null after [PuzzleGeneratorLimits.maxGenerationAttempts].
  Puzzle? generate({
    required PuzzleGenerationConfig config,
    required int playerLevel,
    Set<String> forbiddenSignatures = const {},
  }) {
    for (var attempt = 0;
        attempt < PuzzleGeneratorLimits.maxGenerationAttempts;
        attempt++) {
      final puzzle = _tryOnce(
        config: config,
        playerLevel: playerLevel,
        attempt: attempt,
      );
      if (puzzle == null) continue;
      final sig = signatureOf(puzzle);
      if (forbiddenSignatures.contains(sig)) continue;
      if (!PuzzleValidator.hasUniqueSolution(puzzle)) continue;
      if (_difficultyScore(puzzle) < config.minDifficultyScore) continue;
      return puzzle;
    }
    return null;
  }

  Puzzle? _tryOnce({
    required PuzzleGenerationConfig config,
    required int playerLevel,
    required int attempt,
  }) {
    final seats = config.seatCountForLevel(
      playerLevel,
      (min, max) => min + _random.nextInt(max - min + 1),
    );

    // Slightly fewer characters than seats on higher levels (empty seats).
    final maxChars = seats;
    final minChars = (seats - (config.difficulty.index >= 2 ? 1 : 0))
        .clamp(3, seats);
    final charCount =
        minChars + _random.nextInt((maxChars - minChars + 1).clamp(1, 99));

    final scenario = _pickScenario(seats);
    final namePool = List<String>.from(_names)..shuffle(_random);
    final characters = <PuzzleCharacter>[
      for (var i = 0; i < charCount; i++)
        PuzzleCharacter(
          id: 'c$i',
          name: namePool[i % namePool.length],
          assetKey: namePool[i % namePool.length]
              .toLowerCase()
              .replaceAll('é', 'e'),
        ),
    ];
    final positions = <PuzzlePosition>[
      for (var i = 0; i < seats; i++)
        PuzzlePosition(id: 'p$i', index: i, label: '${i + 1}'),
    ];

    final seatOrder = List<int>.generate(seats, (i) => i)..shuffle(_random);
    final solution = <String, int>{
      for (var i = 0; i < charCount; i++) characters[i].id: seatOrder[i],
    };

    final constraintCount = config.minConstraints +
        _random.nextInt(
          (config.maxConstraints - config.minConstraints + 1).clamp(1, 99),
        );

    var constraints = _buildConstraints(
      characters: characters,
      solution: solution,
      seatCount: seats,
      targetCount: constraintCount,
      difficulty: config.difficulty,
    );
    if (constraints.length < config.minConstraints) return null;

    // Tighten until unique (add more constraints from solution) without looping forever.
    var working = Puzzle(
      id: 'tmp_$attempt',
      title: 'tmp',
      description: '',
      scenario: scenario,
      difficulty: config.difficulty,
      characters: characters,
      positions: positions,
      constraints: constraints,
      referenceSolution: solution,
    );
    for (var tighten = 0;
        tighten < 12 && !PuzzleValidator.hasUniqueSolution(working);
        tighten++) {
      final extra = _buildConstraints(
        characters: characters,
        solution: solution,
        seatCount: seats,
        targetCount: constraints.length + 2,
        difficulty: config.difficulty,
      );
      if (extra.length <= constraints.length) break;
      constraints = extra;
      working = Puzzle(
        id: working.id,
        title: working.title,
        description: working.description,
        scenario: scenario,
        difficulty: config.difficulty,
        characters: characters,
        positions: positions,
        constraints: constraints,
        referenceSolution: solution,
      );
    }

    if (!PuzzleValidator.hasUniqueSolution(working)) return null;

    final id = 'gen_${_idCounter++}_$attempt';
    return Puzzle(
      id: id,
      title: 'Puzzle adaptatif #$playerLevel',
      description:
          'Généré pour ton niveau — $seats places, ${constraints.length} indices logiques.',
      scenario: scenario,
      difficulty: config.difficulty,
      characters: characters,
      positions: positions,
      constraints: constraints,
      referenceSolution: solution,
    );
  }

  String _pickScenario(int seats) {
    final options = _scenariosBySize[seats] ??
        _scenariosBySize[seats.clamp(4, 10)] ??
        const ['bus'];
    return options[_random.nextInt(options.length)];
  }

  List<PuzzleConstraint> _buildConstraints({
    required List<PuzzleCharacter> characters,
    required Map<String, int> solution,
    required int seatCount,
    required int targetCount,
    required PuzzleDifficulty difficulty,
  }) {
    final ids = characters.map((c) => c.id).toList();
    final pool = <PuzzleConstraint>[];
    var seq = 0;
    String nid() => 'g${seq++}';

    final fixedBudget = switch (difficulty) {
      PuzzleDifficulty.easy => 2,
      PuzzleDifficulty.medium => 1,
      PuzzleDifficulty.hard || PuzzleDifficulty.veryHard => 0,
    };
    final shuffled = List<String>.from(ids)..shuffle(_random);
    for (var i = 0; i < fixedBudget && i < shuffled.length; i++) {
      final id = shuffled[i];
      final index = solution[id]!;
      final name = characters.firstWhere((c) => c.id == id).name;
      pool.add(
        FixedPositionConstraint(
          id: nid(),
          characterId: id,
          index: index,
          description: '$name est en position ${index + 1}.',
        ),
      );
    }

    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        final a = ids[i];
        final b = ids[j];
        final ai = solution[a]!;
        final bi = solution[b]!;
        final an = characters.firstWhere((c) => c.id == a).name;
        final bn = characters.firstWhere((c) => c.id == b).name;
        final dist = (ai - bi).abs();

        if (dist == 1) {
          pool.add(
            AdjacentConstraint(
              id: nid(),
              a: a,
              b: b,
              description: '$an est à côté de $bn.',
            ),
          );
        } else {
          pool.add(
            NotAdjacentConstraint(
              id: nid(),
              a: a,
              b: b,
              description: '$an n’est pas à côté de $bn.',
            ),
          );
        }

        if (ai < bi) {
          pool.add(
            BeforeConstraint(
              id: nid(),
              a: a,
              b: b,
              description: '$an est avant $bn.',
            ),
          );
        } else {
          pool.add(
            AfterConstraint(
              id: nid(),
              a: a,
              b: b,
              description: '$an est après $bn.',
            ),
          );
        }

        final mid = seatCount ~/ 2;
        final aLeft = ai < mid;
        final bLeft = bi < mid;
        if (aLeft == bLeft) {
          pool.add(
            SameSideConstraint(
              id: nid(),
              a: a,
              b: b,
              seatCount: seatCount,
              description: '$an et $bn sont du même côté.',
            ),
          );
        } else {
          pool.add(
            DifferentSideConstraint(
              id: nid(),
              a: a,
              b: b,
              seatCount: seatCount,
              description: '$an et $bn sont de côtés différents.',
            ),
          );
        }
      }
    }

    for (var i = 0; i < ids.length; i++) {
      for (var j = 0; j < ids.length; j++) {
        if (i == j) continue;
        for (var k = 0; k < ids.length; k++) {
          if (k == i || k == j) continue;
          final left = ids[i];
          final mid = ids[j];
          final right = ids[k];
          final li = solution[left]!;
          final mi = solution[mid]!;
          final ri = solution[right]!;
          final lo = li < ri ? li : ri;
          final hi = li < ri ? ri : li;
          if (mi > lo && mi < hi) {
            final ln = characters.firstWhere((c) => c.id == left).name;
            final mn = characters.firstWhere((c) => c.id == mid).name;
            final rn = characters.firstWhere((c) => c.id == right).name;
            pool.add(
              BetweenConstraint(
                id: nid(),
                middle: mid,
                left: left,
                right: right,
                description: '$mn est entre $ln et $rn.',
              ),
            );
          }
        }
      }
    }

    pool.shuffle(_random);

    final selected = <PuzzleConstraint>[];
    final usedKinds = <ConstraintKind>{};
    for (final c in pool) {
      if (selected.length >= targetCount) break;
      if (usedKinds.contains(c.kind) && selected.length < targetCount ~/ 2) {
        continue;
      }
      selected.add(c);
      usedKinds.add(c.kind);
    }
    for (final c in pool) {
      if (selected.length >= targetCount) break;
      if (selected.any((s) => s.id == c.id)) continue;
      selected.add(c);
    }

    final placement = PuzzlePlacement(Map<String, int>.from(solution));
    final result = PuzzleValidator.validate(
      puzzle: Puzzle(
        id: 'tmp',
        title: 'tmp',
        description: '',
        scenario: 'bus',
        difficulty: difficulty,
        characters: characters,
        positions: [
          for (var i = 0; i < seatCount; i++)
            PuzzlePosition(id: 'p$i', index: i),
        ],
        constraints: selected,
        referenceSolution: solution,
      ),
      placement: placement,
    );
    if (!result.isSolved) return [];
    return selected;
  }

  static int _difficultyScore(Puzzle puzzle) {
    var score = puzzle.seatCount * 2 + puzzle.characters.length;
    for (final c in puzzle.constraints) {
      score += switch (c.kind) {
        ConstraintKind.fixedPosition => 1,
        ConstraintKind.before || ConstraintKind.after => 2,
        ConstraintKind.adjacent || ConstraintKind.notAdjacent => 3,
        ConstraintKind.sameSide || ConstraintKind.differentSide => 4,
        ConstraintKind.between => 5,
        ConstraintKind.sameRow ||
        ConstraintKind.sameCol ||
        ConstraintKind.nearObject ||
        ConstraintKind.notNearObject ||
        ConstraintKind.distanceAtMost =>
          4,
      };
    }
    return score;
  }

  /// Logical signature to avoid near-duplicates.
  static String signatureOf(Puzzle puzzle) {
    final kinds = puzzle.constraints.map((c) => c.kind.name).toList()..sort();
    final names = puzzle.characters.map((c) => c.name).toList()..sort();
    return [
      puzzle.scenario,
      '${puzzle.seatCount}',
      names.join(','),
      kinds.join('|'),
      puzzle.difficulty.name,
    ].join('::');
  }
}
