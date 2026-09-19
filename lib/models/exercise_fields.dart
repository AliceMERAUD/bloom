import 'exercise.dart';

/// Describes which input fields an exercise type should expose.
class ExerciseFields {
  const ExerciseFields._({
    required this.showRepetitions,
    required this.showWeight,
    required this.showAssistance,
    required this.showDuration,
    required this.weightLabel,
    required this.assistanceLabel,
    required this.durationLabel,
  });

  final bool showRepetitions;
  final bool showWeight;
  final bool showAssistance;
  final bool showDuration;
  final String weightLabel;
  final String assistanceLabel;
  final String durationLabel;

  factory ExerciseFields.forType(ExerciseType type) {
    switch (type) {
      case ExerciseType.assisted:
        return const ExerciseFields._(
          showRepetitions: true,
          showWeight: false,
          showAssistance: true,
          showDuration: false,
          weightLabel: 'Charge (kg)',
          assistanceLabel: 'Assistance (kg)',
          durationLabel: 'Durée (secondes)',
        );
      case ExerciseType.weighted:
        return const ExerciseFields._(
          showRepetitions: true,
          showWeight: true,
          showAssistance: false,
          showDuration: false,
          weightLabel: 'Charge supplémentaire (kg)',
          assistanceLabel: 'Assistance (kg)',
          durationLabel: 'Durée (secondes)',
        );
      case ExerciseType.machine:
        return const ExerciseFields._(
          showRepetitions: true,
          showWeight: true,
          showAssistance: false,
          showDuration: false,
          weightLabel: 'Charge (kg)',
          assistanceLabel: 'Assistance (kg)',
          durationLabel: 'Durée (secondes)',
        );
      case ExerciseType.negative:
      case ExerciseType.isometric:
        return const ExerciseFields._(
          showRepetitions: true,
          showWeight: false,
          showAssistance: false,
          showDuration: true,
          weightLabel: 'Charge (kg)',
          assistanceLabel: 'Assistance (kg)',
          durationLabel: 'Durée (secondes)',
        );
      case ExerciseType.bodyweight:
      case ExerciseType.other:
        return const ExerciseFields._(
          showRepetitions: true,
          showWeight: false,
          showAssistance: false,
          showDuration: false,
          weightLabel: 'Charge (kg)',
          assistanceLabel: 'Assistance (kg)',
          durationLabel: 'Durée (secondes)',
        );
    }
  }

  static double? parseDecimal(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  static int? parseInt(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }
}
