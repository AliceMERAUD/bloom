import '../models/sport_activity.dart';
import 'bloom_refresh.dart';
import 'storage_service.dart';

class SportActivityService {
  static Future<void> ensureDefaults() async {
    final existing = StorageService.getAllSportActivities();
    if (existing.any((s) => s.id == kBuiltinStrengthSportId)) return;
    await StorageService.saveSportActivity(
      SportActivity(
        id: kBuiltinStrengthSportId,
        name: 'Musculation',
        description: 'Séances avec exercices, séries et progression',
        iconName: 'fitness_center',
        colorValue: 0xFF2E7D4F,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        builtin: true,
      ),
    );
  }

  static List<SportActivity> getAll({bool enabledOnly = false}) {
    final list = StorageService.getAllSportActivities();
    if (!enabledOnly) return list;
    return list.where((s) => s.enabled).toList();
  }

  static SportActivity? getById(String id) => StorageService.getSportActivity(id);

  static Future<SportActivity> add({
    required String name,
    String? description,
    String iconName = 'sports',
    int colorValue = 0xFF2E7D4F,
  }) async {
    final activity = SportActivity(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      iconName: iconName,
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );
    await StorageService.saveSportActivity(activity);
    BloomRefresh.notify();
    return activity;
  }

  static Future<SportActivity> update(SportActivity activity) async {
    await StorageService.saveSportActivity(activity);
    BloomRefresh.notify();
    return activity;
  }

  static Future<void> delete(String id) async {
    final activity = StorageService.getSportActivity(id);
    if (activity == null) return;
    if (activity.builtin) {
      throw StateError('Impossible de supprimer un sport intégré');
    }
    await StorageService.deleteSportActivity(id);
    BloomRefresh.notify();
  }
}
