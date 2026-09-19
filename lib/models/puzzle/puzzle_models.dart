enum PuzzleDifficulty {
  easy,
  medium,
  hard,
}

extension PuzzleDifficultyX on PuzzleDifficulty {
  String get label {
    switch (this) {
      case PuzzleDifficulty.easy:
        return 'Facile';
      case PuzzleDifficulty.medium:
        return 'Moyen';
      case PuzzleDifficulty.hard:
        return 'Difficile';
    }
  }
}

class PuzzleCharacter {
  final String id;
  final String name;

  /// Optional future asset key (pose variants later).
  final String? assetKey;

  const PuzzleCharacter({
    required this.id,
    required this.name,
    this.assetKey,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'assetKey': assetKey,
      };

  factory PuzzleCharacter.fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    return PuzzleCharacter(
      id: data['id'] as String,
      name: data['name'] as String,
      assetKey: data['assetKey'] as String?,
    );
  }
}

class PuzzlePosition {
  final String id;
  final int index;
  final String? label;

  const PuzzlePosition({
    required this.id,
    required this.index,
    this.label,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'index': index,
        'label': label,
      };

  factory PuzzlePosition.fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    return PuzzlePosition(
      id: data['id'] as String,
      index: (data['index'] as num).toInt(),
      label: data['label'] as String?,
    );
  }
}

/// Current assignment of characters to seat indices.
class PuzzlePlacement {
  /// characterId -> position index
  final Map<String, int> seats;

  const PuzzlePlacement([this.seats = const {}]);

  bool get isEmpty => seats.isEmpty;

  int? indexOf(String characterId) => seats[characterId];

  String? characterAt(int index) {
    for (final entry in seats.entries) {
      if (entry.value == index) return entry.key;
    }
    return null;
  }

  PuzzlePlacement place(String characterId, int index) {
    final next = Map<String, int>.from(seats);

    // Free the target seat if occupied.
    next.removeWhere((_, seat) => seat == index);

    // Move or place the character.
    next[characterId] = index;
    return PuzzlePlacement(next);
  }

  PuzzlePlacement remove(String characterId) {
    final next = Map<String, int>.from(seats)..remove(characterId);
    return PuzzlePlacement(next);
  }

  PuzzlePlacement swap(String a, String b) {
    final ia = seats[a];
    final ib = seats[b];
    if (ia == null || ib == null) return this;
    final next = Map<String, int>.from(seats);
    next[a] = ib;
    next[b] = ia;
    return PuzzlePlacement(next);
  }

  Map<String, dynamic> toMap() => {'seats': seats};

  factory PuzzlePlacement.fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    final raw = Map<dynamic, dynamic>.from(data['seats'] as Map? ?? {});
    final seats = <String, int>{};
    raw.forEach((key, value) {
      seats[key.toString()] = (value as num).toInt();
    });
    return PuzzlePlacement(seats);
  }
}
