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
    this.paths = const <GridPoint, List<GridPoint>>{},
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
      point.row >= 0 && point.row < rows && point.col >= 0 && point.col < columns;
}

/// Generates dense, guaranteed-clearable "Tap to Clear" arrow boards.
///
/// The arrow endpoints are created in reverse solution order. Every newly
/// added arrow is required to have at least one direction whose ray is clear
/// of all arrows already added. This removes the random-generation deadlock
/// that could otherwise throw a StateError on dense levels.
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
    final hard = d >= 6;

    // Keep the endpoint density high while leaving enough free rays for a
    // guaranteed solution. Long overlapping paths provide the dense visual
    // coverage without requiring an impossible number of arrowheads.
    final pieceCount = hard
        ? min((r * c * 4) ~/ 5, 85 + d * 4)
        : min(r * c ~/ 4, 8 + d * 2);

    for (var attempt = 0; attempt < 80; attempt++) {
      final cells = List<ArrowCell>.generate(
        r * c,
        (index) => ArrowCell(row: index ~/ c, col: index % c),
      );
      final paths = <GridPoint, List<GridPoint>>{};
      final endpoints = <GridPoint>[];
      final occupied = <GridPoint>{};

      final candidates = <GridPoint>[];
      for (var row = 0; row < r; row++) {
        for (var col = 0; col < c; col++) {
          candidates.add(GridPoint(row, col));
        }
      }
      candidates.shuffle(_random);

      // Build the board backwards from the final clear order. An arrow added
      // now only needs to avoid arrows that will be cleared after it.
      for (final endpoint in candidates) {
        if (endpoints.length >= pieceCount) break;
        if (occupied.contains(endpoint)) continue;

        final directions = ArrowDirection.values.toList()..shuffle(_random);
        ArrowDirection? chosenDirection;
        for (final direction in directions) {
          if (_rayIsClearFromOccupied(endpoint, direction, occupied, r, c)) {
            chosenDirection = direction;
            break;
          }
        }
        if (chosenDirection == null) continue;

        final length = hard ? 4 + _random.nextInt(4) : 2 + _random.nextInt(4);
        final path = _buildPath(
          endpoint,
          chosenDirection,
          length,
          r,
          c,
          <GridPoint>{},
          allowVisualOverlap: hard,
        );
        if (path == null) continue;

        endpoints.add(endpoint);
        occupied.add(endpoint);
        paths[endpoint] = List.unmodifiable(path);
        cells[endpoint.row * c + endpoint.col].arrows.add(chosenDirection);
      }

      // If the shuffled candidate order could not reach the target density,
      // retry with a new order. The final fallback below is deterministic and
      // still guarantees solvability.
      if (endpoints.length < pieceCount) continue;

      final solution = endpoints.reversed.toList(growable: false);
      final puzzle = ArrowPuzzle(
        rows: r,
        columns: c,
        cells: cells,
        start: solution.first,
        finish: solution.last,
        solution: solution,
        paths: Map.unmodifiable(paths),
      );

      if (_isClearable(puzzle)) return puzzle;
    }

    // Guaranteed fallback: construct a moderate-density board using a fixed
    // row/column pattern. This prevents a playable screen from ever crashing
    // because a dense random board could not be found.
    return _generateFallback(r, c, d);
  }

  ArrowPuzzle _generateFallback(int rows, int columns, int d) {
    final cells = List<ArrowCell>.generate(
      rows * columns,
      (index) => ArrowCell(row: index ~/ columns, col: index % columns),
    );
    final paths = <GridPoint, List<GridPoint>>{};
    final endpoints = <GridPoint>[];
    final occupied = <GridPoint>{};
    final target = min((rows * columns * 3) ~/ 4, 70 + d * 3);

    // Repeatedly pick an edge-clearable point. Removing in reverse insertion
    // order is always valid because each new point avoids existing blockers.
    final candidates = <GridPoint>[];
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        candidates.add(GridPoint(row, col));
      }
    }
    candidates.sort((a, b) {
      final da = min(min(a.row, rows - 1 - a.row), min(a.col, columns - 1 - a.col));
      final db = min(min(b.row, rows - 1 - b.row), min(b.col, columns - 1 - b.col));
      return da.compareTo(db);
    });

    for (final point in candidates.reversed) {
      if (endpoints.length >= target) break;
      final direction = _firstClearDirection(point, occupied, rows, columns);
      if (direction == null) continue;
      endpoints.add(point);
      occupied.add(point);
      cells[point.row * columns + point.col].arrows.add(direction);
      paths[point] = List.unmodifiable(_buildPath(
            point,
            direction,
            d >= 6 ? 5 : 3,
            rows,
            columns,
            <GridPoint>{},
            allowVisualOverlap: true,
          ) ?? <GridPoint>[point]);
    }

    final solution = endpoints.reversed.toList(growable: false);
    final puzzle = ArrowPuzzle(
      rows: rows,
      columns: columns,
      cells: cells,
      start: solution.first,
      finish: solution.last,
      solution: solution,
      paths: Map.unmodifiable(paths),
    );
    if (_isClearable(puzzle)) return puzzle;

    // Last-resort single-arrow board. It is preferable to a crash and is
    // reached only if an extremely unusual board geometry defeats the above.
    final safe = GridPoint(rows ~/ 2, columns ~/ 2);
    final safeDirection = _firstClearDirection(safe, <GridPoint>{}, rows, columns) ?? ArrowDirection.up;
    final safeCells = List<ArrowCell>.generate(
      rows * columns,
      (index) => ArrowCell(row: index ~/ columns, col: index % columns),
    );
    safeCells[safe.row * columns + safe.col].arrows.add(safeDirection);
    return ArrowPuzzle(
      rows: rows,
      columns: columns,
      cells: safeCells,
      start: safe,
      finish: safe,
      solution: <GridPoint>[safe],
      paths: <GridPoint, List<GridPoint>>{safe: <GridPoint>[safe]},
    );
  }

  ArrowDirection? _firstClearDirection(
    GridPoint point,
    Set<GridPoint> occupied,
    int rows,
    int columns,
  ) {
    final directions = ArrowDirection.values.toList();
    for (final direction in directions) {
      if (_rayIsClearFromOccupied(point, direction, occupied, rows, columns)) {
        return direction;
      }
    }
    return null;
  }

  bool _rayIsClearFromOccupied(
    GridPoint from,
    ArrowDirection direction,
    Set<GridPoint> occupied,
    int rows,
    int columns,
  ) {
    var next = from.move(direction);
    while (next.row >= 0 && next.row < rows && next.col >= 0 && next.col < columns) {
      if (occupied.contains(next)) return false;
      next = next.move(direction);
    }
    return true;
  }

  List<GridPoint>? _buildPath(
    GridPoint endpoint,
    ArrowDirection arrowDirection,
    int length,
    int rows,
    int columns,
    Set<GridPoint> used,
    {bool allowVisualOverlap = false}) {
    var current = endpoint.move(_opposite(arrowDirection));
    if (current.row < 0 ||
        current.row >= rows ||
        current.col < 0 ||
        current.col >= columns) {
      return null;
    }
    if (used.contains(endpoint) ||
        (!allowVisualOverlap && used.contains(current))) {
      return null;
    }

    final path = <GridPoint>[endpoint, current];
    var previousDirection = _opposite(arrowDirection);

    for (var i = 2; i < length; i++) {
      final straight = <ArrowDirection>[previousDirection];
      final perpendicular = previousDirection == ArrowDirection.up ||
              previousDirection == ArrowDirection.down
          ? <ArrowDirection>[ArrowDirection.left, ArrowDirection.right]
          : <ArrowDirection>[ArrowDirection.up, ArrowDirection.down];

      final options = <ArrowDirection>[];
      if (allowVisualOverlap) {
        options.addAll(perpendicular);
        options.addAll(perpendicular);
        if (_random.nextInt(5) == 0) options.addAll(straight);
      } else {
        options.addAll(straight);
        options.addAll(perpendicular);
        options.shuffle(_random);
      }

      GridPoint? next;
      ArrowDirection? chosen;
      for (final direction in options) {
        final candidate = current.move(direction);
        if (candidate.row < 0 ||
            candidate.row >= rows ||
            candidate.col < 0 ||
            candidate.col >= columns) continue;
        if (used.contains(candidate) || path.contains(candidate)) continue;
        next = candidate;
        chosen = direction;
        break;
      }
      if (next == null || chosen == null) break;
      path.add(next);
      current = next;
      previousDirection = chosen;
    }

    return path.length >= 2 ? path : null;
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

  (int, int) _sizeForDifficulty(int difficulty) {
    if (difficulty <= 2) return (8, 10);
    if (difficulty <= 4) return (9, 11);
    if (difficulty == 5) return (10, 12);
    if (difficulty == 6) return (14, 17);
    if (difficulty == 7) return (15, 18);
    if (difficulty == 8) return (16, 18);
    if (difficulty == 9) return (17, 19);
    return (18, 20);
  }

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
        if (_rayIsClear(puzzle, occupied, point, arrows.first)) removable.add(point);
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
    if (cell.arrows.isEmpty || cleared.contains(point)) return false;

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
        search({...left}..remove(point), {...cleared, point});
        if (count >= limit) return;
      }
    }

    search(remaining, <GridPoint>{});
    return count;
  }
}
