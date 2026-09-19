import 'package:flutter/material.dart';

import '../../services/exercise_service.dart';
import '../../services/workout_session_service.dart';
import 'exercise_screen.dart';
import 'history_screen.dart';
import 'next_session_screen.dart';
import 'workout_summary_screen.dart';

class SportScreen extends StatefulWidget {
  const SportScreen({super.key});

  @override
  State<SportScreen> createState() => _SportScreenState();
}

class _SportScreenState extends State<SportScreen> {
  bool hasOpenSession = false;

  @override
  void initState() {
    super.initState();
    hasOpenSession = WorkoutSessionService.hasOpenSession;
    _refreshSessionState();
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
      body: Column(
              children: [
                if (hasOpenSession)
                  Card(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];

                      return Card(
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
                      );
                    },
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
