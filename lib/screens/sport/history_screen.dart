import 'package:flutter/material.dart';

import '../../models/workout_session.dart';
import '../../models/workout_set.dart';
import '../../services/exercise_service.dart';
import '../../services/storage_service.dart';
import 'session_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String formatDateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} à '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String formatDuration(Duration? duration) {
    if (duration == null) {
      return 'En cours';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
    }
    if (minutes > 0) {
      return '$minutes min';
    }
    return '${seconds}s';
  }

  Future<List<_SessionSummary>> _loadSummaries() async {
    final sessions = StorageService.getAllSessions();
    final summaries = <_SessionSummary>[];

    for (final session in sessions) {
      final sets = await StorageService.getSessionSets(session.id);
      summaries.add(_SessionSummary(session: session, sets: sets));
    }

    return summaries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
      ),
      body: FutureBuilder<List<_SessionSummary>>(
        future: _loadSummaries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final summaries = snapshot.data ?? const <_SessionSummary>[];

          if (summaries.isEmpty) {
            return const Center(
              child: Text(
                'Aucune séance enregistrée pour le moment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: summaries.length,
            itemBuilder: (context, index) {
              final summary = summaries[index];
              final session = summary.session;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      session.isOpen ? Icons.timelapse : Icons.fitness_center,
                    ),
                  ),
                  title: Text(
                    session.isOpen
                        ? 'Séance en cours'
                        : 'Séance du ${formatDateTime(session.startedAt)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${formatDateTime(session.startedAt)}\n'
                    'Durée : ${formatDuration(session.duration)} • '
                    '${summary.exerciseCount} exercice'
                    '${summary.exerciseCount > 1 ? 's' : ''} • '
                    '${summary.sets.length} série'
                    '${summary.sets.length > 1 ? 's' : ''}\n'
                    '${summary.exerciseNames}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionDetailScreen(
                          sessionId: session.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SessionSummary {
  final WorkoutSession session;
  final List<WorkoutSet> sets;

  const _SessionSummary({
    required this.session,
    required this.sets,
  });

  int get exerciseCount => sets.map((set) => set.exerciseId).toSet().length;

  String get exerciseNames {
    if (sets.isEmpty) {
      return 'Aucune série';
    }

    final names = sets
        .map((set) => set.exerciseId)
        .toSet()
        .map(_exerciseName)
        .toList();

    if (names.length <= 3) {
      return names.join(', ');
    }

    return '${names.take(3).join(', ')}…';
  }

  String _exerciseName(String id) {
    for (final exercise in ExerciseService.getAll()) {
      if (exercise.id == id) {
        return exercise.name;
      }
    }
    return id;
  }
}
