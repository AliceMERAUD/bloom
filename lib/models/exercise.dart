enum ExerciseType {
  assisted,
  bodyweight,
  weighted,
  negative,
  isometric,
  machine,
  other,
}

class Exercise {
  final String id;
  final String name;
  final ExerciseType type;
  final String? description;

  const Exercise({
    required this.id,
    required this.name,
    required this.type,
    this.description,
  });
}