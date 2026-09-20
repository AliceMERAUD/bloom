import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/sport_activity.dart';
import '../../models/task.dart';
import '../../screens/sport/sport_activity_form_screen.dart';
import '../../screens/sport/sport_bag_checklist_sheet.dart';
import '../../services/sport_activity_service.dart';
import 'bloom_widgets.dart';

/// Shared task row used by Planning and the legacy Tasks screen.
class BloomTaskTile extends StatelessWidget {
  final BloomTask task;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final bool compact;

  const BloomTaskTile({
    super.key,
    required this.task,
    required this.onOpen,
    required this.onToggle,
    this.compact = false,
  });

  String _dueLabel() {
    if (task.completed) return 'Terminé';
    if (task.isOverdue) return 'En retard';
    if (task.dueDate == null) return 'Sans échéance';
    if (task.isDueToday) {
      if (task.dueTime != null) {
        final h = task.dueTime!.hour.toString().padLeft(2, '0');
        final m = task.dueTime!.minute.toString().padLeft(2, '0');
        return 'Aujourd’hui · $h:$m';
      }
      return 'Aujourd’hui';
    }
    final d = task.dueDate!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = task.isOverdue;
    final SportActivity? sport = task.sportId == null
        ? null
        : SportActivityService.getById(task.sportId!);
    final icon = sport?.icon ?? task.category.icon;
    final categoryLabel = sport?.name ?? task.category.label;

    return BloomCard(
      onTap: onOpen,
      elevated: !compact,
      accent: BloomTheme.tasks,
      color: overdue ? scheme.errorContainer.withValues(alpha: 0.35) : null,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: task.completed ? 'Réouvrir' : 'Terminer',
            onPressed: onToggle,
            icon: Icon(
              task.completed ? Icons.check_circle : Icons.circle_outlined,
              color: task.completed ? scheme.primary : scheme.outline,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration:
                        task.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(icon, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$categoryLabel · ${_dueLabel()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: overdue ? scheme.error : null,
                              fontWeight: overdue ? FontWeight.w600 : null,
                            ),
                      ),
                    ),
                  ],
                ),
                if (task.priority == TaskPriority.high) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Priorité haute',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (task.sportId != null) ...[
            IconButton(
              tooltip: 'Voir le sport',
              icon: const Icon(Icons.fitness_center_outlined),
              onPressed: sport == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SportActivityFormScreen(activity: sport),
                        ),
                      );
                    },
            ),
            IconButton(
              tooltip: 'Checklist du sac',
              icon: const Icon(Icons.shopping_bag_outlined),
              onPressed: () => showSportBagChecklistSheet(
                context,
                sportId: task.sportId,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
