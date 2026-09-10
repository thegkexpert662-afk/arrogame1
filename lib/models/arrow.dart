import 'package:flutter/material.dart';

enum ArrowDirection { up, right, down, left }

extension ArrowDirectionX on ArrowDirection {
  Offset get vector => switch (this) {
        ArrowDirection.up => const Offset(0, -1),
        ArrowDirection.right => const Offset(1, 0),
        ArrowDirection.down => const Offset(0, 1),
        ArrowDirection.left => const Offset(-1, 0),
      };
}

class ArrowPoint {
  final int row;
  final int col;

  const ArrowPoint(this.row, this.col);

  ArrowPoint copy() => ArrowPoint(row, col);

  @override
  bool operator ==(Object other) => other is ArrowPoint && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}

/// An arrow may be a straight line or a connected grid path with 90-degree turns.
class Arrow {
  final String id;
  double x;
  double y;
  double length;
  final ArrowDirection direction;
  List<ArrowPoint> path;
  final int gridSize;

  Arrow(
    this.id,
    this.x,
    this.y,
    this.length,
    this.direction, {
    List<ArrowPoint>? path,
    this.gridSize = 9,
  }) : path = path ?? <ArrowPoint>[];

  bool get isPathArrow => path.length >= 2;

  int get segmentCount {
    if (path.length < 2) return 1;
    var count = 0;
    for (var i = 1; i < path.length; i++) {
      count += (path[i].row - path[i - 1].row).abs() + (path[i].col - path[i - 1].col).abs();
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
        gridSize: gridSize,
      );

  static ArrowDirection directionBetween(ArrowPoint a, ArrowPoint b) {
    final dr = b.row - a.row;
    final dc = b.col - a.col;
    if (dr < 0) return ArrowDirection.up;
    if (dr > 0) return ArrowDirection.down;
    if (dc > 0) return ArrowDirection.right;
    return ArrowDirection.left;
  }

  bool get hasValidPath {
    if (path.length < 2) return false;
    final seen = <ArrowPoint>{};
    for (var i = 0; i < path.length; i++) {
      if (!seen.add(path[i])) return false;
      if (i == 0) continue;
      final d = (path[i].row - path[i - 1].row).abs() + (path[i].col - path[i - 1].col).abs();
      if (d != 1) return false;
    }
    return true;
  }
}
