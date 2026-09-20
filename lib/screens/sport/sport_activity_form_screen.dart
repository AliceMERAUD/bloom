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
  final _notifMessageController = TextEditingController();
  final _bagMessageController = TextEditingController();
  String _iconName = 'sports';
  bool _notificationEnabled = true;
  int _minutesBefore = 30;
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
      _notificationEnabled = activity.notificationEnabled;
      _minutesBefore = activity.notificationMinutesBefore;
      _notifMessageController.text = activity.notificationMessage ?? '';
      _bagMessageController.text = activity.notificationBagMessage ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _notifMessageController.dispose();
    _bagMessageController.dispose();
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
      final notifMsg = _notifMessageController.text.trim();
      final bagMsg = _bagMessageController.text.trim();
      if (_isEditing) {
        await SportActivityService.update(
          widget.activity!.copyWith(
            name: name,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            clearDescription: _descriptionController.text.trim().isEmpty,
            iconName: _iconName,
            notificationEnabled: _notificationEnabled,
            notificationMinutesBefore: _minutesBefore,
            notificationMessage: notifMsg.isEmpty ? null : notifMsg,
            clearNotificationMessage: notifMsg.isEmpty,
            notificationBagMessage: bagMsg.isEmpty ? null : bagMsg,
            clearNotificationBagMessage: bagMsg.isEmpty,
          ),
        );
      } else {
        final created = await SportActivityService.add(
          name: name,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          iconName: _iconName,
        );
        await SportActivityService.update(
          created.copyWith(
            notificationEnabled: _notificationEnabled,
            notificationMinutesBefore: _minutesBefore,
            notificationMessage: notifMsg.isEmpty ? null : notifMsg,
            clearNotificationMessage: notifMsg.isEmpty,
            notificationBagMessage: bagMsg.isEmpty ? null : bagMsg,
            clearNotificationBagMessage: bagMsg.isEmpty,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = SportActivity(
      id: 'preview',
      name: _nameController.text.trim().isEmpty
          ? 'Mon sport'
          : _nameController.text.trim(),
      iconName: _iconName,
      createdAt: DateTime.now(),
      notificationEnabled: _notificationEnabled,
      notificationMessage: _notifMessageController.text.trim().isEmpty
          ? null
          : _notifMessageController.text.trim(),
      notificationBagMessage: _bagMessageController.text.trim().isEmpty
          ? null
          : _bagMessageController.text.trim(),
      notificationMinutesBefore: _minutesBefore,
    );

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
            onChanged: (_) => setState(() {}),
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
          Text(
            'Notification',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Messages et délai propres à ce sport',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Activer les rappels pour ce sport'),
            value: _notificationEnabled,
            onChanged: (v) => setState(() => _notificationEnabled = v),
          ),
          Text('Délai', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: kSportReminderLeadChoices.map((mins) {
              final label = mins == 0 ? 'À l’heure' : '$mins min avant';
              return ChoiceChip(
                label: Text(label),
                selected: _minutesBefore == mins,
                onSelected: _notificationEnabled
                    ? (_) => setState(() => _minutesBefore = mins)
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notifMessageController,
            enabled: _notificationEnabled,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Message personnalisé (optionnel)',
              hintText: 'Laisse vide pour le message par défaut',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bagMessageController,
            enabled: _notificationEnabled,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Rappel sac (optionnel)',
              hintText: 'ex. Pense à ton maillot !',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(
                  alpha: 0.45,
                ),
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Aperçu'),
              subtitle: Text(
                preview.resolvedNotificationBody(includeBagHint: true),
              ),
            ),
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
