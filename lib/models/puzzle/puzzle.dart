import 'puzzle_constraint.dart';
import 'puzzle_geometry.dart';
import 'puzzle_models.dart';

class Puzzle {
  final String id;
  final String title;
  final String description;
  final String scenario;
  final PuzzleDifficulty difficulty;
  final List<PuzzleCharacter> characters;
  final List<PuzzlePosition> positions;
  final List<PuzzleConstraint> constraints;

  /// One known valid solution: characterId -> index.
  final Map<String, int> referenceSolution;

  /// Optional 2D grid (Puzzle 2.0). When null, seats are a 1D row.
  final PuzzleGeometry? geometry;

  const Puzzle({
    required this.id,
    required this.title,
    required this.description,
    required this.scenario,
    required this.difficulty,
    required this.characters,
    required this.positions,
    required this.constraints,
    required this.referenceSolution,
    this.geometry,
  });

  int get seatCount => positions.length;

  PuzzleGeometry get resolvedGeometry =>
      geometry ?? PuzzleGeometry.row(seatCount);

  PuzzleCharacter? characterById(String id) {
    for (final character in characters) {
      if (character.id == id) return character;
    }
    return null;
  }

  String characterName(String id) => characterById(id)?.name ?? id;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'scenario': scenario,
        'difficulty': difficulty.name,
        'characters': characters.map((c) => c.toMap()).toList(),
        'positions': positions.map((p) => p.toMap()).toList(),
        'constraints': constraints.map((c) => c.toMap()).toList(),
        'referenceSolution': referenceSolution,
        'createdAt': null, // filled by GeneratedPuzzleRecord when needed
      };

  factory Puzzle.fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    final characters = List<dynamic>.from(data['characters'] as List? ?? [])
        .map((e) => PuzzleCharacter.fromMap(e as Map))
        .toList();
    final positions = List<dynamic>.from(data['positions'] as List? ?? [])
        .map((e) => PuzzlePosition.fromMap(e as Map))
        .toList();
    final constraints = List<dynamic>.from(data['constraints'] as List? ?? [])
        .map((e) => PuzzleConstraint.fromMap(e as Map))
        .toList();
    final rawSolution =
        Map<dynamic, dynamic>.from(data['referenceSolution'] as Map? ?? {});
    final solution = <String, int>{
      for (final e in rawSolution.entries)
        e.key.toString(): (e.value as num).toInt(),
    };
    return Puzzle(
      id: data['id'] as String,
      title: data['title'] as String? ?? 'Puzzle',
      description: data['description'] as String? ?? '',
      scenario: data['scenario'] as String? ?? 'bus',
      difficulty: PuzzleDifficultyX.fromName(data['difficulty'] as String?),
      characters: characters,
      positions: positions,
      constraints: constraints,
      referenceSolution: solution,
    );
  }
}

class ConstraintCheck {
  final PuzzleConstraint constraint;
  final bool evaluable;
  final bool satisfied;

  const ConstraintCheck({
    required this.constraint,
    required this.evaluable,
    required this.satisfied,
  });
}

class PuzzleValidationResult {
  final bool isComplete;
  final bool isSolved;
  final List<ConstraintCheck> checks;

  const PuzzleValidationResult({
    required this.isComplete,
    required this.isSolved,
    required this.checks,
  });

  int get satisfiedCount =>
      checks.where((check) => check.evaluable && check.satisfied).length;

  int get failedCount =>
      checks.where((check) => check.evaluable && !check.satisfied).length;

  List<PuzzleConstraint> get failedConstraints => checks
      .where((check) => check.evaluable && !check.satisfied)
      .map((check) => check.constraint)
      .toList();
}

class PuzzleValidator {
  static PuzzleValidationResult validate({
    required Puzzle puzzle,
    required PuzzlePlacement placement,
  }) {
    final geo = puzzle.resolvedGeometry;
    final checks = puzzle.constraints.map((constraint) {
      final evaluable = constraint.canEvaluate(placement);
      final satisfied =
          evaluable ? constraint.isSatisfied(placement, geo) : false;
      return ConstraintCheck(
        constraint: constraint,
        evaluable: evaluable,
        satisfied: satisfied,
      );
    }).toList();

    final isComplete =
        puzzle.characters.every((c) => placement.indexOf(c.id) != null);

    final allSatisfied = checks.every(
      (check) => check.evaluable && check.satisfied,
    );

    return PuzzleValidationResult(
      isComplete: isComplete,
      isSolved: isComplete && allSatisfied,
      checks: checks,
    );
  }

