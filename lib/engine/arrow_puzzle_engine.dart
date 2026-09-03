import 'dart:math';

import '../models/arrow_cell.dart';
import '../models/arrow_direction.dart';

class ArrowPuzzle {
  const ArrowPuzzle({
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

/// Generates the visual style of a "tap to clear" arrow puzzle: sparse
/// arrow paths spread across a board, with every puzzle guaranteed to have
/// a valid sequence in which every arrow can be cleared.
class ArrowPuzzleEngine {
  ArrowPuzzleEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  ArrowPuzzle generate({
    int? rows,
    int? columns,
    int difficulty = 1,
  }) {
    final d = difficulty.clamp(1, 10).toInt();
    final size = _sizeForDifficulty(d);
    final r = rows ?? size.$1;
    final c = columns ?? size.$2;
    final count = min(r * c - 1, 10 + d * 5);

    for (var attempt = 0; attempt < 250; attempt++) {
      final positions = <GridPoint>[];
      final available = <GridPoint>[];
      for (var row = 0; row < r; row++) {
        for (var col = 0; col < c; col++) {
          available.add(GridPoint(row, col));
        }
      }
      available.shuffle(_random);

      // Keep a little breathing room between most arrows so the board reads
      // like the reference game's clean line pattern rather than a grid.
      for (final point in available) {
        if (positions.length >= count) break;
        if (positions.any((p) => (p.row - point.row).abs() + (p.col - point.col).abs() <= 0)) {
          continue;
        }
        positions.add(point);
      }

      final cells = List<ArrowCell>.generate(
        r * c,
        (index) => ArrowCell(row: index ~/ c, col: index % c),
      );

      for (final point in positions) {
        final directions = ArrowDirection.values.toList()..shuffle(_random);
        cells[point.row * c + point.col].arrows.add(directions.first);
      }

      final puzzle = ArrowPuzzle(
        rows: r,
        columns: c,
        cells: cells,
        start: positions.first,
        finish: positions.last,
        solution: List.unmodifiable(positions),
      );

      if (_isClearable(puzzle)) return puzzle;
    }

    throw StateError('Could not generate a clearable arrow puzzle.');
  }

  (int, int) _sizeForDifficulty(int difficulty) {
    if (difficulty <= 2) return (7, 9);
    if (difficulty <= 4) return (8, 10);
    if (difficulty <= 6) return (9, 11);
    if (difficulty <= 8) return (10, 13);
    return (11, 14);
  }

  /// In the tap-to-clear game an arrow is free when every board cell in the
  /// direction it points toward is already empty. We simulate clearing and
  /// require that all arrows can eventually be removed.
  bool _isClearable(ArrowPuzzle puzzle) {
    final occupied = <GridPoint>{};
    for (final cell in puzzle.cells) {
      if (cell.arrows.isNotEmpty) occupied.add(GridPoint(cell.row, cell.col));
    }

    var cleared = 0;
    while (occupied.isNotEmpty) {
      final removable = <GridPoint>[];
      for (final point in occupied) {
        final arrows = puzzle.cellAt(point).arrows;
        if (arrows.isEmpty) continue;
        if (_rayIsClear(puzzle, occupied, point, arrows.first)) {
          removable.add(point);
        }
      }
      if (removable.isEmpty) return false;
      for (final point in removable) {
        occupied.remove(point);
        cleared++;
      }
    }
    return cleared > 0;
  }

  bool _rayIsClear(
    ArrowPuzzle puzzle,
    Set<GridPoint> occupied,
    GridPoint from,
    ArrowDirection direction,
  ) {
    var next = from.move(direction);
    while (puzzle.contains(next)) {
      if (occupied.contains(next)) return false;
      next = next.move(direction);
    }
    return true;
  }

  bool canClear(ArrowPuzzle puzzle, GridPoint point, Set<GridPoint> cleared) {
    if (!puzzle.contains(point)) return false;
    final cell = puzzle.cellAt(point);
    if (cell.arrows.isEmpty) return false;

    final occupied = <GridPoint>{};
    for (final item in puzzle.cells) {
      final p = GridPoint(item.row, item.col);
      if (item.arrows.isNotEmpty && !cleared.contains(p)) occupied.add(p);
    }
    return _rayIsClear(puzzle, occupied, point, cell.arrows.first);
  }

  bool canMove(ArrowPuzzle puzzle, GridPoint from, ArrowDirection direction) {
    if (!puzzle.contains(from)) return false;
    return puzzle.cellAt(from).has(direction);
  }

  bool validateSolution(ArrowPuzzle puzzle) => _isClearable(puzzle);

  List<GridPoint>? findSolutionPath(ArrowPuzzle puzzle) {
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
      if (next == null) return null;
      cleared.add(next);
      remaining.remove(next);
      result.add(next);
    }
    return result;
  }

  bool isSolvable(ArrowPuzzle puzzle) => findSolutionPath(puzzle) != null;

  int countSolutions(ArrowPuzzle puzzle, {int limit = 2}) {
    if (limit < 1) return 0;
    var count = 0;
    final remaining = <GridPoint>{};
    for (final cell in puzzle.cells) {
      if (cell.arrows.isNotEmpty) remaining.add(GridPoint(cell.row, cell.col));
    }

    void search(Set<GridPoint> left, Set<GridPoint> cleared) {
      if (count >= limit) return;
      if (left.isEmpty) {
        count++;
        return;
      }
      for (final point in left) {
        if (!canClear(puzzle, point, cleared)) continue;
        final nextLeft = {...left}..remove(point);
        final nextCleared = {...cleared, point};
        search(nextLeft, nextCleared);
        if (count >= limit) return;
      }
    }

    search(remaining, <GridPoint>{});
    return count;
  }
}
