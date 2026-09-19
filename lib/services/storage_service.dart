import 'package:hive_flutter/hive_flutter.dart';

import '../models/workout_set.dart';

class StorageService {
  static const String workoutBoxName = 'workout_sets';
  static const String workoutSessionBoxName = 'workout_sessions';
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(workoutBoxName);
    await Hive.openBox(workoutSessionBoxName);
  }

  static Box get _box => Hive.box(workoutBoxName);
  static Box get _sessionBox => Hive.box(workoutSessionBoxName);
  static Future<String> saveWorkoutSet(
    WorkoutSet workoutSet,
    ) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    await _box.put(id, {
        'id': id,
        'exerciseId': workoutSet.exerciseId,
        'repetitions': workoutSet.repetitions,
        'weight': workoutSet.weight,
        'assistance': workoutSet.assistance,
        'durationSeconds': workoutSet.durationSeconds,
        'date': DateTime.now().toIso8601String(),
    });

    return id;
    }

    static List<Map<String, dynamic>> getWorkoutSets() {
        return _box.values.map((value) {
        return Map<String, dynamic>.from(value as Map);
        }).toList();
    }


    static Future<List<Map<String, dynamic>>> getSetsForExercise(
        String exerciseId,
    ) async {
        return _box.values
            .map((value) {
            return Map<String, dynamic>.from(value as Map);
            })
            .where((set) => set['exerciseId'] == exerciseId)
            .toList();
    }

  static Future<void> clearWorkoutSets() async {
    await _box.clear();
  }

  static Future<String> createWorkoutSession() async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    await _sessionBox.put(id, {
        'id': id,
        'date': DateTime.now().toIso8601String(),
        'setIds': <String>[],
    });

    return id;
    }

    static Future<void> addSetToSession(
    String sessionId,
    String setId,
    ) async {
    final session = _sessionBox.get(sessionId);

    if (session == null) {
        return;
    }

    final data = Map<String, dynamic>.from(session as Map);

    final setIds = List<String>.from(
        data['setIds'] ?? <String>[],
    );

    setIds.add(setId);

    data['setIds'] = setIds;

    await _sessionBox.put(sessionId, data);
    }
    static Future<Map<String, dynamic>?> getSession(
        String sessionId,
        ) async {
        final session = _sessionBox.get(sessionId);

        if (session == null) {
            return null;
        }

        return Map<String, dynamic>.from(session as Map);
        }

        static Future<List<Map<String, dynamic>>> getSessionSets(
        String sessionId,
        ) async {
        final session = await getSession(sessionId);

        if (session == null) {
            return [];
        }

        final setIds = List<String>.from(
            session['setIds'] ?? <String>[],
        );

        return setIds
            .map((id) => _box.get(id))
            .where((set) => set != null)
            .map((set) => Map<String, dynamic>.from(set as Map))
            .toList();
        }
}