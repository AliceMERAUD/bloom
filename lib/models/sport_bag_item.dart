/// An item in the sport bag checklist (general or per-sport).
class SportBagItem {
  final String id;
  final String name;
  final String? sportId;
  final bool checked;
  final DateTime createdAt;

  const SportBagItem({
    required this.id,
    required this.name,
    this.sportId,
    this.checked = false,
    required this.createdAt,
  });

  bool get isGeneral => sportId == null;

  SportBagItem copyWith({
    String? name,
    String? sportId,
    bool? checked,
    bool clearSportId = false,
  }) {
    return SportBagItem(
      id: id,
      name: name ?? this.name,
      sportId: clearSportId ? null : (sportId ?? this.sportId),
      checked: checked ?? this.checked,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'sportId': sportId,
        'checked': checked,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SportBagItem.fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    return SportBagItem(
      id: data['id'] as String,
      name: data['name'] as String,
      sportId: data['sportId'] as String?,
      checked: data['checked'] as bool? ?? false,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }
}
