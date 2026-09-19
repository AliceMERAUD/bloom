import 'package:flutter/material.dart';

import '../../models/wellbeing_entry.dart';
import '../../models/wellbeing_enums.dart';
import '../../services/wellbeing_service.dart';
import 'wellbeing_entry_screen.dart';

class WellbeingHistoryScreen extends StatefulWidget {
  const WellbeingHistoryScreen({super.key});

  @override
  State<WellbeingHistoryScreen> createState() => _WellbeingHistoryScreenState();
}

class _WellbeingHistoryScreenState extends State<WellbeingHistoryScreen> {
  List<WellbeingEntry> entries = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      entries = WellbeingService.getAllEntries();
    });
  }

  Future<void> _openEntry(WellbeingEntry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WellbeingEntryScreen(
          initialDate: entry.date,
          existing: entry,
        ),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique bien-être'),
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text(
                'Aucune journée enregistrée pour le moment.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      _formatDate(entry.date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Humeur : ${entry.mood?.label ?? '—'} • '
                      'Énergie : ${entry.energy?.label ?? '—'}\n'
                      'Douleur : ${entry.pain.label} • '
                      'Cycle : ${_cycleLabel(entry)}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openEntry(entry),
                  ),
                );
              },
            ),
    );
  }

  String _cycleLabel(WellbeingEntry entry) {
    switch (entry.periodMarker) {
      case PeriodMarker.start:
        return 'Début';
      case PeriodMarker.end:
        return 'Fin';
      case PeriodMarker.none:
        return entry.bleeding.isPresent ? entry.bleeding.label : '—';
    }
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}
