import 'puzzle_constraint.dart';
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
  });

  int get seatCount => positions.length;

  PuzzleCharacter? characterById(String id) {
    for (final character in characters) {
      if (character.id == id) return character;
    }
    return null;
  }

  String characterName(String id) => characterById(id)?.name ?? id;
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
}

class PuzzleValidator {
  static PuzzleValidationResult validate({
    required Puzzle puzzle,
    required PuzzlePlacement placement,
  }) {
    final checks = puzzle.constraints.map((constraint) {
      final evaluable = constraint.canEvaluate(placement);
      final satisfied =
          evaluable ? constraint.isSatisfied(placement) : false;
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
  static int countSolutions(Puzzle puzzle) {
    final ids = puzzle.characters.map((c) => c.id).toList();
    final seats = List<int>.generate(puzzle.seatCount, (i) => i);
    var count = 0;

    void search(int depth, Map<String, int> current, Set<int> used) {
      if (depth == ids.length) {
        final placement = PuzzlePlacement(Map<String, int>.from(current));
        final result = validate(puzzle: puzzle, placement: placement);
        if (result.isSolved) count++;
        return;
      }

      final characterId = ids[depth];
      for (final seat in seats) {
        if (used.contains(seat)) continue;
        current[characterId] = seat;
        used.add(seat);
        search(depth + 1, current, used);
        used.remove(seat);
        current.remove(characterId);
      }
    }

    search(0, {}, {});
    return count;
  }
}
