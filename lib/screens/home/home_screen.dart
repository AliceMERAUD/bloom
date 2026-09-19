import 'package:flutter/material.dart';

import '../../models/wellbeing_enums.dart';
import '../../services/dashboard_service.dart';
import '../../services/workout_session_service.dart';
import '../../widgets/common/bloom_widgets.dart';

/// Personalized local-first home dashboard.
class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenSport;
  final VoidCallback? onOpenWellbeing;
  final VoidCallback? onOpenTasks;
  final VoidCallback? onOpenPuzzle;
  final VoidCallback? onOpenSettings;

  const HomeScreen({
    super.key,
    this.onOpenSport,
    this.onOpenWellbeing,
    this.onOpenTasks,
    this.onOpenPuzzle,
    this.onOpenSettings,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DashboardSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _reload();
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
                'Aujourd’hui sur Bloom',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              BloomSection(
                title: 'Sport',
                child: _SportCard(
                  data: data,
                  onOpen: widget.onOpenSport,
                ),
              ),
              const SizedBox(height: 20),
              BloomSection(
                title: 'Bien-être',
                child: _WellbeingCard(
                  data: data,
                  onOpen: widget.onOpenWellbeing,
                ),
              ),
              const SizedBox(height: 20),
              BloomSection(
                title: 'Tasks',
                child: _TasksCard(
                  data: data,
                  onOpen: widget.onOpenTasks,
                ),
              ),
              const SizedBox(height: 20),
              BloomSection(
                title: 'Puzzle',
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
                      onPressed: widget.onOpenSport,
                      icon: const Icon(Icons.fitness_center, size: 18),
                      label: const Text('Séance'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: widget.onOpenWellbeing,
                      icon: const Icon(Icons.favorite, size: 18),
                      label: const Text('Humeur'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: widget.onOpenTasks,
                      icon: const Icon(Icons.checklist, size: 18),
                      label: const Text('Tasks'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: widget.onOpenPuzzle,
                      icon: const Icon(Icons.extension, size: 18),
                      label: const Text('Puzzle'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              BloomSection(
                title: 'Statistiques',
                subtitle: 'Calculées à partir de tes données locales',
                child: Column(
                  children: [
                    BloomStatChip(
                      icon: Icons.fitness_center,
                      label: 'Séances terminées',
                      value: '${data.closedSessionCount}',
                    ),
                    const SizedBox(height: 8),
                    BloomStatChip(
                      icon: Icons.repeat,
                      label: 'Séries enregistrées',
                      value: '${data.totalSetCount}',
                    ),
                    const SizedBox(height: 8),
                    BloomStatChip(
                      icon: Icons.calendar_today,
                      label: 'Jours bien-être',
                      value: '${data.wellbeingDayCount}',
                    ),
                    const SizedBox(height: 8),
                    BloomStatChip(
                      icon: Icons.checklist,
                      label: 'Tâches à faire',
                      value: '${data.pendingTaskCount}',
                    ),
                    const SizedBox(height: 8),
                    BloomStatChip(
                      icon: Icons.extension,
                      label: 'Puzzles terminés',
                      value: '${data.puzzleCompleted} / ${data.puzzleTotal}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle_fill,
                    color: Theme.of(context).colorScheme.primary),
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
        message: 'Aucune séance pour le moment',
        actionLabel: 'Commencer une séance',
        onAction: onOpen,
      );
    }

    final last = data.lastClosedSession!;
    final date =
        '${last.startedAt.day.toString().padLeft(2, '0')}/${last.startedAt.month.toString().padLeft(2, '0')}';

    return BloomCard(
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
        message: 'Ta journée n’est pas encore renseignée',
        actionLabel: 'Ajouter mon humeur',
        onAction: onOpen,
      );
    }

    final mood = entry.mood?.label ?? 'Pas renseignée';
    final energy = entry.energy?.label ?? 'Pas renseignée';

    return BloomCard(
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
        message: 'Aucune tâche pour le moment',
        actionLabel: 'Voir mes tâches',
        onAction: onOpen,
      );
    }

    if (data.pendingTaskCount == 0) {
      return BloomCard(
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
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'À faire aujourd’hui',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text('${data.pendingTaskCount} tâche(s) restante(s)'),
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
        message: 'Tu n’as encore terminé aucun puzzle',
        actionLabel: 'Jouer',
        onAction: onOpen,
      );
    }

    if (!data.hasPuzzleProgress) {
      return BloomEmptyState(
        icon: Icons.extension,
        message: 'Tu n’as encore terminé aucun puzzle',
        actionLabel: 'Jouer',
        onAction: onOpen,
      );
    }

    return BloomCard(
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
