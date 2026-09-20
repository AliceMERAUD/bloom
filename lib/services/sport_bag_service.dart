import '../models/sport_bag_item.dart';
import 'bloom_refresh.dart';
import 'storage_service.dart';

class SportBagService {
  static List<SportBagItem> getAll() => StorageService.getAllBagItems();

  static List<SportBagItem> getGeneral() =>
      getAll().where((i) => i.sportId == null).toList();

  static List<SportBagItem> getForSport(String sportId) =>
      getAll().where((i) => i.sportId == sportId).toList();

  /// General items + sport-specific items for a checklist.
  static List<SportBagItem> checklistFor(String? sportId) {
    final general = getGeneral();
    if (sportId == null) return general;
    return [...general, ...getForSport(sportId)];
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
