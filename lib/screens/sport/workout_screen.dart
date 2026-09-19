import 'package:flutter/material.dart';

import '../../models/exercise.dart';
import '../../models/exercise_fields.dart';
import '../../models/workout_plan.dart';
import '../../models/workout_set.dart';
import '../../services/exercise_service.dart';
import '../../services/workout_session_service.dart';
import 'workout_summary_screen.dart';

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

    final fields = ExerciseFields.forType(_findExercise().type);
    final repetitions = ExerciseFields.parseInt(
      repetitionsController.text,
    );

    if (repetitions == null || repetitions <= 0) {
      _showMessage(
        'Entre un nombre de répétitions valide.',
      );
      return;
    }

    setState(() {
      saving = true;
    });

    final workoutSet = WorkoutSet(
      exerciseId: plan.exerciseId,
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

    final lastSet = currentSet + 1 >= plan.sets;
    final lastExercise =
        currentExercise + 1 >= widget.plans.length;

    if (lastSet && lastExercise) {
      setState(() {
        saving = false;
      });

      await _finishSession();
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

  Future<void> _finishSession() async {
    final sessionId = WorkoutSessionService.currentSessionId;

    await WorkoutSessionService.endSession();

    if (!mounted) return;

    if (sessionId == null) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryScreen(
          sessionId: sessionId,
        ),
      ),
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
    final fields = ExerciseFields.forType(exercise.type);

    return Column(
      children: [
        if (fields.showRepetitions)
          _buildInput(
            controller: repetitionsController,
            label: 'Répétitions réalisées',
            icon: Icons.repeat,
            keyboardType: TextInputType.number,
          ),
        if (fields.showAssistance)
          _buildInput(
            controller: assistanceController,
            label: fields.assistanceLabel,
            icon: Icons.trending_down,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
        if (fields.showWeight)
          _buildInput(
            controller: weightController,
            label: fields.weightLabel,
            icon: Icons.fitness_center,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
        if (fields.showDuration)
          _buildInput(
            controller: durationController,
            label: fields.durationLabel,
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