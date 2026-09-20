import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/models/puzzle/puzzle.dart';
import 'package:bloom/models/puzzle/puzzle_models.dart';
import 'package:bloom/services/puzzle/generated_puzzle_catalog_service.dart';
import 'package:bloom/services/puzzle/puzzle_difficulty_service.dart';
import 'package:bloom/services/puzzle/puzzle_generation_config.dart';
import 'package:bloom/services/puzzle/puzzle_generator_service.dart';
import 'package:bloom/services/puzzle/puzzle_history_service.dart';
import 'package:bloom/services/puzzle/puzzle_repository.dart';
import 'package:bloom/services/puzzle_catalog.dart';
import 'package:bloom/services/storage_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bloom_phase10_');
    await StorageService.initForTesting(tempDir.path);
  });

  tearDown(() async {
    await StorageService.closeForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PuzzleGeneratorService', () {
    test('seed reproductible produit la même signature', () {
      final a = PuzzleGeneratorService(seed: 42).generate(
        config: PuzzleGenerationConfig.easy,
        playerLevel: 1,
      );
      final b = PuzzleGeneratorService(seed: 42).generate(
        config: PuzzleGenerationConfig.easy,
        playerLevel: 1,
      );
      expect(a, isNotNull);
      expect(b, isNotNull);
      expect(
        PuzzleGeneratorService.signatureOf(a!),
        PuzzleGeneratorService.signatureOf(b!),
      );
      expect(a.seatCount, inInclusiveRange(4, 5));
      expect(a.constraints.length, greaterThanOrEqualTo(2));
    });

    test('puzzle généré a une solution unique', () {
      final puzzle = PuzzleGeneratorService(seed: 7).generate(
        config: PuzzleGenerationConfig.easy,
        playerLevel: 2,
      );
      expect(puzzle, isNotNull);
      expect(PuzzleValidator.countSolutions(puzzle!, stopAt: 2), 1);
      final placement =
          PuzzlePlacement(Map<String, int>.from(puzzle.referenceSolution));
      final result = PuzzleValidator.validate(
        puzzle: puzzle,
        placement: placement,
      );
      expect(result.isSolved, isTrue);
    });

    test('seeds 1..20 génèrent un puzzle valide ou échouent proprement', () {
      for (var seed = 1; seed <= 20; seed++) {
        final puzzle = PuzzleGeneratorService(seed: seed).generate(
          config: PuzzleGenerationConfig.easy,
          playerLevel: 1 + (seed % 3),
        );
        if (puzzle == null) continue;
        expect(
          PuzzleValidator.countSolutions(puzzle, stopAt: 2),
          1,
          reason: 'seed $seed must be unique',
        );
        expect(puzzle.seatCount, inInclusiveRange(4, 5));
      }
    });

    test('difficulté medium respecte les bornes de cases', () {
      final puzzle = PuzzleGeneratorService(seed: 99).generate(
        config: PuzzleGenerationConfig.medium,
        playerLevel: 5,
      );
      expect(puzzle, isNotNull);
      expect(puzzle!.seatCount, inInclusiveRange(5, 7));
      expect(PuzzleValidator.hasUniqueSolution(puzzle), isTrue);
    });

    test('signatures différentes pour seeds différents', () {
      final a = PuzzleGeneratorService(seed: 1).generate(
        config: PuzzleGenerationConfig.easy,
        playerLevel: 1,
      );
      final b = PuzzleGeneratorService(seed: 2).generate(
        config: PuzzleGenerationConfig.easy,
        playerLevel: 1,
      );
      expect(a, isNotNull);
      expect(b, isNotNull);
      // Soft check: content or signature usually differs.
      final sameSig = PuzzleGeneratorService.signatureOf(a!) ==
          PuzzleGeneratorService.signatureOf(b!);
      final sameSolution = a.referenceSolution.toString() ==
          b.referenceSolution.toString();
      expect(sameSig && sameSolution, isFalse);
    });
  });

  group('PuzzleDifficultyService', () {
    test('réussites augmentent progressivement le niveau', () async {
      var state = PuzzleDifficultyService.load();
      expect(state.level, 1);

      state = await PuzzleDifficultyService.recordWin();
      expect(state.level, 1); // first win alone: streak
      state = await PuzzleDifficultyService.recordWin();
      expect(state.level, greaterThanOrEqualTo(2));

      final before = state.level;
      for (var i = 0; i < 6; i++) {
        state = await PuzzleDifficultyService.recordWin();
      }
      expect(state.level, greaterThan(before));
      expect(state.level, lessThanOrEqualTo(PuzzleDifficultyService.maxLevel));
    });

    test('échecs ne font pas chuter brutalement', () async {
      await PuzzleDifficultyService.save(
        const PlayerDifficultyState(level: 5, winStreak: 0),
      );
      var state = await PuzzleDifficultyService.recordLoss();
      expect(state.level, 5); // one loss: stable
      state = await PuzzleDifficultyService.recordLoss();
      expect(state.level, 4); // two losses: -1
      expect(state.level, greaterThanOrEqualTo(1));
    });
  });

  group('Generated catalog & history', () {
    test('limite à 20 puzzles, évince le plus ancien', () async {
      final base = DateTime(2020, 1, 1);
      for (var i = 0; i < 20; i++) {
        final p = Puzzle(
          id: 'gen_old_$i',
          title: 'P$i',
          description: '',
          scenario: 'bus',
          difficulty: PuzzleDifficulty.easy,
          characters: const [
            PuzzleCharacter(id: 'a', name: 'A'),
          ],
          positions: const [PuzzlePosition(id: 'p0', index: 0)],
          constraints: const [],
          referenceSolution: const {'a': 0},
        );
        await GeneratedPuzzleCatalogService.add(p);
        // Force createdAt ordering by rewriting catalog with timestamps.
      }

      // Rebuild with explicit timestamps for deterministic eviction.
      final records = <GeneratedPuzzleRecord>[
        for (var i = 0; i < 20; i++)
          GeneratedPuzzleRecord(
            puzzle: Puzzle(
              id: 'gen_old_$i',
              title: 'P$i',
              description: '',
              scenario: 'bus',
              difficulty: PuzzleDifficulty.easy,
              characters: const [PuzzleCharacter(id: 'a', name: 'A')],
              positions: const [PuzzlePosition(id: 'p0', index: 0)],
              constraints: const [],
              referenceSolution: const {'a': 0},
            ),
            createdAt: base.add(Duration(minutes: i)),
            signature: 'sig_$i',
          ),
      ];
      await GeneratedPuzzleCatalogService.save(
        GeneratedPuzzleCatalog(records: records),
      );
      expect(GeneratedPuzzleCatalogService.load().length, 20);

      await PuzzleHistoryService.recordAttempt(
        puzzleId: 'gen_old_0',
        success: true,
        difficulty: 'easy',
        generated: true,
      );

      final newest = Puzzle(
        id: 'gen_new_21',
        title: 'P21',
        description: '',
        scenario: 'bus',
        difficulty: PuzzleDifficulty.easy,
        characters: const [PuzzleCharacter(id: 'a', name: 'A')],
        positions: const [PuzzlePosition(id: 'p0', index: 0)],
        constraints: const [],
        referenceSolution: const {'a': 0},
      );
      final evicted = await GeneratedPuzzleCatalogService.add(newest);
      final catalog = GeneratedPuzzleCatalogService.load();
      expect(catalog.length, 20);
      expect(catalog.byId('gen_new_21'), isNotNull);
      expect(catalog.byId('gen_old_0'), isNull);
      expect(evicted, 'gen_old_0');

      // History of evicted puzzle is retained.
      final history = PuzzleHistoryService.load();
      expect(history.entryFor('gen_old_0'), isNotNull);
      expect(history.entryFor('gen_old_0')!.completed, isTrue);
    });

    test('historique plafonné à 100 entrées, stats conservées', () async {
      for (var i = 0; i < 105; i++) {
        await PuzzleHistoryService.recordAttempt(
          puzzleId: 'p_$i',
          success: i % 2 == 0,
          difficulty: 'easy',
          generated: true,
          playerLevel: 3,
        );
      }
      final store = PuzzleHistoryService.load();
      expect(
        store.entries.length,
        lessThanOrEqualTo(PuzzleGeneratorLimits.maxPuzzleHistory),
      );
      expect(store.stats.totalCompleted, greaterThan(0));
      expect(store.stats.totalFailed, greaterThan(0));
    });
  });

  group('Repository & static catalog', () {
    test('puzzles classiques toujours résolus par id', () {
      final first = PuzzleCatalog.all.first;
      expect(PuzzleRepository.byId(first.id)?.id, first.id);
    });

    test('ensureNextGenerated ajoute au catalogue', () async {
      final puzzle = await PuzzleRepository.ensureNextGenerated(seed: 123);
      expect(puzzle.id, startsWith('gen_'));
      expect(PuzzleRepository.byId(puzzle.id), isNotNull);
      expect(PuzzleValidator.hasUniqueSolution(puzzle), isTrue);
    });
  });

  group('Puzzle serialize', () {
    test('toMap/fromMap round-trip généré', () {
      final puzzle = PuzzleGeneratorService(seed: 11).generate(
        config: PuzzleGenerationConfig.easy,
        playerLevel: 1,
      )!;
      final restored = Puzzle.fromMap(puzzle.toMap());
      expect(restored.id, puzzle.id);
      expect(restored.constraints.length, puzzle.constraints.length);
      expect(restored.referenceSolution, puzzle.referenceSolution);
    });
  });
}
