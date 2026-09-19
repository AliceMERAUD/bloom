import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';

class TaskFormScreen extends StatefulWidget {
  final BloomTask? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskCategory _category = TaskCategory.other;
  TaskPriority _priority = TaskPriority.normal;
  TaskRecurrence _recurrence = TaskRecurrence.none;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _reminderEnabled = false;
  bool _saving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _category = task.category;
      _priority = task.priority;
      _recurrence = task.recurrence;
      _dueDate = task.dueDate;
      _dueTime = task.dueTime;
      _reminderEnabled = task.reminderEnabled;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre est obligatoire.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        final existing = widget.task!;
        await TaskService.updateTask(
          existing.copyWith(
            title: title,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            clearDescription: _descriptionController.text.trim().isEmpty,
            category: _category,
            priority: _priority,
            recurrence: _recurrence,
            dueDate: _dueDate,
            clearDueDate: _dueDate == null,
            dueTime: _dueTime,
            clearDueTime: _dueTime == null,
            reminderEnabled: _reminderEnabled && _dueDate != null,
          ),
        );
      } else {
        await TaskService.addTask(
          title: title,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          category: _category,
          priority: _priority,
          recurrence: _recurrence,
          dueDate: _dueDate,
          dueTime: _dueTime,
          reminderEnabled: _reminderEnabled && _dueDate != null,
        );
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la tâche'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await TaskService.deleteTask(widget.task!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _toggleComplete() async {
    final task = widget.task!;
    if (task.completed) {
      await TaskService.reopenTask(task.id);
    } else {
      await TaskService.completeTask(task.id);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la tâche' : 'Nouvelle tâche'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Supprimer',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Titre',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description (optionnel)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Catégorie', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskCategory.values.map((c) {
              return FilterChip(
                avatar: Icon(c.icon, size: 16),
                label: Text(c.label),
                selected: _category == c,
                onSelected: (_) => setState(() => _category = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text('Priorité', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<TaskPriority>(
            segments: TaskPriority.values
                .map(
                  (p) => ButtonSegment(value: p, label: Text(p.label)),
                )
                .toList(),
            selected: {_priority},
            onSelectionChanged: (s) => setState(() => _priority = s.first),
          ),
          const SizedBox(height: 12),
          Text('Récurrence', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<TaskRecurrence>(
            segments: TaskRecurrence.values
                .map(
                  (r) => ButtonSegment(value: r, label: Text(r.label)),
                )
                .toList(),
            selected: {_recurrence},
            onSelectionChanged: (s) => setState(() => _recurrence = s.first),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Échéance'),
            subtitle: Text(
              _dueDate == null
                  ? 'Aucune'
                  : '${_dueDate!.day.toString().padLeft(2, '0')}/'
                      '${_dueDate!.month.toString().padLeft(2, '0')}/'
                      '${_dueDate!.year}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_dueDate != null)
                  IconButton(
                    tooltip: 'Effacer',
                    onPressed: () => setState(() {
                      _dueDate = null;
                      _dueTime = null;
                      _reminderEnabled = false;
                    }),
                    icon: const Icon(Icons.clear),
                  ),
                IconButton(
                  tooltip: 'Choisir une date',
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                ),
              ],
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            enabled: _dueDate != null,
            title: const Text('Heure'),
            subtitle: Text(
              _dueTime == null
                  ? 'Aucune'
                  : '${_dueTime!.hour.toString().padLeft(2, '0')}:'
                      '${_dueTime!.minute.toString().padLeft(2, '0')}',
            ),
            trailing: IconButton(
              tooltip: 'Choisir une heure',
              onPressed: _dueDate == null ? null : _pickTime,
              icon: const Icon(Icons.schedule),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rappel local'),
            subtitle: Text(
              _dueDate == null
                  ? 'Choisis d’abord une échéance'
                  : 'Notification à l’échéance',
            ),
            value: _reminderEnabled && _dueDate != null,
            onChanged: _dueDate == null
                ? null
                : (v) => setState(() => _reminderEnabled = v),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_isEditing ? 'Enregistrer' : 'Créer'),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _toggleComplete,
              child: Text(
                widget.task!.completed ? 'Réouvrir' : 'Marquer terminée',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
