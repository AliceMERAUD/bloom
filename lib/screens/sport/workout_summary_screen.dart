import 'package:flutter/material.dart';

import '../../services/storage_service.dart';
import '../../services/exercise_service.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final String sessionId;

  const WorkoutSummaryScreen({
    super.key,
    required this.sessionId,
  });

  @override
  State<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState
    extends State<WorkoutSummaryScreen> {
        String getExerciseName(dynamic exerciseId) {
  final exercises = ExerciseService.getAll();

  for (final exercise in exercises) {
    if (exercise.id == exerciseId) {
      return exercise.name;
    }
  }

  return 'Exercice';
}
  bool loading = true;

  List<Map<String, dynamic>> sets = [];

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final result = await StorageService.getSessionSets(
      widget.sessionId,
    );

    if (!mounted) return;

    setState(() {
      sets = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final totalRepetitions = sets.fold<int>(
      0,
      (total, set) =>
          total + ((set['repetitions'] ?? 0) as num).toInt(),
    );

    final exercises = sets
        .map((set) => set['exerciseId'])
        .where((id) => id != null)
        .toSet()
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Séance terminée'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.celebration,
            size: 70,
          ),

          const SizedBox(height: 16),

          const Text(
            'Bravo ! 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${sets.length} séries • '
            '$totalRepetitions répétitions • '
            '$exercises exercices',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          const Text(
            'Séries réalisées',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          ...sets.asMap().entries.map(
            (entry) {
              final index = entry.key + 1;
              final set = entry.value;

              final repetitions =
                  set['repetitions'] ?? 0;

              final weight = set['weight'];
              final assistance = set['assistance'];

              String details =
                  '$repetitions répétitions';

              if (assistance != null) {
                details +=
                    ' • Assistance : $assistance kg';
              }

              if (weight != null) {
                details +=
                    ' • Charge : $weight kg';
              }

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('$index'),
                  ),
                  title: Text(
                    getExerciseName(set['exerciseId']),
                    ),
                  subtitle: Text(details),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Retour au sport'),
          ),
        ],
      ),
    );
  }
}