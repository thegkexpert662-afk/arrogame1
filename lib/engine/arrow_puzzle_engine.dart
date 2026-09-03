import 'dart:math';

import '../models/arrow_cell.dart';
import '../models/arrow_direction.dart';

class DenseArrowPuzzle {
  const DenseArrowPuzzle({
    required this.rows,
    required this.columns,
    required this.cells,
    required this.start,
    required this.finish,
    required this.solution,
  });

  final int rows;
  final int columns;
  final List<ArrowCell> cells;
  final GridPoint start;
  final GridPoint finish;
  final List<GridPoint> solution;

  ArrowCell cellAt(GridPoint point) => cells[point.row * columns + point.col];

  bool contains(GridPoint point) =>
      point.row >= 0 && point.row < rows && point.col >= 0 && point.col < columns;
}

/// Deterministic dense Tap-to-Clear generator.
/// Every hard board is filled with arrows and every arrow points to a nearest
/// edge. Therefore there is always at least one valid clearing order.
class DenseArrowPuzzleEngine {
  DenseArrowPuzzleEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  DenseArrowPuzzle generate({int? rows, int? columns, int difficulty = 6}) {
    final d = difficulty.clamp(1, 10).toInt();
    final size = _sizeForDifficulty(d);
    final r = rows ?? size.$1;
    final c = columns ?? size.$2;
    final density = d >= 6 ? 1.0 : .55;

    final cells = List<ArrowCell>.generate(
      r * c,
      (index) => ArrowCell(row: index ~/ c, col: index % c),
    );
    final points = <GridPoint>[];
    final all = <GridPoint>[];

    for (var row = 0; row < r; row++) {
      for (var col = 0; col < c; col++) {
        all.add(GridPoint(row, col));
      }
    }
    all.shuffle(_random);

    final target = max(1, (r * c * density).round());
    final selected = density >= .999 ? all : all.take(target);

    for (final point in selected) {
      final direction = _nearestEdgeDirection(point, r, c);
      cells[point.row * c + point.col].arrows.add(direction);
      points.add(point);
    }

    // Valid moves are ordered from the outside toward the centre. Ties are
    // harmless because tied arrows point toward different nearest edges.
    points.sort((a, b) {
      final da = _edgeDistance(a, r, c);
      final db = _edgeDistance(b, r, c);
      return da.compareTo(db);
    });

    return DenseArrowPuzzle(
      rows: r,
      columns: c,
      cells: cells,
      start: points.first,
      finish: points.last,
      solution: List.unmodifiable(points),
    );
  }

  ArrowDirection _nearestEdgeDirection(GridPoint p, int rows, int columns) {
    final distances = <ArrowDirection, int>{
      ArrowDirection.up: p.row,
      ArrowDirection.down: rows - 1 - p.row,
      ArrowDirection.left: p.col,
      ArrowDirection.right: columns - 1 - p.col,
    };
    final minimum = distances.values.reduce(min);
    final choices = distances.entries
        .where((entry) => entry.value == minimum)
        .map((entry) => entry.key)
        .toList();
    return choices[_random.nextInt(choices.length)];
  }

  int _edgeDistance(GridPoint p, int rows, int columns) =>
      min(min(p.row, rows - 1 - p.row), min(p.col, columns - 1 - p.col));

  (int, int) _sizeForDifficulty(int d) {
    if (d <= 2) return (8, 10);
    if (d <= 4) return (9, 11);
    if (d == 5) return (10, 12);
    if (d == 6) return (14, 17);
    if (d == 7) return (15, 18);
    if (d == 8) return (16, 18);
    if (d == 9) return (17, 19);
    return (18, 20);
  }

  bool _rayClear(DenseArrowPuzzle puzzle, Set<GridPoint> occupied,
      GridPoint from, ArrowDirection direction) {
    var next = from.move(direction);
    while (puzzle.contains(next)) {
      if (occupied.contains(next)) return false;
      next = next.move(direction);
    }
    return true;
  }

  bool canClear(DenseArrowPuzzle puzzle, GridPoint point, Set<GridPoint> cleared) {
    if (!puzzle.contains(point) || cleared.contains(point)) return false;
    final cell = puzzle.cellAt(point);
    if (cell.arrows.isEmpty) return false;
    final occupied = <GridPoint>{};
    for (final item in puzzle.cells) {
      final p = GridPoint(item.row, item.col);
      if (item.arrows.isNotEmpty && !cleared.contains(p)) occupied.add(p);
    }
    return _rayClear(puzzle, occupied, point, cell.arrows.first);
  }

  List<GridPoint> findSolutionPath(DenseArrowPuzzle puzzle) {
    final remaining = <GridPoint>{};
    for (final cell in puzzle.cells) {
      if (cell.arrows.isNotEmpty) remaining.add(GridPoint(cell.row, cell.col));
    }
    final cleared = <GridPoint>{};
    final result = <GridPoint>[];
    while (remaining.isNotEmpty) {
      GridPoint? next;
      for (final point in remaining) {
        if (canClear(puzzle, point, cleared)) {
          next = point;
          break;
        }
      }
      if (next == null) {
        // The generator is deterministic, so this is only a defensive guard.
        return puzzle.solution;
      }
      cleared.add(next);
      remaining.remove(next);
      result.add(next);
    }
    return result;
  }
}
