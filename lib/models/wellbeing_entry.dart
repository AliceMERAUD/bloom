import 'wellbeing_enums.dart';

class WellbeingEntry {
  final String id;

  /// Calendar day (time component ignored; stored at local midnight).
  final DateTime date;

  final Mood? mood;
  final Energy? energy;
  final Pain pain;
  final Bleeding bleeding;
  final List<Symptom> symptoms;
  final String? note;
  final PeriodMarker periodMarker;

  const WellbeingEntry({
    required this.id,
    required this.date,
    this.mood,
    this.energy,
    this.pain = Pain.none,
    this.bleeding = Bleeding.none,
    this.symptoms = const [],
    this.note,
    this.periodMarker = PeriodMarker.none,
  });

  static DateTime normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String dateKey(DateTime value) {
    final day = normalizeDate(value);
    final month = day.month.toString().padLeft(2, '0');
    final dayNum = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$dayNum';
  }

  WellbeingEntry copyWith({
    String? id,
    DateTime? date,
    Mood? mood,
    Energy? energy,
    Pain? pain,
    Bleeding? bleeding,
    List<Symptom>? symptoms,
    String? note,
    PeriodMarker? periodMarker,
    bool clearMood = false,
    bool clearEnergy = false,
    bool clearNote = false,
  }) {
    return WellbeingEntry(
      id: id ?? this.id,
      date: date != null ? normalizeDate(date) : this.date,
      mood: clearMood ? null : (mood ?? this.mood),
      energy: clearEnergy ? null : (energy ?? this.energy),
      pain: pain ?? this.pain,
      bleeding: bleeding ?? this.bleeding,
      symptoms: symptoms ?? this.symptoms,
      note: clearNote ? null : (note ?? this.note),
      periodMarker: periodMarker ?? this.periodMarker,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': dateKey(date),
      'mood': mood?.name,
      'energy': energy?.name,
      'pain': pain.name,
      'bleeding': bleeding.name,
      'symptoms': symptoms.map((s) => s.name).toList(),
      'note': note,
      'periodMarker': periodMarker.name,
    };
  }

  factory WellbeingEntry.fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    final rawDate = data['date'];
    DateTime date;

    if (rawDate is String) {
      final parsed = DateTime.tryParse(rawDate);
      date = parsed != null
          ? normalizeDate(parsed)
          : normalizeDate(DateTime.now());
    } else {
      date = normalizeDate(DateTime.now());
    }

    final symptomNames = List<dynamic>.from(data['symptoms'] ?? const []);
    final symptoms = symptomNames
        .map((name) => SymptomX.fromName(name as String?))
        .whereType<Symptom>()
        .toList();

    return WellbeingEntry(
      id: data['id'] as String? ?? dateKey(date),
      date: date,
      mood: MoodX.fromName(data['mood'] as String?),
      energy: EnergyX.fromName(data['energy'] as String?),
      pain: PainX.fromName(data['pain'] as String?),
      bleeding: BleedingX.fromName(data['bleeding'] as String?),
      symptoms: symptoms,
      note: data['note'] as String?,
      periodMarker: PeriodMarkerX.fromName(data['periodMarker'] as String?),
    );
  }
}

/// A menstrual period derived only from recorded start/end markers.
class MenstrualPeriod {
  final DateTime start;
  final DateTime? end;

  const MenstrualPeriod({
    required this.start,
    this.end,
  });

  bool get isOngoing => end == null;

  int? get durationDays {
    if (end == null) return null;
    return end!.difference(start).inDays + 1;
  }
}
