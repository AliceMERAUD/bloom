import '../models/workout_set.dart';
import 'storage_service.dart';

class WorkoutSessionService {
  static String? _currentSessionId;

  static String? get currentSessionId => _currentSessionId;

  static Future<void> startSession() async {
    _currentSessionId =
        await StorageService.createWorkoutSession();
  }

  static Future<void> addSet(WorkoutSet workoutSet) async {
    if (_currentSessionId == null) {
      await startSession();
    }

    final setId = await StorageService.saveWorkoutSet(workoutSet);

    await StorageService.addSetToSession(
      _currentSessionId!,
      setId,
    );
  }

  static void endSession() {
    _currentSessionId = null;
  }
}