import 'package:flutter/material.dart';

import '../../models/exercise.dart';
import '../../models/exercise_fields.dart';
import '../../models/workout_set.dart';
import '../../services/workout_session_service.dart';
import 'next_workout_screen.dart';
import 'progress_screen.dart';

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
    final repetitions = ExerciseFields.parseInt(repetitionsController.text);

    if (repetitions == null || repetitions <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entre un nombre de répétitions valide.'),
        ),
      );
      return;
    }

    final fields = ExerciseFields.forType(widget.exercise.type);

    final workoutSet = WorkoutSet(
      exerciseId: widget.exercise.id,
      repetitions: repetitions,
      weight: fields.showWeight
          ? ExerciseFields.parseDecimal(weightController.text)
          : null,
      assistance: fields.showAssistance
          ? ExerciseFields.parseDecimal(assistanceController.text)
          : null,
      durationSeconds: fields.showDuration
          ? ExerciseFields.parseInt(durationController.text)
          : null,
    );

    await WorkoutSessionService.addSet(workoutSet);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Série ajoutée à la séance !'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fields = ExerciseFields.forType(widget.exercise.type);

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
          if (fields.showRepetitions) ...[
            TextField(
              controller: repetitionsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Répétitions',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (fields.showAssistance) ...[
            TextField(
              controller: assistanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: fields.assistanceLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (fields.showWeight) ...[
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: fields.weightLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (fields.showDuration) ...[
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: fields.durationLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 14),
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
