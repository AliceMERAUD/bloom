import '../models/exercise.dart';

class ExerciseService {
  static const List<Exercise> exercises = [
    Exercise(
      id: 'pull_up_assisted',
      name: 'Traction assistée',
      type: ExerciseType.assisted,
      description: 'Traction réalisée avec une machine d’assistance.',
    ),
    Exercise(
      id: 'pull_up',
      name: 'Traction',
      type: ExerciseType.bodyweight,
      description: 'Traction au poids du corps.',
    ),
    Exercise(
      id: 'pull_up_weighted',
      name: 'Traction lestée',
      type: ExerciseType.weighted,
      description: 'Traction avec une charge supplémentaire.',
    ),
    Exercise(
      id: 'pull_up_negative',
      name: 'Traction négative',
      type: ExerciseType.negative,
      description: 'Phase descendante contrôlée.',
    ),
    Exercise(
      id: 'pull_up_isometric',
      name: 'Traction isométrique',
      type: ExerciseType.isometric,
      description: 'Maintien statique dans une position de traction.',
    ),
    Exercise(
      id: 'lat_pulldown',
      name: 'Tirage vertical',
      type: ExerciseType.machine,
      description: 'Tirage vertical à la machine.',
    ),
    Exercise(
      id: 'push_up',
      name: 'Pompes',
      type: ExerciseType.bodyweight,
      description: 'Pompes au poids du corps.',
    ),
  ];

  static List<Exercise> getAll() {
    return exercises;
  }
}