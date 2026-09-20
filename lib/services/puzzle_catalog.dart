import '../models/puzzle/puzzle.dart';
import '../models/puzzle/puzzle_constraint.dart';
import '../models/puzzle/puzzle_geometry.dart';
import '../models/puzzle/puzzle_models.dart';

PuzzleCharacter _c(String id, String name) =>
    PuzzleCharacter(id: id, name: name, assetKey: id);

Puzzle _gridPuzzle({
  required String id,
  required String title,
  required String description,
  required String scenario,
  required PuzzleDifficulty difficulty,
  required List<PuzzleCharacter> characters,
  required List<String> layout,
  required List<PuzzleConstraint> constraints,
  required Map<String, int> referenceSolution,
}) {
  final geo = PuzzleGeometry.fromAscii(layout: layout);
  return Puzzle(
    id: id,
    title: title,
    description: description,
    scenario: scenario,
    difficulty: difficulty,
    characters: characters,
    positions: positionsFromGeometry(geo),
    constraints: constraints,
    referenceSolution: referenceSolution,
    geometry: geo,
  );
}

/// Deterministic catalog of 15 Puzzle 2.0 grid logic puzzles.
class PuzzleCatalog {
  static final List<Puzzle> all = List.unmodifiable([
    _p01(),
    _p02(),
    _p03(),
    _p04(),
    _p05(),
    _p06(),
    _p07(),
    _p08(),
    _p09(),
    _p10(),
    _p11(),
    _p12(),
    _p13(),
    _p14(),
    _p15(),
  ]);

  static Puzzle byId(String id) => all.firstWhere((p) => p.id == id);

  static int indexOf(String id) => all.indexWhere((p) => p.id == id);

  /// 2×3 bus — seats 0,1 / 2,3
  static Puzzle _p01() => _gridPuzzle(
        id: 'bus_friends',
        title: 'Les amis dans le bus',
        description: 'Quatre amis trouvent leur place dans le bus.',
        scenario: 'bus',
        difficulty: PuzzleDifficulty.easy,
        characters: [
          _c('alice', 'Alice'),
          _c('bob', 'Bob'),
          _c('charlie', 'Charlie'),
          _c('dana', 'Dana'),
        ],
        layout: const [
          'W..',
          'D..',
        ],
        constraints: [
          NearObjectConstraint(
            id: '1',
            characterId: 'alice',
            objectId: 'window',
            description: 'Alice est près de la fenêtre.',
          ),
          NearObjectConstraint(
            id: '2',
            characterId: 'dana',
            objectId: 'door',
            description: 'Dana est près de la porte.',
          ),
          AdjacentConstraint(
            id: '3',
            a: 'alice',
            b: 'bob',
            description: 'Bob est à côté d’Alice.',
          ),
          BeforeConstraint(
            id: '4',
            a: 'bob',
            b: 'charlie',
            description: 'Bob est avant Charlie.',
          ),
        ],
        referenceSolution: {
          'alice': 0,
          'bob': 1,
          'dana': 2,
          'charlie': 3,
        },
      );

