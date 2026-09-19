import 'package:flutter/material.dart';

import '../../models/puzzle/puzzle.dart';

class PuzzleConstraintFeedback extends StatelessWidget {
  final Puzzle puzzle;
  final PuzzleValidationResult? result;

  const PuzzleConstraintFeedback({
    super.key,
    required this.puzzle,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: puzzle.constraints.map((constraint) {
        final check = result?.checks
            .where((c) => c.constraint.id == constraint.id)
            .firstOrNull;

        late final String status;
        late final IconData icon;
        late final Color color;

        if (check == null) {
          status = 'À vérifier';
          icon = Icons.circle_outlined;
          color = Colors.grey;
        } else if (!check.evaluable) {
          status = 'Incomplet';
          icon = Icons.help_outline;
          color = Colors.grey;
        } else if (check.satisfied) {
          status = 'Respectée';
          icon = Icons.check_circle;
          color = Colors.green.shade700;
        } else {
          status = 'Non respectée';
          icon = Icons.cancel;
          color = Colors.red.shade700;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            dense: true,
            leading: Icon(icon, color: color),
            title: Text(
              _describe(constraint.description),
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _describe(String raw) {
    var text = raw;
    for (final character in puzzle.characters) {
      text = text.replaceAll(character.id, character.name);
    }
    return text;
  }
}
