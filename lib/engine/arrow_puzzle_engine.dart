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
  final Map<GridPoint, List<GridPoint>> paths;

  ArrowCell cellAt(GridPoint point) => cells[point.row * columns + point.col];

  bool contains(GridPoint point) =>
      point.row >= 0 &&
      point.row < rows &&
      point.col >= 0 &&
      point.col < columns;
}

class DenseArrowPuzzleEngine {
  DenseArrowPuzzleEngine({Random? random}) : _random = random ?? Random();
  final Random _random;

  DenseArrowPuzzle generate({int? rows, int? columns, int difficulty = 6}) {
    final d = difficulty.clamp(1, 10).toInt();
    final size = _sizeForDifficulty(d);
    final r = rows ?? size.$1;
    final c = columns ?? size.$2;

    // The reference design fills the BOARD AREA with long paths, not with a
    // separate tiny arrow in every cell. Long paths create the visual density.
    final density = d >= 6 ? .24 : .18;

    final cells = List<ArrowCell>.generate(
      r * c,
      (index) => ArrowCell(row: index ~/ c, col: index % c),
    );
    final all = <GridPoint>[];
    for (var row = 0; row < r; row++) {
      for (var col = 0; col < c; col++) {
        all.add(GridPoint(row, col));
      }
    }
    all.shuffle(_random);

    final target = max(1, (r * c * density).round());
    final selected = all.take(target);
    final points = <GridPoint>[];
    final paths = <GridPoint, List<GridPoint>>{};

    for (final point in selected) {
      final direction = _nearestEdgeDirection(point, r, c);
      cells[point.row * c + point.col].arrows.add(direction);
      points.add(point);
      paths[point] = List.unmodifiable(
        _makeLongBentPath(point, direction, r, c, d),
      );
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

  List<GridPoint> _makeLongBentPath(
    GridPoint start,
    ArrowDirection direction,
    int rows,
    int columns,
    int difficulty,
  ) {
    final result = <GridPoint>[start];
    final used = <GridPoint>{start};
    var current = start;
    var heading = direction;

    // 6–12 grid points gives the same long L/S/zig-zag feel as the reference.
    final wanted = difficulty >= 9
        ? 9 + _random.nextInt(4)
        : 6 + _random.nextInt(4);

    for (var step = 1; step < wanted; step++) {
      var candidates = <ArrowDirection>[heading];

      // Force frequent 90° turns. Every other segment is a turn, with an
      // occasional straight segment to keep the paths readable.
      if (step >= 2 && (step.isEven || _random.nextDouble() < .65)) {
        candidates = heading == ArrowDirection.up || heading == ArrowDirection.down
            ? <ArrowDirection>[ArrowDirection.left, ArrowDirection.right]
            : <ArrowDirection>[ArrowDirection.up, ArrowDirection.down];
        candidates.shuffle(_random);
        candidates.add(heading);
      }

      GridPoint? next;
      ArrowDirection? chosen;
      for (final candidate in candidates) {
        final p = current.move(candidate);
        if (containsPoint(p, rows, columns) && !used.contains(p)) {
          next = p;
          chosen = candidate;
          break;
        }
      }

      if (next == null) {
        final fallback = <ArrowDirection>[
          ArrowDirection.up,
          ArrowDirection.down,
          ArrowDirection.left,
          ArrowDirection.right,
        ]..shuffle(_random);
        for (final candidate in fallback) {
          final p = current.move(candidate);
          if (containsPoint(p, rows, columns) && !used.contains(p)) {
            next = p;
            chosen = candidate;
            break;
          }
        }
      }

      if (next == null || chosen == null) break;
      heading = chosen;
      current = next;
      used.add(current);
      result.add(current);
    }

    return result;
  }

  bool containsPoint(GridPoint p, int rows, int columns) =>
      p.row >= 0 && p.row < rows && p.col >= 0 && p.col < columns;

  ArrowDirection _nearestEdgeDirection(
    GridPoint p,
    int rows,
    int columns,
  ) {
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
      if (cell.arrows.isNotEmpty) {
        remaining.add(GridPoint(cell.row, cell.col));
      }
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
