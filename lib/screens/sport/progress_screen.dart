import 'package:flutter/material.dart';

import '../../services/exercise_service.dart';
import '../../services/storage_service.dart';

class ProgressScreen extends StatefulWidget {
  final String exerciseId;

  const ProgressScreen({
    super.key,
    required this.exerciseId,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool loading = true;

  List<Map<String, dynamic>> sets = [];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final result =
        await StorageService.getSetsForExercise(
      widget.exerciseId,
    );

    if (!mounted) return;

    setState(() {
      sets = result;
      loading = false;
    });
  }

  String _exerciseName() {
    final exercises = ExerciseService.getAll();

    for (final exercise in exercises) {
      if (exercise.id == widget.exerciseId) {
        return exercise.name;
      }
    }

    return 'Exercice';
  }

  int _maxRepetitions() {
    if (sets.isEmpty) return 0;

    return sets
        .map(
          (set) => (set['repetitions'] ?? 0) as num,
        )
        .map((value) => value.toInt())
        .reduce((a, b) => a > b ? a : b);
  }

  double? _maxWeight() {
    final weights = sets
        .map((set) => set['weight'])
        .where((value) => value != null)
        .map((value) => (value as num).toDouble())
        .toList();

    if (weights.isEmpty) return null;

    return weights.reduce((a, b) => a > b ? a : b);
  }

  double? _bestAssistance() {
    final assistance = sets
        .map((set) => set['assistance'])
        .where((value) => value != null)
        .map((value) => (value as num).toDouble())
        .toList();

    if (assistance.isEmpty) return null;

    // Pour une traction assistée, moins d'assistance = mieux.
    return assistance.reduce((a, b) => a < b ? a : b);
  }

  int _totalRepetitions() {
    return sets.fold(
      0,
      (total, set) =>
          total +
          ((set['repetitions'] ?? 0) as num).toInt(),
    );
  }

  double _totalVolume() {
    return sets.fold(
      0.0,
      (total, set) {
        final weight = set['weight'];

        if (weight == null) {
          return total;
        }

        final repetitions =
            ((set['repetitions'] ?? 0) as num).toDouble();

        return total +
            (weight as num).toDouble() *
                repetitions;
      },
    );
  }

  String _nextGoal() {
    if (sets.isEmpty) {
      return 'Fais une première série pour commencer !';
    }

    final lastSet = sets.last;

    final repetitions =
        ((lastSet['repetitions'] ?? 0) as num).toInt();

    final assistance = lastSet['assistance'];

    if (assistance != null) {
      final assistanceValue =
          (assistance as num).toDouble();

      if (repetitions >= 8) {
        final nextAssistance =
            (assistanceValue - 2.5).clamp(0, 999);

        return 'Objectif : $repetitions reps avec '
            '${nextAssistance.toStringAsFixed(1)} kg '
            'd’assistance.';
      }

      return 'Objectif : atteindre 8 répétitions '
          'avec ${assistanceValue.toStringAsFixed(1)} kg '
          'd’assistance.';
    }

    if (repetitions >= 10) {
      return 'Objectif : ajouter 1 à 2 répétitions '
          'la prochaine fois.';
    }

    return 'Objectif : dépasser $repetitions répétitions.';
  }

  @override
  Widget build(BuildContext context) {
    final name = _exerciseName();

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : sets.isEmpty
              ? const Center(
                  child: Text(
                    'Pas encore de données 📊',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProgress,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildGoalCard(),

                      const SizedBox(height: 20),

                      const Text(
                        'Tes statistiques',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _buildStats(),

                      const SizedBox(height: 24),

                      const Text(
                        'Historique',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ...sets.reversed
                          .toList()
                          .asMap()
                          .entries
                          .map(
                        (entry) {
                          final set = entry.value;

                          return _buildSetCard(
                            set,
                            sets.length - entry.key,
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildGoalCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flag),
                SizedBox(width: 8),
                Text(
                  'Objectif suivant',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _nextGoal(),
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final maxWeight = _maxWeight();
    final bestAssistance = _bestAssistance();
    final totalVolume = _totalVolume();

    return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
        children: [
        _statCard(
            'Meilleur',
            '${_maxRepetitions()} reps',
            Icons.repeat,
        ),
        _statCard(
            'Total',
            '${_totalRepetitions()} reps',
            Icons.numbers,
        ),
        _statCard(
            'Charge max',
            maxWeight == null
                ? '-'
                : '${maxWeight.toStringAsFixed(1)} kg',
            Icons.fitness_center,
        ),
        _statCard(
            'Meilleure assistance',
            bestAssistance == null
                ? '-'
                : '${bestAssistance.toStringAsFixed(1)} kg',
            Icons.trending_down,
        ),
        _statCard(
            'Volume total',
            totalVolume == 0
                ? '-'
                : '${totalVolume.toStringAsFixed(0)} kg',
            Icons.bar_chart,
        ),
        ],
    );
    }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _buildSetCard(
    Map<String, dynamic> set,
    int number,
  ) {
    final repetitions =
        set['repetitions'] ?? 0;

    final weight = set['weight'];
    final assistance = set['assistance'];

    String subtitle =
        '$repetitions répétitions';

    if (assistance != null) {
      subtitle +=
          ' • Assistance : $assistance kg';
    }

    if (weight != null) {
      subtitle +=
          ' • Charge : $weight kg';
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text('$number'),
        ),
        title: Text(
          _exerciseName(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}