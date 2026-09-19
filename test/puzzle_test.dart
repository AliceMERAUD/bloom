import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/models/puzzle/puzzle.dart';
import 'package:bloom/models/puzzle/puzzle_constraint.dart';
import 'package:bloom/models/puzzle/puzzle_models.dart';
import 'package:bloom/services/puzzle_catalog.dart';
import 'package:bloom/services/puzzle_progress_service.dart';
import 'package:bloom/services/storage_service.dart';

void main() {
  group('PuzzlePlacement', () {
    test('place, remove et swap', () {
      var placement = const PuzzlePlacement();
      placement = placement.place('a', 0);
      placement = placement.place('b', 1);
      expect(placement.indexOf('a'), 0);
      expect(placement.characterAt(1), 'b');

      placement = placement.swap('a', 'b');
      expect(placement.indexOf('a'), 1);
      expect(placement.indexOf('b'), 0);

      placement = placement.remove('a');
      expect(placement.indexOf('a'), isNull);
    });

    test('sérialisation round-trip', () {
      final original = const PuzzlePlacement({'a': 2, 'b': 0});
      final restored = PuzzlePlacement.fromMap(original.toMap());
      expect(restored.seats, original.seats);
    });
  });

  group('Contraintes', () {
    final placement = const PuzzlePlacement({
      'alice': 0,
      'bob': 1,
      'charlie': 3,
    });

    test('Adjacent', () {
      final ok = AdjacentConstraint(id: '1', a: 'alice', b: 'bob');
      final ko = AdjacentConstraint(id: '2', a: 'alice', b: 'charlie');
      expect(ok.isSatisfied(placement), isTrue);
      expect(ko.isSatisfied(placement), isFalse);
    });

    test('NotAdjacent', () {
      final ok = NotAdjacentConstraint(id: '1', a: 'alice', b: 'charlie');
      expect(ok.isSatisfied(placement), isTrue);
    });

    test('Before / After', () {
      expect(
        BeforeConstraint(id: '1', a: 'alice', b: 'bob').isSatisfied(placement),
        isTrue,
      );
      expect(
        AfterConstraint(id: '2', a: 'charlie', b: 'bob').isSatisfied(placement),
        isTrue,
      );
    });

    test('FixedPosition', () {
      expect(
        FixedPositionConstraint(id: '1', characterId: 'alice', index: 0)
            .isSatisfied(placement),
        isTrue,
      );
    });

    test('Between', () {
      final full = const PuzzlePlacement({
        'a': 0,
        'm': 1,
        'b': 3,
      });
      expect(
        BetweenConstraint(id: '1', middle: 'm', left: 'a', right: 'b')
            .isSatisfied(full),
        isTrue,
      );
    });
  });

  group('Validation', () {
    final puzzle = PuzzleCatalog.byId('bus_friends');

    test('placement vide', () {
      final result = PuzzleValidator.validate(
        puzzle: puzzle,
        placement: const PuzzlePlacement(),
      );
      expect(result.isComplete, isFalse);
      expect(result.isSolved, isFalse);
      expect(result.checks.every((c) => !c.evaluable), isTrue);
    });

    test('placement incomplet', () {
      final result = PuzzleValidator.validate(
        puzzle: puzzle,
        placement: const PuzzlePlacement({'alice': 0, 'bob': 1}),
      );
      expect(result.isComplete, isFalse);
      expect(result.isSolved, isFalse);
    });

    test('placement correct', () {
      final result = PuzzleValidator.validate(
        puzzle: puzzle,
        placement: PuzzlePlacement(puzzle.referenceSolution),
      );
      expect(result.isComplete, isTrue);
      expect(result.isSolved, isTrue);
      expect(result.failedCount, 0);
    });

    test('placement incorrect', () {
      final wrong = PuzzlePlacement({
        'alice': 0,
        'bob': 2,
        'charlie': 1,
        'dana': 3,
      });
      final result = PuzzleValidator.validate(
        puzzle: puzzle,
        placement: wrong,
      );
      expect(result.isSolved, isFalse);
      expect(result.failedCount, greaterThan(0));
    });
  });

  group('15 puzzles', () {
    test('le catalogue contient 15 puzzles', () {
      expect(PuzzleCatalog.all, hasLength(15));
    });

    for (final puzzle in PuzzleCatalog.all) {
      test('${puzzle.id} a une solution de référence valide', () {
        expect(puzzle.characters, isNotEmpty);
        expect(puzzle.constraints, isNotEmpty);
        expect(puzzle.referenceSolution.keys.toSet(),
            puzzle.characters.map((c) => c.id).toSet());

        final result = PuzzleValidator.validate(
          puzzle: puzzle,
          placement: PuzzlePlacement(puzzle.referenceSolution),
        );
        expect(result.isSolved, isTrue, reason: puzzle.id);
      });

      test('${puzzle.id} a au moins une solution', () {
        final count = PuzzleValidator.countSolutions(puzzle);
        expect(count, greaterThanOrEqualTo(1), reason: puzzle.id);
      });
    }
  });

  group('Progression', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('bloom_puzzle_');
      await StorageService.initForTesting(tempDir.path);
    });

    tearDown(() async {
      await StorageService.closeForTesting();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('déblocage séquentiel et sauvegarde', () async {
      final first = PuzzleCatalog.all.first;
      final second = PuzzleCatalog.all[1];

      var progress = PuzzleProgressService.load();
      expect(progress.isUnlocked(first.id), isTrue);
      expect(progress.isUnlocked(second.id), isFalse);

      progress = await PuzzleProgressService.markCompleted(first.id);
      expect(progress.isCompleted(first.id), isTrue);
      expect(progress.isUnlocked(second.id), isTrue);

      final restored = PuzzleProgressService.load();
      expect(restored.isCompleted(first.id), isTrue);
    });

    test('sauvegarde du placement en cours', () async {
      final puzzle = PuzzleCatalog.all.first;
      await PuzzleProgressService.savePlacement(
        puzzle.id,
        const PuzzlePlacement({'alice': 0}),
      );
      final loaded = PuzzleProgressService.load();
      expect(loaded.placements[puzzle.id]?.indexOf('alice'), 0);
    });
  });
}
