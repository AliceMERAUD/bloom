import 'package:flutter/material.dart';

/// A user sport / activity (Natation, Vélo…), distinct from strength exercises.
class SportActivity {
  final String id;
  final String name;
  final String? description;
  final String iconName;
  final int colorValue;
  final DateTime createdAt;
  final bool enabled;
  final bool builtin;

  const SportActivity({
    required this.id,
    required this.name,
    this.description,
    this.iconName = 'sports',
    this.colorValue = 0xFF2E7D4F,
    required this.createdAt,
    this.enabled = true,
    this.builtin = false,
  });

  IconData get icon => sportIconFromName(iconName);

  Color get color => Color(colorValue);

  SportActivity copyWith({
    String? name,
    String? description,
    String? iconName,
    int? colorValue,
    bool? enabled,
    bool clearDescription = false,
  }) {
    return SportActivity(
      id: id,
      name: name ?? this.name,
      description:
          clearDescription ? null : (description ?? this.description),
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      enabled: enabled ?? this.enabled,
      builtin: builtin,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'iconName': iconName,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
        'enabled': enabled,
        'builtin': builtin,
      };

  factory SportActivity.fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    return SportActivity(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      iconName: data['iconName'] as String? ?? 'sports',
      colorValue: (data['colorValue'] as num?)?.toInt() ?? 0xFF2E7D4F,
      createdAt: DateTime.parse(data['createdAt'] as String),
      enabled: data['enabled'] as bool? ?? true,
      builtin: data['builtin'] as bool? ?? false,
    );
  }
}

IconData sportIconFromName(String name) {
  switch (name) {
    case 'fitness_center':
      return Icons.fitness_center;
    case 'pool':
      return Icons.pool;
    case 'directions_run':
      return Icons.directions_run;
    case 'directions_bike':
      return Icons.directions_bike;
    case 'sports_handball':
      return Icons.sports_handball;
    case 'self_improvement':
      return Icons.self_improvement;
    case 'sports_tennis':
      return Icons.sports_tennis;
    case 'music_note':
      return Icons.music_note;
    case 'terrain':
      return Icons.terrain;
    case 'sports_soccer':
      return Icons.sports_soccer;
    default:
      return Icons.sports;
  }
}

const kBuiltinStrengthSportId = 'strength';

/// Icons offered in the create/edit sport form.
const kSportIconChoices = <String>[
  'sports',
  'fitness_center',
  'pool',
  'directions_run',
  'directions_bike',
  'sports_handball',
  'self_improvement',
  'sports_tennis',
  'music_note',
  'terrain',
  'sports_soccer',
];
