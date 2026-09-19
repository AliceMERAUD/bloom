import 'package:flutter/material.dart';

import '../../models/puzzle/puzzle.dart';
import '../../models/puzzle/puzzle_geometry.dart';
import '../../models/puzzle/puzzle_models.dart';
import '../../models/puzzle/puzzle_scene.dart';
import 'puzzle_character_widget.dart';

/// Visual board: real grid from [Puzzle.resolvedGeometry] + tactile seats.
class PuzzleSceneBoard extends StatelessWidget {
  final Puzzle puzzle;
  final PuzzlePlacement placement;
  final String? selectedCharacterId;
  final ValueChanged<int> onTapSeat;

  const PuzzleSceneBoard({
    super.key,
    required this.puzzle,
    required this.placement,
    required this.selectedCharacterId,
    required this.onTapSeat,
  });

  static const double _minCell = 44;

  bool get _preferSitting {
    switch (puzzle.scenario) {
      case 'bus':
      case 'train':
      case 'cinema':
      case 'diner':
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = PuzzleSceneTheme.forScenario(puzzle.scenario);
    final geo = puzzle.resolvedGeometry;
    final isDarkFloor = theme.floorColor.computeLuminance() < 0.35;
    final pose =
        _preferSitting ? CharacterPose.sitting : CharacterPose.normal;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.wallColor, theme.floorColor],
        ),
        border: Border.all(color: theme.accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Icon(theme.motifIcon, color: theme.accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    theme.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkFloor ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  '${geo.seats.length} ${theme.seatNoun}s',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkFloor ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellW = (constraints.maxWidth / geo.cols)
                      .clamp(_minCell, 96.0);
                  final cellH = ((constraints.maxHeight - 4) / geo.rows)
                      .clamp(_minCell, 110.0);
                  final gridW = cellW * geo.cols;
                  final gridH = cellH * geo.rows;

                  return Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: SizedBox(
                          width: gridW,
                          height: gridH,
                          child: Table(
                            defaultColumnWidth: FixedColumnWidth(cellW),
                            children: [
                              for (var r = 0; r < geo.rows; r++)
                                TableRow(
                                  children: [
                                    for (var c = 0; c < geo.cols; c++)
                                      SizedBox(
                                        width: cellW,
                                        height: cellH,
                                        child: _GridCell(
                                          cell: geo.cellAt(r, c),
                                          puzzle: puzzle,
                                          theme: theme,
                                          placement: placement,
                                          selectedCharacterId:
                                              selectedCharacterId,
                                          onTapSeat: onTapSeat,
                                          isDark: isDarkFloor,
                                          pose: pose,
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  final PuzzleCell? cell;
  final Puzzle puzzle;
  final PuzzleSceneTheme theme;
  final PuzzlePlacement placement;
  final String? selectedCharacterId;
  final ValueChanged<int> onTapSeat;
  final bool isDark;
  final CharacterPose pose;

  const _GridCell({
    required this.cell,
    required this.puzzle,
    required this.theme,
    required this.placement,
    required this.selectedCharacterId,
    required this.onTapSeat,
    required this.isDark,
    required this.pose,
  });

  @override
  Widget build(BuildContext context) {
    final c = cell;
    if (c == null) {
      return const SizedBox.shrink();
    }

    switch (c.kind) {
      case PuzzleCellKind.seat:
        return _SeatTile(
          puzzle: puzzle,
          theme: theme,
          cell: c,
          placement: placement,
          selectedCharacterId: selectedCharacterId,
          onTap: () => onTapSeat(c.index),
          isDark: isDark,
          pose: pose,
        );
      case PuzzleCellKind.blocked:
        return _ObjectTile(
          theme: theme,
          tile: c.tile,
          label: c.label,
          dimmed: true,
          isDark: isDark,
        );
      case PuzzleCellKind.object:
      case PuzzleCellKind.decor:
        return _ObjectTile(
          theme: theme,
          tile: c.tile,
          label: c.label ?? c.objectId,
          dimmed: c.kind == PuzzleCellKind.decor,
          isDark: isDark,
        );
    }
  }
}

class _ObjectTile extends StatelessWidget {
  final PuzzleSceneTheme theme;
  final PuzzleTileKind tile;
  final String? label;
  final bool dimmed;
  final bool isDark;

  const _ObjectTile({
    required this.theme,
    required this.tile,
    this.label,
    this.dimmed = false,
    required this.isDark,
  });

  IconData get _icon {
    switch (tile) {
      case PuzzleTileKind.window:
        return Icons.window;
      case PuzzleTileKind.door:
        return Icons.door_front_door_outlined;
      case PuzzleTileKind.table:
        return Icons.table_restaurant;
      case PuzzleTileKind.seat:
        return Icons.weekend_outlined;
      case PuzzleTileKind.wall:
        return Icons.crop_square;
      case PuzzleTileKind.floor:
        return Icons.texture;
      case PuzzleTileKind.decor:
        return Icons.park_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alpha = dimmed ? 0.35 : 0.85;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: theme.accentColor.withValues(alpha: dimmed ? 0.12 : 0.22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.accentColor.withValues(alpha: dimmed ? 0.2 : 0.4),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _icon,
              size: 22,
              color: theme.accentColor.withValues(alpha: alpha),
            ),
            if (label != null && label!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: (isDark ? Colors.white70 : Colors.black54)
                      .withValues(alpha: alpha),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeatTile extends StatelessWidget {
  final Puzzle puzzle;
  final PuzzleSceneTheme theme;
  final PuzzleCell cell;
  final PuzzlePlacement placement;
  final String? selectedCharacterId;
  final VoidCallback onTap;
  final bool isDark;
  final CharacterPose pose;

  const _SeatTile({
    required this.puzzle,
    required this.theme,
    required this.cell,
    required this.placement,
    required this.selectedCharacterId,
    required this.onTap,
    required this.isDark,
    required this.pose,
  });

  @override
  Widget build(BuildContext context) {
    final characterId = placement.characterAt(cell.index);
    final character =
        characterId == null ? null : puzzle.characterById(characterId);
    final selected =
        characterId != null && characterId == selectedCharacterId;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Semantics(
        button: true,
        label: '${theme.seatNoun} ${cell.label ?? cell.index + 1}'
            '${character == null ? ', vide' : ', ${character.name}'}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            decoration: BoxDecoration(
              color: selected
                  ? theme.accentColor.withValues(alpha: 0.35)
                  : theme.seatColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? theme.accentColor
                    : theme.accentColor.withValues(alpha: 0.4),
                width: selected ? 2.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cell.label ?? '${cell.index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: character == null
                          ? Icon(
                              Icons.add_circle_outline,
                              key: ValueKey('empty-${cell.index}'),
                              color: theme.accentColor.withValues(alpha: 0.7),
                              size: 26,
                            )
                          : PuzzleCharacterWidget(
                              key: ValueKey(character.id),
                              character: character,
                              pose: pose,
                              selected: selected,
                              showName: false,
                              size: 36,
                            ),
                    ),
                  ),
                ),
                Text(
                  character?.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
