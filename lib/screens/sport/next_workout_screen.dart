import 'package:flutter/material.dart';

import '../../models/workout_plan.dart';
import '../../services/exercise_service.dart';
import '../../services/progression_service.dart';
import '../../services/workout_session_service.dart';
import 'workout_screen.dart';

class NextWorkoutScreen extends StatefulWidget {
  final String exerciseId;

  const NextWorkoutScreen({
    super.key,
    required this.exerciseId,
  });

  @override
  State<NextWorkoutScreen> createState() => _NextWorkoutScreenState();
}

class _NextWorkoutScreenState extends State<NextWorkoutScreen> {
  WorkoutPlan? plan;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final result =
        await ProgressionService.generateNextWorkout(
      widget.exerciseId,
    );

    if (!mounted) return;

    setState(() {
      plan = result;
      loading = false;
    });
  }

  String _exerciseName() {
    final exercises = ExerciseService.getAll();

    for (final exercise in exercises) {
      if (exercise.id == widget.exerciseId) {
        return exercise.name;
      }
    }

    return 'Exercice';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prochaine séance'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final currentPlan = plan!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  _exerciseName(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentPlan.reason,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Ta prochaine séance',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        ...List.generate(
          currentPlan.sets,
          (index) => _buildSetCard(
            index + 1,
            currentPlan,
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () async {
              await WorkoutSessionService.ensureActiveSession();

              if (!mounted) return;

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutScreen(
                    plans: [currentPlan],
                  ),
                ),
              );

              if (mounted) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text(
              'Commencer la séance',
              style: TextStyle(
                fontSize: 17,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetCard(
    int number,
    WorkoutPlan plan,
  ) {
    String details = '${plan.repetitions} répétitions';

    if (plan.assistance != null) {
      details +=
          ' • Assistance : '
          '${plan.assistance!.toStringAsFixed(1)} kg';
    }

    if (plan.weight != null) {
      details +=
          ' • Charge : '
          '${plan.weight!.toStringAsFixed(1)} kg';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Text('$number'),
        ),
        title: Text(
          'Série $number',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(details),
        trailing: const Icon(
          Icons.check_circle_outline,
        ),
      ),
    );
  }
}