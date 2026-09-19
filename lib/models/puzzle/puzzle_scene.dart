import 'package:flutter/material.dart';

enum CharacterPose {
  normal,
  walking,
  sitting,
}

extension CharacterPoseX on CharacterPose {
  String get assetSuffix {
    switch (this) {
      case CharacterPose.normal:
        return 'normal';
      case CharacterPose.walking:
        return 'walking';
      case CharacterPose.sitting:
        return 'sitting';
    }
  }

  IconData get fallbackIcon {
    switch (this) {
      case CharacterPose.normal:
        return Icons.person;
      case CharacterPose.walking:
        return Icons.directions_walk;
      case CharacterPose.sitting:
        return Icons.airline_seat_recline_normal;
    }
  }
}

/// Reusable décor tile kinds for composing scenes without full-scene art.
enum PuzzleTileKind {
  floor,
  wall,
  seat,
  table,
  door,
  window,
  decor,
}

extension PuzzleTileKindX on PuzzleTileKind {
  String get assetToken {
    switch (this) {
      case PuzzleTileKind.floor:
        return 'floor';
      case PuzzleTileKind.wall:
        return 'wall';
      case PuzzleTileKind.seat:
        return 'seat';
      case PuzzleTileKind.table:
        return 'table';
      case PuzzleTileKind.door:
        return 'door';
      case PuzzleTileKind.window:
        return 'window';
      case PuzzleTileKind.decor:
        return 'decor';
    }
  }
}

/// Data-driven visual layout: maps logical seats to optional screen slots.
/// Constraint logic never reads these coordinates.
class PuzzleSceneLayout {
  final String scenario;
  final int seatCount;
  final List<PuzzleTileKind> tiles;
  final Axis seatAxis;
  final List<Offset>? seatOffsets;

  const PuzzleSceneLayout({
    required this.scenario,
    required this.seatCount,
    this.tiles = const [
      PuzzleTileKind.floor,
      PuzzleTileKind.wall,
      PuzzleTileKind.seat,
    ],
    this.seatAxis = Axis.horizontal,
    this.seatOffsets,
  });

  factory PuzzleSceneLayout.forScenario(String scenario, {int seatCount = 4}) {
    switch (scenario) {
      case 'bus':
      case 'train':
        return PuzzleSceneLayout(
          scenario: scenario,
          seatCount: seatCount,
          tiles: const [
            PuzzleTileKind.floor,
            PuzzleTileKind.wall,
            PuzzleTileKind.window,
            PuzzleTileKind.seat,
            PuzzleTileKind.door,
          ],
        );
      case 'cinema':
        return PuzzleSceneLayout(
          scenario: scenario,
          seatCount: seatCount,
          tiles: const [
            PuzzleTileKind.floor,
            PuzzleTileKind.wall,
            PuzzleTileKind.seat,
            PuzzleTileKind.decor,
          ],
        );
      case 'bureau':
      case 'bibliotheque':
        return PuzzleSceneLayout(
          scenario: scenario,
          seatCount: seatCount,
          tiles: const [
            PuzzleTileKind.floor,
            PuzzleTileKind.wall,
            PuzzleTileKind.table,
            PuzzleTileKind.seat,
            PuzzleTileKind.window,
          ],
        );
      case 'cafe':
      case 'diner':
        return PuzzleSceneLayout(
          scenario: scenario,
          seatCount: seatCount,
          tiles: const [
            PuzzleTileKind.floor,
            PuzzleTileKind.wall,
            PuzzleTileKind.table,
            PuzzleTileKind.seat,
            PuzzleTileKind.door,
          ],
        );
      case 'parc':
        return PuzzleSceneLayout(
          scenario: scenario,
          seatCount: seatCount,
          tiles: const [
            PuzzleTileKind.floor,
            PuzzleTileKind.seat,
            PuzzleTileKind.decor,
          ],
        );
      default:
        return PuzzleSceneLayout(
          scenario: scenario,
          seatCount: seatCount,
        );
    }
  }
}

/// Visual theme for a puzzle scenario (independent from constraint logic).
class PuzzleSceneTheme {
  final String scenario;
  final String title;
  final Color floorColor;
  final Color wallColor;
  final Color accentColor;
  final Color seatColor;
  final IconData motifIcon;
  final String seatNoun;

  const PuzzleSceneTheme({
    required this.scenario,
    required this.title,
    required this.floorColor,
    required this.wallColor,
    required this.accentColor,
    required this.seatColor,
    required this.motifIcon,
    required this.seatNoun,
  });

