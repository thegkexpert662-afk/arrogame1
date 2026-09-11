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
///
/// Four grid points, straight, facing right:  -> -> ->
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

/// Central registry for reusable arrow templates.
/// Add arrowTemplate02, arrowTemplate03, ... here as the library grows.
const List<ArrowTemplate> arrowTemplates = <ArrowTemplate>[
  arrowTemplate01,
];
