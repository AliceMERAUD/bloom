import '../models/workout_plan.dart';
import 'storage_service.dart';

class ProgressionService {
  static Future<WorkoutPlan> generateNextWorkout(
    String exerciseId,
  ) async {
    final sets = await StorageService.getSetsForExercise(
      exerciseId,
    );

    if (sets.isEmpty) {
      return WorkoutPlan(
        exerciseId: exerciseId,
        sets: 3,
        repetitions: 8,
        reason: 'Première séance : on commence progressivement.',
      );
    }

    final lastSets = sets.reversed.take(4).toList();

    final averageRepetitions =
        lastSets.fold<double>(
              0,
              (total, set) =>
                  total +
                  ((set['repetitions'] ?? 0) as num).toDouble(),
            ) /
            lastSets.length;

    final assistanceValues = lastSets
        .map((set) => set['assistance'])
        .where((value) => value != null)
        .map((value) => (value as num).toDouble())
        .toList();

    if (assistanceValues.isNotEmpty) {
      final assistance = assistanceValues.last;

      if (averageRepetitions >= 8) {
        final nextAssistance =
            (assistance - 2.5).clamp(0, 999).toDouble();

        return WorkoutPlan(
          exerciseId: exerciseId,
          sets: 4,
          repetitions: 8,
          assistance: nextAssistance,
          reason:
              'Tu atteins ton objectif. On diminue légèrement l’assistance.',
        );
      }

      return WorkoutPlan(
        exerciseId: exerciseId,
        sets: 4,
        repetitions: 8,
        assistance: assistance,
        reason:
            'On consolide ton niveau avant de diminuer l’assistance.',
      );
    }

    final weightValues = lastSets
        .map((set) => set['weight'])
        .where((value) => value != null)
        .map((value) => (value as num).toDouble())
        .toList();

    if (weightValues.isNotEmpty) {
      final weight = weightValues.last;

      if (averageRepetitions >= 10) {
        return WorkoutPlan(
          exerciseId: exerciseId,
          sets: 4,
          repetitions: 8,
          weight: weight + 2.5,
          reason:
              'Tu maîtrises la charge actuelle. On augmente légèrement.',
        );
      }

      return WorkoutPlan(
        exerciseId: exerciseId,
        sets: 4,
        repetitions: 8,
        weight: weight,
        reason:
            'On consolide la charge actuelle.',
      );
    }

    return WorkoutPlan(
      exerciseId: exerciseId,
      sets: 3,
      repetitions: 8,
      reason:
          'On augmente progressivement le nombre de répétitions.',
    );
  }
}