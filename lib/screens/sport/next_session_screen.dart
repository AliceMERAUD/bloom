import 'package:flutter/material.dart';

import '../../models/exercise.dart';
import '../../models/workout_session_plan.dart';
import '../../services/exercise_service.dart';
import '../../services/workout_session_plan_service.dart';
import '../../services/workout_session_service.dart';
import 'workout_screen.dart';

class NextSessionScreen extends StatefulWidget {
  const NextSessionScreen({super.key});

  @override
  State<NextSessionScreen> createState() => _NextSessionScreenState();
}

class _NextSessionScreenState extends State<NextSessionScreen> {
  WorkoutSessionPlan? sessionPlan;
  bool loading = true;
  late final List<Exercise> catalogue;
  late final Set<String> selectedIds;

  @override
  void initState() {
    super.initState();
    catalogue = ExerciseService.getAll();
    selectedIds = catalogue.map((exercise) => exercise.id).toSet();
    _loadSession();
  }

  Future<void> _loadSession() async {
    setState(() {
      loading = true;
    });

    final orderedIds = catalogue
        .where((exercise) => selectedIds.contains(exercise.id))
        .map((exercise) => exercise.id)
        .toList();

    final result = await WorkoutSessionPlanService.generateNextSession(
      exerciseIds: orderedIds,
    );

    if (!mounted) return;

    setState(() {
      sessionPlan = result;
      loading = false;
    });
  }

  void _toggleExercise(String id, bool selected) {
    setState(() {
      if (selected) {
        selectedIds.add(id);
      } else {
        selectedIds.remove(id);
      }
    });
    _loadSession();
  }

  Future<void> _startGuidedSession() async {
    final plan = sessionPlan;
    if (plan == null || plan.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionne au moins un exercice.'),
        ),
      );
      return;
    }

    await WorkoutSessionService.ensureActiveSession();

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutScreen(
          plans: plan.exercises,
        ),
      ),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma prochaine séance'),
      ),
      body: loading && sessionPlan == null
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final plan = sessionPlan;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Exercices de la séance',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Décoche les exercices que tu ne veux pas inclure.',
        ),
        const SizedBox(height: 12),
        ...catalogue.map((exercise) {
          return CheckboxListTile(
            value: selectedIds.contains(exercise.id),
            title: Text(exercise.name),
            subtitle: Text(exercise.description ?? ''),
            onChanged: (value) {
              _toggleExercise(exercise.id, value ?? false);
            },
          );
        }),
        const SizedBox(height: 16),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (plan == null || plan.exercises.isEmpty)
          const Text(
            'Sélectionne au moins un exercice pour générer un plan.',
          )
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, size: 32),
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
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${plan.totalExercises} exercices • '
                    '${plan.totalSets} séries',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
          ...plan.exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercisePlan = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text(
                  _exerciseName(exercisePlan.exerciseId),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${exercisePlan.sets} séries × '
                  '${exercisePlan.repetitions} reps',
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _startGuidedSession,
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'Commencer la séance',
                style: TextStyle(fontSize: 17),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _exerciseName(String id) {
    for (final exercise in catalogue) {
      if (exercise.id == id) {
        return exercise.name;
      }
    }
    return id;
  }
}
