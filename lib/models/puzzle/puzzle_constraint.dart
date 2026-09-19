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
  bool isSatisfied(PuzzlePlacement placement);

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
    }
  }
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
  bool isSatisfied(PuzzlePlacement placement) {
    final ia = placement.indexOf(a);
    final ib = placement.indexOf(b);
    if (ia == null || ib == null) return false;
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
  bool isSatisfied(PuzzlePlacement placement) {
    final ia = placement.indexOf(a);
    final ib = placement.indexOf(b);
    if (ia == null || ib == null) return false;
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
  bool isSatisfied(PuzzlePlacement placement) {
    final ia = placement.indexOf(a);
    final ib = placement.indexOf(b);
    if (ia == null || ib == null) return false;
    return ia < ib;
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
  bool isSatisfied(PuzzlePlacement placement) {
    final ia = placement.indexOf(a);
    final ib = placement.indexOf(b);
    if (ia == null || ib == null) return false;
    return ia > ib;
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
  bool isSatisfied(PuzzlePlacement placement) {
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
  bool isSatisfied(PuzzlePlacement placement) {
    final im = placement.indexOf(middle);
    final il = placement.indexOf(left);
    final ir = placement.indexOf(right);
    if (im == null || il == null || ir == null) return false;
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

bool _isLeftSide(int index, int seatCount) => index < (seatCount / 2).ceil();

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
  bool isSatisfied(PuzzlePlacement placement) {
    final ia = placement.indexOf(a);
    final ib = placement.indexOf(b);
    if (ia == null || ib == null) return false;
    return _isLeftSide(ia, seatCount) == _isLeftSide(ib, seatCount);
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
  bool isSatisfied(PuzzlePlacement placement) {
    final ia = placement.indexOf(a);
    final ib = placement.indexOf(b);
    if (ia == null || ib == null) return false;
    return _isLeftSide(ia, seatCount) != _isLeftSide(ib, seatCount);
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
