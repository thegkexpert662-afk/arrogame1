import 'arrow.dart';

/// Reusable definition of an arrow shape.
///
/// A template contains only the arrow's own properties. A level can reuse the
/// same template multiple times and choose a different board position/direction.
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

/// First reusable arrow in the library.
const ArrowTemplate arrowTemplate01 = ArrowTemplate(
  id: 'arrow_001',
  path: <ArrowPoint>[
    ArrowPoint(0, 0),
    ArrowPoint(0, 1),
    ArrowPoint(0, 2),
    ArrowPoint(0, 3),
  ],
  direction: ArrowDirection.right,
);

/// Second reusable arrow: 3 cells right, then 2 cells down.
/// Shape:  -> -> -> v v
/// This gives the template one 90-degree turn.
const ArrowTemplate arrowTemplate02 = ArrowTemplate(
  id: 'arrow_002',
  path: <ArrowPoint>[
    ArrowPoint(0, 0),
    ArrowPoint(0, 1),
    ArrowPoint(0, 2),
    ArrowPoint(0, 3),
    ArrowPoint(1, 3),
    ArrowPoint(2, 3),
  ],
  direction: ArrowDirection.right,
);

/// Central registry for reusable arrow templates.
/// The same template can be selected by multiple levels.
const List<ArrowTemplate> arrowTemplates = <ArrowTemplate>[
  arrowTemplate01,
  arrowTemplate02,
];
