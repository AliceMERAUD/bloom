import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/wellbeing_entry.dart';
import '../../models/wellbeing_enums.dart';
import '../../services/wellbeing_service.dart';
import '../../widgets/common/bloom_widgets.dart';
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
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucune journée enregistrée pour le moment.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BloomCard(
                    accent: BloomTheme.wellbeing,
                    onTap: () => _openEntry(entry),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📅 ${_formatDate(entry.date)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('🌸 Humeur : ${entry.mood?.label ?? '—'}'),
                        Text('⚡ Énergie : ${entry.energy?.label ?? '—'}'),
                        Text('🩸 Saignement : ${entry.bleeding.label}'),
                        if (entry.pain != Pain.none)
                          Text('Douleur : ${entry.pain.label}'),
                        if (entry.symptoms.isNotEmpty)
                          Text(
                            'Symptômes : ${entry.symptoms.map((s) => s.label).join(', ')}',
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    final months = const [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}
