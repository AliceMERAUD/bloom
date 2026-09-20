import '../models/puzzle/puzzle_models.dart';
import 'bloom_refresh.dart';
import 'puzzle_catalog.dart';
import 'storage_service.dart';

class PuzzleProgress {
  final Set<String> completedIds;
  final String? selectedPuzzleId;
  final Map<String, PuzzlePlacement> placements;

  const PuzzleProgress({
    this.completedIds = const {},
    this.selectedPuzzleId,
    this.placements = const {},
  });

  bool isCompleted(String puzzleId) => completedIds.contains(puzzleId);

  bool isUnlocked(String puzzleId) {
    if (puzzleId.startsWith('gen_')) return true;
    final index = PuzzleCatalog.indexOf(puzzleId);
    if (index < 0) return true;
    if (index == 0) return true;
    final previous = PuzzleCatalog.all[index - 1];
    return isCompleted(previous.id);
  }

  String? get nextPlayableId {
    for (final puzzle in PuzzleCatalog.all) {
      if (!isCompleted(puzzle.id) && isUnlocked(puzzle.id)) {
        return puzzle.id;
      }
    }
    return PuzzleCatalog.all.isEmpty ? null : PuzzleCatalog.all.last.id;
  }

  PuzzleProgress copyWith({
    Set<String>? completedIds,
    String? selectedPuzzleId,
    Map<String, PuzzlePlacement>? placements,
    bool clearSelected = false,
  }) {
    return PuzzleProgress(
      completedIds: completedIds ?? this.completedIds,
      selectedPuzzleId:
          clearSelected ? null : (selectedPuzzleId ?? this.selectedPuzzleId),
      placements: placements ?? this.placements,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'completedIds': completedIds.toList(),
      'selectedPuzzleId': selectedPuzzleId,
      'placements': placements.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }

  factory PuzzleProgress.fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    final completed = List<dynamic>.from(data['completedIds'] ?? const [])
        .map((e) => e.toString())
        .toSet();

    final rawPlacements =
        Map<dynamic, dynamic>.from(data['placements'] as Map? ?? {});
    final placements = <String, PuzzlePlacement>{};
    rawPlacements.forEach((key, value) {
      placements[key.toString()] = PuzzlePlacement.fromMap(value as Map);
    });

    return PuzzleProgress(
      completedIds: completed,
      selectedPuzzleId: data['selectedPuzzleId'] as String?,
      placements: placements,
    );
  }
}

class PuzzleProgressService {
  static PuzzleProgress load() {
    return StorageService.getPuzzleProgress() ?? const PuzzleProgress();
  }

  static Future<void> save(PuzzleProgress progress) {
    return StorageService.savePuzzleProgress(progress);
  }

  static Future<PuzzleProgress> markCompleted(String puzzleId) async {
    final current = load();
    final updated = current.copyWith(
      completedIds: {...current.completedIds, puzzleId},
      selectedPuzzleId: puzzleId,
    );
    await save(updated);
    BloomRefresh.notify();
    return updated;
  }

  static Future<PuzzleProgress> savePlacement(
    String puzzleId,
    PuzzlePlacement placement,
  ) async {
    final current = load();
    final placements = Map<String, PuzzlePlacement>.from(current.placements);
    placements[puzzleId] = placement;
    final updated = current.copyWith(
      placements: placements,
      selectedPuzzleId: puzzleId,
    );
    await save(updated);
    return updated;
  }

  static Future<PuzzleProgress> clearPlacement(String puzzleId) async {
    final current = load();
    final placements = Map<String, PuzzlePlacement>.from(current.placements)
      ..remove(puzzleId);
    final updated = current.copyWith(placements: placements);
    await save(updated);
    return updated;
  }
}
