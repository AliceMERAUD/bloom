import 'puzzle_geometry.dart';
import 'puzzle_models.dart';

enum ConstraintKind {
  adjacent,
  notAdjacent,
  before,
  after,
  fixedPosition,
  between,
  sameSide,
  differentSide,
  sameRow,
  sameCol,
  nearObject,
  notNearObject,
  distanceAtMost,
}

/// A reusable placement constraint evaluated against a [PuzzlePlacement].
abstract class PuzzleConstraint {
  String get id;
  ConstraintKind get kind;

  /// Human-readable description shown in the UI.
  String get description;

  /// Whether enough characters are placed to evaluate this constraint.
  bool canEvaluate(PuzzlePlacement placement);

  /// True when the constraint holds for the current placement.
  bool isSatisfied(PuzzlePlacement placement, [PuzzleGeometry? geometry]);

  Map<String, dynamic> toMap();

  static PuzzleConstraint fromMap(Map<dynamic, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    final kind = ConstraintKind.values.firstWhere(
      (value) => value.name == data['kind'],
    );

    switch (kind) {
      case ConstraintKind.adjacent:
        return AdjacentConstraint(
          id: data['id'] as String,
          a: data['a'] as String,
          b: data['b'] as String,
          description: data['description'] as String?,
        );
      case ConstraintKind.notAdjacent:
        return NotAdjacentConstraint(
          id: data['id'] as String,
          a: data['a'] as String,
          b: data['b'] as String,
          description: data['description'] as String?,
        );
      case ConstraintKind.before:
        return BeforeConstraint(
          id: data['id'] as String,
          a: data['a'] as String,
          b: data['b'] as String,
          description: data['description'] as String?,
        );
      case ConstraintKind.after:
        return AfterConstraint(
          id: data['id'] as String,
          a: data['a'] as String,
          b: data['b'] as String,
          description: data['description'] as String?,
        );
      case ConstraintKind.fixedPosition:
        return FixedPositionConstraint(
          id: data['id'] as String,
          characterId: data['characterId'] as String,
          index: (data['index'] as num).toInt(),
          description: data['description'] as String?,
        );
      case ConstraintKind.between:
        return BetweenConstraint(
          id: data['id'] as String,
          middle: data['middle'] as String,
          left: data['left'] as String,
          right: data['right'] as String,
          description: data['description'] as String?,
        );
      case ConstraintKind.sameSide:
        return SameSideConstraint(
          id: data['id'] as String,
          a: data['a'] as String,
          b: data['b'] as String,
          seatCount: (data['seatCount'] as num).toInt(),
          description: data['description'] as String?,
        );
      case ConstraintKind.differentSide:
        return DifferentSideConstraint(
          id: data['id'] as String,
          a: data['a'] as String,
          b: data['b'] as String,
          seatCount: (data['seatCount'] as num).toInt(),
          description: data['description'] as String?,
        );
      case ConstraintKind.sameRow:
        return SameRowConstraint(
          id: data['id'] as String,
          a: data['a'] as String,
          b: data['b'] as String,
          description: data['description'] as String?,
        );
      case ConstraintKind.sameCol:
        return SameColConstraint(
          id: data['id'] as String,
          a: data['a'] as String,
          b: data['b'] as String,
          description: data['description'] as String?,
        );
      case ConstraintKind.nearObject:
        return NearObjectConstraint(
          id: data['id'] as String,
          characterId: data['characterId'] as String,
          objectId: data['objectId'] as String,
          description: data['description'] as String?,
        );
      case ConstraintKind.notNearObject:
        return NotNearObjectConstraint(
          id: data['id'] as String,
          characterId: data['characterId'] as String,
          objectId: data['objectId'] as String,
          description: data['description'] as String?,
        );
      case ConstraintKind.distanceAtMost:
        return DistanceAtMostConstraint(
          id: data['id'] as String,
          a: data['a'] as String,
          b: data['b'] as String,
          maxDistance: (data['maxDistance'] as num).toInt(),
          description: data['description'] as String?,
        );
    }
  }
}

int? _readingOrder(int index, PuzzleGeometry? geometry) {
  if (geometry == null) return index;
  final cell = geometry.cellAtIndex(index);
  if (cell == null) return index;
  // Left-to-right, then top-to-bottom (row-major).
  return cell.row * geometry.cols + cell.col;
}

bool _isLeftSideIndex(int index, int seatCount) =>
    index < (seatCount / 2).ceil();

bool _isLeftHalfCol(int col, int cols) => col < (cols / 2).ceil();