  /// Brute-force count of solutions (for tests / authoring).
  /// When [stopAt] is set (e.g. 2 for uniqueness), stops as soon as that
  /// many solutions are found — avoids exploding search for large puzzles.
  static int countSolutions(Puzzle puzzle, {int? stopAt}) {
    final ids = puzzle.characters.map((c) => c.id).toList();
    final seats = List<int>.generate(puzzle.seatCount, (i) => i);
    var count = 0;
    final limit = stopAt;

    void search(int depth, Map<String, int> current, Set<int> used) {
      if (limit != null && count >= limit) return;
      if (depth == ids.length) {
        final placement = PuzzlePlacement(Map<String, int>.from(current));
        final result = validate(puzzle: puzzle, placement: placement);
        if (result.isSolved) count++;
        return;
      }

      final characterId = ids[depth];
      for (final seat in seats) {
        if (limit != null && count >= limit) return;
        if (used.contains(seat)) continue;
        current[characterId] = seat;
        used.add(seat);
        // Prune: if any evaluable constraint already fails, skip subtree.
        final trial = PuzzlePlacement(Map<String, int>.from(current));
        final geo = puzzle.resolvedGeometry;
        var broken = false;
        for (final c in puzzle.constraints) {
          if (c.canEvaluate(trial) && !c.isSatisfied(trial, geo)) {
            broken = true;
            break;
          }
        }
        if (!broken) {
          search(depth + 1, current, used);
        }
        used.remove(seat);
        current.remove(characterId);
      }
    }

    search(0, {}, {});
    return count;
  }

  /// True iff exactly one solution exists (stops at 2).
  static bool hasUniqueSolution(Puzzle puzzle) {
    return countSolutions(puzzle, stopAt: 2) == 1;
  }
}

/// Simple progressive hints for Puzzle 2.0.
class PuzzleHintService {
  /// Level 0: highlight a failed / unevaluable constraint description.
  /// Level 1: mark an impossible seat for the selected character.
  /// Level 2: place one correct character from the reference solution.
  static String describeHint(Puzzle puzzle, PuzzlePlacement placement, int level) {
    final result = PuzzleValidator.validate(puzzle: puzzle, placement: placement);
    final geo = puzzle.resolvedGeometry;

    if (level <= 0) {
      final pending = result.checks.where((c) => !c.evaluable || !c.satisfied);
      if (pending.isEmpty) {
        return 'Tout semble cohérent — vérifie la disposition complète.';
      }
      return 'Indice : ${pending.first.constraint.description}';
    }

    if (level == 1) {
      for (final character in puzzle.characters) {
        if (placement.indexOf(character.id) != null) continue;
        for (final seat in List.generate(puzzle.seatCount, (i) => i)) {
          if (placement.characterAt(seat) != null) continue;
          final trial = placement.place(character.id, seat);
          final trialResult =
              PuzzleValidator.validate(puzzle: puzzle, placement: trial);
          final broken = trialResult.checks.any(
            (c) => c.evaluable && !c.satisfied,
          );
          if (broken) {
            final cell = geo.cellAtIndex(seat);
            final label = cell?.label ?? '${seat + 1}';
            return 'Indice : ${character.name} ne peut probablement pas aller en case $label.';
          }
        }
      }
      return 'Indice : regarde les cases déjà occupées et les objets autour.';
    }

    // Level 2+: reveal one correct placement.
    for (final entry in puzzle.referenceSolution.entries) {
      if (placement.indexOf(entry.key) == entry.value) continue;
      final name = puzzle.characterName(entry.key);
      final cell = geo.cellAtIndex(entry.value);
      final label = cell?.label ?? '${entry.value + 1}';
      return 'Indice fort : $name doit être en case $label.';
    }
    return 'Plus d’indice disponible — tu es très proche !';
  }

  static PuzzlePlacement? applyRevealHint(
    Puzzle puzzle,
    PuzzlePlacement placement,
  ) {
    for (final entry in puzzle.referenceSolution.entries) {
      if (placement.indexOf(entry.key) == entry.value) continue;
      return placement.place(entry.key, entry.value);
    }
    return null;
  }
}
