import 'package:flutter/material.dart';

import '../../models/wellbeing_enums.dart';
import '../../services/wellbeing_service.dart';

class WellbeingInsightsScreen extends StatelessWidget {
  const WellbeingInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = WellbeingService.getAllEntries();
    final recent = entries.take(14).toList().reversed.toList();
    final periods = WellbeingService.getPeriods();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aperçu'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Humeur (14 derniers jours)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _SimpleBarChart(
            values: recent
                .where((e) => e.mood != null)
                .map((e) => e.mood!.score.toDouble())
                .toList(),
            maxValue: 5,
            emptyMessage: 'Pas encore assez de données d’humeur.',
          ),
          const SizedBox(height: 28),
          const Text(
            'Énergie (14 derniers jours)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _SimpleBarChart(
            values: recent
                .where((e) => e.energy != null)
                .map((e) => e.energy!.score.toDouble())
                .toList(),
            maxValue: 5,
            emptyMessage: 'Pas encore assez de données d’énergie.',
          ),
          const SizedBox(height: 28),
          const Text(
            'Périodes enregistrées',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (periods.isEmpty)
            const Text('Aucune période marquée pour le moment.')
          else
            ...periods.take(8).map((period) {
              final endLabel = period.end == null
                  ? 'en cours'
                  : _formatDate(period.end!);
              final duration = period.durationDays;
              return Card(
                child: ListTile(
                  title: Text(
                    '${_formatDate(period.start)} → $endLabel',
                  ),
                  subtitle: Text(
                    duration == null
                        ? 'Durée : en cours'
                        : 'Durée : $duration jour${duration > 1 ? 's' : ''}',
                  ),
                ),
              );
            }),
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

class _SimpleBarChart extends StatelessWidget {
  final List<double> values;
  final double maxValue;
  final String emptyMessage;

  const _SimpleBarChart({
    required this.values,
    required this.maxValue,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Text(emptyMessage);
    }

    final color = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((value) {
          final height = (value / maxValue).clamp(0.05, 1.0) * 100;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
