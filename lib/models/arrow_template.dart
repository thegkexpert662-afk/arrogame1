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

const ArrowTemplate arrowTemplate01 = ArrowTemplate(
  id: 'arrow_001',
  path: <ArrowPoint>[
    ArrowPoint(0, 0), ArrowPoint(0, 1), ArrowPoint(0, 2), ArrowPoint(0, 3),
  ],
  direction: ArrowDirection.right,
);

const ArrowTemplate arrowTemplate02 = ArrowTemplate(
  id: 'arrow_002',
  path: <ArrowPoint>[
    ArrowPoint(0, 0), ArrowPoint(0, 1), ArrowPoint(0, 2), ArrowPoint(0, 3),
    ArrowPoint(1, 3), ArrowPoint(2, 3),
  ],
  direction: ArrowDirection.right,
);

const ArrowTemplate arrowTemplate03 = ArrowTemplate(
  id: 'arrow_003',
  path: <ArrowPoint>[
    ArrowPoint(0, 0), ArrowPoint(1, 0), ArrowPoint(2, 0),
    ArrowPoint(2, 1), ArrowPoint(2, 2), ArrowPoint(2, 3),
  ],
  direction: ArrowDirection.down,
);

const ArrowTemplate arrowTemplate04 = ArrowTemplate(
  id: 'arrow_004',
  path: <ArrowPoint>[
    ArrowPoint(2, 0), ArrowPoint(2, 1), ArrowPoint(2, 2), ArrowPoint(2, 3),
    ArrowPoint(1, 3), ArrowPoint(0, 3),
  ],
  direction: ArrowDirection.right,
);

/// Arrow 5: 2 cells right, 2 cells down, 1 cell right.
/// Shape: -> -> v v -> ; two 90-degree turns.
const ArrowTemplate arrowTemplate05 = ArrowTemplate(
  id: 'arrow_005',
  path: <ArrowPoint>[
    ArrowPoint(0, 0),
    ArrowPoint(0, 1),
    ArrowPoint(0, 2),
    ArrowPoint(1, 2),
    ArrowPoint(2, 2),
    ArrowPoint(2, 3),
  ],
  direction: ArrowDirection.right,
);

/// Arrow 6: 2 cells down, 2 cells left, 1 cell down.
/// Shape: vv << v ; two 90-degree turns.
const ArrowTemplate arrowTemplate06 = ArrowTemplate(
  id: 'arrow_006',
  path: <ArrowPoint>[
    ArrowPoint(0, 3),
    ArrowPoint(1, 3),
    ArrowPoint(2, 3),
    ArrowPoint(2, 2),
    ArrowPoint(2, 1),
    ArrowPoint(3, 1),
  ],
  direction: ArrowDirection.down,
);

/// Arrow 7: 1 cell right, 2 cells up, 2 cells right.
/// Shape: -> ^^ -> -> ; two 90-degree turns.
const ArrowTemplate arrowTemplate07 = ArrowTemplate(
  id: 'arrow_007',
  path: <ArrowPoint>[
    ArrowPoint(3, 0),
    ArrowPoint(3, 1),
    ArrowPoint(2, 1),
    ArrowPoint(1, 1),
    ArrowPoint(1, 2),
    ArrowPoint(1, 3),
  ],
  direction: ArrowDirection.right,
);

/// Arrow 8: 2 cells left, 1 cell up, 2 cells left.
/// Shape: << ^ << ; two 90-degree turns.
const ArrowTemplate arrowTemplate08 = ArrowTemplate(
  id: 'arrow_008',
  path: <ArrowPoint>[
    ArrowPoint(1, 4),
    ArrowPoint(1, 3),
    ArrowPoint(1, 2),
    ArrowPoint(0, 2),
    ArrowPoint(0, 1),
    ArrowPoint(0, 0),
  ],
  direction: ArrowDirection.left,
);

/// Arrow 9: 1 cell down, 2 cells right, 2 cells down.
/// Shape: v -> -> vv ; two 90-degree turns.
const ArrowTemplate arrowTemplate09 = ArrowTemplate(
  id: 'arrow_009',
  path: <ArrowPoint>[
    ArrowPoint(0, 0),
    ArrowPoint(1, 0),
    ArrowPoint(1, 1),
    ArrowPoint(1, 2),
    ArrowPoint(2, 2),
    ArrowPoint(3, 2),
  ],
  direction: ArrowDirection.down,
);

/// Central registry for reusable arrow templates.
const List<ArrowTemplate> arrowTemplates = <ArrowTemplate>[
  arrowTemplate01,
  arrowTemplate02,
  arrowTemplate03,
  arrowTemplate04,
  arrowTemplate05,
  arrowTemplate06,
  arrowTemplate07,
  arrowTemplate08,
  arrowTemplate09,
];
