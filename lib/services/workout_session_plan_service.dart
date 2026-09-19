import '../models/workout_session_plan.dart';
import '../services/exercise_service.dart';
import '../services/progression_service.dart';

class WorkoutSessionPlanService {
  static Future<WorkoutSessionPlan> generateNextSession() async {
    final exercises = ExerciseService.getAll();

    final plans = <dynamic>[];

    for (final exercise in exercises) {
      final plan = await ProgressionService.generateNextWorkout(
        exercise.id,
      );

      plans.add(plan);
    }

    return WorkoutSessionPlan(
      name: 'Ma prochaine séance',
      reason: 'Une séance adaptée à ta progression.',
      exercises: plans.cast(),
    );
  }
}