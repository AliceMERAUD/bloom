import 'package:hive_flutter/hive_flutter.dart';

import '../models/wellbeing_entry.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';

class StorageService {
  static const String workoutBoxName = 'workout_sets';
  static const String workoutSessionBoxName = 'workout_sessions';
  static const String wellbeingBoxName = 'wellbeing_entries';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(workoutBoxName);
    await Hive.openBox(workoutSessionBoxName);
    await Hive.openBox(wellbeingBoxName);
  }

  /// Initialise Hive avec un chemin local (tests unitaires).
  static Future<void> initForTesting(String path) async {
    try {
      await Hive.close();
    } catch (_) {
      // Ignore if Hive was not open.
    }
    Hive.init(path);
    await Hive.openBox(workoutBoxName);
    await Hive.openBox(workoutSessionBoxName);
    await Hive.openBox(wellbeingBoxName);
  }

  static Future<void> closeForTesting() async {
    await Hive.close();
  }

  static Box get _box => Hive.box(workoutBoxName);
  static Box get _sessionBox => Hive.box(workoutSessionBoxName);
  static Box get _wellbeingBox => Hive.box(wellbeingBoxName);

  static Future<String> saveWorkoutSet(WorkoutSet workoutSet) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final date = workoutSet.date ?? DateTime.now();

    await _box.put(id, workoutSet.toMap(id: id, date: date));

    return id;
  }

  static List<WorkoutSet> getWorkoutSets() {
    return _box.values
        .map((value) => WorkoutSet.fromMap(value as Map))
        .toList();
  }

  static Future<List<WorkoutSet>> getSetsForExercise(
    String exerciseId,
  ) async {
    return getWorkoutSets()
        .where((set) => set.exerciseId == exerciseId)
        .toList();
  }

  static Future<void> clearWorkoutSets() async {
    await _box.clear();
  }

  static Future<String> createWorkoutSession() async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final now = DateTime.now();

    final session = WorkoutSession(
      id: id,
      startedAt: now,
      endedAt: null,
      setIds: const [],
    );

    await _sessionBox.put(id, session.toMap());

    return id;
  }

  static Future<void> addSetToSession(
    String sessionId,
    String setId,
  ) async {
    final session = await getSession(sessionId);

    if (session == null) {
      return;
    }

    final updated = session.copyWith(
      setIds: [...session.setIds, setId],
    );

    await _sessionBox.put(sessionId, updated.toMap());
  }

  static Future<void> endWorkoutSession(String sessionId) async {
    final session = await getSession(sessionId);

    if (session == null) {
      return;
    }

    if (session.endedAt != null) {
      return;
    }

    final updated = session.copyWith(endedAt: DateTime.now());

    await _sessionBox.put(sessionId, updated.toMap());
  }

  static Future<WorkoutSession?> getSession(String sessionId) async {
    final session = _sessionBox.get(sessionId);

    if (session == null) {
      return null;
    }

    return WorkoutSession.fromMap(session as Map);
  }

  static List<WorkoutSession> getAllSessions() {
    final sessions = _sessionBox.values
        .map((value) => WorkoutSession.fromMap(value as Map))
        .toList();

    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions;
  }

  static List<WorkoutSession> getOpenSessions() {
    return getAllSessions().where((session) => session.isOpen).toList();
  }

  static Future<List<WorkoutSet>> getSessionSets(
    String sessionId,
  ) async {
    final session = await getSession(sessionId);

    if (session == null) {
      return [];
    }

    return session.setIds
        .map((id) => _box.get(id))
        .where((set) => set != null)
        .map((set) => WorkoutSet.fromMap(set as Map))
        .toList();
  }

  // --- Wellbeing ---

  static Future<WellbeingEntry> saveWellbeingEntry(
    WellbeingEntry entry,
  ) async {
    final normalized = entry.copyWith(
      date: WellbeingEntry.normalizeDate(entry.date),
    );
    final id = WellbeingEntry.dateKey(normalized.date);
    final toStore = normalized.copyWith(id: id);

    await _wellbeingBox.put(id, toStore.toMap());
    return toStore;
  }

  static WellbeingEntry? getWellbeingEntry(String id) {
    final raw = _wellbeingBox.get(id);
    if (raw == null) return null;
    return WellbeingEntry.fromMap(raw as Map);
  }

  static WellbeingEntry? getWellbeingEntryForDate(DateTime date) {
    return getWellbeingEntry(WellbeingEntry.dateKey(date));
  }

  static List<WellbeingEntry> getAllWellbeingEntries() {
    final entries = _wellbeingBox.values
        .map((value) => WellbeingEntry.fromMap(value as Map))
        .toList();

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  static Future<void> deleteWellbeingEntry(String id) async {
    await _wellbeingBox.delete(id);
  }
}
