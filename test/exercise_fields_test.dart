import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/models/exercise.dart';
import 'package:bloom/models/exercise_fields.dart';

void main() {
  test('champs assisté : assistance + reps', () {
    final fields = ExerciseFields.forType(ExerciseType.assisted);
    expect(fields.showAssistance, isTrue);
    expect(fields.showWeight, isFalse);
    expect(fields.showDuration, isFalse);
    expect(fields.showRepetitions, isTrue);
  });

  test('champs lesté et machine : charge + reps', () {
    final weighted = ExerciseFields.forType(ExerciseType.weighted);
    final machine = ExerciseFields.forType(ExerciseType.machine);

    expect(weighted.showWeight, isTrue);
    expect(machine.showWeight, isTrue);
    expect(weighted.showAssistance, isFalse);
    expect(machine.showAssistance, isFalse);
  });

  test('champs isométrique : durée + reps', () {
    final fields = ExerciseFields.forType(ExerciseType.isometric);
    expect(fields.showDuration, isTrue);
    expect(fields.showWeight, isFalse);
  });

  test('parseDecimal accepte la virgule', () {
    expect(ExerciseFields.parseDecimal('12,5'), 12.5);
    expect(ExerciseFields.parseDecimal(''), isNull);
  });
}
