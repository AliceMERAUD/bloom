import '../models/puzzle/puzzle.dart';
import '../models/puzzle/puzzle_constraint.dart';
import '../models/puzzle/puzzle_models.dart';

List<PuzzlePosition> _row(int count) {
  return List.generate(
    count,
    (index) => PuzzlePosition(
      id: 'p$index',
      index: index,
      label: '${index + 1}',
    ),
  );
}

PuzzleCharacter _c(String id, String name) =>
    PuzzleCharacter(id: id, name: name, assetKey: id);

/// Deterministic catalog of 15 V1 logic puzzles.
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

  static Puzzle _p01() => Puzzle(
        id: 'bus_friends',
        title: 'Les amis dans le bus',
        description: 'Quatre amis montent dans le bus.',
        scenario: 'bus',
        difficulty: PuzzleDifficulty.easy,
        characters: [
          _c('alice', 'Alice'),
          _c('bob', 'Bob'),
          _c('charlie', 'Charlie'),
          _c('dana', 'Dana'),
        ],
        positions: _row(4),
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'alice',
            index: 0,
            description: 'Alice est à la place 1.',
          ),
          AdjacentConstraint(
            id: '2',
            a: 'alice',
            b: 'bob',
            description: 'Bob est à côté d’Alice.',
          ),
          BeforeConstraint(
            id: '3',
            a: 'bob',
            b: 'charlie',
            description: 'Bob est avant Charlie.',
          ),
          BeforeConstraint(
            id: '4',
            a: 'charlie',
            b: 'dana',
            description: 'Charlie est avant Dana.',
          ),
        ],
        referenceSolution: {
          'alice': 0,
          'bob': 1,
          'charlie': 2,
          'dana': 3,
        },
      );

  static Puzzle _p02() => Puzzle(
        id: 'bus_commuters',
        title: 'Trajet du matin',
        description: 'Cinq voyageurs partagent une rangée.',
        scenario: 'bus',
        difficulty: PuzzleDifficulty.easy,
        characters: [
          _c('eve', 'Ève'),
          _c('frank', 'Frank'),
          _c('gina', 'Gina'),
          _c('hugo', 'Hugo'),
          _c('iris', 'Iris'),
        ],
        positions: _row(5),
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'eve',
            index: 2,
            description: 'Ève est au milieu (place 3).',
          ),
          AdjacentConstraint(
            id: '2',
            a: 'eve',
            b: 'frank',
            description: 'Frank est à côté d’Ève.',
          ),
          BeforeConstraint(
            id: '3',
            a: 'gina',
            b: 'eve',
            description: 'Gina est avant Ève.',
          ),
          AfterConstraint(
            id: '4',
            a: 'iris',
            b: 'hugo',
            description: 'Iris est après Hugo.',
          ),
          NotAdjacentConstraint(
            id: '5',
            a: 'gina',
            b: 'hugo',
            description: 'Gina n’est pas à côté de Hugo.',
          ),
        ],
        referenceSolution: {
          'gina': 0,
          'frank': 1,
          'eve': 2,
          'hugo': 3,
          'iris': 4,
        },
      );

  static Puzzle _p03() => Puzzle(
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
        positions: _row(6),
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'lea',
            index: 0,
            description: 'Léa est à la place 1.',
          ),
          AdjacentConstraint(
            id: '2',
            a: 'lea',
            b: 'max',
            description: 'Max est à côté de Léa.',
          ),
          BetweenConstraint(
            id: '3',
            middle: 'nina',
            left: 'max',
            right: 'omar',
            description: 'Nina est entre Max et Omar.',
          ),
          BeforeConstraint(
            id: '4',
            a: 'omar',
            b: 'paul',
            description: 'Omar est avant Paul.',
          ),
          AdjacentConstraint(
            id: '5',
            a: 'paul',
            b: 'quin',
            description: 'Paul est à côté de Quinn.',
          ),
          AfterConstraint(
            id: '6',
            a: 'quin',
            b: 'paul',
            description: 'Quinn est après Paul.',
          ),
        ],
        referenceSolution: {
          'lea': 0,
          'max': 1,
          'nina': 2,
          'omar': 3,
          'paul': 4,
          'quin': 5,
        },
      );

  static Puzzle _p04() => Puzzle(
        id: 'wedding_family',
        title: 'Photo de famille',
        description: 'La famille se range pour la photo.',
        scenario: 'mariage',
        difficulty: PuzzleDifficulty.easy,
        characters: [
          _c('anne', 'Anne'),
          _c('ben', 'Ben'),
          _c('claire', 'Claire'),
          _c('david', 'David'),
        ],
        positions: _row(4),
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'anne',
            index: 1,
            description: 'Anne est à la place 2.',
          ),
          AdjacentConstraint(
            id: '2',
            a: 'anne',
            b: 'ben',
            description: 'Ben est à côté d’Anne.',
          ),
          BeforeConstraint(
            id: '3',
            a: 'claire',
            b: 'anne',
            description: 'Claire est avant Anne.',
          ),
          AfterConstraint(
            id: '4',
            a: 'david',
            b: 'ben',
            description: 'David est après Ben.',
          ),
        ],
        referenceSolution: {
          'claire': 0,
          'anne': 1,
          'ben': 2,
          'david': 3,
        },
      );

  static Puzzle _p05() => Puzzle(
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
        positions: _row(5),
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'emma',
            index: 0,
            description: 'Emma ouvre le cortège (place 1).',
          ),
          AdjacentConstraint(
            id: '2',
            a: 'emma',
            b: 'felix',
            description: 'Félix marche à côté d’Emma.',
          ),
          BetweenConstraint(
            id: '3',
            middle: 'grace',
            left: 'felix',
            right: 'henri',
            description: 'Grace est entre Félix et Henri.',
          ),
          BeforeConstraint(
            id: '4',
            a: 'henri',
            b: 'ines',
            description: 'Henri est avant Inès.',
          ),
          NotAdjacentConstraint(
            id: '5',
            a: 'emma',
            b: 'grace',
            description: 'Emma n’est pas à côté de Grace.',
          ),
        ],
        referenceSolution: {
          'emma': 0,
          'felix': 1,
          'grace': 2,
          'henri': 3,
          'ines': 4,
        },
      );

  static Puzzle _p06() => Puzzle(
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
        positions: _row(4),
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'jade',
            index: 3,
            description: 'Jade est à la place 4.',
          ),
          AdjacentConstraint(
            id: '2',
            a: 'jade',
            b: 'karl',
            description: 'Karl est à côté de Jade.',
          ),
          BeforeConstraint(
            id: '3',
            a: 'lina',
            b: 'karl',
            description: 'Lina est avant Karl.',
          ),
          AdjacentConstraint(
            id: '4',
            a: 'lina',
            b: 'marc',
            description: 'Marc est à côté de Lina.',
          ),
        ],
        referenceSolution: {
          'lina': 0,
          'marc': 1,
          'karl': 2,
          'jade': 3,
        },
      );

  static Puzzle _p07() => Puzzle(
        id: 'waiting_station',
        title: 'Gare routière',
        description: 'Cinq voyageurs attendent sur un banc.',
        scenario: 'salle_attente',
        difficulty: PuzzleDifficulty.medium,
        characters: [
          _c('nora', 'Nora'),
          _c('oscar', 'Oscar'),
          _c('piper', 'Piper'),
          _c('quentin', 'Quentin'),
          _c('rose', 'Rose'),
        ],
        positions: _row(5),
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'nora',
            index: 2,
            description: 'Nora est au centre.',
          ),
          BeforeConstraint(
            id: '2',
            a: 'oscar',
            b: 'nora',
            description: 'Oscar est avant Nora.',
          ),
          AdjacentConstraint(
            id: '3',
            a: 'oscar',
            b: 'piper',
            description: 'Piper est à côté d’Oscar.',
          ),
          AdjacentConstraint(
            id: '4',
            a: 'nora',
            b: 'quentin',
            description: 'Quentin est à côté de Nora.',
          ),
          AfterConstraint(
            id: '5',
            a: 'rose',
            b: 'quentin',
            description: 'Rose est après Quentin.',
          ),
          NotAdjacentConstraint(
            id: '6',
            a: 'nora',
            b: 'rose',
            description: 'Nora n’est pas à côté de Rose.',
          ),
        ],
        referenceSolution: {
          'oscar': 0,
          'piper': 1,
          'nora': 2,
          'quentin': 3,
          'rose': 4,
        },
      );

  static Puzzle _p08() => Puzzle(
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
        positions: _row(4),
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'sam',
            index: 0,
            description: 'Sam est à la place 1.',
          ),
          AdjacentConstraint(
            id: '2',
            a: 'sam',
            b: 'tina',
            description: 'Tina est à côté de Sam.',
          ),
          BeforeConstraint(
            id: '3',
            a: 'ugo',
            b: 'vera',
            description: 'Ugo est avant Vera.',
          ),
          NotAdjacentConstraint(
            id: '4',
            a: 'tina',
            b: 'vera',
            description: 'Tina n’est pas à côté de Vera.',
          ),
        ],
        // Sam0 Tina1 Ugo2 Vera3 — Tina not adj Vera: 1 and 3 OK
        referenceSolution: {
          'sam': 0,
          'tina': 1,
          'ugo': 2,
          'vera': 3,
        },
      );

  static Puzzle _p09() => Puzzle(
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
        positions: _row(6),
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'alex',
            index: 0,
            description: 'Alex est au bureau 1.',
          ),
          SameSideConstraint(
            id: '2',
            a: 'alex',
            b: 'bella',
            seatCount: 6,
            description: 'Alex et Bella sont du même côté.',
          ),
          DifferentSideConstraint(
            id: '3',
            a: 'chris',
            b: 'diana',
            seatCount: 6,
            description: 'Chris et Diana sont de côtés opposés.',
          ),
          AdjacentConstraint(
            id: '4',
            a: 'bella',
            b: 'chris',
            description: 'Chris est à côté de Bella.',
          ),
          BetweenConstraint(
            id: '5',
            middle: 'diana',
            left: 'chris',
            right: 'eric',
            description: 'Diana est entre Chris et Éric.',
          ),
          AfterConstraint(
            id: '6',
            a: 'fay',
            b: 'eric',
            description: 'Fay est après Éric.',
          ),
        ],
        // left 0,1,2 / right 3,4,5
        // Alex0 Bella1 (same left) Chris2 (adj Bella) — Chris left so Diana right.
        // Diana between Chris and Eric: Chris=2, Diana=3, Eric=4, Fay=5
        referenceSolution: {
          'alex': 0,
          'bella': 1,
          'chris': 2,
          'diana': 3,
          'eric': 4,
          'fay': 5,
        },
      );

  static Puzzle _p10() => Puzzle(
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
        positions: _row(5),
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
          BeforeConstraint(
            id: '3',
            a: 'xena',
            b: 'yan',
            description: 'Xena est avant Yan.',
          ),
          BetweenConstraint(
            id: '4',
            middle: 'will',
            left: 'xena',
            right: 'yan',
            description: 'Will est entre Xena et Yan.',
          ),
          AdjacentConstraint(
            id: '5',
            a: 'xena',
            b: 'vik',
            description: 'Vik est à côté de Xena.',
          ),
        ],
        // Vik0 Xena1 Will2 Yan3 Zoe4
        referenceSolution: {
          'vik': 0,
          'xena': 1,
          'will': 2,
          'yan': 3,
          'zoe': 4,
        },
      );

  static Puzzle _p11() => Puzzle(
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
        positions: _row(4),
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'uma',
            index: 2,
            description: 'Uma est à la place 3.',
          ),
          AdjacentConstraint(
            id: '2',
            a: 'uma',
            b: 'ted',
            description: 'Ted est à côté d’Uma.',
          ),
          BeforeConstraint(
            id: '3',
            a: 'sara',
            b: 'uma',
            description: 'Sara est avant Uma.',
          ),
          AfterConstraint(
            id: '4',
            a: 'ron',
            b: 'ted',
            description: 'Ron est après Ted.',
          ),
        ],
        // Sara0 Ted1 Uma2 Ron3 OR Sara0 Uma2 Ted3 — Ted adj Uma: 1 or 3.
        // If Ted=3, Ron after Ted impossible. So Ted=1 Ron=3 Sara=0
        referenceSolution: {
          'sara': 0,
          'ted': 1,
          'uma': 2,
          'ron': 3,
        },
      );

  static Puzzle _p12() => Puzzle(
        id: 'cafe_counter',
        title: 'Comptoir du café',
        description: 'Cinq clients font la file.',
        scenario: 'cafe',
        difficulty: PuzzleDifficulty.medium,
        characters: [
          _c('pauline', 'Pauline'),
          _c('quent', 'Quentin'),
          _c('remy', 'Rémy'),
          _c('sofia', 'Sofia'),
          _c('theo', 'Théo'),
        ],
        positions: _row(5),
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'pauline',
            index: 0,
            description: 'Pauline est la première.',
          ),
          AdjacentConstraint(
            id: '2',
            a: 'pauline',
            b: 'quent',
            description: 'Quentin est juste derrière Pauline.',
          ),
          BetweenConstraint(
            id: '3',
            middle: 'remy',
            left: 'quent',
            right: 'theo',
            description: 'Rémy est entre Quentin et Théo.',
          ),
          BeforeConstraint(
            id: '4',
            a: 'sofia',
            b: 'theo',
            description: 'Sofia est avant Théo.',
          ),
          NotAdjacentConstraint(
            id: '5',
            a: 'quent',
            b: 'sofia',
            description: 'Quentin n’est pas à côté de Sofia.',
          ),
        ],
        // P0 Q1 R2 S3 T4 — Quent not adj Sofia: 1 and 3 OK
        referenceSolution: {
          'pauline': 0,
          'quent': 1,
          'remy': 2,
          'sofia': 3,
          'theo': 4,
        },
      );

  static Puzzle _p13() => Puzzle(
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
        positions: _row(4),
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'lucie',
            index: 0,
            description: 'Lucie est à gauche.',
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
        ],
        referenceSolution: {
          'lucie': 0,
          'noah': 1,
          'olivia': 2,
          'pierre': 3,
        },
      );

  static Puzzle _p14() => Puzzle(
        id: 'train_carriage',
        title: 'Voiture de train',
        description: 'Six passagers occupent une banquette.',
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
        positions: _row(6),
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'aria',
            index: 5,
            description: 'Aria est à la place 6.',
          ),
          AdjacentConstraint(
            id: '2',
            a: 'aria',
            b: 'bruno',
            description: 'Bruno est à côté d’Aria.',
          ),
          BeforeConstraint(
            id: '3',
            a: 'celia',
            b: 'bruno',
            description: 'Célia est avant Bruno.',
          ),
          BetweenConstraint(
            id: '4',
            middle: 'diego',
            left: 'celia',
            right: 'bruno',
            description: 'Diego est entre Célia et Bruno.',
          ),
          SameSideConstraint(
            id: '5',
            a: 'celia',
            b: 'elena',
            seatCount: 6,
            description: 'Célia et Elena sont du même côté.',
          ),
          DifferentSideConstraint(
            id: '6',
            a: 'finn',
            b: 'bruno',
            seatCount: 6,
            description: 'Finn et Bruno sont de côtés opposés.',
          ),
        ],
        // Aria5 Bruno4. Célia before Bruno, Diego between. Célia left (0,1,2), Elena same left.
        // Bruno right (4) so Finn left. 
        // C0 E1 D2 ? F3 B4 A5 — Diego between C and B: between 0 and 4 → 1,2,3. If D=2 OK. Finn=3 left? left<3 so 0,1,2 — Finn at 3 is RIGHT. Fail.
        // C0 E1 F2 D3 B4 A5 — Diego between 0 and 4: 3 OK. Finn=2 left, Bruno=4 right OK. Célia&Elena left OK.
        referenceSolution: {
          'celia': 0,
          'elena': 1,
          'finn': 2,
          'diego': 3,
          'bruno': 4,
          'aria': 5,
        },
      );

  static Puzzle _p15() => Puzzle(
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
        positions: _row(5),
        constraints: [
          FixedPositionConstraint(
            id: '1',
            characterId: 'chloe',
            index: 2,
            description: 'Chloé est au centre.',
          ),
          AdjacentConstraint(
            id: '2',
            a: 'chloe',
            b: 'dylan',
            description: 'Dylan est à côté de Chloé.',
          ),
          BeforeConstraint(
            id: '3',
            a: 'eva',
            b: 'chloe',
            description: 'Eva est avant Chloé.',
          ),
          AfterConstraint(
            id: '4',
            a: 'hannah',
            b: 'gabriel',
            description: 'Hannah est après Gabriel.',
          ),
          NotAdjacentConstraint(
            id: '5',
            a: 'dylan',
            b: 'gabriel',
            description: 'Dylan n’est pas à côté de Gabriel.',
          ),
          AdjacentConstraint(
            id: '6',
            a: 'eva',
            b: 'gabriel',
            description: 'Gabriel est à côté d’Eva.',
          ),
        ],
        // Eva0 Gabriel1 Chloe2 Dylan3 Hannah4 — Dylan adj Chloe (3), not adj Gabriel (1) OK
        referenceSolution: {
          'eva': 0,
          'gabriel': 1,
          'chloe': 2,
          'dylan': 3,
          'hannah': 4,
        },
      );
}
