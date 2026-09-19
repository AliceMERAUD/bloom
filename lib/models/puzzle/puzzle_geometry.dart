import 'puzzle.dart';
import 'puzzle_models.dart';
import 'puzzle_scene.dart';

enum PuzzleCellKind {
  /// Character may sit here.
  seat,

  /// Blocked / wall — not interactive.
  blocked,

  /// Fixed scene object (window, door, table…) — not a seat.
  object,

  /// Decorative only.
  decor,
}

class PuzzleCell {
  final int index;
  final int row;
  final int col;
  final PuzzleCellKind kind;
  final PuzzleTileKind tile;
  final String? objectId;
  final String? label;

  const PuzzleCell({
    required this.index,
    required this.row,
    required this.col,
    required this.kind,
    required this.tile,
    this.objectId,
    this.label,
  });

  bool get isSeat => kind == PuzzleCellKind.seat;
}

/// Grid geometry for Puzzle 2.0. Indices match [Puzzle.positions] for seats;
/// object/blocked cells use high indices that are never assigned to characters.
class PuzzleGeometry {
  final int rows;
  final int cols;
  final List<PuzzleCell> cells;

  const PuzzleGeometry({
    required this.rows,
    required this.cols,
    required this.cells,
  });

  PuzzleCell? cellAtIndex(int index) {
    for (final c in cells) {
      if (c.index == index) return c;
    }
    return null;
  }

  PuzzleCell? cellAt(int row, int col) {
    for (final c in cells) {
      if (c.row == row && c.col == col) return c;
    }
    return null;
  }

  List<PuzzleCell> get seats => cells.where((c) => c.isSeat).toList();

  List<int> objectIndices(String objectId) => cells
      .where((c) => c.objectId == objectId)
      .map((c) => c.index)
      .toList();

  int manhattan(int indexA, int indexB) {
    final a = cellAtIndex(indexA);
    final b = cellAtIndex(indexB);
    if (a == null || b == null) return 999;
    return (a.row - b.row).abs() + (a.col - b.col).abs();
  }

  bool areAdjacent(int indexA, int indexB) => manhattan(indexA, indexB) == 1;

  bool sameRow(int indexA, int indexB) {
    final a = cellAtIndex(indexA);
    final b = cellAtIndex(indexB);
    return a != null && b != null && a.row == b.row;
  }

  bool sameCol(int indexA, int indexB) {
    final a = cellAtIndex(indexA);
    final b = cellAtIndex(indexB);
    return a != null && b != null && a.col == b.col;
  }

  /// Build a linear row geometry (Puzzle V1 compatible).
  factory PuzzleGeometry.row(int seatCount) {
    final cells = <PuzzleCell>[
      for (var i = 0; i < seatCount; i++)
        PuzzleCell(
          index: i,
          row: 0,
          col: i,
          kind: PuzzleCellKind.seat,
          tile: PuzzleTileKind.seat,
          label: '${i + 1}',
        ),
    ];
    return PuzzleGeometry(rows: 1, cols: seatCount, cells: cells);
  }

  factory PuzzleGeometry.fromPuzzle(Puzzle puzzle) {
    return puzzle.geometry ?? PuzzleGeometry.row(puzzle.seatCount);
  }

  /// Helper to author a grid: [layout] uses chars:
  /// `.` seat, `#` blocked, letters = object ids (W window, D door, T table…).
  static PuzzleGeometry fromAscii({
    required List<String> layout,
    Map<String, String> objectNames = const {
      'W': 'window',
      'D': 'door',
      'T': 'table',
      'B': 'bench',
      'C': 'counter',
      'A': 'tree',
      'S': 'screen',
    },
  }) {
    final rows = layout.length;
    final cols = layout.first.length;
    final cells = <PuzzleCell>[];
    var seatIndex = 0;
    var extraIndex = 1000;

    for (var r = 0; r < rows; r++) {
      final line = layout[r];
      for (var c = 0; c < cols; c++) {
        final ch = line[c];
        if (ch == '.') {
          cells.add(
            PuzzleCell(
              index: seatIndex,
              row: r,
              col: c,
              kind: PuzzleCellKind.seat,
              tile: PuzzleTileKind.seat,
              label: '${seatIndex + 1}',
            ),
          );
          seatIndex++;
        } else if (ch == '#') {
          cells.add(
            PuzzleCell(
              index: extraIndex++,
              row: r,
              col: c,
              kind: PuzzleCellKind.blocked,
              tile: PuzzleTileKind.wall,
            ),
          );
        } else if (ch == ' ') {
          cells.add(
            PuzzleCell(
              index: extraIndex++,
              row: r,
              col: c,
              kind: PuzzleCellKind.decor,
              tile: PuzzleTileKind.floor,
            ),
          );
        } else {
          final objectId = objectNames[ch] ?? ch.toLowerCase();
          final tile = _tileForObject(objectId);
          cells.add(
            PuzzleCell(
              index: extraIndex++,
              row: r,
              col: c,
              kind: PuzzleCellKind.object,
              tile: tile,
              objectId: objectId,
              label: objectId,
            ),
          );
        }
      }
    }
    return PuzzleGeometry(rows: rows, cols: cols, cells: cells);
  }

  static PuzzleTileKind _tileForObject(String id) {
    switch (id) {
      case 'window':
        return PuzzleTileKind.window;
      case 'door':
        return PuzzleTileKind.door;
      case 'table':
        return PuzzleTileKind.table;
      case 'bench':
      case 'seat':
        return PuzzleTileKind.seat;
      default:
        return PuzzleTileKind.decor;
    }
  }
}

List<PuzzlePosition> positionsFromGeometry(PuzzleGeometry geo) {
  return geo.seats
      .map(
        (c) => PuzzlePosition(
          id: 'p${c.index}',
          index: c.index,
          label: c.label ?? '${c.index + 1}',
          row: c.row,
          col: c.col,
        ),
      )
      .toList();
}
