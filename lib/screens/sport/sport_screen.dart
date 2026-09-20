import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/sport_activity.dart';
import '../../services/dashboard_service.dart';
import '../../services/exercise_service.dart';
import '../../services/sport_activity_service.dart';
import '../../services/workout_session_service.dart';
import '../../widgets/common/bloom_widgets.dart';
import 'exercise_screen.dart';
import 'history_screen.dart';
import 'next_session_screen.dart';
import 'progress_screen.dart';
import 'sport_activities_screen.dart';
import 'sport_activity_form_screen.dart';
import 'sport_bag_screen.dart';
import 'workout_summary_screen.dart';

class SportScreen extends StatefulWidget {
  const SportScreen({super.key});

  @override
  State<SportScreen> createState() => SportScreenState();
}

class SportScreenState extends State<SportScreen> {
  bool hasOpenSession = false;
  List<SportActivity> _activities = [];

  @override
  void initState() {
    super.initState();
    hasOpenSession = WorkoutSessionService.hasOpenSession;
    _reloadActivities();
    _refreshSessionState();
  }

  void _reloadActivities() {
    List<SportActivity> activities = const [];
    try {
      activities = SportActivityService.getAll();
    } catch (_) {
      // Hive may be unavailable in widget tests / edge cases.
    }
    setState(() {
      _activities = activities;
    });
  }

  Future<void> _refreshSessionState() async {
    try {
      await WorkoutSessionService.restoreFromStorage();
    } catch (_) {
      // Hive may be unavailable in edge cases; treat as no open session.
    }

    if (!mounted) return;

    setState(() {
      hasOpenSession = WorkoutSessionService.hasOpenSession;
    });
  }

  /// Used by Home shortcuts to jump into a musculation session.
  Future<void> startSessionFromShortcut() => _startSessionPressed();

  Future<void> _startSessionPressed() async {
    final result = await WorkoutSessionService.startSession();

    if (!mounted) return;

    if (result.outcome == StartSessionOutcome.conflict) {
      await _showOpenSessionDialog();
      return;
    }

    setState(() {
      hasOpenSession = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Séance démarrée ! 💪')),
    );
  }

  Future<void> _showOpenSessionDialog() async {
    final choice = await showDialog<_OpenSessionChoice>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Séance déjà en cours'),
          content: const Text(
            'Une séance est déjà ouverte. Que souhaites-tu faire ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                _OpenSessionChoice.resume,
              ),
              child: const Text('Reprendre'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                _OpenSessionChoice.replace,
              ),
              child: const Text('Terminer et en démarrer une nouvelle'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                _OpenSessionChoice.cancel,
              ),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );

    if (!mounted || choice == null || choice == _OpenSessionChoice.cancel) {
      return;
    }

    if (choice == _OpenSessionChoice.resume) {
      setState(() {
        hasOpenSession = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Séance reprise. Continue à logger !')),
      );
      return;
    }

    final previousId = WorkoutSessionService.currentSessionId;
    final result = await WorkoutSessionService.startSession(forceNew: true);

    if (!mounted) return;

    setState(() {
      hasOpenSession = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nouvelle séance démarrée ! 💪')),
    );

    if (previousId != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutSummaryScreen(sessionId: previousId),
        ),
      );
      if (mounted) {
        await _refreshSessionState();
      }
    } else if (result.outcome == StartSessionOutcome.created) {
      await _refreshSessionState();
    }
  }

  Future<void> _endSessionPressed() async {
    final sessionId = WorkoutSessionService.currentSessionId;

    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune séance en cours.')),
      );
      await _refreshSessionState();
      return;
    }

    await WorkoutSessionService.endSession();

    if (!mounted) return;

    setState(() {
      hasOpenSession = false;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryScreen(sessionId: sessionId),
      ),
    );

    if (mounted) {
      await _refreshSessionState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ExerciseService.getAll();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sport'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Ma prochaine séance',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NextSessionScreen(),
                ),
              );
              if (mounted) {
                await _refreshSessionState();
              }
            },
          ),
          IconButton(
            icon: Icon(
              hasOpenSession ? Icons.play_circle_fill : Icons.play_arrow,
            ),
            tooltip: hasOpenSession ? 'Séance en cours' : 'Nouvelle séance',
            onPressed: _startSessionPressed,
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: 'Terminer la séance',
            onPressed: _endSessionPressed,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                ),
              );
              if (mounted) {
                await _refreshSessionState();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (hasOpenSession)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.timelapse),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Séance en cours — logge des séries ou termine.',
                      ),
                    ),
                    TextButton(
                      onPressed: _endSessionPressed,
                      child: const Text('Terminer'),
                    ),
                  ],
                ),
              ),
            ),
          const _TractionGoalCard(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SportActivitiesScreen(),
                      ),
                    );
                    if (mounted) _reloadActivities();
                  },
                  icon: const Icon(Icons.sports),
                  label: const Text('Mes sports'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SportBagScreen(),
                      ),
                    );
                    if (mounted) _reloadActivities();
                  },
                  icon: const Icon(Icons.backpack_outlined),
                  label: const Text('Sac de sport'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Activités',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SportActivityFormScreen(),
                    ),
                  );
                  if (mounted) _reloadActivities();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Aucun sport enregistré.'),
            )
          else
            ..._activities.map(
              (activity) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: activity.color.withValues(alpha: 0.2),
                    child: Icon(activity.icon, color: activity.color),
                  ),
                  title: Text(activity.name),
                  subtitle: Text(
                    activity.description ??
                        (activity.builtin ? 'Sport intégré' : ''),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    if (activity.id == kBuiltinStrengthSportId) {
                      return;
                    }
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SportActivityFormScreen(activity: activity),
                      ),
                    );
                    if (mounted) _reloadActivities();
                  },
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Musculation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Exercices et séances de force',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ...exercises.map(
            (exercise) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.fitness_center),
                ),
                title: Text(
                  exercise.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(exercise.description ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExerciseScreen(
                        exercise: exercise,
                      ),
                    ),
                  );
                  if (mounted) {
                    await _refreshSessionState();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _OpenSessionChoice {
  resume,
  replace,
  cancel,
}

class _TractionGoalCard extends StatelessWidget {
  const _TractionGoalCard();

  @override
  Widget build(BuildContext context) {
    TractionProgressSummary? summary;
    try {
      summary = DashboardService.load().tractionProgress;
    } catch (_) {
      summary = null;
    }

    final hasData = summary?.hasData == true;
    String body;
    if (!hasData) {
      body = 'Commence une séance pour suivre ta progression.';
    } else if (summary!.previousAssistance != null &&
        summary.latestAssistance != null) {
      body =
          'Dernière progression : ${summary.previousAssistance!.toStringAsFixed(1)} kg → '
          '${summary.latestAssistance!.toStringAsFixed(1)} kg d’assistance\n'
          'Continue comme ça !';
    } else {
      body =
          'Dernière assistance : ${summary.latestAssistance!.toStringAsFixed(1)} kg\n'
          'Continue comme ça !';
    }

    return BloomCard(
      accent: BloomTheme.sport,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProgressScreen(exerciseId: 'pull_up_assisted'),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BloomTheme.sport.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fitness_center, color: BloomTheme.sport),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '💪 Traction stricte',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: 10),
          Text(body),
        ],
      ),
    );
  }
}