bool _isLeftSidePlacement(
  int index,
  int seatCount,
  PuzzleGeometry? geometry,
) {
  if (geometry == null) return _isLeftSideIndex(index, seatCount);
  final cell = geometry.cellAtIndex(index);
  if (cell == null) return _isLeftSideIndex(index, seatCount);
  return _isLeftHalfCol(cell.col, geometry.cols);
}

bool _isBetweenOnGrid(
  PuzzleGeometry geometry,
  int middle,
  int left,
  int right,
) {
  final m = geometry.cellAtIndex(middle);
  final l = geometry.cellAtIndex(left);
  final r = geometry.cellAtIndex(right);
  if (m == null || l == null || r == null) return false;

  if (l.row == r.row && m.row == l.row) {
    final low = l.col < r.col ? l.col : r.col;
    final high = l.col < r.col ? r.col : l.col;
    return m.col > low && m.col < high;
  }

  if (l.col == r.col && m.col == l.col) {
    final low = l.row < r.row ? l.row : r.row;
    final high = l.row < r.row ? r.row : l.row;
    return m.row > low && m.row < high;
  }

  return false;
}

bool _isNearObject(
  PuzzleGeometry geometry,
  int characterIndex,
  String objectId,
) {
  for (final objectIndex in geometry.objectIndices(objectId)) {
    if (geometry.manhattan(characterIndex, objectIndex) == 1) return true;
  }
  return false;
}

class AdjacentConstraint extends PuzzleConstraint {
  @override
  final String id;
  final String a;
  final String b;
  final String? _description;

  AdjacentConstraint({
    required this.id,
    required this.a,
    required this.b,
    String? description,
  }) : _description = description;

  @override
  ConstraintKind get kind => ConstraintKind.adjacent;

  @override
  String get description =>
      _description ?? '$a doit être à côté de $b';

  @override
  bool canEvaluate(PuzzlePlacement placement) =>
      placement.indexOf(a) != null && placement.indexOf(b) != null;

  @override
  bool isSatisfied(PuzzlePlacement placement, [PuzzleGeometry? geometry]) {
    final ia = placement.indexOf(a);
    final ib = placement.indexOf(b);
    if (ia == null || ib == null) return false;
    if (geometry != null) return geometry.areAdjacent(ia, ib);
    return (ia - ib).abs() == 1;
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'a': a,
        'b': b,
        'description': description,
      };
}

class NotAdjacentConstraint extends PuzzleConstraint {
  @override
  final String id;
  final String a;
  final String b;
  final String? _description;

  NotAdjacentConstraint({
    required this.id,
    required this.a,
    required this.b,
    String? description,
  }) : _description = description;

  @override
  ConstraintKind get kind => ConstraintKind.notAdjacent;

  @override
  String get description =>
      _description ?? '$a ne doit pas être à côté de $b';

  @override
  bool canEvaluate(PuzzlePlacement placement) =>
      placement.indexOf(a) != null && placement.indexOf(b) != null;

  @override
  bool isSatisfied(PuzzlePlacement placement, [PuzzleGeometry? geometry]) {
    final ia = placement.indexOf(a);
    final ib = placement.indexOf(b);
    if (ia == null || ib == null) return false;
    if (geometry != null) return !geometry.areAdjacent(ia, ib);
    return (ia - ib).abs() != 1;
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'a': a,
        'b': b,
        'description': description,
      };
}

class BeforeConstraint extends PuzzleConstraint {
  @override
  final String id;
  final String a;
  final String b;
  final String? _description;

  BeforeConstraint({
    required this.id,
    required this.a,
    required this.b,
    String? description,
  }) : _description = description;

  @override
  ConstraintKind get kind => ConstraintKind.before;

  @override
  String get description =>
      _description ?? '$a doit être avant $b';

  @override
  bool canEvaluate(PuzzlePlacement placement) =>
      placement.indexOf(a) != null && placement.indexOf(b) != null;

  @override
  bool isSatisfied(PuzzlePlacement placement, [PuzzleGeometry? geometry]) {
    final ia = placement.indexOf(a);
    final ib = placement.indexOf(b);
    if (ia == null || ib == null) return false;
    final oa = _readingOrder(ia, geometry);
    final ob = _readingOrder(ib, geometry);
    if (oa == null || ob == null) return false;
    return oa < ob;
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'a': a,
        'b': b,
        'description': description,
      };
}

class AfterConstraint extends PuzzleConstraint {
  @override
  final String id;
  final String a;
  final String b;
  final String? _description;

  AfterConstraint({
    required this.id,
    required this.a,
    required this.b,
    String? description,
  }) : _description = description;

  @override
  ConstraintKind get kind => ConstraintKind.after;

  @override
  String get description =>
      _description ?? '$a doit être après $b';

  @override
  bool canEvaluate(PuzzlePlacement placement) =>
      placement.indexOf(a) != null && placement.indexOf(b) != null;

