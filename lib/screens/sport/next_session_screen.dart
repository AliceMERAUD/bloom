import 'package:flutter/material.dart';

import '../../models/workout_session_plan.dart';
import '../../services/workout_session_plan_service.dart';
import '../../services/exercise_service.dart';
import 'workout_screen.dart';

class NextSessionScreen extends StatefulWidget {
  const NextSessionScreen({super.key});

  @override
  State<NextSessionScreen> createState() => _NextSessionScreenState();
}

class _NextSessionScreenState extends State<NextSessionScreen> {
  WorkoutSessionPlan? sessionPlan;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final result =
        await WorkoutSessionPlanService.generateNextSession();

    if (!mounted) return;

    setState(() {
      sessionPlan = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma prochaine séance'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final plan = sessionPlan!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan.reason,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${plan.totalExercises} exercices • '
                  '${plan.totalSets} séries',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Programme',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        ...plan.exercises.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final exercise = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text(
                  _exerciseName(exercise.exerciseId),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${exercise.sets} séries × '
                  '${exercise.repetitions} reps',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                    builder: (_) => WorkoutScreen(
                        plans: plan.exercises,
                    ),
                    ),
                );
                },
            icon: const Icon(Icons.play_arrow),
            label: const Text(
              'Commencer la séance',
              style: TextStyle(fontSize: 17),
            ),
          ),
        ),
      ],
    );
  }

  String _exerciseName(String id) {
    final exercises = ExerciseService.getAll();

    for (final exercise in exercises) {
        if (exercise.id == id) {
        return exercise.name;
        }
    }

    return id;
    }
}