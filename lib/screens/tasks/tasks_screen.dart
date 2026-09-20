import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../widgets/common/bloom_task_tile.dart';
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

  bool get _shouldGroup =>
      _filter == _TaskFilter.pending || _filter == _TaskFilter.all;

  List<Widget> _buildGroupedList(List<BloomTask> tasks) {
    final pending = tasks.where((t) => t.isPending).toList();
    final completed = tasks.where((t) => t.completed).toList();

    final overdue = pending.where((t) => t.isOverdue).toList();
    final today = pending
        .where((t) => t.isDueToday && !t.isOverdue)
        .toList();
    final upcoming = pending.where((t) {
      if (t.dueDate == null || t.isOverdue || t.isDueToday) return false;
      final now = DateTime.now();
      final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      final todayDate = DateTime(now.year, now.month, now.day);
      return due.isAfter(todayDate);
    }).toList();
    final noDue = pending.where((t) => t.dueDate == null).toList();

    final sections = <Widget>[];

    void addSection(String title, List<BloomTask> items, {Color? accent}) {
      if (items.isEmpty) return;
      sections.add(
        Padding(
          padding: EdgeInsets.only(top: sections.isEmpty ? 0 : 8, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accent ?? Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      );
      for (final task in items) {
        sections.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: BloomTaskTile(
              task: task,
              onOpen: () => _openForm(task: task),
              onToggle: () => _toggleComplete(task),
            ),
          ),
        );
      }
    }

    addSection(
      'En retard',
      overdue,
      accent: Theme.of(context).colorScheme.error,
    );
    addSection('Aujourd’hui', today);
    addSection('À venir', upcoming);
    addSection('Sans échéance', noDue);

    if (_filter == _TaskFilter.all && completed.isNotEmpty) {
      addSection('Terminées', completed);
    }

    return sections;
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
              'Les petites choses à faire 🌱',
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
            else if (_shouldGroup)
              ..._buildGroupedList(tasks)
            else
              ...tasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BloomTaskTile(
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
