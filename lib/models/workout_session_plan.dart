import 'workout_plan.dart';

class WorkoutSessionPlan {
  final String name;
  final List<WorkoutPlan> exercises;
  final String reason;

  const WorkoutSessionPlan({
    required this.name,
    required this.exercises,
    required this.reason,
  });

  int get totalExercises => exercises.length;

  int get totalSets {
    return exercises.fold(
      0,
      (total, exercise) => total + exercise.sets,
    );
  }
}