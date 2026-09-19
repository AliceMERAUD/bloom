import 'package:flutter/material.dart';

import '../../models/puzzle/puzzle_models.dart';
import '../../models/puzzle/puzzle_scene.dart';
import '../../services/puzzle_asset_resolver.dart';

/// Displays a puzzle character with optional sprite and graceful fallback.
class PuzzleCharacterWidget extends StatelessWidget {
  final PuzzleCharacter character;
  final CharacterPose pose;
  final bool selected;
  final bool placed;
  final bool showName;
  final double size;
  final VoidCallback? onTap;

  const PuzzleCharacterWidget({
    super.key,
    required this.character,
    this.pose = CharacterPose.normal,
    this.selected = false,
    this.placed = false,
    this.showName = true,
    this.size = 52,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: selected ? 2.5 : 1,
        ),
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.colorScheme.surface,
        boxShadow: selected
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: selected ? 1.08 : 1,
            duration: const Duration(milliseconds: 180),
            child: _Avatar(
              character: character,
              pose: pose,
              size: size,
            ),
          ),
          if (showName) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: size + 12,
              child: Text(
                character.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ],
          if (placed)
            Text(
              'placé',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: character.name,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: content,
            ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final PuzzleCharacter character;
  final CharacterPose pose;
  final double size;

  const _Avatar({
    required this.character,
    required this.pose,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final path = PuzzleAssetResolver.characterPath(character, pose);
    final hue = (character.id.hashCode.abs() % 360).toDouble();
    final color = HSLColor.fromAHSL(1, hue, 0.35, 0.78).toColor();
    final fallback = _FallbackAvatar(
      character: character,
      pose: pose,
      color: color,
      size: size,
    );

    if (!PuzzleAssetResolver.spritesEnabled) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(width: size, height: size, child: fallback),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  final PuzzleCharacter character;
  final CharacterPose pose;
  final Color color;
  final double size;

  const _FallbackAvatar({
    required this.character,
    required this.pose,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final initial = character.name.isEmpty
        ? '?'
        : character.name[0].toUpperCase();

    return ColoredBox(
      color: color,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            initial,
            style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Icon(
              pose.fallbackIcon,
              size: size * 0.28,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
