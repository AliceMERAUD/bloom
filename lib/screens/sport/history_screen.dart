import 'package:flutter/material.dart';

import '../../services/exercise_service.dart';
import '../../services/storage_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String formatDate(String? value) {
    if (value == null) {
      return '';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return '';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} à '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sets = StorageService.getWorkoutSets().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
      ),
      body: sets.isEmpty
          ? const Center(
              child: Text(
                'Aucune séance enregistrée pour le moment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sets.length,
              itemBuilder: (context, index) {
                final set = sets[index];

                final exerciseId = set['exerciseId'] as String?;
                final repetitions = set['repetitions'];
                final weight = set['weight'];
                final assistance = set['assistance'];
                final duration = set['durationSeconds'];
                final date = set['date'] as String?;

                final exercise = ExerciseService.getAll().firstWhere(
                  (exercise) => exercise.id == exerciseId,
                  orElse: () => ExerciseService.getAll().first,
                );

                String details = '$repetitions répétitions';

                if (assistance != null) {
                  details += ' • Assistance : $assistance kg';
                }
                if (weight != null) {
                details += ' • Charge : $weight kg';
                }

                if (duration != null) {
                details += ' • $duration secondes';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.fitness_center),
                    ),
                    title: Text(
                      exercise.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '$details\n${formatDate(date)}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}