  /// 2×3 — seats 0,1 / 2,3,4
  static Puzzle _p02() => _gridPuzzle(
        id: 'bus_commuters',
        title: 'Trajet du matin',
        description: 'Cinq voyageurs partagent la plate-forme.',
        scenario: 'bus',
        difficulty: PuzzleDifficulty.easy,
        characters: [
          _c('eve', 'Ève'),
          _c('frank', 'Frank'),
          _c('gina', 'Gina'),
          _c('hugo', 'Hugo'),
          _c('iris', 'Iris'),
        ],
        layout: const [
          'W..',
          '...',
        ],
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'eve',
            index: 3,
            description: 'Ève est au centre, en bas.',
          ),
          NearObjectConstraint(
            id: '2',
            characterId: 'frank',
            objectId: 'window',
            description: 'Frank est près de la fenêtre.',
          ),
          AdjacentConstraint(
            id: '3',
            a: 'eve',
            b: 'hugo',
            description: 'Hugo est à côté d’Ève.',
          ),
          SameRowConstraint(
            id: '4',
            a: 'gina',
            b: 'iris',
            description: 'Gina et Iris sont sur la même rangée.',
          ),
          BeforeConstraint(
            id: '5',
            a: 'gina',
            b: 'iris',
            description: 'Gina est avant Iris.',
          ),
        ],
        referenceSolution: {
          'gina': 0,
          'iris': 1,
          'frank': 2,
          'eve': 3,
          'hugo': 4,
        },
      );

  /// 2×4 — seats 0,1,2,3 / 4,5 with W..D on bottom
  static Puzzle _p03() => _gridPuzzle(
        id: 'bus_school',
        title: 'Le bus scolaire',
        description: 'Six élèves doivent respecter le plan de places.',
        scenario: 'bus',
        difficulty: PuzzleDifficulty.medium,
        characters: [
          _c('lea', 'Léa'),
          _c('max', 'Max'),
          _c('nina', 'Nina'),
          _c('omar', 'Omar'),
          _c('paul', 'Paul'),
          _c('quin', 'Quinn'),
        ],
        layout: const [
          '....',
          'W..D',
        ],
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'lea',
            index: 0,
            description: 'Léa est à la place 1.',
          ),
          NearObjectConstraint(
            id: '2',
            characterId: 'lea',
            objectId: 'window',
            description: 'Léa est près de la fenêtre.',
          ),
          NearObjectConstraint(
            id: '3',
            characterId: 'omar',
            objectId: 'door',
            description: 'Omar est près de la porte.',
          ),
          AdjacentConstraint(
            id: '4',
            a: 'lea',
            b: 'max',
            description: 'Max est à côté de Léa.',
          ),
          BetweenConstraint(
            id: '5',
            middle: 'nina',
            left: 'max',
            right: 'omar',
            description: 'Nina est entre Max et Omar.',
          ),
          SameRowConstraint(
            id: '6',
            a: 'paul',
            b: 'quin',
            description: 'Paul et Quinn sont sur la même rangée.',
          ),
          BeforeConstraint(
            id: '7',
            a: 'paul',
            b: 'quin',
            description: 'Paul est avant Quinn.',
          ),
        ],
        // Lea0 Max1 Nina2 Omar3 Paul4 Quin5
        referenceSolution: {
          'lea': 0,
          'max': 1,
          'nina': 2,
          'omar': 3,
          'paul': 4,
          'quin': 5,
        },
      );

  /// 2×3 — seats 0 / 1,2,3
  static Puzzle _p04() => _gridPuzzle(
        id: 'wedding_family',
        title: 'Photo de famille',
        description: 'La famille se range près de la table.',
        scenario: 'mariage',
        difficulty: PuzzleDifficulty.easy,
        characters: [
          _c('anne', 'Anne'),
          _c('ben', 'Ben'),
          _c('claire', 'Claire'),
          _c('david', 'David'),
        ],
        layout: const [
          '.T#',
          '...',
        ],
        constraints: [
          NearObjectConstraint(
            id: '1',
            characterId: 'anne',
            objectId: 'table',
            description: 'Anne est près de la table.',
          ),
          AdjacentConstraint(
            id: '2',
            a: 'anne',
            b: 'ben',
            description: 'Ben est à côté d’Anne.',
          ),
          SameRowConstraint(
            id: '3',
            a: 'claire',
            b: 'david',
            description: 'Claire et David sont sur la même rangée.',
          ),
          BeforeConstraint(
            id: '4',
            a: 'claire',
            b: 'david',
            description: 'Claire est avant David.',
          ),
        ],
        referenceSolution: {
          'anne': 0,
          'ben': 1,
          'claire': 2,
          'david': 3,
        },
      );

  /// 2×3 — seats 0,1 / 2,3,4
  static Puzzle _p05() => _gridPuzzle(
        id: 'wedding_photos',
        title: 'Cortège nuptial',
        description: 'Cinq personnes forment le cortège.',
        scenario: 'mariage',
        difficulty: PuzzleDifficulty.medium,
        characters: [
          _c('emma', 'Emma'),
          _c('felix', 'Félix'),
          _c('grace', 'Grace'),
          _c('henri', 'Henri'),
          _c('ines', 'Inès'),
        ],
        layout: const [
          '..D',
          '...',
        ],
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'emma',
            index: 1,
            description: 'Emma est près de la porte (place 2).',
          ),
          NearObjectConstraint(
            id: '2',
            characterId: 'emma',
            objectId: 'door',
            description: 'Emma est près de la porte.',
          ),
          AdjacentConstraint(
            id: '3',
            a: 'emma',
            b: 'felix',
            description: 'Félix marche à côté d’Emma.',
          ),
          SameColConstraint(
            id: '4',
            a: 'felix',
            b: 'grace',
            description: 'Félix et Grace sont dans la même colonne.',
          ),
          AdjacentConstraint(
            id: '5',
            a: 'grace',
            b: 'henri',
            description: 'Henri est à côté de Grace.',
          ),
          BeforeConstraint(
            id: '6',
            a: 'grace',
            b: 'henri',
            description: 'Grace est avant Henri.',
          ),
        ],
        referenceSolution: {
          'felix': 0,
          'emma': 1,
          'grace': 2,
          'henri': 3,
          'ines': 4,
        },
      );

  /// 2×3 — seats 0,1 / 2,3
  static Puzzle _p06() => _gridPuzzle(
        id: 'waiting_clinic',
        title: 'Salle d’attente',
        description: 'Quatre patients attendent à la clinique.',
        scenario: 'salle_attente',
        difficulty: PuzzleDifficulty.easy,
        characters: [
          _c('jade', 'Jade'),
          _c('karl', 'Karl'),
          _c('lina', 'Lina'),
          _c('marc', 'Marc'),
        ],
        layout: const [
          '..D',
          '..W',
        ],
        constraints: [
          NearObjectConstraint(
            id: '1',
            characterId: 'jade',
            objectId: 'door',
            description: 'Jade est près de la porte.',
          ),
          NearObjectConstraint(
            id: '2',
            characterId: 'karl',
            objectId: 'window',
            description: 'Karl est près de la fenêtre.',
          ),
          AdjacentConstraint(
            id: '3',
            a: 'lina',
            b: 'marc',
            description: 'Marc est à côté de Lina.',
          ),
          BeforeConstraint(
            id: '4',
            a: 'lina',
            b: 'jade',
            description: 'Lina est avant Jade.',
          ),
        ],
        referenceSolution: {
          'lina': 0,
          'jade': 1,
          'marc': 2,
          'karl': 3,
        },
      );

  /// 2×3 — seats 0,1 / 2,3,4
  static Puzzle _p07() => _gridPuzzle(
        id: 'waiting_station',
        title: 'Gare routière',
        description: 'Cinq voyageurs attendent sur les bancs.',
        scenario: 'salle_attente',
        difficulty: PuzzleDifficulty.medium,
        characters: [
          _c('nora', 'Nora'),
          _c('oscar', 'Oscar'),
          _c('piper', 'Piper'),
          _c('quentin', 'Quentin'),
          _c('rose', 'Rose'),
        ],
        layout: const [
          'B..',
          '...',
        ],
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'nora',
            index: 0,
            description: 'Nora est près du banc (place 1).',
          ),
          NearObjectConstraint(
            id: '2',
            characterId: 'nora',
            objectId: 'bench',
            description: 'Nora est près du banc.',
          ),
          AdjacentConstraint(
            id: '3',
            a: 'nora',
            b: 'oscar',
            description: 'Oscar est à côté de Nora.',
          ),
          SameColConstraint(
            id: '4',
            a: 'piper',
            b: 'quentin',
            description: 'Piper et Quentin sont dans la même colonne.',
          ),
          BeforeConstraint(
            id: '5',
            a: 'piper',
            b: 'quentin',
            description: 'Piper est avant Quentin.',
          ),
          DistanceAtMostConstraint(
            id: '6',
            a: 'rose',
            b: 'nora',
            maxDistance: 2,
            description: 'Rose est à distance ≤ 2 de Nora.',
          ),
          NotAdjacentConstraint(
            id: '7',
            a: 'nora',
            b: 'rose',
            description: 'Nora n’est pas à côté de Rose.',
          ),
        ],
        referenceSolution: {
          'nora': 0,
          'piper': 1,
          'rose': 2,
          'oscar': 3,
          'quentin': 4,
        },
      );

  /// 2×3 — seats 0,1 / 2,3
  static Puzzle _p08() => _gridPuzzle(
        id: 'office_meeting',
        title: 'Réunion d’équipe',
        description: 'Quatre collègues s’assoient autour de la table.',
        scenario: 'bureau',
        difficulty: PuzzleDifficulty.easy,
        characters: [
          _c('sam', 'Sam'),
          _c('tina', 'Tina'),
          _c('ugo', 'Ugo'),
          _c('vera', 'Vera'),
        ],
        layout: const [
          '.T.',
          '.#.',
        ],
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'sam',
            index: 0,
            description: 'Sam est à gauche de la table.',
          ),
          NearObjectConstraint(
            id: '2',
            characterId: 'sam',
            objectId: 'table',
            description: 'Sam est près de la table.',
          ),
          AdjacentConstraint(
            id: '3',
            a: 'sam',
            b: 'tina',
            description: 'Tina est à côté de Sam.',
          ),
          SameColConstraint(
            id: '4',
            a: 'ugo',
            b: 'vera',
            description: 'Ugo et Vera sont dans la même colonne.',
          ),
          BeforeConstraint(
            id: '5',
            a: 'ugo',
            b: 'vera',
            description: 'Ugo est avant Vera.',
          ),
        ],
        referenceSolution: {
          'sam': 0,
          'ugo': 1,
          'tina': 2,
          'vera': 3,
        },
      );

  /// 2×4 — seats 0,1 / 2,3,4,5
  static Puzzle _p09() => _gridPuzzle(
        id: 'office_desks',
        title: 'Open space',
        description: 'Six collègues choisissent leur bureau.',
        scenario: 'bureau',
        difficulty: PuzzleDifficulty.hard,
        characters: [
          _c('alex', 'Alex'),
          _c('bella', 'Bella'),
          _c('chris', 'Chris'),
          _c('diana', 'Diana'),
          _c('eric', 'Éric'),
          _c('fay', 'Fay'),
        ],
        layout: const [
          'W..D',
          '....',
        ],
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'alex',
            index: 0,
            description: 'Alex est près de la fenêtre (place 1).',
          ),
          NearObjectConstraint(
            id: '2',
            characterId: 'alex',
            objectId: 'window',
            description: 'Alex est près de la fenêtre.',
          ),
          FixedPositionConstraint(
            id: '3',
            characterId: 'fay',
            index: 1,
            description: 'Fay est près de la porte (place 2).',
          ),
          NearObjectConstraint(
            id: '4',
            characterId: 'fay',
            objectId: 'door',
            description: 'Fay est près de la porte.',
          ),
          SameColConstraint(
            id: '5',
            a: 'alex',
            b: 'bella',
            description: 'Alex et Bella sont dans la même colonne.',
          ),
          DifferentSideConstraint(
            id: '6',
            a: 'chris',
            b: 'diana',
            seatCount: 6,
            description: 'Chris et Diana sont de côtés opposés.',
          ),
          AdjacentConstraint(
            id: '7',
            a: 'bella',
            b: 'chris',
            description: 'Chris est à côté de Bella.',
          ),
          DistanceAtMostConstraint(
            id: '8',
            a: 'diana',
            b: 'eric',
            maxDistance: 1,
            description: 'Diana et Éric sont voisins.',
          ),
          BeforeConstraint(
            id: '9',
            a: 'diana',
            b: 'eric',
            description: 'Diana est avant Éric.',
          ),
        ],
        // Alex0 Bella3 (same col). Chris2. Diana4 Eric5.
        referenceSolution: {
          'alex': 0,
          'fay': 1,
          'chris': 2,
          'bella': 3,
          'diana': 4,
          'eric': 5,
        },
      );

  /// Row under screen — seats 0..4
  static Puzzle _p10() => _gridPuzzle(
        id: 'cinema_row',
        title: 'Rangée de cinéma',
        description: 'Cinq amis choisissent leurs sièges.',
        scenario: 'cinema',
        difficulty: PuzzleDifficulty.medium,
        characters: [
          _c('zoe', 'Zoé'),
          _c('yan', 'Yan'),
          _c('xena', 'Xena'),
          _c('will', 'Will'),
          _c('vik', 'Vik'),
        ],
        layout: const [
          'S.....',
        ],
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'zoe',
            index: 4,
            description: 'Zoé est au bout (place 5).',
          ),
          AdjacentConstraint(
            id: '2',
            a: 'zoe',
            b: 'yan',
            description: 'Yan est à côté de Zoé.',
          ),
          BetweenConstraint(
            id: '3',
            middle: 'will',
            left: 'xena',
            right: 'yan',
            description: 'Will est entre Xena et Yan.',
          ),
          AdjacentConstraint(
            id: '4',
            a: 'xena',
            b: 'vik',
            description: 'Vik est à côté de Xena.',
          ),
          NearObjectConstraint(
            id: '5',
            characterId: 'vik',
            objectId: 'screen',
            description: 'Vik est près de l’écran.',
          ),
        ],
        // Seats after S: 0,1,2,3,4. Vik near S→0.
        referenceSolution: {
          'vik': 0,
          'xena': 1,
          'will': 2,
          'yan': 3,
          'zoe': 4,
        },
      );

  static Puzzle _p11() => _gridPuzzle(
        id: 'library_table',
        title: 'Table de bibliothèque',
        description: 'Quatre lecteurs partagent une table.',
        scenario: 'bibliotheque',
        difficulty: PuzzleDifficulty.easy,
        characters: [
          _c('uma', 'Uma'),
          _c('ted', 'Ted'),
          _c('sara', 'Sara'),
          _c('ron', 'Ron'),
        ],
        layout: const [
          '.T#',
          '...',
        ],
        constraints: [
          NearObjectConstraint(
            id: '1',
            characterId: 'uma',
            objectId: 'table',
            description: 'Uma est près de la table.',
          ),
          AdjacentConstraint(
            id: '2',
            a: 'uma',
            b: 'ted',
            description: 'Ted est à côté d’Uma.',
          ),
          SameRowConstraint(
            id: '3',
            a: 'sara',
            b: 'ron',
            description: 'Sara et Ron sont sur la même rangée.',
          ),
          BeforeConstraint(
            id: '4',
            a: 'sara',
            b: 'ron',
            description: 'Sara est avant Ron.',
          ),
        ],
        referenceSolution: {
          'uma': 0,
          'ted': 1,
          'sara': 2,
          'ron': 3,
        },
      );

  /// 2×3 café — seats 0,1 / 2,3,4
  static Puzzle _p12() => _gridPuzzle(
        id: 'cafe_counter',
        title: 'Comptoir du café',
        description: 'Cinq clients s’installent au café.',
        scenario: 'cafe',
        difficulty: PuzzleDifficulty.medium,
        characters: [
          _c('pauline', 'Pauline'),
          _c('quent', 'Quentin'),
          _c('remy', 'Rémy'),
          _c('sofia', 'Sofia'),
          _c('theo', 'Théo'),
        ],
        layout: const [
          'C..',
          '...',
        ],
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'pauline',
            index: 0,
            description: 'Pauline est près du comptoir (place 1).',
          ),
          NearObjectConstraint(
            id: '2',
            characterId: 'pauline',
            objectId: 'counter',
            description: 'Pauline est près du comptoir.',
          ),
          AdjacentConstraint(
            id: '3',
            a: 'pauline',
            b: 'quent',
            description: 'Quentin est à côté de Pauline.',
          ),
          SameColConstraint(
            id: '4',
            a: 'quent',
            b: 'theo',
            description: 'Quentin et Théo sont dans la même colonne.',
          ),
          AdjacentConstraint(
            id: '5',
            a: 'remy',
            b: 'theo',
            description: 'Rémy est à côté de Théo.',
          ),
          BeforeConstraint(
            id: '6',
            a: 'remy',
            b: 'theo',
            description: 'Rémy est avant Théo.',
          ),
          NotAdjacentConstraint(
            id: '7',
            a: 'quent',
            b: 'sofia',
            description: 'Quentin n’est pas à côté de Sofia.',
          ),
        ],
        referenceSolution: {
          'pauline': 0,
          'quent': 1,
          'sofia': 2,
          'remy': 3,
          'theo': 4,
        },
      );

  /// 1×4 parc
  static Puzzle _p13() => _gridPuzzle(
        id: 'park_bench',
        title: 'Banc du parc',
        description: 'Quatre personnes partagent un banc.',
        scenario: 'parc',
        difficulty: PuzzleDifficulty.easy,
        characters: [
          _c('lucie', 'Lucie'),
          _c('noah', 'Noah'),
          _c('olivia', 'Olivia'),
          _c('pierre', 'Pierre'),
        ],
        layout: const [
          'A....',
        ],
        constraints: [
          NearObjectConstraint(
            id: '1',
            characterId: 'lucie',
            objectId: 'tree',
            description: 'Lucie est près de l’arbre.',
          ),
          AdjacentConstraint(
            id: '2',
            a: 'lucie',
            b: 'noah',
            description: 'Noah est à côté de Lucie.',
          ),
          AdjacentConstraint(
            id: '3',
            a: 'olivia',
            b: 'pierre',
            description: 'Olivia est à côté de Pierre.',
          ),
          BeforeConstraint(
            id: '4',
            a: 'noah',
            b: 'olivia',
            description: 'Noah est avant Olivia.',
          ),
          BeforeConstraint(
            id: '5',
            a: 'olivia',
            b: 'pierre',
            description: 'Olivia est avant Pierre.',
          ),
        ],
        referenceSolution: {
          'lucie': 0,
          'noah': 1,
          'olivia': 2,
          'pierre': 3,
        },
      );

  /// 2×4 train — seats 0,1 / 2,3,4,5
  static Puzzle _p14() => _gridPuzzle(
        id: 'train_carriage',
        title: 'Voiture de train',
        description: 'Six passagers occupent le compartiment.',
        scenario: 'train',
        difficulty: PuzzleDifficulty.hard,
        characters: [
          _c('aria', 'Aria'),
          _c('bruno', 'Bruno'),
          _c('celia', 'Célia'),
          _c('diego', 'Diego'),
          _c('elena', 'Elena'),
          _c('finn', 'Finn'),
        ],
        layout: const [
          'W..D',
          '....',
        ],
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'aria',
            index: 5,
            description: 'Aria est près de la porte (place 6).',
          ),
          NearObjectConstraint(
            id: '2',
            characterId: 'aria',
            objectId: 'door',
            description: 'Aria est près de la porte.',
          ),
          AdjacentConstraint(
            id: '3',
            a: 'aria',
            b: 'bruno',
            description: 'Bruno est à côté d’Aria.',
          ),
          NearObjectConstraint(
            id: '4',
            characterId: 'celia',
            objectId: 'window',
            description: 'Célia est près de la fenêtre.',
          ),
          BetweenConstraint(
            id: '5',
            middle: 'diego',
            left: 'celia',
            right: 'bruno',
            description: 'Diego est entre Célia et Bruno.',
          ),
          SameRowConstraint(
            id: '6',
            a: 'celia',
            b: 'bruno',
            description: 'Célia et Bruno sont sur la même rangée.',
          ),
          SameSideConstraint(
            id: '7',
            a: 'celia',
            b: 'elena',
            seatCount: 6,
            description: 'Célia et Elena sont du même côté.',
          ),
          BeforeConstraint(
            id: '8',
            a: 'elena',
            b: 'finn',
            description: 'Elena est avant Finn.',
          ),
          NotNearObjectConstraint(
            id: '9',
            characterId: 'finn',
            objectId: 'window',
            description: 'Finn n’est pas près de la fenêtre.',
          ),
        ],
        // Aria5 Bruno4 Célia2 Diego3 Elena0 Finn1
        referenceSolution: {
          'elena': 0,
          'finn': 1,
          'celia': 2,
          'diego': 3,
          'bruno': 4,
          'aria': 5,
        },
      );

  /// 2×3 dîner — seats 0,1 / 2,3,4
  static Puzzle _p15() => _gridPuzzle(
        id: 'dinner_table',
        title: 'Dîner entre amis',
        description: 'Cinq convives s’installent à table.',
        scenario: 'diner',
        difficulty: PuzzleDifficulty.medium,
        characters: [
          _c('chloe', 'Chloé'),
          _c('dylan', 'Dylan'),
          _c('eva', 'Eva'),
          _c('gabriel', 'Gabriel'),
          _c('hannah', 'Hannah'),
        ],
        layout: const [
          '.T.',
          '...',
        ],
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'chloe',
            index: 0,
            description: 'Chloé est à gauche de la table.',
          ),
          NearObjectConstraint(
            id: '2',
            characterId: 'chloe',
            objectId: 'table',
            description: 'Chloé est près de la table.',
          ),
          AdjacentConstraint(
            id: '3',
            a: 'chloe',
            b: 'dylan',
            description: 'Dylan est à côté de Chloé.',
          ),
          SameRowConstraint(
            id: '4',
            a: 'eva',
            b: 'gabriel',
            description: 'Eva et Gabriel sont sur la même rangée.',
          ),
          BeforeConstraint(
            id: '5',
            a: 'eva',
            b: 'gabriel',
            description: 'Eva est avant Gabriel.',
          ),
          NotAdjacentConstraint(
            id: '6',
            a: 'dylan',
            b: 'gabriel',
            description: 'Dylan n’est pas à côté de Gabriel.',
          ),
          NearObjectConstraint(
            id: '7',
            characterId: 'hannah',
            objectId: 'table',
            description: 'Hannah est près de la table.',
          ),
        ],
        // Chloe0 Dylan2 Eva3 Gabriel4 Hannah1
        referenceSolution: {
          'chloe': 0,
          'hannah': 1,
          'dylan': 2,
          'eva': 3,
          'gabriel': 4,
        },
      );
}
