import 'package:flutter/material.dart';

enum ArrowDirection {
  up,
  right,
  down,
  left,
}

extension ArrowDirectionX on ArrowDirection {
  Offset get vector => switch (this) {
        ArrowDirection.up => const Offset(0, -1),
        ArrowDirection.right => const Offset(1, 0),
        ArrowDirection.down => const Offset(0, 1),
        ArrowDirection.left => const Offset(-1, 0),
      };
}

/// A single point on the puzzle grid.
class ArrowPoint {
  final int row;
  final int col;

  const ArrowPoint(this.row, this.col);

  ArrowPoint copy() => ArrowPoint(row, col);

  @override
  bool operator ==(Object other) =>
      other is ArrowPoint && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}

/// Arrow can contain multiple connected straight segments.
class Arrow {
  final String id;
  double x;
  double y;
  double length;
  final ArrowDirection direction;

  /// Complete arrow path. Empty means the legacy straight-arrow form.
  List<ArrowPoint> path;

  Arrow(
    this.id,
    this.x,
    this.y,
    this.length,
    this.direction, {
    List<ArrowPoint>? path,
  }) : path = path ?? <ArrowPoint>[];

  bool get isPathArrow => path.length >= 2;

  /// Number of grid steps used by the complete path.
  int get segmentCount {
    if (path.length < 2) return 1;

    var count = 0;
    for (var i = 1; i < path.length; i++) {
      final previous = path[i - 1];
      final current = path[i];
      count +=
          (current.row - previous.row).abs() +
          (current.col - previous.col).abs();
    }
    return count;
  }

  Arrow copy() => Arrow(
        id,
        x,
        y,
        length,
        direction,
        path: path.map((p) => p.copy()).toList(),
      );

  /// Direction between two neighbouring grid points.
  static ArrowDirection directionBetween(ArrowPoint a, ArrowPoint b) {
    final dr = b.row - a.row;
    final dc = b.col - a.col;

    if (dr < 0) return ArrowDirection.up;
    if (dr > 0) return ArrowDirection.down;
    if (dc > 0) return ArrowDirection.right;
    return ArrowDirection.left;
  }

  /// Checks that the path contains only adjacent orthogonal grid points
  /// and never visits the same point twice.
  bool get hasValidPath {
    if (path.length < 2) return false;

    final seen = <ArrowPoint>{};

    for (var i = 0; i < path.length; i++) {
      final point = path[i];
      if (!seen.add(point)) return false;
      if (i == 0) continue;

      final previous = path[i - 1];
      final distance =
          (point.row - previous.row).abs() +
          (point.col - previous.col).abs();

      if (distance != 1) return false;
    }

    return true;
  }
}
