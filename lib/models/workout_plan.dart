class WorkoutPlan {
  final String exerciseId;
  final int sets;
  final int repetitions;
  final double? weight;
  final double? assistance;
  final String reason;

  const WorkoutPlan({
    required this.exerciseId,
    required this.sets,
    required this.repetitions,
    this.weight,
    this.assistance,
    required this.reason,
  });
}