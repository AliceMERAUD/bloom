import 'package:bloom/models/puzzle/puzzle.dart';
import 'package:bloom/models/puzzle/puzzle_models.dart';
import 'package:bloom/services/puzzle_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog puzzles have matching seats and unique solutions', () {
    expect(PuzzleCatalog.all, hasLength(15));
    for (final p in PuzzleCatalog.all) {
      expect(
        p.seatCount,
        p.characters.length,
        reason: '${p.id}: seat/character mismatch',
      );
      expect(p.geometry, isNotNull, reason: '${p.id}: missing geometry');

      final ref = PuzzlePlacement(Map<String, int>.from(p.referenceSolution));
      final refResult = PuzzleValidator.validate(puzzle: p, placement: ref);
      expect(refResult.isSolved, isTrue, reason: '${p.id}: reference invalid');

      final n = PuzzleValidator.countSolutions(p);
      expect(n, 1, reason: '${p.id}: expected 1 solution, got $n');
    }
  });
}
