enum Mood {
  veryBad,
  bad,
  neutral,
  good,
  veryGood,
}

extension MoodX on Mood {
  String get label {
    switch (this) {
      case Mood.veryBad:
        return 'Très mauvaise';
      case Mood.bad:
        return 'Mauvaise';
      case Mood.neutral:
        return 'Neutre';
      case Mood.good:
        return 'Bonne';
      case Mood.veryGood:
        return 'Très bonne';
    }
  }

  /// 1–5 scale for simple charts.
  int get score {
    switch (this) {
      case Mood.veryBad:
        return 1;
      case Mood.bad:
        return 2;
      case Mood.neutral:
        return 3;
      case Mood.good:
        return 4;
      case Mood.veryGood:
        return 5;
    }
  }

  static Mood? fromName(String? name) {
    if (name == null) return null;
    for (final value in Mood.values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

enum Energy {
  veryLow,
  low,
  medium,
  good,
  veryGood,
}

extension EnergyX on Energy {
  String get label {
    switch (this) {
      case Energy.veryLow:
        return 'Très faible';
      case Energy.low:
        return 'Faible';
      case Energy.medium:
        return 'Moyenne';
      case Energy.good:
        return 'Bonne';
      case Energy.veryGood:
        return 'Très bonne';
    }
  }

  int get score {
    switch (this) {
      case Energy.veryLow:
        return 1;
      case Energy.low:
        return 2;
      case Energy.medium:
        return 3;
      case Energy.good:
        return 4;
      case Energy.veryGood:
        return 5;
    }
  }

  static Energy? fromName(String? name) {
    if (name == null) return null;
    for (final value in Energy.values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

enum Pain {
  none,
  mild,
  medium,
  strong,
  veryStrong,
}

extension PainX on Pain {
  String get label {
    switch (this) {
      case Pain.none:
        return 'Aucune';
      case Pain.mild:
        return 'Légère';
      case Pain.medium:
        return 'Moyenne';
      case Pain.strong:
        return 'Forte';
      case Pain.veryStrong:
        return 'Très forte';
    }
  }

  int get score {
    switch (this) {
      case Pain.none:
        return 0;
      case Pain.mild:
        return 1;
      case Pain.medium:
        return 2;
      case Pain.strong:
        return 3;
      case Pain.veryStrong:
        return 4;
    }
  }

  static Pain fromName(String? name) {
    if (name == null) return Pain.none;
    for (final value in Pain.values) {
      if (value.name == name) return value;
    }
    return Pain.none;
  }
}

enum Bleeding {
  none,
  light,
  medium,
  heavy,
}

extension BleedingX on Bleeding {
  String get label {
    switch (this) {
      case Bleeding.none:
        return 'Aucun';
      case Bleeding.light:
        return 'Léger';
      case Bleeding.medium:
        return 'Moyen';
      case Bleeding.heavy:
        return 'Fort';
    }
  }

  bool get isPresent => this != Bleeding.none;

  static Bleeding fromName(String? name) {
    if (name == null) return Bleeding.none;
    for (final value in Bleeding.values) {
      if (value.name == name) return value;
    }
    return Bleeding.none;
  }
}

enum Symptom {
  cramps,
  headache,
  fatigue,
  nausea,
  bloating,
  soreBreasts,
  other,
}

extension SymptomX on Symptom {
  String get label {
    switch (this) {
      case Symptom.cramps:
        return 'Crampes';
      case Symptom.headache:
        return 'Mal de tête';
      case Symptom.fatigue:
        return 'Fatigue';
      case Symptom.nausea:
        return 'Nausée';
      case Symptom.bloating:
        return 'Ballonnement';
      case Symptom.soreBreasts:
        return 'Seins sensibles';
      case Symptom.other:
        return 'Autre';
    }
  }

  static Symptom? fromName(String? name) {
    if (name == null) return null;
    for (final value in Symptom.values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

/// Optional marker that this day starts or ends a menstrual period.
enum PeriodMarker {
  none,
  start,
  end,
}

extension PeriodMarkerX on PeriodMarker {
  String get label {
    switch (this) {
      case PeriodMarker.none:
        return 'Aucun';
      case PeriodMarker.start:
        return 'Début des règles';
      case PeriodMarker.end:
        return 'Fin des règles';
    }
  }

  static PeriodMarker fromName(String? name) {
    if (name == null) return PeriodMarker.none;
    for (final value in PeriodMarker.values) {
      if (value.name == name) return value;
    }
    return PeriodMarker.none;
  }
}
