import 'package:flutter/material.dart';

import '../../services/exercise_service.dart';
import '../../services/workout_session_service.dart';
import 'exercise_screen.dart';
import 'history_screen.dart';
import 'workout_summary_screen.dart';
import 'next_session_screen.dart';

class SportScreen extends StatelessWidget {
  const SportScreen({super.key});

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
                onPressed: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NextSessionScreen(),
                    ),
                    );
                },
                ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Nouvelle séance',
            onPressed: () async {
              await WorkoutSessionService.startSession();

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Séance démarrée ! 💪'),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: 'Terminer la séance',
            onPressed: () async {
              final sessionId =
                  WorkoutSessionService.currentSessionId;

              if (sessionId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Aucune séance en cours.'),
                  ),
                );
                return;
              }

              await WorkoutSessionService.endSession();

              if (!context.mounted) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutSummaryScreen(
                    sessionId: sessionId,
                  ),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: ListView.builder(
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

              subtitle: Text(
                exercise.description ?? '',
              ),

              trailing: const Icon(
                Icons.chevron_right,
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseScreen(
                      exercise: exercise,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}