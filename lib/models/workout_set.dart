class WorkoutSet {
  final String? id;
  final String exerciseId;
  final int repetitions;

  /// Poids utilisé en plus du poids du corps.
  final double? weight;

  /// Poids d'assistance utilisé sur une machine.
  final double? assistance;

  /// Durée en secondes pour les exercices isométriques/négatifs.
  final int? durationSeconds;

  final DateTime? date;

  const WorkoutSet({
    this.id,
    required this.exerciseId,
    required this.repetitions,
    this.weight,
    this.assistance,
    this.durationSeconds,
    this.date,
  });

  Map<String, dynamic> toMap({
    required String id,
    required DateTime date,
  }) {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'repetitions': repetitions,
      'weight': weight,
      'assistance': assistance,
      'durationSeconds': durationSeconds,
      'date': date.toIso8601String(),
    };
  }

  factory WorkoutSet.fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);

    return WorkoutSet(
      id: data['id'] as String?,
      exerciseId: data['exerciseId'] as String,
      repetitions: (data['repetitions'] as num).toInt(),
      weight: (data['weight'] as num?)?.toDouble(),
      assistance: (data['assistance'] as num?)?.toDouble(),
      durationSeconds: (data['durationSeconds'] as num?)?.toInt(),
      date: _parseDate(data['date']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
