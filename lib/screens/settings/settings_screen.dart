import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/app_settings.dart';
import '../../services/data_export_service.dart';
import '../../services/reminder_service.dart';
import '../../services/settings_service.dart';
import '../../services/storage_service.dart';
import '../../services/task_service.dart';
import '../../services/workout_session_service.dart';
import '../../widgets/common/bloom_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings get _settings => SettingsService.current;

  Future<void> _update(AppSettings Function(AppSettings) fn) async {
    await SettingsService.update(fn);
    await TaskService.rescheduleAllReminders(SettingsService.current);
    if (mounted) setState(() {});
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final ok = await ReminderService.requestPermission();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permission refusée. Tu peux l’activer dans les réglages Android.',
            ),
          ),
        );
      }
    }
    await _update((s) => s.copyWith(notificationsEnabled: value));
  }

  Future<void> _pickTime() async {
    final initial = TimeOfDay(
      hour: _settings.reminderHour,
      minute: _settings.reminderMinute,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    await _update(
      (s) => s.copyWith(
        reminderHour: picked.hour,
        reminderMinute: picked.minute,
      ),
    );
  }

  Future<void> _export() async {
    try {
      final json = DataExportService.exportJson();
      final dir = await getApplicationDocumentsDirectory();
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${dir.path}/bloom_export_$stamp.json');
      await file.writeAsString(json);
      await Clipboard.setData(ClipboardData(text: json));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Export enregistré et copié dans le presse-papiers.\n${file.path}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export impossible : $e')),
      );
    }
  }

  Future<void> _import() async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importer des données'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Colle le JSON d’un export Bloom. '
                'Cela remplacera toutes tes données actuelles.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '{ "version": 1, ... }',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Remplacer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (raw == null || raw.isEmpty) return;

    try {
      await DataExportService.importAndReplace(raw);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Données importées.')),
      );
    } on DataExportException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import impossible : $e')),
      );
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer toutes mes données'),
        content: const Text(
          'Action irréversible. Sport, Bien-être, Puzzle et Tasks seront effacés. '
          'Les préférences (thème, rappels) sont conservées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    for (final task in TaskService.getTasks()) {
      if (task.reminderId != null) {
        await ReminderService.cancelId(task.reminderId!);
      }
    }
    await StorageService.clearAllUserData(keepSettings: true);
    WorkoutSessionService.resetForTesting();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Données supprimées.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BloomSection(
            title: 'Notifications',
            subtitle: 'Rappels locaux sur cet appareil uniquement',
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Activer les rappels'),
                  value: settings.notificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
                SwitchListTile(
                  title: const Text('Sport'),
                  value: settings.sportReminders,
                  onChanged: settings.notificationsEnabled
                      ? (v) => _update((s) => s.copyWith(sportReminders: v))
                      : null,
                ),
                SwitchListTile(
                  title: const Text('Bien-être'),
                  value: settings.wellbeingReminders,
                  onChanged: settings.notificationsEnabled
                      ? (v) =>
                          _update((s) => s.copyWith(wellbeingReminders: v))
                      : null,
                ),
                SwitchListTile(
                  title: const Text('Puzzle'),
                  value: settings.puzzleReminders,
                  onChanged: settings.notificationsEnabled
                      ? (v) => _update((s) => s.copyWith(puzzleReminders: v))
                      : null,
                ),
                ListTile(
                  title: const Text('Heure du rappel'),
                  subtitle: Text(settings.reminderTimeLabel),
                  trailing: const Icon(Icons.schedule),
                  enabled: settings.notificationsEnabled,
                  onTap:
                      settings.notificationsEnabled ? _pickTime : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          BloomSection(
            title: 'Apparence',
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Clair'),
                  icon: Icon(Icons.light_mode, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Sombre'),
                  icon: Icon(Icons.dark_mode, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Système'),
                  icon: Icon(Icons.brightness_auto, size: 16),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (selected) {
                _update((s) => s.copyWith(themeMode: selected.first));
              },
            ),
          ),
          const SizedBox(height: 24),
          BloomSection(
            title: 'Données',
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Exporter mes données'),
                  subtitle: const Text('Fichier JSON local + presse-papiers'),
                  onTap: _export,
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Importer des données'),
                  subtitle: const Text('Coller un export JSON (remplace tout)'),
                  onTap: _import,
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: const Text('Supprimer toutes mes données'),
                  onTap: _deleteAll,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          BloomSection(
            title: 'À propos',
            child: BloomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bloom',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Version 1.0.0'),
                  const SizedBox(height: 8),
                  Text(
                    'Sport, bien-être et puzzles — données locales sur ton téléphone.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
