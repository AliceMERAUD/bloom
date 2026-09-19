import '../models/workout_set.dart';
import 'storage_service.dart';

enum StartSessionOutcome {
  /// A brand new session was created.
  created,

  /// An already open session was reused / restored.
  resumed,

  /// An open session already exists; caller must choose how to proceed.
  conflict,
}

class StartSessionResult {
  final StartSessionOutcome outcome;
  final String sessionId;

  const StartSessionResult({
    required this.outcome,
    required this.sessionId,
  });
}

class WorkoutSessionService {
  static String? _currentSessionId;

  static String? get currentSessionId => _currentSessionId;

  static bool get hasOpenSession => _currentSessionId != null;

  /// Restores the most recently opened Hive session into memory, if any.
  static Future<String?> restoreFromStorage() async {
    if (_currentSessionId != null) {
      final current = await StorageService.getSession(_currentSessionId!);
      if (current != null && current.isOpen) {
        return _currentSessionId;
      }
      _currentSessionId = null;
    }

    final openSessions = StorageService.getOpenSessions();
    if (openSessions.isEmpty) {
      return null;
    }

    _currentSessionId = openSessions.first.id;
    return _currentSessionId;
  }

  /// Starts a new session, or reports a conflict if one is already open.
  ///
  /// Pass [forceNew] to close the current open session first.
  static Future<StartSessionResult> startSession({
    bool forceNew = false,
  }) async {
    await restoreFromStorage();

    if (_currentSessionId != null) {
      if (!forceNew) {
        return StartSessionResult(
          outcome: StartSessionOutcome.conflict,
          sessionId: _currentSessionId!,
        );
      }

      await endSession();
    }

    _currentSessionId = await StorageService.createWorkoutSession();

    return StartSessionResult(
      outcome: StartSessionOutcome.created,
      sessionId: _currentSessionId!,
    );
  }

  /// Ensures there is an active session (resume open or create).
  static Future<StartSessionResult> ensureActiveSession() async {
    await restoreFromStorage();

    if (_currentSessionId != null) {
      return StartSessionResult(
        outcome: StartSessionOutcome.resumed,
        sessionId: _currentSessionId!,
      );
    }

    _currentSessionId = await StorageService.createWorkoutSession();

    return StartSessionResult(
      outcome: StartSessionOutcome.created,
      sessionId: _currentSessionId!,
    );
  }

  static Future<void> addSet(WorkoutSet workoutSet) async {
    await ensureActiveSession();

    final setId = await StorageService.saveWorkoutSet(workoutSet);

    await StorageService.addSetToSession(
      _currentSessionId!,
      setId,
    );
  }

  static Future<void> endSession() async {
    final sessionId = _currentSessionId;

    if (sessionId != null) {
      await StorageService.endWorkoutSession(sessionId);
    }

    _currentSessionId = null;
  }

  /// Test-only: clears the in-memory session pointer without touching Hive.
  static void resetForTesting() {
    _currentSessionId = null;
  }
}
