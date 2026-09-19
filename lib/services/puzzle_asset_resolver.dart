import 'package:flutter/services.dart';

import '../models/puzzle/puzzle_models.dart';
import '../models/puzzle/puzzle_scene.dart';

/// Resolves optional puzzle asset paths. Missing files never crash the app.
///
/// Set [spritesEnabled] to true after adding PNG files under
/// `assets/puzzle/` and declaring those folders in `pubspec.yaml`.
/// Until then, UI widgets use painted fallbacks (no AssetBundle loads).
class PuzzleAssetResolver {
  static const charactersRoot = 'assets/puzzle/characters';
  static const scenesRoot = 'assets/puzzle/scenes';
  static const tilesRoot = 'assets/puzzle/tiles';

  /// Flip to true when real puzzle PNGs are declared in pubspec.yaml.
  static const spritesEnabled = false;

  static String characterPath(PuzzleCharacter character, CharacterPose pose) {
    final key = character.assetKey ?? character.id;
    return '$charactersRoot/${key}_${pose.assetSuffix}.png';
  }

  static String sceneBackdropPath(String scenario) =>
      '$scenesRoot/$scenario.png';

  static String tilePath(PuzzleTileKind kind, String scenario) =>
      '$tilesRoot/${kind.assetToken}_$scenario.png';

  static Future<bool> exists(String assetPath) async {
    if (!spritesEnabled) return false;
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }
}
