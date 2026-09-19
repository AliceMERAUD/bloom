import 'package:flutter/material.dart';

import '../../models/workout_session.dart';
import '../../models/workout_set.dart';
import '../../services/exercise_service.dart';
import '../../services/storage_service.dart';

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;

  const SessionDetailScreen({
    super.key,
    required this.sessionId,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  bool loading = true;
  WorkoutSession? session;
  List<WorkoutSet> sets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loadedSession = await StorageService.getSession(widget.sessionId);
    final loadedSets = await StorageService.getSessionSets(widget.sessionId);

    if (!mounted) return;

    setState(() {
      session = loadedSession;
      sets = loadedSets;
      loading = false;
    });
  }

  String getExerciseName(String exerciseId) {
    for (final exercise in ExerciseService.getAll()) {
      if (exercise.id == exerciseId) {
        return exercise.name;
      }
    }
    return 'Exercice';
  }

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

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    if (minutes > 0) {
      return '$minutes min ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }

  String setDetails(WorkoutSet set) {
    var details = '${set.repetitions} répétitions';

    if (set.assistance != null) {
      details += ' • Assistance : ${set.assistance} kg';
    }
    if (set.weight != null) {
      details += ' • Charge : ${set.weight} kg';
    }
    if (set.durationSeconds != null) {
      details += ' • ${set.durationSeconds}s';
    }

    return details;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final current = session;
    if (current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Séance')),
        body: const Center(child: Text('Séance introuvable.')),
      );
    }

    final totalRepetitions = sets.fold<int>(
      0,
      (total, set) => total + set.repetitions,
    );
    final exerciseCount = sets.map((set) => set.exerciseId).toSet().length;

    return Scaffold(
      appBar: AppBar(
        title: Text(current.isOpen ? 'Séance en cours' : 'Détail de la séance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            formatDateTime(current.startedAt),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('Durée : ${formatDuration(current.duration)}'),
          Text(
            '${sets.length} séries • $totalRepetitions répétitions • '
            '$exerciseCount exercice${exerciseCount > 1 ? 's' : ''}',
          ),
          if (current.isOpen) ...[
            const SizedBox(height: 8),
            const Text(
              'Cette séance n’est pas encore clôturée.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Séries réalisées',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (sets.isEmpty)
            const Text('Aucune série enregistrée pour cette séance.')
          else
            ...sets.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final set = entry.value;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('$index')),
                  title: Text(getExerciseName(set.exerciseId)),
                  subtitle: Text(setDetails(set)),
                ),
              );
            }),
        ],
      ),
    );
  }
}
