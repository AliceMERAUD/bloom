import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/models/puzzle/puzzle.dart';
import 'package:bloom/models/puzzle/puzzle_models.dart';
import 'package:bloom/models/puzzle/puzzle_scene.dart';
import 'package:bloom/screens/puzzle/puzzle_play_screen.dart';
import 'package:bloom/screens/puzzle/puzzle_screen.dart';
import 'package:bloom/services/puzzle_asset_resolver.dart';
import 'package:bloom/services/puzzle_catalog.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/widgets/puzzle/puzzle_character_widget.dart';
import 'package:bloom/widgets/puzzle/puzzle_constraint_feedback.dart';
import 'package:bloom/widgets/puzzle/puzzle_scene_board.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bloom_puzzle_ux_');
    await StorageService.initForTesting(tempDir.path);
    PuzzlePlayScreenState.suppressPersistence = true;
  });

  tearDown(() async {
    PuzzlePlayScreenState.suppressPersistence = false;
    await StorageService.closeForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> pumpPlay(WidgetTester tester, {String id = 'bus_friends'}) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(home: PuzzlePlayScreen(puzzleId: id)),
    );
    await tester.pump();
  }

  PuzzlePlayScreenState playState(WidgetTester tester) {
    return tester.state<PuzzlePlayScreenState>(
      find.byType(PuzzlePlayScreen),
    );
  }

  test('PuzzleAssetResolver builds character paths from assetKey', () {
    const character = PuzzleCharacter(
      id: 'alice',
      name: 'Alice',
      assetKey: 'alice',
    );
    expect(
      PuzzleAssetResolver.characterPath(character, CharacterPose.sitting),
      'assets/puzzle/characters/alice_sitting.png',
    );
    expect(
      PuzzleAssetResolver.tilePath(PuzzleTileKind.seat, 'bus'),
      'assets/puzzle/tiles/seat_bus.png',
    );
  });

  test('PuzzleAssetResolver.exists returns false when sprites disabled', () async {
    expect(
      await PuzzleAssetResolver.exists('assets/puzzle/characters/x.png'),
      isFalse,
    );
    expect(PuzzleAssetResolver.spritesEnabled, isFalse);
  });

  test('PuzzleSceneTheme resolves by scenario without puzzle ids', () {
    expect(PuzzleSceneTheme.forScenario('bus').title, 'Bus');
    expect(PuzzleSceneTheme.forScenario('mariage').motifIcon, Icons.favorite);
    expect(PuzzleSceneTheme.forScenario('bureau').title, 'Bureau');
    expect(PuzzleSceneTheme.forScenario('train').title, 'Train');
    expect(
      PuzzleSceneLayout.forScenario('bus').tiles,
      contains(PuzzleTileKind.window),
    );
  });

  testWidgets('PuzzleCharacterWidget falls back when sprite missing',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PuzzleCharacterWidget(
            character: PuzzleCharacter(
              id: 'alice',
              name: 'Alice',
              assetKey: 'alice',
            ),
            pose: CharacterPose.normal,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('écran de jeu affiche le décor du scénario', (tester) async {
    await pumpPlay(tester);
    expect(find.text('Bus'), findsWidgets);
    expect(find.text('Vérifier'), findsOneWidget);
    expect(find.byType(PuzzleSceneBoard), findsOneWidget);
  });

  testWidgets('sélection, placement et déplacement', (tester) async {
    await pumpPlay(tester);
    final state = playState(tester);

    state.debugSelectCharacter('alice');
    await tester.pump();
    state.debugTapSeat(0);
    await tester.pump();
    expect(state.placement.indexOf('alice'), 0);
    expect(find.text('placé'), findsOneWidget);

    state.debugSelectCharacter('alice');
    await tester.pump();
    state.debugTapSeat(1);
    await tester.pump();
    expect(state.placement.indexOf('alice'), 1);
  });

  testWidgets('validation réussie avec solution de référence', (tester) async {
    final puzzle = PuzzleCatalog.byId('bus_friends');
    await tester.pumpWidget(
      MaterialApp(home: PuzzlePlayScreen(puzzleId: puzzle.id)),
    );
    await tester.pump();

    final state = playState(tester);
    state.placement = PuzzlePlacement(
      Map<String, int>.from(puzzle.referenceSolution),
    );
    await tester.pump();

    state.debugVerify(showSuccessDialog: true);
    await tester.pump();

    expect(state.solved, isTrue);
    expect(find.text('Respectée'), findsWidgets);
    expect(find.text('Bravo !'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pump();
    expect(find.text('Bravo !'), findsNothing);
  });

  testWidgets('réinitialiser vide le plateau', (tester) async {
    await pumpPlay(tester);
    final state = playState(tester);

    state.debugSelectCharacter('alice');
    state.debugTapSeat(0);
    await tester.pump();
    expect(find.text('placé'), findsOneWidget);

    state.debugReset();
    await tester.pump();
    expect(state.placement.isEmpty, isTrue);
    expect(find.text('placé'), findsNothing);
  });

  testWidgets('mauvaise solution conserve le placement', (tester) async {
    await pumpPlay(tester);
    final puzzle = PuzzleCatalog.byId('bus_friends');
    final state = playState(tester);
    // Swap two characters from the reference so the placement stays wrong
    // even if the catalog solution changes.
    final wrong = Map<String, int>.from(puzzle.referenceSolution);
    final keys = wrong.keys.toList();
    final a = keys[0];
    final b = keys[1];
    final tmp = wrong[a]!;
    wrong[a] = wrong[b]!;
    wrong[b] = tmp;
    state.placement = PuzzlePlacement(wrong);
    await tester.pump();

    state.debugVerify(showSuccessDialog: true);
    await tester.pump();

    expect(state.solved, isFalse);
    expect(find.text('Bravo !'), findsNothing);
    expect(find.text('Non respectée'), findsWidgets);
    expect(state.placement.seats.length, puzzle.seatCount);
  });

  testWidgets('PuzzleScreen liste scénarios et ouvre un puzzle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PuzzleScreen()),
    );
    await tester.pump();

    expect(find.text('Puzzle'), findsOneWidget);
    expect(find.text('Les amis dans le bus'), findsWidgets);

    await tester.tap(find.text('Les amis dans le bus').first);
    await tester.pump();
    await tester.pump();

    expect(find.text('Vérifier'), findsOneWidget);
    expect(find.byType(PuzzleSceneBoard), findsOneWidget);
  });

  testWidgets('PuzzleConstraintFeedback shows status labels', (tester) async {
    final puzzle = PuzzleCatalog.byId('bus_friends');
    final result = PuzzleValidator.validate(
      puzzle: puzzle,
      placement: PuzzlePlacement(
        Map<String, int>.from(puzzle.referenceSolution),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PuzzleConstraintFeedback(puzzle: puzzle, result: result),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Respectée'), findsWidgets);
  });
}
