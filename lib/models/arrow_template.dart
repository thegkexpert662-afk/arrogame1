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

const ArrowTemplate arrowTemplate05 = ArrowTemplate(
  id: 'arrow_005',
  path: <ArrowPoint>[
    ArrowPoint(0, 0), ArrowPoint(0, 1), ArrowPoint(0, 2),
    ArrowPoint(1, 2), ArrowPoint(2, 2), ArrowPoint(2, 3),
  ],
  direction: ArrowDirection.right,
);

const ArrowTemplate arrowTemplate06 = ArrowTemplate(
  id: 'arrow_006',
  path: <ArrowPoint>[
    ArrowPoint(0, 3), ArrowPoint(1, 3), ArrowPoint(2, 3),
    ArrowPoint(2, 2), ArrowPoint(2, 1), ArrowPoint(3, 1),
  ],
  direction: ArrowDirection.down,
);

const ArrowTemplate arrowTemplate07 = ArrowTemplate(
  id: 'arrow_007',
  path: <ArrowPoint>[
    ArrowPoint(3, 0), ArrowPoint(3, 1), ArrowPoint(2, 1),
    ArrowPoint(1, 1), ArrowPoint(1, 2), ArrowPoint(1, 3),
  ],
  direction: ArrowDirection.right,
);

const ArrowTemplate arrowTemplate08 = ArrowTemplate(
  id: 'arrow_008',
  path: <ArrowPoint>[
    ArrowPoint(1, 4), ArrowPoint(1, 3), ArrowPoint(1, 2),
    ArrowPoint(0, 2), ArrowPoint(0, 1), ArrowPoint(0, 0),
  ],
  direction: ArrowDirection.left,
);

const ArrowTemplate arrowTemplate09 = ArrowTemplate(
  id: 'arrow_009',
  path: <ArrowPoint>[
    ArrowPoint(0, 0), ArrowPoint(1, 0), ArrowPoint(1, 1),
    ArrowPoint(1, 2), ArrowPoint(2, 2), ArrowPoint(3, 2),
  ],
  direction: ArrowDirection.down,
);

const ArrowTemplate arrowTemplate10 = ArrowTemplate(
  id: 'arrow_010',
  path: <ArrowPoint>[
    ArrowPoint(0, 0), ArrowPoint(1, 0), ArrowPoint(2, 0), ArrowPoint(3, 0),
    ArrowPoint(3, 1), ArrowPoint(3, 2), ArrowPoint(3, 3),
  ],
  direction: ArrowDirection.down,
);

const ArrowTemplate arrowTemplate11 = ArrowTemplate(
  id: 'arrow_011',
  path: <ArrowPoint>[
    ArrowPoint(3, 3), ArrowPoint(2, 3), ArrowPoint(1, 3), ArrowPoint(0, 3),
    ArrowPoint(0, 2), ArrowPoint(0, 1), ArrowPoint(0, 0),
  ],
  direction: ArrowDirection.up,
);

const ArrowTemplate arrowTemplate12 = ArrowTemplate(
  id: 'arrow_012',
  path: <ArrowPoint>[
    ArrowPoint(3, 0), ArrowPoint(3, 1), ArrowPoint(3, 2),
    ArrowPoint(2, 2), ArrowPoint(1, 2), ArrowPoint(0, 2),
  ],
  direction: ArrowDirection.right,
);

const ArrowTemplate arrowTemplate13 = ArrowTemplate(
  id: 'arrow_013',
  path: <ArrowPoint>[
    ArrowPoint(0, 3), ArrowPoint(0, 2), ArrowPoint(0, 1),
    ArrowPoint(1, 1), ArrowPoint(2, 1), ArrowPoint(2, 0),
  ],
  direction: ArrowDirection.left,
);

const ArrowTemplate arrowTemplate14 = ArrowTemplate(
  id: 'arrow_014',
  path: <ArrowPoint>[
    ArrowPoint(0, 1), ArrowPoint(1, 1), ArrowPoint(2, 1),
    ArrowPoint(2, 2), ArrowPoint(2, 3), ArrowPoint(3, 3),
  ],
  direction: ArrowDirection.down,
);

const ArrowTemplate arrowTemplate15 = ArrowTemplate(
  id: 'arrow_015',
  path: <ArrowPoint>[
    ArrowPoint(3, 2), ArrowPoint(2, 2), ArrowPoint(1, 2), ArrowPoint(0, 2),
    ArrowPoint(0, 1), ArrowPoint(0, 0),
  ],
  direction: ArrowDirection.up,
);

const ArrowTemplate arrowTemplate16 = ArrowTemplate(
  id: 'arrow_016',
  path: <ArrowPoint>[
    ArrowPoint(1, 0), ArrowPoint(1, 1), ArrowPoint(1, 2), ArrowPoint(1, 3),
    ArrowPoint(2, 3), ArrowPoint(3, 3),
  ],
  direction: ArrowDirection.right,
);

const ArrowTemplate arrowTemplate17 = ArrowTemplate(
  id: 'arrow_017',
  path: <ArrowPoint>[
    ArrowPoint(3, 1), ArrowPoint(3, 2), ArrowPoint(2, 2),
    ArrowPoint(1, 2), ArrowPoint(1, 1), ArrowPoint(1, 0),
  ],
  direction: ArrowDirection.right,
);

const ArrowTemplate arrowTemplate18 = ArrowTemplate(
  id: 'arrow_018',
  path: <ArrowPoint>[
    ArrowPoint(0, 2), ArrowPoint(1, 2), ArrowPoint(2, 2),
    ArrowPoint(2, 1), ArrowPoint(2, 0), ArrowPoint(3, 0),
  ],
  direction: ArrowDirection.down,
);

const ArrowTemplate arrowTemplate19 = ArrowTemplate(
  id: 'arrow_019',
  path: <ArrowPoint>[
    ArrowPoint(2, 0), ArrowPoint(2, 1), ArrowPoint(1, 1),
    ArrowPoint(0, 1), ArrowPoint(0, 2), ArrowPoint(0, 3),
    ArrowPoint(1, 3),
  ],
  direction: ArrowDirection.right,
);

const ArrowTemplate arrowTemplate20 = ArrowTemplate(
  id: 'arrow_020',
  path: <ArrowPoint>[
    ArrowPoint(0, 3), ArrowPoint(1, 3), ArrowPoint(1, 2),
    ArrowPoint(1, 1), ArrowPoint(2, 1), ArrowPoint(3, 1),
    ArrowPoint(3, 0),
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
  arrowTemplate10,
  arrowTemplate11,
  arrowTemplate12,
  arrowTemplate13,
  arrowTemplate14,
  arrowTemplate15,
  arrowTemplate16,
  arrowTemplate17,
  arrowTemplate18,
  arrowTemplate19,
  arrowTemplate20,
];
