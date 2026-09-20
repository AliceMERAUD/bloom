import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../models/sport_activity.dart';
import '../models/sport_bag_item.dart';
import '../models/task.dart';
import '../models/wellbeing_entry.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';
import 'puzzle/generated_puzzle_catalog_service.dart';
import 'puzzle/puzzle_difficulty_service.dart';
import 'puzzle/puzzle_history_service.dart';
import 'puzzle_progress_service.dart';

class StorageService {
  static const String workoutBoxName = 'workout_sets';
  static const String workoutSessionBoxName = 'workout_sessions';
  static const String wellbeingBoxName = 'wellbeing_entries';
  static const String puzzleProgressBoxName = 'puzzle_progress';
  static const String settingsBoxName = 'app_settings';
  static const String tasksBoxName = 'tasks';
  static const String sportActivitiesBoxName = 'sport_activities';
  static const String sportBagBoxName = 'sport_bag';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(workoutBoxName);
    await Hive.openBox(workoutSessionBoxName);
    await Hive.openBox(wellbeingBoxName);
    await Hive.openBox(puzzleProgressBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox(tasksBoxName);
    await Hive.openBox(sportActivitiesBoxName);
    await Hive.openBox(sportBagBoxName);
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
    await Hive.openBox(puzzleProgressBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox(tasksBoxName);
    await Hive.openBox(sportActivitiesBoxName);
    await Hive.openBox(sportBagBoxName);
  }

  static Future<void> closeForTesting() async {
    await Hive.close();
  }

  static Box get _box => Hive.box(workoutBoxName);
  static Box get _sessionBox => Hive.box(workoutSessionBoxName);
  static Box get _wellbeingBox => Hive.box(wellbeingBoxName);
  static Box get _puzzleBox => Hive.box(puzzleProgressBoxName);
  static Box get _settingsBox => Hive.box(settingsBoxName);
  static Box get _tasksBox => Hive.box(tasksBoxName);
  static Box get _sportActivitiesBox => Hive.box(sportActivitiesBoxName);
  static Box get _sportBagBox => Hive.box(sportBagBoxName);

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

  // --- Puzzle progress ---

  static PuzzleProgress? getPuzzleProgress() {
    final raw = _puzzleBox.get('progress');
    if (raw == null) return null;
    return PuzzleProgress.fromMap(raw as Map);
  }

  static Future<void> savePuzzleProgress(PuzzleProgress progress) async {
    await _puzzleBox.put('progress', progress.toMap());
  }

  // --- Procedural puzzle keys (same Hive box, separate from `progress`) ---

  static GeneratedPuzzleCatalog? getGeneratedPuzzleCatalog() {
    final raw = _puzzleBox.get('generated_catalog');
    if (raw == null) return null;
    return GeneratedPuzzleCatalog.fromMap(raw as Map);
  }

  static Future<void> saveGeneratedPuzzleCatalog(
    GeneratedPuzzleCatalog catalog,
  ) async {
    await _puzzleBox.put('generated_catalog', catalog.toMap());
  }

  static PlayerDifficultyState? getPlayerDifficulty() {
    final raw = _puzzleBox.get('player_difficulty');
    if (raw == null) return null;
    return PlayerDifficultyState.fromMap(raw as Map);
  }

  static Future<void> savePlayerDifficulty(PlayerDifficultyState state) async {
    await _puzzleBox.put('player_difficulty', state.toMap());
  }

  static PuzzleHistoryStore? getPuzzleHistory() {
    final raw = _puzzleBox.get('puzzle_history');
    if (raw == null) return null;
    return PuzzleHistoryStore.fromMap(raw as Map);
  }

  static Future<void> savePuzzleHistory(PuzzleHistoryStore store) async {
    await _puzzleBox.put('puzzle_history', store.toMap());
  }

  // --- App settings ---

  static AppSettings getAppSettings() {
    final raw = _settingsBox.get('settings');
    if (raw is Map) {
      return AppSettings.fromMap(raw);
    }
    return const AppSettings();
  }

  static Future<void> saveAppSettings(AppSettings settings) async {
    await _settingsBox.put('settings', settings.toMap());
  }

  /// Used by import to restore sets with original ids.
  static Future<void> putWorkoutSetRaw(
    String id,
    Map<String, dynamic> map,
  ) async {
    await _box.put(id, map);
  }

  static Future<void> putWorkoutSessionRaw(
    String id,
    Map<String, dynamic> map,
  ) async {
    await _sessionBox.put(id, map);
  }

  /// Clears Bloom user data. Optionally keeps theme / notification prefs.
  static Future<void> clearAllUserData({bool keepSettings = true}) async {
    await _box.clear();
    await _sessionBox.clear();
    await _wellbeingBox.clear();
    await _puzzleBox.clear();
    await _tasksBox.clear();
    await _sportActivitiesBox.clear();
    await _sportBagBox.clear();
    if (!keepSettings) {
      await _settingsBox.clear();
    }
  }

  // --- Tasks ---

  static Future<void> saveTask(BloomTask task) async {
    await _tasksBox.put(task.id, task.toMap());
  }

  static BloomTask? getTask(String id) {
    final raw = _tasksBox.get(id);
    if (raw is Map) return BloomTask.fromMap(raw);
    return null;
  }

  static List<BloomTask> getAllTasks() {
    final tasks = _tasksBox.values
        .whereType<Map>()
        .map((value) => BloomTask.fromMap(value))
        .toList();
    tasks.sort((a, b) {
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }
      final ad = a.dueDate;
      final bd = b.dueDate;
      if (ad == null && bd == null) {
        return b.createdAt.compareTo(a.createdAt);
      }
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
    return tasks;
  }

  static Future<void> deleteTask(String id) async {
    await _tasksBox.delete(id);
  }

  // --- Sport activities ---

  static Future<void> saveSportActivity(SportActivity activity) async {
    await _sportActivitiesBox.put(activity.id, activity.toMap());
  }

  static SportActivity? getSportActivity(String id) {
    final raw = _sportActivitiesBox.get(id);
    if (raw is Map) return SportActivity.fromMap(raw);
    return null;
  }

  static List<SportActivity> getAllSportActivities() {
    final list = _sportActivitiesBox.values
        .whereType<Map>()
        .map(SportActivity.fromMap)
        .toList();
    list.sort((a, b) {
      if (a.builtin != b.builtin) return a.builtin ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  static Future<void> deleteSportActivity(String id) async {
    await _sportActivitiesBox.delete(id);
  }

  // --- Sport bag ---

  static Future<void> saveBagItem(SportBagItem item) async {
    await _sportBagBox.put(item.id, item.toMap());
  }

  static SportBagItem? getBagItem(String id) {
    final raw = _sportBagBox.get(id);
    if (raw is Map) return SportBagItem.fromMap(raw);
    return null;
  }

  static List<SportBagItem> getAllBagItems() {
    final list = _sportBagBox.values
        .whereType<Map>()
        .map(SportBagItem.fromMap)
        .toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  static Future<void> deleteBagItem(String id) async {
    await _sportBagBox.delete(id);
  }
}
