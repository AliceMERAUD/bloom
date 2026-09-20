import '../models/task.dart';
import '../models/wellbeing_entry.dart';
import '../models/wellbeing_enums.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';
import 'exercise_service.dart';
import 'puzzle_catalog.dart';
import 'puzzle_progress_service.dart';
import 'sport_activity_service.dart';
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
  final int periodCount;
  final Map<String, int> moodCounts;
  final Map<String, int> energyCounts;
  final int puzzleCompleted;
  final int puzzleTotal;
  final String? nextPuzzleId;
  final String? nextPuzzleTitle;
  final int pendingTaskCount;
  final int overdueTaskCount;
  final int dueTodayTaskCount;
  final int upcomingTaskCount;
  final int completedTasksToday;
  final int completedTasksTotal;
  final List<String> topPendingTaskTitles;
  final BloomTask? nextSportTask;
  final String? nextSportName;
  final TractionProgressSummary? tractionProgress;
  final String motivationalLine;

  const DashboardSnapshot({
    required this.closedSessionCount,
    required this.totalSetCount,
    required this.exerciseCatalogueCount,
    required this.lastClosedSession,
    required this.openSession,
    required this.todayEntry,
    required this.cycleStatus,
    required this.wellbeingDayCount,
    required this.periodCount,
    required this.moodCounts,
    required this.energyCounts,
    required this.puzzleCompleted,
    required this.puzzleTotal,
    required this.nextPuzzleId,
    required this.nextPuzzleTitle,
    required this.pendingTaskCount,
    required this.overdueTaskCount,
    required this.dueTodayTaskCount,
    required this.upcomingTaskCount,
    required this.completedTasksToday,
    required this.completedTasksTotal,
    required this.topPendingTaskTitles,
    required this.nextSportTask,
    required this.nextSportName,
    required this.tractionProgress,
    required this.motivationalLine,
  });

  bool get hasSportHistory => closedSessionCount > 0 || openSession != null;
  bool get hasWellbeingToday => todayEntry != null;
  bool get hasPuzzleProgress => puzzleCompleted > 0;

  double? get taskCompletionRate {
    final total = completedTasksTotal + pendingTaskCount;
    if (total == 0) return null;
    return completedTasksTotal / total;
  }
}

class TractionProgressSummary {
  final double? previousAssistance;
  final double? latestAssistance;
  final int setCount;

  const TractionProgressSummary({
    required this.previousAssistance,
    required this.latestAssistance,
    required this.setCount,
  });

  bool get hasData => latestAssistance != null;
}

class DashboardService {
  static DashboardSnapshot load() {
    final sessions = StorageService.getAllSessions();
    final closed = sessions.where((s) => !s.isOpen).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
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

    final nextSport = _nextSportTask(pending);
    String? sportName;
    if (nextSport?.sportId != null) {
      sportName = SportActivityService.getById(nextSport!.sportId!)?.name;
    }

    final moodCounts = <String, int>{};
    final energyCounts = <String, int>{};
    for (final e in entries) {
      if (e.mood != null) {
        moodCounts[e.mood!.label] = (moodCounts[e.mood!.label] ?? 0) + 1;
      }
      if (e.energy != null) {
        energyCounts[e.energy!.label] =
            (energyCounts[e.energy!.label] ?? 0) + 1;
      }
    }

    final upcoming = pending
        .where(
          (t) =>
              t.dueDate != null &&
              !t.isDueToday &&
              !t.isOverdue,
        )
        .length;

    return DashboardSnapshot(
      closedSessionCount: closed.length,
      totalSetCount: sets.length,
      exerciseCatalogueCount: ExerciseService.getAll().length,
      lastClosedSession: closed.isEmpty ? null : closed.first,
      openSession: open.isEmpty ? null : open.first,
      todayEntry: today,
      cycleStatus: WellbeingService.cycleStatusLabel(),
      wellbeingDayCount: entries.length,
      periodCount: WellbeingService.getPeriods().length,
      moodCounts: moodCounts,
      energyCounts: energyCounts,
      puzzleCompleted: progress.completedIds.length,
      puzzleTotal: PuzzleCatalog.all.length,
      nextPuzzleId: nextId,
      nextPuzzleTitle:
          nextId == null ? null : PuzzleCatalog.byId(nextId).title,
      pendingTaskCount: pending.length,
      overdueTaskCount: TaskService.overdueCount(),
      dueTodayTaskCount: TaskService.dueTodayCount(),
      upcomingTaskCount: upcoming,
      completedTasksToday: TaskService.completedTodayCount(),
      completedTasksTotal: TaskService.getCompletedTasks().length,
      topPendingTaskTitles:
          dueFirst.take(3).map((BloomTask t) => t.title).toList(),
      nextSportTask: nextSport,
      nextSportName: sportName,
      tractionProgress: _tractionSummary(sets),
      motivationalLine: _motivation(
        pending: pending.length,
        overdue: TaskService.overdueCount(),
        puzzleDone: progress.completedIds.length,
        puzzleTotal: PuzzleCatalog.all.length,
        hasWellbeing: today != null,
      ),
    );
  }

  static BloomTask? _nextSportTask(List<BloomTask> pending) {
    final sportTasks = pending
        .where(
          (t) =>
              t.category == TaskCategory.sport ||
              (t.sportId != null && t.sportId!.isNotEmpty),
        )
        .toList();
    if (sportTasks.isEmpty) return null;

    sportTasks.sort((a, b) {
      final ad = a.dueDate;
      final bd = b.dueDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;
      final at = (a.dueTime?.hour ?? 99) * 60 + (a.dueTime?.minute ?? 0);
      final bt = (b.dueTime?.hour ?? 99) * 60 + (b.dueTime?.minute ?? 0);
      return at.compareTo(bt);
    });
    return sportTasks.first;
  }

  static TractionProgressSummary? _tractionSummary(List<WorkoutSet> sets) {
    final assisted = sets
        .where((s) => s.exerciseId == 'pull_up_assisted')
        .where((s) => s.assistance != null)
        .toList()
      ..sort((a, b) {
        final ad = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ad.compareTo(bd);
      });
    if (assisted.isEmpty) {
      return const TractionProgressSummary(
        previousAssistance: null,
        latestAssistance: null,
        setCount: 0,
      );
    }
    final latest = assisted.last.assistance;
    final previous =
        assisted.length >= 2 ? assisted[assisted.length - 2].assistance : null;
    return TractionProgressSummary(
      previousAssistance: previous,
      latestAssistance: latest,
      setCount: assisted.length,
    );
  }

  static String _motivation({
    required int pending,
    required int overdue,
    required int puzzleDone,
    required int puzzleTotal,
    required bool hasWellbeing,
  }) {
    if (overdue > 0) {
      return 'Un petit pas après l’autre — commence par une tâche en retard 🌱';
    }
    if (pending == 0 && hasWellbeing && puzzleDone == puzzleTotal) {
      return 'Belle journée Bloom — tout est en ordre ✨';
    }
    if (pending == 0) {
      return 'Bravo, plus aucune tâche en attente 💪';
    }
    if (!hasWellbeing) {
      return 'Pense à noter ton bien-être aujourd’hui 🌸';
    }
    return 'Tu avances bien — continue à ton rythme 🌿';
  }
}
