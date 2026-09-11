import 'arrow.dart';

/// Reusable definition of an arrow shape.
/// A level can reuse the same template multiple times.
class ArrowTemplate {
  final String id;
  final List<ArrowPoint> path;
  final ArrowDirection direction;

  const ArrowTemplate({
    required this.id,
    required this.path,
    required this.direction,
  });

  int get length => path.length;

  int get turns {
    if (path.length < 3) return 0;
    var count = 0;
    for (var i = 2; i < path.length; i++) {
      final previous = Arrow.directionBetween(path[i - 2], path[i - 1]);
      final current = Arrow.directionBetween(path[i - 1], path[i]);
      if (previous != current) count++;
    }
    return count;
  }

  ArrowTemplate copy() => ArrowTemplate(
        id: id,
        path: List<ArrowPoint>.unmodifiable(path),
        direction: direction,
      );
}

const ArrowTemplate arrowTemplate01 = ArrowTemplate(id: 'arrow_001', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(0, 1), ArrowPoint(0, 2), ArrowPoint(0, 3),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate02 = ArrowTemplate(id: 'arrow_002', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(0, 1), ArrowPoint(0, 2), ArrowPoint(0, 3), ArrowPoint(1, 3), ArrowPoint(2, 3),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate03 = ArrowTemplate(id: 'arrow_003', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(1, 0), ArrowPoint(2, 0), ArrowPoint(2, 1), ArrowPoint(2, 2), ArrowPoint(2, 3),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate04 = ArrowTemplate(id: 'arrow_004', path: <ArrowPoint>[
  ArrowPoint(2, 0), ArrowPoint(2, 1), ArrowPoint(2, 2), ArrowPoint(2, 3), ArrowPoint(1, 3), ArrowPoint(0, 3),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate05 = ArrowTemplate(id: 'arrow_005', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(0, 1), ArrowPoint(0, 2), ArrowPoint(1, 2), ArrowPoint(2, 2), ArrowPoint(2, 3),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate06 = ArrowTemplate(id: 'arrow_006', path: <ArrowPoint>[
  ArrowPoint(0, 3), ArrowPoint(1, 3), ArrowPoint(2, 3), ArrowPoint(2, 2), ArrowPoint(2, 1), ArrowPoint(3, 1),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate07 = ArrowTemplate(id: 'arrow_007', path: <ArrowPoint>[
  ArrowPoint(3, 0), ArrowPoint(3, 1), ArrowPoint(2, 1), ArrowPoint(1, 1), ArrowPoint(1, 2), ArrowPoint(1, 3),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate08 = ArrowTemplate(id: 'arrow_008', path: <ArrowPoint>[
  ArrowPoint(1, 4), ArrowPoint(1, 3), ArrowPoint(1, 2), ArrowPoint(0, 2), ArrowPoint(0, 1), ArrowPoint(0, 0),
], direction: ArrowDirection.left);
const ArrowTemplate arrowTemplate09 = ArrowTemplate(id: 'arrow_009', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(1, 0), ArrowPoint(1, 1), ArrowPoint(1, 2), ArrowPoint(2, 2), ArrowPoint(3, 2),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate10 = ArrowTemplate(id: 'arrow_010', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(1, 0), ArrowPoint(2, 0), ArrowPoint(3, 0), ArrowPoint(3, 1), ArrowPoint(3, 2), ArrowPoint(3, 3),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate11 = ArrowTemplate(id: 'arrow_011', path: <ArrowPoint>[
  ArrowPoint(3, 3), ArrowPoint(2, 3), ArrowPoint(1, 3), ArrowPoint(0, 3), ArrowPoint(0, 2), ArrowPoint(0, 1), ArrowPoint(0, 0),
], direction: ArrowDirection.up);
const ArrowTemplate arrowTemplate12 = ArrowTemplate(id: 'arrow_012', path: <ArrowPoint>[
  ArrowPoint(3, 0), ArrowPoint(3, 1), ArrowPoint(3, 2), ArrowPoint(2, 2), ArrowPoint(1, 2), ArrowPoint(0, 2),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate13 = ArrowTemplate(id: 'arrow_013', path: <ArrowPoint>[
  ArrowPoint(0, 3), ArrowPoint(0, 2), ArrowPoint(0, 1), ArrowPoint(1, 1), ArrowPoint(2, 1), ArrowPoint(2, 0),
], direction: ArrowDirection.left);
const ArrowTemplate arrowTemplate14 = ArrowTemplate(id: 'arrow_014', path: <ArrowPoint>[
  ArrowPoint(0, 1), ArrowPoint(1, 1), ArrowPoint(2, 1), ArrowPoint(2, 2), ArrowPoint(2, 3), ArrowPoint(3, 3),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate15 = ArrowTemplate(id: 'arrow_015', path: <ArrowPoint>[
  ArrowPoint(3, 2), ArrowPoint(2, 2), ArrowPoint(1, 2), ArrowPoint(0, 2), ArrowPoint(0, 1), ArrowPoint(0, 0),
], direction: ArrowDirection.up);
const ArrowTemplate arrowTemplate16 = ArrowTemplate(id: 'arrow_016', path: <ArrowPoint>[
  ArrowPoint(1, 0), ArrowPoint(1, 1), ArrowPoint(1, 2), ArrowPoint(1, 3), ArrowPoint(2, 3), ArrowPoint(3, 3),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate17 = ArrowTemplate(id: 'arrow_017', path: <ArrowPoint>[
  ArrowPoint(3, 1), ArrowPoint(3, 2), ArrowPoint(2, 2), ArrowPoint(1, 2), ArrowPoint(1, 1), ArrowPoint(1, 0),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate18 = ArrowTemplate(id: 'arrow_018', path: <ArrowPoint>[
  ArrowPoint(0, 2), ArrowPoint(1, 2), ArrowPoint(2, 2), ArrowPoint(2, 1), ArrowPoint(2, 0), ArrowPoint(3, 0),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate19 = ArrowTemplate(id: 'arrow_019', path: <ArrowPoint>[
  ArrowPoint(2, 0), ArrowPoint(2, 1), ArrowPoint(1, 1), ArrowPoint(0, 1), ArrowPoint(0, 2), ArrowPoint(0, 3), ArrowPoint(1, 3),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate20 = ArrowTemplate(id: 'arrow_020', path: <ArrowPoint>[
  ArrowPoint(0, 3), ArrowPoint(1, 3), ArrowPoint(1, 2), ArrowPoint(1, 1), ArrowPoint(2, 1), ArrowPoint(3, 1), ArrowPoint(3, 0),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate21 = ArrowTemplate(id: 'arrow_021', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(0, 1), ArrowPoint(1, 1), ArrowPoint(2, 1), ArrowPoint(2, 2), ArrowPoint(2, 3),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate22 = ArrowTemplate(id: 'arrow_022', path: <ArrowPoint>[
  ArrowPoint(0, 2), ArrowPoint(0, 1), ArrowPoint(1, 1), ArrowPoint(2, 1), ArrowPoint(2, 0),
], direction: ArrowDirection.left);
const ArrowTemplate arrowTemplate23 = ArrowTemplate(id: 'arrow_023', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(1, 0), ArrowPoint(1, 1), ArrowPoint(1, 2), ArrowPoint(2, 2), ArrowPoint(3, 2), ArrowPoint(3, 3),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate24 = ArrowTemplate(id: 'arrow_024', path: <ArrowPoint>[
  ArrowPoint(3, 3), ArrowPoint(3, 2), ArrowPoint(2, 2), ArrowPoint(1, 2), ArrowPoint(1, 1), ArrowPoint(0, 1), ArrowPoint(0, 0),
], direction: ArrowDirection.left);
const ArrowTemplate arrowTemplate25 = ArrowTemplate(id: 'arrow_025', path: <ArrowPoint>[
  ArrowPoint(0, 1), ArrowPoint(0, 2), ArrowPoint(1, 2), ArrowPoint(1, 3), ArrowPoint(2, 3), ArrowPoint(3, 3),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate26 = ArrowTemplate(id: 'arrow_026', path: <ArrowPoint>[
  ArrowPoint(3, 0), ArrowPoint(2, 0), ArrowPoint(2, 1), ArrowPoint(2, 2), ArrowPoint(1, 2), ArrowPoint(0, 2),
], direction: ArrowDirection.up);
const ArrowTemplate arrowTemplate27 = ArrowTemplate(id: 'arrow_027', path: <ArrowPoint>[
  ArrowPoint(0, 3), ArrowPoint(1, 3), ArrowPoint(1, 2), ArrowPoint(1, 1), ArrowPoint(2, 1), ArrowPoint(3, 1),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate28 = ArrowTemplate(id: 'arrow_028', path: <ArrowPoint>[
  ArrowPoint(3, 1), ArrowPoint(3, 2), ArrowPoint(2, 2), ArrowPoint(1, 2), ArrowPoint(1, 3), ArrowPoint(0, 3),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate29 = ArrowTemplate(id: 'arrow_029', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(0, 1), ArrowPoint(0, 2), ArrowPoint(1, 2), ArrowPoint(1, 1), ArrowPoint(2, 1), ArrowPoint(2, 0),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate30 = ArrowTemplate(id: 'arrow_030', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(1, 0), ArrowPoint(2, 0), ArrowPoint(2, 1), ArrowPoint(1, 1), ArrowPoint(1, 2), ArrowPoint(0, 2),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate31 = ArrowTemplate(id: 'arrow_031', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(0, 1), ArrowPoint(1, 1), ArrowPoint(1, 2), ArrowPoint(2, 2), ArrowPoint(2, 3), ArrowPoint(3, 3),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate32 = ArrowTemplate(id: 'arrow_032', path: <ArrowPoint>[
  ArrowPoint(3, 3), ArrowPoint(3, 2), ArrowPoint(2, 2), ArrowPoint(2, 1), ArrowPoint(1, 1), ArrowPoint(1, 0), ArrowPoint(0, 0),
], direction: ArrowDirection.left);
const ArrowTemplate arrowTemplate33 = ArrowTemplate(id: 'arrow_033', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(1, 0), ArrowPoint(1, 1), ArrowPoint(2, 1), ArrowPoint(2, 2), ArrowPoint(3, 2),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate34 = ArrowTemplate(id: 'arrow_034', path: <ArrowPoint>[
  ArrowPoint(3, 0), ArrowPoint(3, 1), ArrowPoint(2, 1), ArrowPoint(2, 2), ArrowPoint(1, 2), ArrowPoint(1, 3), ArrowPoint(0, 3),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate35 = ArrowTemplate(id: 'arrow_035', path: <ArrowPoint>[
  ArrowPoint(0, 3), ArrowPoint(0, 2), ArrowPoint(1, 2), ArrowPoint(1, 1), ArrowPoint(2, 1), ArrowPoint(2, 0),
], direction: ArrowDirection.left);
const ArrowTemplate arrowTemplate36 = ArrowTemplate(id: 'arrow_036', path: <ArrowPoint>[
  ArrowPoint(3, 0), ArrowPoint(2, 0), ArrowPoint(2, 1), ArrowPoint(1, 1), ArrowPoint(1, 2), ArrowPoint(0, 2), ArrowPoint(0, 3),
], direction: ArrowDirection.up);
const ArrowTemplate arrowTemplate37 = ArrowTemplate(id: 'arrow_037', path: <ArrowPoint>[
  ArrowPoint(0, 1), ArrowPoint(1, 1), ArrowPoint(1, 0), ArrowPoint(2, 0), ArrowPoint(2, 1), ArrowPoint(3, 1),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate38 = ArrowTemplate(id: 'arrow_038', path: <ArrowPoint>[
  ArrowPoint(3, 2), ArrowPoint(3, 1), ArrowPoint(2, 1), ArrowPoint(2, 0), ArrowPoint(1, 0), ArrowPoint(1, 1), ArrowPoint(0, 1),
], direction: ArrowDirection.left);
const ArrowTemplate arrowTemplate39 = ArrowTemplate(id: 'arrow_039', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(0, 1), ArrowPoint(1, 1), ArrowPoint(1, 2), ArrowPoint(2, 2), ArrowPoint(2, 1), ArrowPoint(3, 1),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate40 = ArrowTemplate(id: 'arrow_040', path: <ArrowPoint>[
  ArrowPoint(3, 3), ArrowPoint(2, 3), ArrowPoint(2, 2), ArrowPoint(1, 2), ArrowPoint(1, 1), ArrowPoint(0, 1), ArrowPoint(0, 0),
], direction: ArrowDirection.up);
const ArrowTemplate arrowTemplate41 = ArrowTemplate(id: 'arrow_041', path: <ArrowPoint>[
  ArrowPoint(0, 2), ArrowPoint(1, 2), ArrowPoint(1, 3), ArrowPoint(2, 3), ArrowPoint(2, 2), ArrowPoint(3, 2),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate42 = ArrowTemplate(id: 'arrow_042', path: <ArrowPoint>[
  ArrowPoint(3, 1), ArrowPoint(2, 1), ArrowPoint(2, 0), ArrowPoint(1, 0), ArrowPoint(1, 1), ArrowPoint(0, 1),
], direction: ArrowDirection.up);
const ArrowTemplate arrowTemplate43 = ArrowTemplate(id: 'arrow_043', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(1, 0), ArrowPoint(1, 1), ArrowPoint(0, 1), ArrowPoint(0, 2), ArrowPoint(1, 2), ArrowPoint(1, 3),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate44 = ArrowTemplate(id: 'arrow_044', path: <ArrowPoint>[
  ArrowPoint(3, 3), ArrowPoint(3, 2), ArrowPoint(2, 2), ArrowPoint(2, 3), ArrowPoint(1, 3), ArrowPoint(1, 2), ArrowPoint(0, 2),
], direction: ArrowDirection.left);
const ArrowTemplate arrowTemplate45 = ArrowTemplate(id: 'arrow_045', path: <ArrowPoint>[
  ArrowPoint(0, 3), ArrowPoint(1, 3), ArrowPoint(1, 2), ArrowPoint(2, 2), ArrowPoint(2, 1), ArrowPoint(3, 1), ArrowPoint(3, 0),
], direction: ArrowDirection.right);

/// Arrow 46: a compact zig-zag with four 90-degree turns.
/// Directions: right -> down -> right -> down -> right.
const ArrowTemplate arrowTemplate46 = ArrowTemplate(id: 'arrow_046', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(0, 1), ArrowPoint(1, 1), ArrowPoint(1, 2), ArrowPoint(2, 2), ArrowPoint(2, 3),
], direction: ArrowDirection.right);

const ArrowTemplate arrowTemplate47 = ArrowTemplate(id: 'arrow_047', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(1, 0), ArrowPoint(1, 1), ArrowPoint(2, 1), ArrowPoint(2, 2), ArrowPoint(2, 3),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate48 = ArrowTemplate(id: 'arrow_048', path: <ArrowPoint>[
  ArrowPoint(3, 3), ArrowPoint(3, 2), ArrowPoint(2, 2), ArrowPoint(2, 1), ArrowPoint(1, 1), ArrowPoint(0, 1),
], direction: ArrowDirection.left);
const ArrowTemplate arrowTemplate49 = ArrowTemplate(id: 'arrow_049', path: <ArrowPoint>[
  ArrowPoint(0, 1), ArrowPoint(0, 2), ArrowPoint(1, 2), ArrowPoint(2, 2), ArrowPoint(2, 1), ArrowPoint(2, 0),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate50 = ArrowTemplate(id: 'arrow_050', path: <ArrowPoint>[
  ArrowPoint(3, 0), ArrowPoint(3, 1), ArrowPoint(2, 1), ArrowPoint(2, 2), ArrowPoint(1, 2), ArrowPoint(0, 2),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate51 = ArrowTemplate(id: 'arrow_051', path: <ArrowPoint>[
  ArrowPoint(0, 3), ArrowPoint(1, 3), ArrowPoint(1, 2), ArrowPoint(2, 2), ArrowPoint(2, 1), ArrowPoint(3, 1),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate52 = ArrowTemplate(id: 'arrow_052', path: <ArrowPoint>[
  ArrowPoint(3, 1), ArrowPoint(2, 1), ArrowPoint(2, 2), ArrowPoint(1, 2), ArrowPoint(1, 3), ArrowPoint(0, 3),
], direction: ArrowDirection.up);
const ArrowTemplate arrowTemplate53 = ArrowTemplate(id: 'arrow_053', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(0, 1), ArrowPoint(1, 1), ArrowPoint(1, 0), ArrowPoint(2, 0), ArrowPoint(2, 1), ArrowPoint(2, 2),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate54 = ArrowTemplate(id: 'arrow_054', path: <ArrowPoint>[
  ArrowPoint(0, 2), ArrowPoint(1, 2), ArrowPoint(1, 1), ArrowPoint(2, 1), ArrowPoint(2, 0), ArrowPoint(3, 0), ArrowPoint(3, 1),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate55 = ArrowTemplate(id: 'arrow_055', path: <ArrowPoint>[
  ArrowPoint(3, 2), ArrowPoint(3, 1), ArrowPoint(2, 1), ArrowPoint(2, 2), ArrowPoint(1, 2), ArrowPoint(1, 3), ArrowPoint(0, 3),
], direction: ArrowDirection.left);
const ArrowTemplate arrowTemplate56 = ArrowTemplate(id: 'arrow_056', path: <ArrowPoint>[
  ArrowPoint(0, 1), ArrowPoint(1, 1), ArrowPoint(1, 2), ArrowPoint(2, 2), ArrowPoint(2, 1), ArrowPoint(3, 1), ArrowPoint(3, 0),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate57 = ArrowTemplate(id: 'arrow_057', path: <ArrowPoint>[
  ArrowPoint(3, 0), ArrowPoint(3, 1), ArrowPoint(2, 1), ArrowPoint(2, 0), ArrowPoint(1, 0), ArrowPoint(1, 1), ArrowPoint(0, 1),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate58 = ArrowTemplate(id: 'arrow_058', path: <ArrowPoint>[
  ArrowPoint(0, 3), ArrowPoint(0, 2), ArrowPoint(1, 2), ArrowPoint(1, 3), ArrowPoint(2, 3), ArrowPoint(2, 2), ArrowPoint(3, 2),
], direction: ArrowDirection.left);
const ArrowTemplate arrowTemplate59 = ArrowTemplate(id: 'arrow_059', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(1, 0), ArrowPoint(1, 1), ArrowPoint(2, 1), ArrowPoint(2, 0), ArrowPoint(3, 0),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate60 = ArrowTemplate(id: 'arrow_060', path: <ArrowPoint>[
  ArrowPoint(3, 3), ArrowPoint(2, 3), ArrowPoint(2, 2), ArrowPoint(1, 2), ArrowPoint(1, 3), ArrowPoint(0, 3),
], direction: ArrowDirection.up);
const ArrowTemplate arrowTemplate61 = ArrowTemplate(id: 'arrow_061', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(0, 1), ArrowPoint(1, 1), ArrowPoint(1, 2), ArrowPoint(2, 2), ArrowPoint(2, 3),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate62 = ArrowTemplate(id: 'arrow_062', path: <ArrowPoint>[
  ArrowPoint(3, 0), ArrowPoint(2, 0), ArrowPoint(2, 1), ArrowPoint(1, 1), ArrowPoint(1, 2), ArrowPoint(0, 2),
], direction: ArrowDirection.up);
const ArrowTemplate arrowTemplate63 = ArrowTemplate(id: 'arrow_063', path: <ArrowPoint>[
  ArrowPoint(0, 3), ArrowPoint(1, 3), ArrowPoint(1, 2), ArrowPoint(2, 2), ArrowPoint(2, 3), ArrowPoint(3, 3),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate64 = ArrowTemplate(id: 'arrow_064', path: <ArrowPoint>[
  ArrowPoint(3, 2), ArrowPoint(2, 2), ArrowPoint(2, 1), ArrowPoint(1, 1), ArrowPoint(1, 2), ArrowPoint(0, 2),
], direction: ArrowDirection.up);
const ArrowTemplate arrowTemplate65 = ArrowTemplate(id: 'arrow_065', path: <ArrowPoint>[
  ArrowPoint(0, 0), ArrowPoint(0, 1), ArrowPoint(0, 2), ArrowPoint(1, 2), ArrowPoint(1, 3), ArrowPoint(2, 3), ArrowPoint(3, 3),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate66 = ArrowTemplate(id: 'arrow_066', path: <ArrowPoint>[
  ArrowPoint(3, 3), ArrowPoint(3, 2), ArrowPoint(3, 1), ArrowPoint(2, 1), ArrowPoint(1, 1), ArrowPoint(1, 0), ArrowPoint(0, 0),
], direction: ArrowDirection.left);
const ArrowTemplate arrowTemplate67 = ArrowTemplate(id: 'arrow_067', path: <ArrowPoint>[
  ArrowPoint(0, 1), ArrowPoint(1, 1), ArrowPoint(2, 1), ArrowPoint(2, 2), ArrowPoint(3, 2), ArrowPoint(3, 3),
], direction: ArrowDirection.down);
const ArrowTemplate arrowTemplate68 = ArrowTemplate(id: 'arrow_068', path: <ArrowPoint>[
  ArrowPoint(3, 1), ArrowPoint(3, 2), ArrowPoint(2, 2), ArrowPoint(2, 3), ArrowPoint(1, 3), ArrowPoint(0, 3),
], direction: ArrowDirection.right);
const ArrowTemplate arrowTemplate69 = ArrowTemplate(id: 'arrow_069', path: <ArrowPoint>[
  ArrowPoint(0, 2), ArrowPoint(0, 1), ArrowPoint(1, 1), ArrowPoint(1, 0), ArrowPoint(2, 0), ArrowPoint(2, 1), ArrowPoint(3, 1),
], direction: ArrowDirection.left);
const ArrowTemplate arrowTemplate70 = ArrowTemplate(id: 'arrow_070', path: <ArrowPoint>[
  ArrowPoint(3, 0), ArrowPoint(2, 0), ArrowPoint(2, 1), ArrowPoint(1, 1), ArrowPoint(1, 0), ArrowPoint(0, 0),
], direction: ArrowDirection.up);

/// Central registry for reusable arrow templates.
const List<ArrowTemplate> arrowTemplates = <ArrowTemplate>[
  arrowTemplate01, arrowTemplate02, arrowTemplate03, arrowTemplate04, arrowTemplate05,
  arrowTemplate06, arrowTemplate07, arrowTemplate08, arrowTemplate09, arrowTemplate10,
  arrowTemplate11, arrowTemplate12, arrowTemplate13, arrowTemplate14, arrowTemplate15,
  arrowTemplate16, arrowTemplate17, arrowTemplate18, arrowTemplate19, arrowTemplate20,
  arrowTemplate21, arrowTemplate22, arrowTemplate23, arrowTemplate24, arrowTemplate25,
  arrowTemplate26, arrowTemplate27, arrowTemplate28, arrowTemplate29, arrowTemplate30,
  arrowTemplate31, arrowTemplate32, arrowTemplate33, arrowTemplate34, arrowTemplate35,
  arrowTemplate36, arrowTemplate37, arrowTemplate38, arrowTemplate39, arrowTemplate40,
  arrowTemplate41, arrowTemplate42, arrowTemplate43, arrowTemplate44, arrowTemplate45,
  arrowTemplate46, arrowTemplate47, arrowTemplate48, arrowTemplate49, arrowTemplate50,
  arrowTemplate51, arrowTemplate52, arrowTemplate53, arrowTemplate54, arrowTemplate55,
  arrowTemplate56, arrowTemplate57, arrowTemplate58, arrowTemplate59, arrowTemplate60,
  arrowTemplate61, arrowTemplate62, arrowTemplate63, arrowTemplate64, arrowTemplate65,
  arrowTemplate66, arrowTemplate67, arrowTemplate68, arrowTemplate69, arrowTemplate70,
];
