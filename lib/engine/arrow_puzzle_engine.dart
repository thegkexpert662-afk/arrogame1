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

  /// Visual polyline for each arrow piece. The first point is the arrow tip;
  /// the remaining points travel backwards through the line and bends.
  final Map<GridPoint, List<GridPoint>> paths;

  ArrowCell cellAt(GridPoint point) => cells[point.row * columns + point.col];

  bool contains(GridPoint point) =>
      point.row >= 0 && point.row < rows && point.col >= 0 && point.col < columns;
}

/// Generates the connected-line "Tap to Clear" style used by the reference
/// game: many separate short, bent arrow pieces with one arrow head at the tip.
/// Levels 1-5 stay lighter; level 6+ uses a much denser, harder board.
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
    final pieceCount = hard
        ? min(r * c ~/ 3, 65 + d * 4)
        : min(r * c ~/ 4, 8 + d * 2);

    for (var attempt = 0; attempt < 500; attempt++) {
      final cells = List<ArrowCell>.generate(
        r * c,
        (index) => ArrowCell(row: index ~/ c, col: index % c),
      );
      final paths = <GridPoint, List<GridPoint>>{};
      final usedPathCells = <GridPoint>{};
      final endpoints = <GridPoint>[];

      final candidates = <GridPoint>[];
      for (var row = 0; row < r; row++) {
        for (var col = 0; col < c; col++) {
          candidates.add(GridPoint(row, col));
        }
      }
      candidates.shuffle(_random);

      for (final endpoint in candidates) {
        if (endpoints.length >= pieceCount) break;
        final directions = ArrowDirection.values.toList()..shuffle(_random);
        var placed = false;

        for (final direction in directions) {
          final maxLength = hard ? 5 : min(5, 2 + (d ~/ 3));
          final minLength = hard ? 3 : 2;
          final length = minLength +
              _random.nextInt(max(1, maxLength - minLength + 1));
          final path = _buildPath(
            endpoint,
            direction,
            length,
            r,
            c,
            usedPathCells,
            allowVisualOverlap: hard,
          );
          if (path == null) continue;

          endpoints.add(endpoint);
          paths[endpoint] = List.unmodifiable(path);
          if (!hard) usedPathCells.addAll(path);
          cells[endpoint.row * c + endpoint.col].arrows.add(direction);
          placed = true;
          break;
        }

        if (placed) continue;
      }

      if (endpoints.length < (hard ? pieceCount * 3 ~/ 4 : max(5, pieceCount ~/ 2))) {
        continue;
      }

      final puzzle = ArrowPuzzle(
        rows: r,
        columns: c,
        cells: cells,
        start: endpoints.first,
        finish: endpoints.last,
        solution: List.unmodifiable(endpoints),
        paths: Map.unmodifiable(paths),
      );

      if (_isClearable(puzzle)) return puzzle;
    }

    throw StateError('Could not generate a clearable arrow-line puzzle.');
  }

  List<GridPoint>? _buildPath(
    GridPoint endpoint,
    ArrowDirection arrowDirection,
    int length,
    int rows,
    int columns,
    Set<GridPoint> used,
    {bool allowVisualOverlap = false}) {
    // The line enters the arrow tip from the opposite direction.
    var current = endpoint.move(_opposite(arrowDirection));
    if (current.row < 0 ||
        current.row >= rows ||
        current.col < 0 ||
        current.col >= columns) {
      return null;
    }
    if (used.contains(endpoint) || (!allowVisualOverlap && used.contains(current))) {
      return null;
    }

    final path = <GridPoint>[endpoint, current];
    var previousDirection = _opposite(arrowDirection);

    for (var i = 2; i < length; i++) {
      final straight = <ArrowDirection>[previousDirection];
      final perpendicular = previousDirection == ArrowDirection.up ||
              previousDirection == ArrowDirection.down
          ? <ArrowDirection>[
              ArrowDirection.left,
              ArrowDirection.right,
            ]
          : <ArrowDirection>[
              ArrowDirection.up,
              ArrowDirection.down,
            ];

      // Hard boards deliberately prefer a bend at every short segment.
      final options = <ArrowDirection>[];
      if (allowVisualOverlap) {
        options.addAll(perpendicular);
        if (_random.nextInt(4) == 0) options.addAll(straight);
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
            candidate.col >= columns) {
          continue;
        }
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