  /// Resolves a theme from [Puzzle.scenario] without puzzle-id branching.
  static PuzzleSceneTheme forScenario(String scenario) {
    switch (scenario) {
      case 'bus':
        return const PuzzleSceneTheme(
          scenario: 'bus',
          title: 'Bus',
          floorColor: Color(0xFFE8EEF7),
          wallColor: Color(0xFFD4E0F0),
          accentColor: Color(0xFF7BA3D4),
          seatColor: Color(0xFFB8C9DE),
          motifIcon: Icons.directions_bus,
          seatNoun: 'siège',
        );
      case 'mariage':
        return const PuzzleSceneTheme(
          scenario: 'mariage',
          title: 'Mariage',
          floorColor: Color(0xFFFFF5F8),
          wallColor: Color(0xFFF8E6EE),
          accentColor: Color(0xFFE8A7C4),
          seatColor: Color(0xFFF0D0DE),
          motifIcon: Icons.favorite,
          seatNoun: 'place',
        );
      case 'salle_attente':
        return const PuzzleSceneTheme(
          scenario: 'salle_attente',
          title: 'Salle d’attente',
          floorColor: Color(0xFFF3F7F4),
          wallColor: Color(0xFFE0EBE3),
          accentColor: Color(0xFF8FBF9F),
          seatColor: Color(0xFFC5D9CB),
          motifIcon: Icons.local_hospital,
          seatNoun: 'chaise',
        );
      case 'bureau':
        return const PuzzleSceneTheme(
          scenario: 'bureau',
          title: 'Bureau',
          floorColor: Color(0xFFF5F3EF),
          wallColor: Color(0xFFE8E2D8),
          accentColor: Color(0xFFB5A48A),
          seatColor: Color(0xFFD4C8B4),
          motifIcon: Icons.desktop_windows,
          seatNoun: 'bureau',
        );
      case 'cinema':
        return const PuzzleSceneTheme(
          scenario: 'cinema',
          title: 'Cinéma',
          floorColor: Color(0xFF2A2433),
          wallColor: Color(0xFF3D3450),
          accentColor: Color(0xFFC9A0DC),
          seatColor: Color(0xFF5A4A70),
          motifIcon: Icons.movie,
          seatNoun: 'fauteuil',
        );
      case 'bibliotheque':
        return const PuzzleSceneTheme(
          scenario: 'bibliotheque',
          title: 'Bibliothèque',
          floorColor: Color(0xFFF7F1E8),
          wallColor: Color(0xFFEADFCF),
          accentColor: Color(0xFFC4A882),
          seatColor: Color(0xFFD9C6A8),
          motifIcon: Icons.menu_book,
          seatNoun: 'place',
        );
      case 'cafe':
        return const PuzzleSceneTheme(
          scenario: 'cafe',
          title: 'Café',
          floorColor: Color(0xFFFFF8F0),
          wallColor: Color(0xFFF5E6D3),
          accentColor: Color(0xFFD4A574),
          seatColor: Color(0xFFE8C9A8),
          motifIcon: Icons.coffee,
          seatNoun: 'place',
        );
      case 'parc':
        return const PuzzleSceneTheme(
          scenario: 'parc',
          title: 'Parc',
          floorColor: Color(0xFFEAF6E8),
          wallColor: Color(0xFFD5EBD1),
          accentColor: Color(0xFF7CB87A),
          seatColor: Color(0xFFA8CFA6),
          motifIcon: Icons.park,
          seatNoun: 'banc',
        );
      case 'train':
        return const PuzzleSceneTheme(
          scenario: 'train',
          title: 'Train',
          floorColor: Color(0xFFECEFF5),
          wallColor: Color(0xFFD8DEE9),
          accentColor: Color(0xFF8899B4),
          seatColor: Color(0xFFB0BCCF),
          motifIcon: Icons.train,
          seatNoun: 'place',
        );
      case 'diner':
        return const PuzzleSceneTheme(
          scenario: 'diner',
          title: 'Dîner',
          floorColor: Color(0xFFFFF9F2),
          wallColor: Color(0xFFF5EADF),
          accentColor: Color(0xFFE0B089),
          seatColor: Color(0xFFE8CDB0),
          motifIcon: Icons.restaurant,
          seatNoun: 'couvert',
        );
      default:
        return PuzzleSceneTheme(
          scenario: scenario,
          title: scenario,
          floorColor: const Color(0xFFFFFBFD),
          wallColor: const Color(0xFFF5EAF0),
          accentColor: const Color(0xFFE8A7C4),
          seatColor: const Color(0xFFE8D0DC),
          motifIcon: Icons.extension,
          seatNoun: 'place',
        );
    }
  }
}