  @override
  bool isSatisfied(PuzzlePlacement placement, [PuzzleGeometry? geometry]) {
    final ia = placement.indexOf(a);
    final ib = placement.indexOf(b);
    if (ia == null || ib == null) return false;
    final oa = _readingOrder(ia, geometry);
    final ob = _readingOrder(ib, geometry);
    if (oa == null || ob == null) return false;
    return oa > ob;
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'a': a,
        'b': b,
        'description': description,
      };
}

class FixedPositionConstraint extends PuzzleConstraint {
  @override
  final String id;
  final String characterId;
  final int index;
  final String? _description;

  FixedPositionConstraint({
    required this.id,
    required this.characterId,
    required this.index,
    String? description,
  }) : _description = description;

  @override
  ConstraintKind get kind => ConstraintKind.fixedPosition;

  @override
  String get description =>
      _description ?? '$characterId doit être en position ${index + 1}';

  @override
  bool canEvaluate(PuzzlePlacement placement) =>
      placement.indexOf(characterId) != null;

  @override
  bool isSatisfied(PuzzlePlacement placement, [PuzzleGeometry? geometry]) {
    return placement.indexOf(characterId) == index;
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'characterId': characterId,
        'index': index,
        'description': description,
      };
}

class BetweenConstraint extends PuzzleConstraint {
  @override
  final String id;
  final String middle;
  final String left;
  final String right;
  final String? _description;

  BetweenConstraint({
    required this.id,
    required this.middle,
    required this.left,
    required this.right,
    String? description,
  }) : _description = description;

  @override
  ConstraintKind get kind => ConstraintKind.between;

  @override
  String get description =>
      _description ?? '$middle doit être entre $left et $right';

  @override
  bool canEvaluate(PuzzlePlacement placement) =>
      placement.indexOf(middle) != null &&
      placement.indexOf(left) != null &&
      placement.indexOf(right) != null;

  @override
  bool isSatisfied(PuzzlePlacement placement, [PuzzleGeometry? geometry]) {
    final im = placement.indexOf(middle);
    final il = placement.indexOf(left);
    final ir = placement.indexOf(right);
    if (im == null || il == null || ir == null) return false;
    if (geometry != null) {
      return _isBetweenOnGrid(geometry, im, il, ir);
    }
    final low = il < ir ? il : ir;
    final high = il < ir ? ir : il;
    return im > low && im < high;
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'middle': middle,
        'left': left,
        'right': right,
        'description': description,
      };
}

class SameSideConstraint extends PuzzleConstraint {
  @override
  final String id;
  final String a;
  final String b;
  final int seatCount;
  final String? _description;

  SameSideConstraint({
    required this.id,
    required this.a,
    required this.b,
    required this.seatCount,
    String? description,
  }) : _description = description;

  @override
  ConstraintKind get kind => ConstraintKind.sameSide;

  @override
  String get description =>
      _description ?? '$a et $b doivent être du même côté';

  @override
  bool canEvaluate(PuzzlePlacement placement) =>
      placement.indexOf(a) != null && placement.indexOf(b) != null;

  @override
  bool isSatisfied(PuzzlePlacement placement, [PuzzleGeometry? geometry]) {
    final ia = placement.indexOf(a);
    final ib = placement.indexOf(b);
    if (ia == null || ib == null) return false;
    return _isLeftSidePlacement(ia, seatCount, geometry) ==
        _isLeftSidePlacement(ib, seatCount, geometry);
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'a': a,
        'b': b,
        'seatCount': seatCount,
        'description': description,
      };
}

class DifferentSideConstraint extends PuzzleConstraint {
  @override
  final String id;
  final String a;
  final String b;
  final int seatCount;
  final String? _description;

  DifferentSideConstraint({
    required this.id,
    required this.a,
    required this.b,
    required this.seatCount,
    String? description,
  }) : _description = description;

  @override
  ConstraintKind get kind => ConstraintKind.differentSide;

  @override
  String get description =>
      _description ?? '$a et $b doivent être de côtés opposés';

  @override
  bool canEvaluate(PuzzlePlacement placement) =>
      placement.indexOf(a) != null && placement.indexOf(b) != null;

  @override
  bool isSatisfied(PuzzlePlacement placement, [PuzzleGeometry? geometry]) {
    final ia = placement.indexOf(a);
    final ib = placement.indexOf(b);
    if (ia == null || ib == null) return false;
    return _isLeftSidePlacement(ia, seatCount, geometry) !=
        _isLeftSidePlacement(ib, seatCount, geometry);
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'a': a,
        'b': b,
        'seatCount': seatCount,
        'description': description,
      };
}

class SameRowConstraint extends PuzzleConstraint {
  @override
  final String id;
  final String a;
  final String b;
  final String? _description;

