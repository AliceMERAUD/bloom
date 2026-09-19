class WorkoutSession {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<String> setIds;

  const WorkoutSession({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.setIds,
  });

  bool get isOpen => endedAt == null;

  /// Duration of a closed session; null while the session is still open.
  Duration? get duration {
    if (endedAt == null) {
      return null;
    }
    return endedAt!.difference(startedAt);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      // `date` conservé pour compatibilité avec les données déjà enregistrées.
      'date': startedAt.toIso8601String(),
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'setIds': setIds,
    };
  }

  factory WorkoutSession.fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);

    final startedAt = _parseRequiredDate(
      data['startedAt'] ?? data['date'],
    );

    return WorkoutSession(
      id: data['id'] as String,
      startedAt: startedAt,
      endedAt: _parseOptionalDate(data['endedAt']),
      setIds: List<String>.from(data['setIds'] ?? <String>[]),
    );
  }

  WorkoutSession copyWith({
    DateTime? startedAt,
    DateTime? endedAt,
    List<String>? setIds,
    bool clearEndedAt = false,
  }) {
    return WorkoutSession(
      id: id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      setIds: setIds ?? this.setIds,
    );
  }

  static DateTime _parseRequiredDate(dynamic value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
