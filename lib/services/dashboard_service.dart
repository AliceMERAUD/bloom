import '../models/task.dart';
import '../models/wellbeing_entry.dart';
import '../models/workout_session.dart';
import 'exercise_service.dart';
import 'puzzle_catalog.dart';
import 'puzzle_progress_service.dart';
import 'storage_service.dart';
import 'task_service.dart';
import 'wellbeing_service.dart';
import 'workout_session_service.dart';

/// Snapshot of local data for the home dashboard (no fake stats).
class DashboardSnapshot {
  final int closedSessionCount;
  final int totalSetCount;
  final int exerciseCatalogueCount;
  final WorkoutSession? lastClosedSession;
  final WorkoutSession? openSession;
  final WellbeingEntry? todayEntry;
  final String? cycleStatus;
  final int wellbeingDayCount;
  final int puzzleCompleted;
  final int puzzleTotal;
  final String? nextPuzzleId;
  final String? nextPuzzleTitle;
  final int pendingTaskCount;
  final int overdueTaskCount;
  final int dueTodayTaskCount;
  final int completedTasksToday;
  final List<String> topPendingTaskTitles;

  const DashboardSnapshot({
    required this.closedSessionCount,
    required this.totalSetCount,
    required this.exerciseCatalogueCount,
    required this.lastClosedSession,
    required this.openSession,
    required this.todayEntry,
    required this.cycleStatus,
    required this.wellbeingDayCount,
    required this.puzzleCompleted,
    required this.puzzleTotal,
    required this.nextPuzzleId,
    required this.nextPuzzleTitle,
    required this.pendingTaskCount,
    required this.overdueTaskCount,
    required this.dueTodayTaskCount,
    required this.completedTasksToday,
    required this.topPendingTaskTitles,
  });

  bool get hasSportHistory => closedSessionCount > 0 || openSession != null;
  bool get hasWellbeingToday => todayEntry != null;
  bool get hasPuzzleProgress => puzzleCompleted > 0;
}

class DashboardService {
  static DashboardSnapshot load() {
    final sessions = StorageService.getAllSessions();
    final closed = sessions.where((s) => !s.isOpen).toList();
    final open = WorkoutSessionService.hasOpenSession
        ? sessions.where((s) => s.isOpen).toList()
        : StorageService.getOpenSessions();

    final sets = StorageService.getWorkoutSets();
    final today = WellbeingService.getEntryForDate(DateTime.now());
    final entries = WellbeingService.getAllEntries();
    final progress = PuzzleProgressService.load();
    final nextId = progress.nextPlayableId;

    final pending = TaskService.getPendingTasks();
    final dueFirst = [
      ...pending.where((t) => t.isOverdue || t.isDueToday),
      ...pending.where((t) => !t.isOverdue && !t.isDueToday),
    ];

    return DashboardSnapshot(
      closedSessionCount: closed.length,
      totalSetCount: sets.length,
      exerciseCatalogueCount: ExerciseService.getAll().length,
      lastClosedSession: closed.isEmpty ? null : closed.first,
      openSession: open.isEmpty ? null : open.first,
      todayEntry: today,
      cycleStatus: WellbeingService.cycleStatusLabel(),
      wellbeingDayCount: entries.length,
      puzzleCompleted: progress.completedIds.length,
      puzzleTotal: PuzzleCatalog.all.length,
      nextPuzzleId: nextId,
      nextPuzzleTitle:
          nextId == null ? null : PuzzleCatalog.byId(nextId).title,
      pendingTaskCount: pending.length,
      overdueTaskCount: TaskService.overdueCount(),
      dueTodayTaskCount: TaskService.dueTodayCount(),
      completedTasksToday: TaskService.completedTodayCount(),
      topPendingTaskTitles:
          dueFirst.take(3).map((BloomTask t) => t.title).toList(),
    );
  }
}
