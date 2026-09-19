import 'package:flutter/material.dart';

import '../../models/wellbeing_entry.dart';
import '../../models/wellbeing_enums.dart';
import '../../services/wellbeing_service.dart';
import 'wellbeing_entry_screen.dart';
import 'wellbeing_history_screen.dart';
import 'wellbeing_insights_screen.dart';

class WellbeingScreen extends StatefulWidget {
  const WellbeingScreen({super.key});

  @override
  State<WellbeingScreen> createState() => _WellbeingScreenState();
}

class _WellbeingScreenState extends State<WellbeingScreen> {
  WellbeingEntry? todayEntry;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      todayEntry = WellbeingService.getEntryForDate(DateTime.now());
    });
  }

  Future<void> _openEditor({DateTime? date}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WellbeingEntryScreen(
          initialDate: date ?? DateTime.now(),
        ),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _startPeriod() async {
    await WellbeingService.startPeriod(DateTime.now());
    if (!mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Début des règles enregistré.')),
    );
  }

  Future<void> _endPeriod() async {
    await WellbeingService.endPeriod(DateTime.now());
    if (!mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fin des règles enregistrée.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = todayEntry;
    final cycleLabel = WellbeingService.cycleStatusLabel();
    final hasOpenPeriod = WellbeingService.getCurrentPeriod() != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bien-être'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'Aperçu',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WellbeingInsightsScreen(),
                ),
              );
              if (mounted) _reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WellbeingHistoryScreen(),
                ),
              );
              if (mounted) _reload();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Aujourd’hui',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(DateTime.now()),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cycleLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!hasOpenPeriod)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _startPeriod,
                            child: const Text('Début des règles'),
                          ),
                        ),
                      if (hasOpenPeriod)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _endPeriod,
                            child: const Text('Fin des règles'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: entry == null
                  ? const Text(
                      'Pas encore de note pour aujourd’hui.\n'
                      'Prends un instant pour consigner ton ressenti.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _summaryRow('Humeur', entry.mood?.label ?? '—'),
                        _summaryRow('Énergie', entry.energy?.label ?? '—'),
                        _summaryRow('Douleur', entry.pain.label),
                        _summaryRow('Saignement', entry.bleeding.label),
                        _summaryRow(
                          'Symptômes',
                          entry.symptoms.isEmpty
                              ? 'Aucun'
                              : entry.symptoms.map((s) => s.label).join(', '),
                        ),
                        if (entry.note != null && entry.note!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              entry.note!,
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: () => _openEditor(),
              icon: Icon(entry == null ? Icons.add : Icons.edit),
              label: Text(
                entry == null ? 'Ajouter ma journée' : 'Modifier ma journée',
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}
