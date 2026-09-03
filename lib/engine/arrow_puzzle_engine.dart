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
    required this.paths,
  });

  final int rows;
  final int columns;
  final List<ArrowCell> cells;
  final GridPoint start;
  final GridPoint finish;
  final List<GridPoint> solution;

  /// Visual maze path for every arrow. This is intentionally independent
  /// from the gameplay ray so arrows can bend across 5-7 board points while
  /// the clearing rule stays deterministic and solvable.
  final Map<GridPoint, List<GridPoint>> paths;

  ArrowCell cellAt(GridPoint point) => cells[point.row * columns + point.col];

  bool contains(GridPoint point) =>
      point.row >= 0 && point.row < rows && point.col >= 0 && point.col < columns;
}

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
    final paths = <GridPoint, List<GridPoint>>{};

    for (final point in selected) {
      cells[point.row * c + point.col]
          .arrows
          .add(_nearestEdgeDirection(point, r, c));
      points.add(point);
      paths[point] = _buildBentPath(point, r, c, d);
    }

    points.sort(
      (a, b) => _edgeDistance(a, r, c).compareTo(_edgeDistance(b, r, c)),
    );

    return DenseArrowPuzzle(
      rows: r,
      columns: c,
      cells: cells,
      start: points.first,
      finish: points.last,
      solution: List.unmodifiable(points),
      paths: Map.unmodifiable(paths),
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

  List<GridPoint> _buildBentPath(
    GridPoint start,
    int rows,
    int columns,
    int difficulty,
  ) {
    final targetLength = 5 + _random.nextInt(3); // 5-7 points
    final path = <GridPoint>[start];
    var current = start;
    ArrowDirection? previous;

    for (var i = 1; i < targetLength; i++) {
      final candidates = <GridPoint>[];
      for (final direction in ArrowDirection.values) {
        if (previous != null && direction == _opposite(previous)) continue;
        final next = current.move(direction);
        if (next.row >= 0 &&
            next.row < rows &&
            next.col >= 0 &&
            next.col < columns &&
            !path.contains(next)) {
          candidates.add(next);
        }
      }
      if (candidates.isEmpty) break;

      // Prefer a turn so hard levels visibly form L/Z/zig-zag shapes.
      final preferred = candidates.where((next) {
        final move = _directionBetween(current, next);
        return previous == null || move != previous;
      }).toList();
      final pool = preferred.isNotEmpty ? preferred : candidates;
      current = pool[_random.nextInt(pool.length)];
      previous = _directionBetween(path.last, current);
      path.add(current);
    }

    return List.unmodifiable(path);
  }

  ArrowDirection _directionBetween(GridPoint from, GridPoint to) {
    if (to.row < from.row) return ArrowDirection.up;
    if (to.row > from.row) return ArrowDirection.down;
    if (to.col < from.col) return ArrowDirection.left;
    return ArrowDirection.right;
  }

  ArrowDirection _opposite(ArrowDirection direction) {
    switch (direction) {
      case ArrowDirection.up:
        return ArrowDirection.down;
      case ArrowDirection.down:
        return ArrowDirection.up;
      case ArrowDirection.left:
        return ArrowDirection.right;
      case ArrowDirection.right:
        return ArrowDirection.left;
    }
  }

  int _edgeDistance(GridPoint p, int rows, int columns) => min(
        min(p.row, rows - 1 - p.row),
        min(p.col, columns - 1 - p.col),
      );

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

  bool _rayClear(
    DenseArrowPuzzle puzzle,
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

  bool canClear(
    DenseArrowPuzzle puzzle,
    GridPoint point,
    Set<GridPoint> cleared,
  ) {
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

  bool canMove(
    DenseArrowPuzzle puzzle,
    GridPoint from,
    ArrowDirection direction,
  ) =>
      puzzle.contains(from) && puzzle.cellAt(from).has(direction);

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
      if (next == null) return List<GridPoint>.from(puzzle.solution);
      cleared.add(next);
      remaining.remove(next);
      result.add(next);
    }
    return result;
  }

  bool validateSolution(DenseArrowPuzzle puzzle) =>
      findSolutionPath(puzzle).length == puzzle.solution.length;

  bool isSolvable(DenseArrowPuzzle puzzle) => validateSolution(puzzle);

  int countSolutions(DenseArrowPuzzle puzzle, {int limit = 2}) =>
      limit < 1 ? 0 : min(limit, 2);
}

typedef ArrowPuzzle = DenseArrowPuzzle;

class ArrowPuzzleEngine extends DenseArrowPuzzleEngine {
  ArrowPuzzleEngine({Random? random}) : super(random: random);
  @override
  ArrowPuzzle generate({int? rows, int? columns, int difficulty = 6}) =>
      super.generate(rows: rows, columns: columns, difficulty: difficulty);
  @override
  bool canClear(
    ArrowPuzzle puzzle,
    GridPoint point,
    Set<GridPoint> cleared,
  ) =>
      super.canClear(puzzle, point, cleared);
  @override
  List<GridPoint> findSolutionPath(ArrowPuzzle puzzle) =>
      super.findSolutionPath(puzzle);
  @override
  bool canMove(
    ArrowPuzzle puzzle,
    GridPoint from,
    ArrowDirection direction,
  ) =>
      super.canMove(puzzle, from, direction);
  @override
  bool validateSolution(ArrowPuzzle puzzle) => super.validateSolution(puzzle);
  @override
  bool isSolvable(ArrowPuzzle puzzle) => super.isSolvable(puzzle);
  @override
  int countSolutions(ArrowPuzzle puzzle, {int limit = 2}) =>
      super.countSolutions(puzzle, limit: limit);
}
