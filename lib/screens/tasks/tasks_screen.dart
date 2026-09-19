import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../widgets/common/bloom_widgets.dart';
import 'task_form_screen.dart';

enum _TaskFilter { all, pending, completed }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _TaskFilter _filter = _TaskFilter.pending;
  TaskCategory? _categoryFilter;

  void _reload() => setState(() {});

  Future<void> _openForm({BloomTask? task}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(task: task),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _toggleComplete(BloomTask task) async {
    if (task.completed) {
      await TaskService.reopenTask(task.id);
    } else {
      await TaskService.completeTask(task.id);
    }
    if (mounted) _reload();
  }

  List<BloomTask> get _visible {
    var list = TaskService.getTasks();
    switch (_filter) {
      case _TaskFilter.pending:
        list = list.where((t) => t.isPending).toList();
      case _TaskFilter.completed:
        list = list.where((t) => t.completed).toList();
      case _TaskFilter.all:
        break;
    }
    if (_categoryFilter != null) {
      list = list.where((t) => t.category == _categoryFilter).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final pending = TaskService.getPendingTasks().length;
    final doneToday = TaskService.completedTodayCount();
    final tasks = _visible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Ajouter',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          children: [
            Text(
              'Les petites choses à faire',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            BloomCard(
              child: Text(
                '$pending à faire · $doneToday terminée(s) aujourd’hui',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (pending == 0 && TaskService.getTasks().isNotEmpty) ...[
              const SizedBox(height: 12),
              BloomCard(
                child: Text(
                  doneToday > 0
                      ? '✨ $doneToday terminée(s) aujourd’hui — Bravo, tout est fait !'
                      : 'Bravo, tout est fait !',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Toutes'),
                  selected: _filter == _TaskFilter.all,
                  onSelected: (_) =>
                      setState(() => _filter = _TaskFilter.all),
                ),
                ChoiceChip(
                  label: const Text('À faire'),
                  selected: _filter == _TaskFilter.pending,
                  onSelected: (_) =>
                      setState(() => _filter = _TaskFilter.pending),
                ),
                ChoiceChip(
                  label: const Text('Terminées'),
                  selected: _filter == _TaskFilter.completed,
                  onSelected: (_) =>
                      setState(() => _filter = _TaskFilter.completed),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: PopupMenuButton<String>(
                tooltip: 'Filtrer par catégorie',
                onSelected: (value) => setState(() {
                  _categoryFilter =
                      value == 'all' ? null : TaskCategoryX.fromName(value);
                }),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'all',
                    child: Text('Toutes catégories'),
                  ),
                  ...TaskCategory.values.map(
                    (c) => PopupMenuItem(
                      value: c.name,
                      child: Row(
                        children: [
                          Icon(c.icon, size: 18),
                          const SizedBox(width: 8),
                          Text(c.label),
                        ],
                      ),
                    ),
                  ),
                ],
                child: Chip(
                  avatar: Icon(
                    _categoryFilter?.icon ?? Icons.filter_list,
                    size: 16,
                  ),
                  label: Text(_categoryFilter?.label ?? 'Catégorie'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (tasks.isEmpty)
              BloomEmptyState(
                icon: Icons.spa_outlined,
                message: _filter == _TaskFilter.completed
                    ? 'Aucune tâche terminée pour le moment'
                    : 'Rien à faire pour le moment',
                actionLabel: 'Créer une tâche',
                onAction: () => _openForm(),
              )
            else
              ...tasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TaskTile(
                    task: task,
                    onOpen: () => _openForm(task: task),
                    onToggle: () => _toggleComplete(task),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final BloomTask task;
  final VoidCallback onOpen;
  final VoidCallback onToggle;

  const _TaskTile({
    required this.task,
    required this.onOpen,
    required this.onToggle,
  });

  String _dueLabel() {
    if (task.completed) {
      return 'Terminé';
    }
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

    return BloomCard(
      onTap: onOpen,
      color: overdue
          ? scheme.errorContainer.withValues(alpha: 0.35)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: task.completed ? 'Réouvrir' : 'Terminer',
            onPressed: onToggle,
            icon: Icon(
              task.completed
                  ? Icons.check_circle
                  : Icons.circle_outlined,
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
                    Icon(task.category.icon, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${task.category.label} · ${_dueLabel()}',
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
        ],
      ),
    );
  }
}
