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

  /// Per-sport local reminder preferences.
  final bool notificationEnabled;
  final String? notificationMessage;
  final String? notificationBagMessage;
  final int notificationMinutesBefore;

  const SportActivity({
    required this.id,
    required this.name,
    this.description,
    this.iconName = 'sports',
    this.colorValue = 0xFF2E7D4F,
    required this.createdAt,
    this.enabled = true,
    this.builtin = false,
    this.notificationEnabled = true,
    this.notificationMessage,
    this.notificationBagMessage,
    this.notificationMinutesBefore = 30,
  });

  IconData get icon => sportIconFromName(iconName);

  Color get color => Color(colorValue);

  /// Default body when no custom message is set.
  String defaultNotificationMessage({int? minutesBefore}) {
    final mins = minutesBefore ?? notificationMinutesBefore;
    final lead = mins <= 0 ? 'C’est l’heure' : 'Dans $mins min';
    switch (iconName) {
      case 'fitness_center':
        return '💪 $lead de ta séance ! Prête à soulever du lourd ?';
      case 'pool':
        return '🏊 Piscine${mins > 0 ? ' dans $mins min' : ''} ! '
            'N’oublie pas ton maillot et ta serviette.';
      case 'sports_handball':
        return '🤾 C’est l’heure du hand ! Vérifie ton sac avant de partir.';
      case 'directions_run':
        return '🏃 $lead de ta course !';
      case 'directions_bike':
        return '🚴 $lead du vélo !';
      case 'self_improvement':
        return '🧘 $lead de ton yoga / détente.';
      case 'sports_tennis':
        return '🎾 $lead du tennis !';
      case 'music_note':
        return '💃 $lead de la danse !';
      default:
        return '🏅 $lead — $name !';
    }
  }

  String defaultBagMessage() =>
      notificationBagMessage?.trim().isNotEmpty == true
          ? notificationBagMessage!.trim()
          : 'Pense à ton sac !';

  String resolvedNotificationBody({required bool includeBagHint}) {
    final base = notificationMessage?.trim().isNotEmpty == true
        ? notificationMessage!.trim()
        : defaultNotificationMessage();
    if (!includeBagHint) return base;
    final bag = defaultBagMessage();
    if (base.contains(bag) || base.toLowerCase().contains('sac')) {
      return base;
    }
    return '$base $bag';
  }

  SportActivity copyWith({
    String? name,
    String? description,
    String? iconName,
    int? colorValue,
    bool? enabled,
    bool? notificationEnabled,
    String? notificationMessage,
    String? notificationBagMessage,
    int? notificationMinutesBefore,
    bool clearDescription = false,
    bool clearNotificationMessage = false,
    bool clearNotificationBagMessage = false,
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
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationMessage: clearNotificationMessage
          ? null
          : (notificationMessage ?? this.notificationMessage),
      notificationBagMessage: clearNotificationBagMessage
          ? null
          : (notificationBagMessage ?? this.notificationBagMessage),
      notificationMinutesBefore:
          notificationMinutesBefore ?? this.notificationMinutesBefore,
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
        'notificationEnabled': notificationEnabled,
        'notificationMessage': notificationMessage,
        'notificationBagMessage': notificationBagMessage,
        'notificationMinutesBefore': notificationMinutesBefore,
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
      notificationEnabled: data['notificationEnabled'] as bool? ?? true,
      notificationMessage: data['notificationMessage'] as String?,
      notificationBagMessage: data['notificationBagMessage'] as String?,
      notificationMinutesBefore:
          (data['notificationMinutesBefore'] as num?)?.toInt() ?? 30,
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

const kSportReminderLeadChoices = <int>[0, 15, 30, 60];
