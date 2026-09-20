import 'package:flutter/material.dart';

import '../../models/sport_activity.dart';
import '../../services/sport_activity_service.dart';

class SportActivityFormScreen extends StatefulWidget {
  final SportActivity? activity;

  const SportActivityFormScreen({super.key, this.activity});

  @override
  State<SportActivityFormScreen> createState() =>
      _SportActivityFormScreenState();
}

class _SportActivityFormScreenState extends State<SportActivityFormScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _iconName = 'sports';
  bool _saving = false;

  bool get _isEditing => widget.activity != null;

  @override
  void initState() {
    super.initState();
    final activity = widget.activity;
    if (activity != null) {
      _nameController.text = activity.name;
      _descriptionController.text = activity.description ?? '';
      _iconName = activity.iconName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom est obligatoire.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await SportActivityService.update(
          widget.activity!.copyWith(
            name: name,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            clearDescription: _descriptionController.text.trim().isEmpty,
            iconName: _iconName,
          ),
        );
      } else {
        await SportActivityService.add(
          name: name,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          iconName: _iconName,
        );
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le sport' : 'Nouveau sport'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nom',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (optionnel)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Icône', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kSportIconChoices.map((name) {
              final selected = _iconName == name;
              return InkWell(
                onTap: () => setState(() => _iconName = name),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: selected ? 2 : 1,
                    ),
                    color: selected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12)
                        : null,
                  ),
                  child: Icon(sportIconFromName(name)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_isEditing ? 'Enregistrer' : 'Créer'),
          ),
        ],
      ),
    );
  }
}
