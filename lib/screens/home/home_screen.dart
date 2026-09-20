import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/wellbeing_enums.dart';
import '../../services/bloom_refresh.dart';
import '../../services/dashboard_service.dart';
import '../../services/google_calendar/google_calendar_service.dart';
import '../../services/settings_service.dart';
import '../../services/workout_session_service.dart';
import '../../widgets/common/bloom_widgets.dart';
import '../settings/settings_screen.dart';

/// Personalized local-first home dashboard.
class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenSport;
  final VoidCallback? onOpenWellbeing;
  final VoidCallback? onOpenTasks;
  final VoidCallback? onOpenPuzzle;
  final VoidCallback? onOpenGoogleCalendar;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onAddTask;
  final VoidCallback? onAddWellbeing;
  final VoidCallback? onContinuePuzzle;
  final VoidCallback? onStartSession;

  const HomeScreen({
    super.key,
    this.onOpenSport,
    this.onOpenWellbeing,
    this.onOpenTasks,
    this.onOpenPuzzle,
    this.onOpenGoogleCalendar,
    this.onOpenSettings,
    this.onAddTask,
    this.onAddWellbeing,
    this.onContinuePuzzle,
    this.onStartSession,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DashboardSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    BloomRefresh.version.addListener(_onRefresh);
    _reload();
  }

  @override
  void dispose() {
    BloomRefresh.version.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    if (mounted) _reload();
  }

  Future<void> _reload() async {
    await WorkoutSessionService.restoreFromStorage();
    if (!mounted) return;
    setState(() {
      _snapshot = DashboardService.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _snapshot ?? DashboardService.load();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bloom',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Paramètres',
            icon: const Icon(Icons.settings_outlined),
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                'Bonjour',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                data.motivationalLine,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              BloomSection(
                title: 'Aujourd’hui',
                icon: Icons.spa,
                accent: BloomTheme.accentGreen,
                child: _TodayCard(
                  data: data,
                  onOpenTasks: widget.onOpenTasks,
                  onOpenWellbeing: widget.onOpenWellbeing,
                  onOpenSport: widget.onOpenSport,
                  onOpenPuzzle: widget.onOpenPuzzle,
                ),
              ),
              const SizedBox(height: 20),
              BloomSection(
                title: 'Google Calendar',
                icon: Icons.calendar_month,
                accent: BloomTheme.planning,
                child: _GoogleCalendarCard(
                  onOpenSettings:
                      widget.onOpenGoogleCalendar ?? widget.onOpenSettings,
                ),
              ),
              const SizedBox(height: 20),
              BloomSection(
                title: 'Sport',
                icon: Icons.fitness_center,
                accent: BloomTheme.sport,
                child: Column(
                  children: [
                    _SportCard(
                      data: data,
                      onOpen: widget.onOpenSport,
                    ),
                    if (data.tractionProgress?.hasData == true) ...[
                      const SizedBox(height: 10),
                      _TractionMiniCard(summary: data.tractionProgress!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              BloomSection(
                title: 'Bien-être',
                icon: Icons.favorite,
                accent: BloomTheme.wellbeing,
                child: _WellbeingCard(
                  data: data,
                  onOpen: widget.onOpenWellbeing,
                ),
              ),
              const SizedBox(height: 20),
              BloomSection(
                title: 'Tasks',
                icon: Icons.checklist,
                accent: BloomTheme.tasks,
                child: _TasksCard(
                  data: data,
                  onOpen: widget.onOpenTasks,
                ),
              ),
              const SizedBox(height: 20),
              BloomSection(
                title: 'Puzzle',
                icon: Icons.extension,
                accent: BloomTheme.puzzle,
                child: _PuzzleCard(
                  data: data,
                  onOpen: widget.onOpenPuzzle,
                ),
              ),
              const SizedBox(height: 24),
              BloomSection(
                title: 'Actions rapides',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: widget.onAddTask ?? widget.onOpenTasks,
                      icon: const Icon(Icons.add_task, size: 18),
                      label: const Text('+ Tâche'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: widget.onStartSession ?? widget.onOpenSport,
                      icon: const Icon(Icons.fitness_center, size: 18),
                      label: const Text('+ Séance'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed:
                          widget.onAddWellbeing ?? widget.onOpenWellbeing,
                      icon: const Icon(Icons.favorite, size: 18),
                      label: const Text('+ Bien-être'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed:
                          widget.onContinuePuzzle ?? widget.onOpenPuzzle,
                      icon: const Icon(Icons.extension, size: 18),
                      label: const Text('Continuer le puzzle'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              BloomSection(
                title: 'Statistiques',
                subtitle: 'Calculées à partir de tes données locales',
                child: _StatsSection(data: data),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final DashboardSnapshot data;
  final VoidCallback? onOpenTasks;
  final VoidCallback? onOpenWellbeing;
  final VoidCallback? onOpenSport;
  final VoidCallback? onOpenPuzzle;

  const _TodayCard({
    required this.data,
    this.onOpenTasks,
    this.onOpenWellbeing,
    this.onOpenSport,
    this.onOpenPuzzle,
  });

  List<_TodayLine> _lines() {
    final lines = <_TodayLine>[];

    if (data.overdueTaskCount > 0) {
      lines.add(
        _TodayLine(
          icon: Icons.warning_amber_outlined,
          text: '${data.overdueTaskCount} en retard',
          onTap: onOpenTasks,
          emphasize: true,
        ),
      );
    }

    if (data.dueTodayTaskCount > 0) {
      lines.add(
        _TodayLine(
          icon: Icons.today_outlined,
          text: '${data.dueTodayTaskCount} à faire aujourd’hui',
          onTap: onOpenTasks,
        ),
      );
    } else if (data.pendingTaskCount > 0) {
      lines.add(
        _TodayLine(
          icon: Icons.checklist,
          text: '${data.pendingTaskCount} tâche(s) en attente',
          onTap: onOpenTasks,
        ),
      );
    }

    final sportTask = data.nextSportTask;
    if (sportTask != null) {
      final name = data.nextSportName ?? sportTask.title;
      final time = sportTask.dueTime;
      final timeLabel = time == null
          ? null
          : '${time.hour.toString().padLeft(2, '0')}:'
              '${time.minute.toString().padLeft(2, '0')}';
      lines.add(
        _TodayLine(
          icon: Icons.fitness_center,
          text: timeLabel == null ? name : '$name · $timeLabel',
          onTap: onOpenSport,
        ),
      );
    }

    final entry = data.todayEntry;
    if (entry != null) {
      final mood = entry.mood?.label;
      final energy = entry.energy?.label;
      final parts = <String>[
        if (mood != null) 'Humeur $mood',
        if (energy != null) 'Énergie $energy',
      ];
      lines.add(
        _TodayLine(
          icon: Icons.favorite,
          text: parts.isEmpty ? 'Entrée du jour enregistrée' : parts.join(' · '),
          onTap: onOpenWellbeing,
        ),
      );
    } else {
      lines.add(
        _TodayLine(
          icon: Icons.favorite_outline,
          text: 'entrée du jour à compléter',
          onTap: onOpenWellbeing,
        ),
      );
    }

    if (data.puzzleTotal > 0) {
      lines.add(
        _TodayLine(
          icon: Icons.extension,
          text: 'Puzzle ${data.puzzleCompleted} / ${data.puzzleTotal}',
          onTap: onOpenPuzzle,
        ),
      );
    }

    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final lines = _lines();
    if (lines.isEmpty) {
      return BloomEmptyState(
        icon: Icons.spa_outlined,
        accent: BloomTheme.accentGreen,
        message: 'Rien de prévu pour aujourd’hui — profite-en',
      );
    }

    return BloomCard(
      accent: BloomTheme.accentGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            InkWell(
              onTap: lines[i].onTap,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Icon(
                    lines[i].icon,
                    size: 18,
                    color: lines[i].emphasize
                        ? Theme.of(context).colorScheme.error
                        : BloomTheme.accentGreen,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lines[i].text,
                      style: TextStyle(
                        fontWeight: lines[i].emphasize
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: lines[i].emphasize
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoogleCalendarCard extends StatelessWidget {
  final VoidCallback? onOpenSettings;

  const _GoogleCalendarCard({this.onOpenSettings});

  Future<void> _openSettings(BuildContext context) async {
    if (onOpenSettings != null) {
      onOpenSettings!();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = SettingsService.current.googleCalendar;
    final email = prefs.accountEmail;

    if (email == null) {
      return BloomEmptyState(
        icon: Icons.calendar_month_outlined,
        accent: BloomTheme.planning,
        message: 'Connecte Google Calendar pour synchroniser tes tâches',
        actionLabel: 'Connecter',
        onAction: () => _openSettings(context),
      );
    }

    final calendarName = prefs.selectedCalendarName ?? 'Calendrier';

    return BloomCard(
      accent: BloomTheme.planning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connecté',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(email, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            calendarName,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => GoogleCalendarService.openGoogleCalendarApp(),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Ouvrir Google Calendar'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openSettings(context),
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Paramètres'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayLine {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final bool emphasize;

  const _TodayLine({
    required this.icon,
    required this.text,
    this.onTap,
    this.emphasize = false,
  });
}

class _TractionMiniCard extends StatelessWidget {
  final TractionProgressSummary summary;

  const _TractionMiniCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final latest = summary.latestAssistance!;
    final previous = summary.previousAssistance;
    String detail;
    if (previous != null) {
      final delta = previous - latest;
      if (delta > 0) {
        detail =
            'Assistance ${latest.toStringAsFixed(1)} kg (−${delta.toStringAsFixed(1)})';
      } else if (delta < 0) {
        detail =
            'Assistance ${latest.toStringAsFixed(1)} kg (+${(-delta).toStringAsFixed(1)})';
      } else {
        detail = 'Assistance ${latest.toStringAsFixed(1)} kg (stable)';
      }
    } else {
      detail = 'Assistance ${latest.toStringAsFixed(1)} kg';
    }

    return BloomCard(
      accent: BloomTheme.sport,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: BloomTheme.sport, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Traction assistée',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final DashboardSnapshot data;

  const _StatsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final rate = data.taskCompletionRate;
    final traction = data.tractionProgress;
    final chips = <Widget>[
      BloomStatChip(
        icon: Icons.fitness_center,
        label: 'Séances terminées',
        value: '${data.closedSessionCount}',
        accent: BloomTheme.sport,
      ),
      BloomStatChip(
        icon: Icons.repeat,
        label: 'Séries enregistrées',
        value: '${data.totalSetCount}',
        accent: BloomTheme.sport,
      ),
      BloomStatChip(
        icon: Icons.sports_gymnastics,
        label: 'Exercices',
        value: '${data.exerciseCatalogueCount}',
        accent: BloomTheme.sport,
      ),
      BloomStatChip(
        icon: Icons.calendar_today,
        label: 'Jours bien-être',
        value: '${data.wellbeingDayCount}',
        accent: BloomTheme.wellbeing,
      ),
      BloomStatChip(
        icon: Icons.water_drop_outlined,
        label: 'Cycles',
        value: '${data.periodCount}',
        accent: BloomTheme.wellbeing,
      ),
      BloomStatChip(
        icon: Icons.checklist,
        label: 'Tâches restantes',
        value: '${data.pendingTaskCount}',
        accent: BloomTheme.tasks,
      ),
      BloomStatChip(
        icon: Icons.warning_amber_outlined,
        label: 'En retard',
        value: '${data.overdueTaskCount}',
        accent: BloomTheme.tasks,
      ),
      BloomStatChip(
        icon: Icons.check_circle_outline,
        label: 'Terminées',
        value: '${data.completedTasksTotal}',
        accent: BloomTheme.tasks,
      ),
      if (rate != null)
        BloomStatChip(
          icon: Icons.percent,
          label: 'Taux de complétion',
          value: '${(rate * 100).round()} %',
          accent: BloomTheme.tasks,
        ),
      BloomStatChip(
        icon: Icons.extension,
        label: 'Puzzles',
        value: '${data.puzzleCompleted} / ${data.puzzleTotal}',
        accent: BloomTheme.puzzle,
      ),
      if (traction?.hasData == true)
        BloomStatChip(
          icon: Icons.trending_up,
          label: 'Traction (assistance)',
          value: '${traction!.latestAssistance!.toStringAsFixed(1)} kg',
          accent: BloomTheme.sport,
        ),
    ];

    return Column(
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          chips[i],
        ],
      ],
    );
  }
}

class _SportCard extends StatelessWidget {
  final DashboardSnapshot data;
  final VoidCallback? onOpen;

  const _SportCard({required this.data, this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (data.openSession != null) {
      return BloomCard(
        accent: BloomTheme.sport,
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle_fill, color: BloomTheme.sport),
                const SizedBox(width: 8),
                const Text(
                  'Séance en cours',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reprendre ta séance ouverte',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${data.exerciseCatalogueCount} exercices dans le catalogue',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    if (!data.hasSportHistory) {
      return BloomEmptyState(
        icon: Icons.fitness_center,
        accent: BloomTheme.sport,
        message: 'Aucune séance pour le moment',
        actionLabel: 'Commencer une séance',
        onAction: onOpen,
      );
    }

    final last = data.lastClosedSession!;
    final date =
        '${last.startedAt.day.toString().padLeft(2, '0')}/${last.startedAt.month.toString().padLeft(2, '0')}';

    return BloomCard(
      accent: BloomTheme.sport,
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dernière séance',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text('Le $date · ${data.closedSessionCount} terminée(s)'),
          const SizedBox(height: 6),
          Text(
            '${data.exerciseCatalogueCount} exercices · ${data.totalSetCount} séries',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _WellbeingCard extends StatelessWidget {
  final DashboardSnapshot data;
  final VoidCallback? onOpen;

  const _WellbeingCard({required this.data, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final entry = data.todayEntry;
    if (entry == null) {
      return BloomEmptyState(
        icon: Icons.favorite_outline,
        accent: BloomTheme.wellbeing,
        message: 'Ta journée n’est pas encore renseignée',
        actionLabel: 'Ajouter mon humeur',
        onAction: onOpen,
      );
    }

    final mood = entry.mood?.label ?? 'Pas renseignée';
    final energy = entry.energy?.label ?? 'Pas renseignée';

    return BloomCard(
      accent: BloomTheme.wellbeing,
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Humeur : $mood',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Énergie : $energy'),
          if (data.cycleStatus != null && data.cycleStatus!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              data.cycleStatus!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _TasksCard extends StatelessWidget {
  final DashboardSnapshot data;
  final VoidCallback? onOpen;

  const _TasksCard({required this.data, this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (data.pendingTaskCount == 0 && data.completedTasksToday == 0) {
      return BloomEmptyState(
        icon: Icons.checklist,
        accent: BloomTheme.tasks,
        message: 'Aucune tâche pour le moment',
        actionLabel: 'Voir mes tâches',
        onAction: onOpen,
      );
    }

    if (data.pendingTaskCount == 0) {
      return BloomCard(
        accent: BloomTheme.tasks,
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✨ ${data.completedTasksToday} terminée(s) aujourd’hui',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('Bravo, tout est fait !'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onOpen,
              child: const Text('Voir mes tâches'),
            ),
          ],
        ),
      );
    }

    return BloomCard(
      accent: BloomTheme.tasks,
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'À faire aujourd’hui',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text('${data.pendingTaskCount} tâche(s) restante(s)'),
          if (data.overdueTaskCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${data.overdueTaskCount} en retard',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (data.topPendingTaskTitles.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...data.topPendingTaskTitles.map(
              (title) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('· $title'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: onOpen,
            child: const Text('Voir mes tâches'),
          ),
        ],
      ),
    );
  }
}

class _PuzzleCard extends StatelessWidget {
  final DashboardSnapshot data;
  final VoidCallback? onOpen;

  const _PuzzleCard({required this.data, this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (!data.hasPuzzleProgress && data.nextPuzzleId == null) {
      return BloomEmptyState(
        icon: Icons.extension,
        accent: BloomTheme.puzzle,
        message: 'Tu n’as encore terminé aucun puzzle',
        actionLabel: 'Jouer',
        onAction: onOpen,
      );
    }

    if (!data.hasPuzzleProgress) {
      return BloomEmptyState(
        icon: Icons.extension,
        accent: BloomTheme.puzzle,
        message: 'Tu n’as encore terminé aucun puzzle',
        actionLabel: 'Jouer',
        onAction: onOpen,
      );
    }

    return BloomCard(
      accent: BloomTheme.puzzle,
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${data.puzzleCompleted} / ${data.puzzleTotal} terminés',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            data.nextPuzzleTitle == null
                ? 'Tous les puzzles sont terminés'
                : 'Continuer : ${data.nextPuzzleTitle}',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onOpen,
              child: const Text('Continuer'),
            ),
          ),
        ],
      ),
    );
  }
}
