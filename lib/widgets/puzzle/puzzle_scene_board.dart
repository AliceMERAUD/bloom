import 'package:flutter/material.dart';

import '../../models/puzzle/puzzle.dart';
import '../../models/puzzle/puzzle_models.dart';
import '../../models/puzzle/puzzle_scene.dart';
import 'puzzle_character_widget.dart';

/// Visual board: scenario décor + tactile seats (logic indices unchanged).
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

  @override
  Widget build(BuildContext context) {
    final theme = PuzzleSceneTheme.forScenario(puzzle.scenario);
    final layout = PuzzleSceneLayout.forScenario(
      puzzle.scenario,
      seatCount: puzzle.positions.length,
    );
    final isDarkFloor = theme.floorColor.computeLuminance() < 0.35;
    final hasWindows = layout.tiles.contains(PuzzleTileKind.window);
    final hasTable = layout.tiles.contains(PuzzleTileKind.table);
    final hasDoor = layout.tiles.contains(PuzzleTileKind.door);

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
                if (hasDoor)
                  Icon(
                    Icons.door_front_door_outlined,
                    size: 18,
                    color: theme.accentColor.withValues(alpha: 0.8),
                  ),
                if (hasDoor) const SizedBox(width: 6),
                Text(
                  '${puzzle.positions.length} ${theme.seatNoun}s',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkFloor ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (hasWindows)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(
                  3,
                  (i) => Expanded(
                    child: Container(
                      height: 14,
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: theme.accentColor.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: theme.accentColor.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          if (hasTable)
            Container(
              height: 8,
              margin: const EdgeInsets.fromLTRB(40, 10, 40, 0),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final seatCount = puzzle.positions.length;
                  final maxSeatWidth = (constraints.maxWidth / seatCount) - 6;
                  final seatWidth = maxSeatWidth.clamp(56.0, 96.0);

                  return Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: puzzle.positions.map((position) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: SizedBox(
                              width: seatWidth,
                              child: _SeatTile(
                                puzzle: puzzle,
                                theme: theme,
                                position: position,
                                placement: placement,
                                selectedCharacterId: selectedCharacterId,
                                onTap: () => onTapSeat(position.index),
                                isDark: isDarkFloor,
                              ),
                            ),
                          );
                        }).toList(),
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

class _SeatTile extends StatelessWidget {
  final Puzzle puzzle;
  final PuzzleSceneTheme theme;
  final PuzzlePosition position;
  final PuzzlePlacement placement;
  final String? selectedCharacterId;
  final VoidCallback onTap;
  final bool isDark;

  const _SeatTile({
    required this.puzzle,
    required this.theme,
    required this.position,
    required this.placement,
    required this.selectedCharacterId,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final characterId = placement.characterAt(position.index);
    final character =
        characterId == null ? null : puzzle.characterById(characterId);
    final selected =
        characterId != null && characterId == selectedCharacterId;

    return Semantics(
      button: true,
      label: '${theme.seatNoun} ${position.label ?? position.index + 1}'
          '${character == null ? ', vide' : ', ${character.name}'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? theme.accentColor.withValues(alpha: 0.35)
                : theme.seatColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? theme.accentColor : theme.accentColor.withValues(alpha: 0.4),
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                position.label ?? '${position.index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: character == null
                    ? Icon(
                        Icons.add_circle_outline,
                        key: ValueKey('empty-${position.index}'),
                        color: theme.accentColor.withValues(alpha: 0.7),
                        size: 28,
                      )
                    : PuzzleCharacterWidget(
                        key: ValueKey(character.id),
                        character: character,
                        pose: CharacterPose.sitting,
                        selected: selected,
                        showName: false,
                        size: 40,
                      ),
              ),
              const SizedBox(height: 4),
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
    );
  }
}
