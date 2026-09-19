import '../models/workout_plan.dart';
import '../models/workout_session_plan.dart';
import 'exercise_service.dart';
import 'progression_service.dart';

class WorkoutSessionPlanService {
  /// Builds a session plan for [exerciseIds] (order preserved).
  ///
  /// When [exerciseIds] is `null`, uses the full catalogue (legacy callers).
  /// When [exerciseIds] is an empty list, returns an empty plan so the UI can
  /// require an explicit selection.
  static Future<WorkoutSessionPlan> generateNextSession({
    List<String>? exerciseIds,
  }) async {
    final selectedIds = exerciseIds ??
        ExerciseService.getAll().map((exercise) => exercise.id).toList();

    final plans = <WorkoutPlan>[];

    for (final exerciseId in selectedIds) {
      final plan = await ProgressionService.generateNextWorkout(
        exerciseId,
      );
      plans.add(plan);
    }

    final reason = selectedIds.isEmpty
        ? 'Sélectionne au moins un exercice.'
        : selectedIds.length == ExerciseService.getAll().length
            ? 'Une séance adaptée à ta progression.'
            : 'Séance avec ${selectedIds.length} exercice'
                '${selectedIds.length > 1 ? 's' : ''} sélectionné'
                '${selectedIds.length > 1 ? 's' : ''}.';

    return WorkoutSessionPlan(
      name: 'Ma prochaine séance',
      reason: reason,
      exercises: plans,
    );
  }
}
