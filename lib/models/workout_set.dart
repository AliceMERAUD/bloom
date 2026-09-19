class WorkoutSet {
  final String exerciseId;
  final int repetitions;

  /// Poids utilisé en plus du poids du corps.
  final double? weight;

  /// Poids d'assistance utilisé sur une machine.
  final double? assistance;

  /// Durée en secondes pour les exercices isométriques/négatifs.
  final int? durationSeconds;

  const WorkoutSet({
    required this.exerciseId,
    required this.repetitions,
    this.weight,
    this.assistance,
    this.durationSeconds,
  });
}