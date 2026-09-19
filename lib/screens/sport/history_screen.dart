import 'package:flutter/material.dart';

import '../../models/workout_set.dart';
import '../../services/exercise_service.dart';
import '../../services/storage_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }

    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} à '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
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
                final WorkoutSet set = sets[index];

                final exercise = ExerciseService.getAll().firstWhere(
                  (exercise) => exercise.id == set.exerciseId,
                  orElse: () => ExerciseService.getAll().first,
                );

                String details = '${set.repetitions} répétitions';

                if (set.assistance != null) {
                  details += ' • Assistance : ${set.assistance} kg';
                }
                if (set.weight != null) {
                  details += ' • Charge : ${set.weight} kg';
                }

                if (set.durationSeconds != null) {
                  details += ' • ${set.durationSeconds} secondes';
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
                      '$details\n${formatDate(set.date)}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
