import 'package:flutter/material.dart';

import '../../models/sport_activity.dart';
import '../../services/sport_activity_service.dart';
import 'sport_activity_form_screen.dart';

class SportActivitiesScreen extends StatefulWidget {
  const SportActivitiesScreen({super.key});

  @override
  State<SportActivitiesScreen> createState() => _SportActivitiesScreenState();
}

class _SportActivitiesScreenState extends State<SportActivitiesScreen> {
  List<SportActivity> _activities = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _activities = SportActivityService.getAll();
    });
  }

  Future<void> _openForm({SportActivity? activity}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SportActivityFormScreen(activity: activity),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _confirmDelete(SportActivity activity) async {
    if (activity.builtin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de supprimer un sport intégré.'),
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le sport'),
        content: Text('Supprimer « ${activity.name} » ?'),
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

    try {
      await SportActivityService.delete(activity.id);
      if (mounted) _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes sports'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: _activities.isEmpty
          ? const Center(child: Text('Aucun sport pour le moment.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final activity = _activities[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: activity.color.withValues(alpha: 0.2),
                      child: Icon(activity.icon, color: activity.color),
                    ),
                    title: Text(activity.name),
                    subtitle: Text(
                      activity.builtin
                          ? 'Sport intégré'
                          : (activity.description ?? 'Sport personnalisé'),
                    ),
                    trailing: activity.builtin
                        ? null
                        : IconButton(
                            tooltip: 'Supprimer',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(activity),
                          ),
                    onTap: activity.builtin
                        ? null
                        : () => _openForm(activity: activity),
                  ),
                );
              },
            ),
    );
  }
}
