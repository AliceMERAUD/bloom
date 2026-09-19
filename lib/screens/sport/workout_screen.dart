import 'package:flutter/material.dart';

import '../../models/exercise.dart';
import '../../models/workout_plan.dart';
import '../../models/workout_set.dart';
import '../../services/workout_session_service.dart';
import '../../services/exercise_service.dart';

class WorkoutScreen extends StatefulWidget {
  final List<WorkoutPlan> plans;

  const WorkoutScreen({
    super.key,
    required this.plans,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  int currentExercise = 0;
  int currentSet = 0;
  bool saving = false;

  late final TextEditingController repetitionsController;
  late final TextEditingController weightController;
  late final TextEditingController assistanceController;
  late final TextEditingController durationController;

  WorkoutPlan get plan => widget.plans[currentExercise];

  @override
  void initState() {
    super.initState();

    repetitionsController = TextEditingController();
    weightController = TextEditingController();
    assistanceController = TextEditingController();
    durationController = TextEditingController();

    _loadPlanValues();
  }

  void _loadPlanValues() {
    repetitionsController.text = plan.repetitions.toString();
    weightController.text = plan.weight?.toString() ?? '';
    assistanceController.text = plan.assistance?.toString() ?? '';
    durationController.clear();
  }

  @override
  void dispose() {
    repetitionsController.dispose();
    weightController.dispose();
    assistanceController.dispose();
    durationController.dispose();
    super.dispose();
  }

  Future<void> _validateSet() async {
    if (saving) return;

    final repetitions = int.tryParse(
      repetitionsController.text,
    );

    if (repetitions == null || repetitions < 0) {
      _showMessage(
        'Entre un nombre de répétitions valide.',
      );
      return;
    }

    final weight = double.tryParse(
      weightController.text.replaceAll(',', '.'),
    );

    final assistance = double.tryParse(
      assistanceController.text.replaceAll(',', '.'),
    );

    final duration = int.tryParse(
      durationController.text,
    );

    setState(() {
      saving = true;
    });

    final workoutSet = WorkoutSet(
      exerciseId: plan.exerciseId,
      repetitions: repetitions,
      weight: weight,
      assistance: assistance,
      durationSeconds: duration,
    );

    await WorkoutSessionService.addSet(workoutSet);

    if (!mounted) return;

    final lastSet = currentSet + 1 >= plan.sets;
    final lastExercise =
        currentExercise + 1 >= widget.plans.length;

    if (lastSet && lastExercise) {
      setState(() {
        saving = false;
      });

      _showFinishedDialog();
      return;
    }

    if (lastSet) {
      setState(() {
        currentExercise++;
        currentSet = 0;
        saving = false;
        _loadPlanValues();
      });

      _showMessage(
        'Exercice terminé ! 💪',
      );
      return;
    }

    setState(() {
      currentSet++;
      saving = false;
    });

    _loadPlanValues();
  }

  void _showFinishedDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Séance terminée 🎉',
          ),
          content: Text(
            '${widget.plans.length} exercices terminés.\n\n'
            'Toutes tes performances ont été enregistrées.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                WorkoutSessionService.endSession();

                Navigator.of(dialogContext).pop();

                Navigator.of(context).pop();
              },
              child: const Text('Terminer'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProgress =
        '${currentExercise + 1} / ${widget.plans.length}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Séance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExerciseHeader(exerciseProgress),

          const SizedBox(height: 20),

          _buildPlanInformation(),

          const SizedBox(height: 24),

          _buildInputs(),

          const SizedBox(height: 20),

          SizedBox(
            height: 55,
            child: FilledButton.icon(
              onPressed: saving ? null : _validateSet,
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(
                _buttonText(),
                style: const TextStyle(
                  fontSize: 17,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          _buildProgress(),

          const SizedBox(height: 24),

          _buildExerciseList(),
        ],
      ),
    );
  }

  Widget _buildExerciseHeader(
    String exerciseProgress,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Exercice $exerciseProgress',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _exerciseName(),
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Série ${currentSet + 1} / ${plan.sets}',
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanInformation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Objectif',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${plan.repetitions} répétitions',
              style: const TextStyle(
                fontSize: 17,
              ),
            ),
            if (plan.assistance != null) ...[
              const SizedBox(height: 5),
              Text(
                'Assistance prévue : '
                '${plan.assistance!.toStringAsFixed(1)} kg',
              ),
            ],
            if (plan.weight != null) ...[
              const SizedBox(height: 5),
              Text(
                'Charge prévue : '
                '${plan.weight!.toStringAsFixed(1)} kg',
              ),
            ],
            if (plan.reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                plan.reason,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputs() {
    final exercise = _findExercise();

    return Column(
      children: [
        _buildInput(
          controller: repetitionsController,
          label: 'Répétitions réalisées',
          icon: Icons.repeat,
          keyboardType: TextInputType.number,
        ),

        if (exercise.type == ExerciseType.assisted)
          _buildInput(
            controller: assistanceController,
            label: 'Assistance utilisée (kg)',
            icon: Icons.trending_down,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),

        if (exercise.type == ExerciseType.weighted ||
            exercise.type == ExerciseType.machine)
          _buildInput(
            controller: weightController,
            label: 'Charge utilisée (kg)',
            icon: Icons.fitness_center,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),

        if (exercise.type == ExerciseType.negative ||
            exercise.type == ExerciseType.isometric)
          _buildInput(
            controller: durationController,
            label: 'Durée réalisée (secondes)',
            icon: Icons.timer,
            keyboardType: TextInputType.number,
          ),
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final totalSets = widget.plans.fold<int>(
      0,
      (total, item) => total + item.sets,
    );

    final completedSets =
        widget.plans
            .take(currentExercise)
            .fold<int>(
              0,
              (total, item) => total + item.sets,
            ) +
        currentSet;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Progression de la séance',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: totalSets == 0
              ? 0
              : completedSets / totalSets,
        ),
        const SizedBox(height: 8),
        Text(
          '$completedSets / $totalSets séries',
        ),
      ],
    );
  }

  Widget _buildExerciseList() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Programme',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(
          widget.plans.length,
          (index) {
            final item = widget.plans[index];
            final completed =
                index < currentExercise;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: completed
                      ? const Icon(Icons.check)
                      : Text('${index + 1}'),
                ),
                title: Text(
                  _exerciseNameForId(
                    item.exerciseId,
                  ),
                ),
                subtitle: Text(
                  '${item.sets} × '
                  '${item.repetitions} reps',
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _buttonText() {
    final lastSet = currentSet + 1 >= plan.sets;
    final lastExercise =
        currentExercise + 1 >= widget.plans.length;

    if (lastSet && lastExercise) {
      return 'Terminer la séance';
    }

    if (lastSet) {
      return 'Exercice suivant';
    }

    return 'Valider la série';
  }

  Exercise _findExercise() {
    return ExerciseService.getAll().firstWhere(
      (exercise) => exercise.id == plan.exerciseId,
      orElse: () => ExerciseService.getAll().first,
    );
  }

  String _exerciseName() {
    return _findExercise().name;
  }

  String _exerciseNameForId(String id) {
    return ExerciseService.getAll()
        .firstWhere(
          (exercise) => exercise.id == id,
          orElse: () => ExerciseService.getAll().first,
        )
        .name;
  }
}