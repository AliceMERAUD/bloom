import '../models/sport_bag_item.dart';
import 'bloom_refresh.dart';
import 'storage_service.dart';

class SportBagService {
  static List<SportBagItem> getAll() => StorageService.getAllBagItems();

  static List<SportBagItem> getGeneral() =>
      getAll().where((i) => i.sportId == null).toList();

  static List<SportBagItem> getForSport(String sportId) =>
      getAll().where((i) => i.sportId == sportId).toList();

  static List<SportBagItem> checklistFor(String? sportId) {
    final general = getGeneral();
    if (sportId == null || sportId.isEmpty) return general;
    final specific = getForSport(sportId);
    // Merge without duplicating ids (generals stay general in storage).
    final seen = <String>{};
    final merged = <SportBagItem>[];
    for (final item in [...general, ...specific]) {
      if (seen.add(item.id)) merged.add(item);
    }
    return merged;
  }

  /// Items shown in the bag management screen for a filter chip.
  /// Sport filter = general + that sport (not sport-only).
  static List<SportBagItem> itemsForFilter(String? filterSportId) {
    if (filterSportId == null) return getAll();
    if (filterSportId.isEmpty) return getGeneral();
    return checklistFor(filterSportId);
  }

  static Future<SportBagItem> add({
    required String name,
    String? sportId,
  }) async {
    final item = SportBagItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      sportId: sportId,
      createdAt: DateTime.now(),
    );
    await StorageService.saveBagItem(item);
    BloomRefresh.notify();
    return item;
  }

  static Future<SportBagItem> update(SportBagItem item) async {
    await StorageService.saveBagItem(item);
    BloomRefresh.notify();
    return item;
  }

  static Future<void> toggleChecked(String id) async {
    final item = StorageService.getBagItem(id);
    if (item == null) return;
    await update(item.copyWith(checked: !item.checked));
  }

  static Future<void> delete(String id) async {
    await StorageService.deleteBagItem(id);
    BloomRefresh.notify();
  }

  static Future<void> resetChecked({String? sportId}) async {
    for (final item in checklistFor(sportId)) {
      if (item.checked) {
        await StorageService.saveBagItem(item.copyWith(checked: false));
      }
    }
    BloomRefresh.notify();
  }
}
