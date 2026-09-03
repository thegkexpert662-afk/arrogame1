import 'package:flutter/foundation.dart';

enum ArrowDirection { up, down, left, right }

extension ArrowDirectionX on ArrowDirection {
  int get rowDelta {
    switch (this) {
      case ArrowDirection.up:
        return -1;
      case ArrowDirection.down:
        return 1;
      case ArrowDirection.left:
      case ArrowDirection.right:
        return 0;
    }
  }

  int get colDelta {
    switch (this) {
      case ArrowDirection.left:
        return -1;
      case ArrowDirection.right:
        return 1;
      case ArrowDirection.up:
      case ArrowDirection.down:
        return 0;
    }
  }

  /// Visual arrow used by the puzzle board. The line makes the board look
  /// like a clean arrow-maze instead of a grid of standalone arrow icons.
  String get symbol {
    switch (this) {
      case ArrowDirection.up:
        return '│↑';
      case ArrowDirection.down:
        return '↓│';
      case ArrowDirection.left:
        return '←─';
      case ArrowDirection.right:
        return '─→';
    }
  }
}

@immutable
class GridPoint {
  const GridPoint(this.row, this.col);

  final int row;
  final int col;

  GridPoint move(ArrowDirection direction) =>
      GridPoint(row + direction.rowDelta, col + direction.colDelta);

  @override
  bool operator ==(Object other) =>
      other is GridPoint && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}