  SameRowConstraint({
    required this.id,
    required this.a,
    required this.b,
    String? description,
  }) : _description = description;

  @override
  ConstraintKind get kind => ConstraintKind.sameRow;

  @override
  String get description =>
      _description ?? '$a et $b doivent être sur la même rangée';

  @override
  bool canEvaluate(PuzzlePlacement placement) =>
      placement.indexOf(a) != null && placement.indexOf(b) != null;

  @override
  bool isSatisfied(PuzzlePlacement placement, [PuzzleGeometry? geometry]) {
    final ia = placement.indexOf(a);
    final ib = placement.indexOf(b);
    if (ia == null || ib == null) return false;
    if (geometry == null) return false;
    return geometry.sameRow(ia, ib);
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'a': a,
        'b': b,
        'description': description,
      };
}

class SameColConstraint extends PuzzleConstraint {
  @override
  final String id;
  final String a;
  final String b;
  final String? _description;

  SameColConstraint({
    required this.id,
    required this.a,
    required this.b,
    String? description,
  }) : _description = description;

  @override
  ConstraintKind get kind => ConstraintKind.sameCol;

  @override
  String get description =>
      _description ?? '$a et $b doivent être dans la même colonne';

  @override
  bool canEvaluate(PuzzlePlacement placement) =>
      placement.indexOf(a) != null && placement.indexOf(b) != null;

  @override
  bool isSatisfied(PuzzlePlacement placement, [PuzzleGeometry? geometry]) {
    final ia = placement.indexOf(a);
    final ib = placement.indexOf(b);
    if (ia == null || ib == null) return false;
    if (geometry == null) return false;
    return geometry.sameCol(ia, ib);
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'a': a,
        'b': b,
        'description': description,
      };
}

class NearObjectConstraint extends PuzzleConstraint {
  @override
  final String id;
  final String characterId;
  final String objectId;
  final String? _description;

  NearObjectConstraint({
    required this.id,
    required this.characterId,
    required this.objectId,
    String? description,
  }) : _description = description;

  @override
  ConstraintKind get kind => ConstraintKind.nearObject;

  @override
  String get description =>
      _description ?? '$characterId doit être près de $objectId';

  @override
  bool canEvaluate(PuzzlePlacement placement) =>
      placement.indexOf(characterId) != null;

  @override
  bool isSatisfied(PuzzlePlacement placement, [PuzzleGeometry? geometry]) {
    final index = placement.indexOf(characterId);
    if (index == null || geometry == null) return false;
    return _isNearObject(geometry, index, objectId);
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'characterId': characterId,
        'objectId': objectId,
        'description': description,
      };
}

class NotNearObjectConstraint extends PuzzleConstraint {
  @override
  final String id;
  final String characterId;
  final String objectId;
  final String? _description;

  NotNearObjectConstraint({
    required this.id,
    required this.characterId,
    required this.objectId,
    String? description,
  }) : _description = description;

  @override
  ConstraintKind get kind => ConstraintKind.notNearObject;

  @override
  String get description =>
      _description ?? '$characterId ne doit pas être près de $objectId';

  @override
  bool canEvaluate(PuzzlePlacement placement) =>
      placement.indexOf(characterId) != null;

  @override
  bool isSatisfied(PuzzlePlacement placement, [PuzzleGeometry? geometry]) {
    final index = placement.indexOf(characterId);
    if (index == null || geometry == null) return false;
    return !_isNearObject(geometry, index, objectId);
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'characterId': characterId,
        'objectId': objectId,
        'description': description,
      };
}

class DistanceAtMostConstraint extends PuzzleConstraint {
  @override
  final String id;
  final String a;
  final String b;
  final int maxDistance;
  final String? _description;

  DistanceAtMostConstraint({
    required this.id,
    required this.a,
    required this.b,
    required this.maxDistance,
    String? description,
  }) : _description = description;

  @override
  ConstraintKind get kind => ConstraintKind.distanceAtMost;

  @override
  String get description =>
      _description ??
      '$a et $b doivent être à distance ≤ $maxDistance';

  @override
  bool canEvaluate(PuzzlePlacement placement) =>
      placement.indexOf(a) != null && placement.indexOf(b) != null;

  @override
  bool isSatisfied(PuzzlePlacement placement, [PuzzleGeometry? geometry]) {
    final ia = placement.indexOf(a);
    final ib = placement.indexOf(b);
    if (ia == null || ib == null) return false;
    if (geometry != null) {
      return geometry.manhattan(ia, ib) <= maxDistance;
    }
    return (ia - ib).abs() <= maxDistance;
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'a': a,
        'b': b,
        'maxDistance': maxDistance,
        'description': description,
      };
}
