import 'package:flutter/material.dart';

import '../../services/workout_session_service.dart';
import '../../models/exercise.dart';
import '../../models/workout_set.dart';
import 'progress_screen.dart';
import 'next_workout_screen.dart';

class ExerciseScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseScreen({
    super.key,
    required this.exercise,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final repetitionsController = TextEditingController();
  final weightController = TextEditingController();
  final assistanceController = TextEditingController();
  final durationController = TextEditingController();

  @override
  void dispose() {
    repetitionsController.dispose();
    weightController.dispose();
    assistanceController.dispose();
    durationController.dispose();
    super.dispose();
  }

  Future<void> saveSet() async {
  final repetitions = int.tryParse(repetitionsController.text);

  if (repetitions == null || repetitions <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entre un nombre de répétitions valide.'),
      ),
    );
    return;
  }

  final workoutSet = WorkoutSet(
    exerciseId: widget.exercise.id,
    repetitions: repetitions,
    weight: double.tryParse(weightController.text),
    assistance: double.tryParse(assistanceController.text),
    durationSeconds: int.tryParse(durationController.text),
    );

    await WorkoutSessionService.addSet(workoutSet);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
        content: Text('Série ajoutée à la séance ! '),
    ),
    );
}

  @override
  Widget build(BuildContext context) {
    final type = widget.exercise.type;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.exercise.name,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
            ),
            ),
        actions: [
            IconButton(
                icon: const Icon(Icons.show_chart),
                tooltip: 'Progression',
                onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                    builder: (_) => ProgressScreen(
                        exerciseId: widget.exercise.id,
                    ),
                    ),
                );
                },
            ),
            IconButton(
                icon: const Icon(Icons.auto_awesome),
                tooltip: 'Prochaine séance',
                onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                    builder: (_) => NextWorkoutScreen(
                        exerciseId: widget.exercise.id,
                    ),
                    ),
                );
                },
            ),
            ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.exercise.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          

          const SizedBox(height: 20),

            Card(
            child: ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text(
                'Prochaine séance',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                ),
                ),
                subtitle: const Text(
                'Séance adaptée à ta progression',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                    builder: (_) => NextWorkoutScreen(
                        exerciseId: widget.exercise.id,
                    ),
                    ),
                );
                },
            ),
            ),

            const SizedBox(height: 20),

          TextField(
            controller: repetitionsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Répétitions',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          if (type == ExerciseType.assisted) ...[
            TextField(
              controller: assistanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Assistance (kg)',
                border: OutlineInputBorder(),
              ),
            ),
          ],

          if (type == ExerciseType.weighted) ...[
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Charge supplémentaire (kg)',
                border: OutlineInputBorder(),
              ),
            ),
          ],

          if (type == ExerciseType.negative ||
              type == ExerciseType.isometric) ...[
            const SizedBox(height: 16),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Durée (secondes)',
                border: OutlineInputBorder(),
              ),
            ),
          ],

          const SizedBox(height: 30),

          SizedBox(
            height: 55,
            child: FilledButton.icon(
              onPressed: saveSet,
              icon: const Icon(Icons.save),
              label: const Text(
                'Enregistrer la série',
                style: TextStyle(fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}