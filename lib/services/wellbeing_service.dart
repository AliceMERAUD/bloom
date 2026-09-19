import '../models/wellbeing_entry.dart';
import '../models/wellbeing_enums.dart';
import 'storage_service.dart';

class WellbeingService {
  static Future<WellbeingEntry> saveEntry(WellbeingEntry entry) {
    return StorageService.saveWellbeingEntry(entry);
  }

  static WellbeingEntry? getEntryForDate(DateTime date) {
    return StorageService.getWellbeingEntryForDate(date);
  }

  static List<WellbeingEntry> getAllEntries() {
    return StorageService.getAllWellbeingEntries();
  }

  static Future<void> deleteEntry(String id) {
    return StorageService.deleteWellbeingEntry(id);
  }

  /// Marks [date] as the start of a period (creates/updates the day entry).
  static Future<WellbeingEntry> startPeriod(DateTime date) async {
    final existing = getEntryForDate(date);
    final base = existing ??
        WellbeingEntry(
          id: WellbeingEntry.dateKey(date),
          date: WellbeingEntry.normalizeDate(date),
        );

    final updated = base.copyWith(
      periodMarker: PeriodMarker.start,
      bleeding: base.bleeding == Bleeding.none ? Bleeding.light : base.bleeding,
    );

    return saveEntry(updated);
  }

  /// Marks [date] as the end of a period (creates/updates the day entry).
  static Future<WellbeingEntry> endPeriod(DateTime date) async {
    final existing = getEntryForDate(date);
    final base = existing ??
        WellbeingEntry(
          id: WellbeingEntry.dateKey(date),
          date: WellbeingEntry.normalizeDate(date),
        );

    return saveEntry(base.copyWith(periodMarker: PeriodMarker.end));
  }

  /// Periods deduced solely from start/end markers on entries.
  static List<MenstrualPeriod> getPeriods() {
    final entries = getAllEntries().reversed.toList(); // oldest first
    final periods = <MenstrualPeriod>[];
    DateTime? openStart;

    for (final entry in entries) {
      if (entry.periodMarker == PeriodMarker.start) {
        if (openStart != null) {
          // Previous period without explicit end: close the day before.
          periods.add(
            MenstrualPeriod(
              start: openStart,
              end: entry.date.subtract(const Duration(days: 1)),
            ),
          );
        }
        openStart = entry.date;
      } else if (entry.periodMarker == PeriodMarker.end && openStart != null) {
        periods.add(MenstrualPeriod(start: openStart, end: entry.date));
        openStart = null;
      }
    }

    if (openStart != null) {
      periods.add(MenstrualPeriod(start: openStart));
    }

    return periods.reversed.toList();
  }

  static MenstrualPeriod? getCurrentPeriod() {
    final periods = getPeriods();
    for (final period in periods) {
      if (period.isOngoing) return period;
    }
    return null;
  }

  static String cycleStatusLabel() {
    final current = getCurrentPeriod();
    if (current != null) {
      final day = DateTime.now()
              .difference(WellbeingEntry.normalizeDate(current.start))
              .inDays +
          1;
      return 'Règles en cours (jour $day)';
    }

    final closed = getPeriods().where((p) => !p.isOngoing).toList();
    if (closed.isEmpty) {
      return 'Aucune période enregistrée';
    }

    final last = closed.first;
    final days = last.durationDays;
    if (days == null) {
      return 'Dernière période enregistrée';
    }
    return 'Dernière période : $days jour${days > 1 ? 's' : ''}';
  }
}
