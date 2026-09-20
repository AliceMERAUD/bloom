import '../../models/puzzle/puzzle.dart';
import '../storage_service.dart';
import 'puzzle_generation_config.dart';
import 'puzzle_generator_service.dart';

/// Hive-backed ring of recently generated puzzles (max 20).
class GeneratedPuzzleRecord {
  final Puzzle puzzle;
  final DateTime createdAt;
  final String signature;

  const GeneratedPuzzleRecord({
    required this.puzzle,
    required this.createdAt,
    required this.signature,
  });

  Map<String, dynamic> toMap() => {
        'puzzle': puzzle.toMap(),
        'createdAt': createdAt.toIso8601String(),
        'signature': signature,
      };

  factory GeneratedPuzzleRecord.fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    return GeneratedPuzzleRecord(
      puzzle: Puzzle.fromMap(data['puzzle'] as Map),
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      signature: data['signature'] as String? ?? '',
    );
  }
}

class GeneratedPuzzleCatalog {
  final List<GeneratedPuzzleRecord> records;

  const GeneratedPuzzleCatalog({this.records = const []});

  int get length => records.length;

  List<Puzzle> get puzzles => records.map((r) => r.puzzle).toList();

  Puzzle? byId(String id) {
    for (final r in records) {
      if (r.puzzle.id == id) return r.puzzle;
    }
    return null;
  }

  GeneratedPuzzleCatalog copyWith({List<GeneratedPuzzleRecord>? records}) {
    return GeneratedPuzzleCatalog(records: records ?? this.records);
  }

  Map<String, dynamic> toMap() => {
        'records': records.map((r) => r.toMap()).toList(),
      };

  factory GeneratedPuzzleCatalog.fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    final raw = List<dynamic>.from(data['records'] as List? ?? const []);
    return GeneratedPuzzleCatalog(
      records: raw
          .map((e) => GeneratedPuzzleRecord.fromMap(e as Map))
          .toList(),
    );
  }
}

class GeneratedPuzzleCatalogService {
  static GeneratedPuzzleCatalog load() {
    return StorageService.getGeneratedPuzzleCatalog() ??
        const GeneratedPuzzleCatalog();
  }

  static Future<void> save(GeneratedPuzzleCatalog catalog) {
    return StorageService.saveGeneratedPuzzleCatalog(catalog);
  }

  /// Adds [puzzle], evicting oldest when over [PuzzleGeneratorLimits.maxGeneratedPuzzles].
  /// Returns the id of any evicted puzzle (for history retention checks).
  static Future<String?> add(Puzzle puzzle, {String? signature}) async {
    final catalog = load();
    final sig = signature ?? PuzzleGeneratorService.signatureOf(puzzle);
    final next = List<GeneratedPuzzleRecord>.from(catalog.records)
      ..add(
        GeneratedPuzzleRecord(
          puzzle: puzzle,
          createdAt: DateTime.now(),
          signature: sig,
        ),
      );

    String? evictedId;
    while (next.length > PuzzleGeneratorLimits.maxGeneratedPuzzles) {
      next.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      evictedId = next.removeAt(0).puzzle.id;
    }

    await save(GeneratedPuzzleCatalog(records: next));
    return evictedId;
  }

  static Set<String> signatures() {
    return load().records.map((r) => r.signature).toSet();
  }

  static Puzzle? latest() {
    final records = load().records;
    if (records.isEmpty) return null;
    final sorted = List<GeneratedPuzzleRecord>.from(records)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first.puzzle;
  }
}
