import 'dart:collection';
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

/// Procedural generator for arrow-path puzzles.
/// Generation always starts with a guaranteed path, then adds decoys and
/// dead-end traps. Every generated puzzle is verified before it is returned.
class ArrowPuzzleEngine {
  ArrowPuzzleEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  ArrowPuzzle generate({
    int? rows,
    int? columns,
    int difficulty = 1,
  }) {
    final int level = difficulty.clamp(1, 10).toInt();
    final size = _sizeForDifficulty(level);
    final r = rows ?? size.$1;
    final c = columns ?? size.$2;

    if (r < 3 || c < 3) {
      throw ArgumentError('Arrow puzzle must be at least 3x3.');
    }

    final fingerprints = <String>{};

    for (var attempt = 0; attempt < 250; attempt++) {
      final start = GridPoint(_random.nextInt(r), 0);
      final finish = GridPoint(_random.nextInt(r), c - 1);
      if (start == finish) continue;

      final solution = _makeGuaranteedSolutionPath(r, c, start, finish);
      if (solution.length < 3) continue;

      final cells = List<ArrowCell>.generate(
        r * c,
        (index) => ArrowCell(row: index ~/ c, col: index % c),
      );

      _placeSolutionArrows(cells, solution, c);
      _placeDecoysAndDeadEnds(
        cells,
        rows: r,
        columns: c,
        solution: solution,
        difficulty: level,
      );
      _lockStartToSolution(cells, start, solution, c);
      _clearFinish(cells, finish, c);

      final puzzle = ArrowPuzzle(
        rows: r,
        columns: c,
        cells: cells,
        start: start,
        finish: finish,
        solution: List.unmodifiable(solution),
      );

      final fingerprint = _fingerprint(puzzle);
      if (!fingerprints.add(fingerprint)) continue;

      // Verify the stored solution and the actual arrows independently.
      if (validateSolution(puzzle) && findSolutionPath(puzzle) != null) {
        return puzzle;
      }
    }

    throw StateError('Could not generate a valid arrow puzzle.');
  }

  (int, int) _sizeForDifficulty(int difficulty) {
    if (difficulty <= 2) return (6, 8);
    if (difficulty <= 4) return (7, 9);
    if (difficulty <= 6) return (8, 11);
    if (difficulty <= 8) return (10, 13);
    return (12, 16);
  }

  /// Builds a guaranteed route. Horizontal progress is always to the right;
  /// vertical progress is always toward the finish row. The order is random,
  /// creating many layouts without introducing cycles into the authored path.
  List<GridPoint> _makeGuaranteedSolutionPath(
    int rows,
    int columns,
    GridPoint start,
    GridPoint finish,
  ) {
    final path = <GridPoint>[start];
    var row = start.row;
    var col = start.col;

    final vertical = <GridPoint>[];
    final rowStep = finish.row >= row ? 1 : -1;
    while (row != finish.row) {
      row += rowStep;
      vertical.add(GridPoint(row, col));
    }

    final horizontal = <GridPoint>[];
    while (col != finish.col) {
      col += 1;
      horizontal.add(GridPoint(row, col));
    }

    final verticalQueue = Queue<GridPoint>.from(vertical);
    final horizontalQueue = Queue<GridPoint>.from(horizontal);

    while (verticalQueue.isNotEmpty || horizontalQueue.isNotEmpty) {
      final takeVertical = horizontalQueue.isEmpty ||
          (verticalQueue.isNotEmpty && _random.nextBool());
      path.add(
        takeVertical
            ? verticalQueue.removeFirst()
            : horizontalQueue.removeFirst(),
      );
    }

    return path;
  }

  void _placeSolutionArrows(
    List<ArrowCell> cells,
    List<GridPoint> solution,
    int columns,
  ) {
    for (var i = 0; i < solution.length - 1; i++) {
      final from = solution[i];
      final to = solution[i + 1];
      cells[from.row * columns + from.col].arrows.add(
            _directionBetween(from, to),
          );
    }
  }

  void _placeDecoysAndDeadEnds(
    List<ArrowCell> cells, {
    required int rows,
    required int columns,
    required List<GridPoint> solution,
    required int difficulty,
  }) {
    final solutionSet = solution.toSet();
    final profile = _difficultyProfile(difficulty);

    // Empty trap targets act as true dead ends. Nearby decoy cells point into
    // them, creating paths that can be entered but cannot be continued.
    final candidates = cells
        .map((cell) => GridPoint(cell.row, cell.col))
        .where((point) =>
            !solutionSet.contains(point) && point != solution.last)
        .toList()
      ..shuffle(_random);

    final targetCount = min(
      candidates.length,
      max(1, (candidates.length * profile.trapChance).round()),
    );
    final trapTargets = candidates.take(targetCount).toList();

    for (final target in trapTargets) {
      final feeders = <GridPoint>[];
      for (final direction in ArrowDirection.values) {
        final from = target.move(direction.opposite);
        if (_inside(from, rows, columns) && !solutionSet.contains(from)) {
          feeders.add(from);
        }
      }
      feeders.shuffle(_random);
      if (feeders.isNotEmpty) {
        final feeder = feeders.first;
        cells[feeder.row * columns + feeder.col].arrows.add(
              _directionBetween(feeder, target),
            );
      }
    }

    // Controlled decoys make non-solution regions meaningful.
    for (final cell in cells) {
      final point = GridPoint(cell.row, cell.col);
      if (point == solution.last || solutionSet.contains(point)) continue;

      final possible = ArrowDirection.values.where((direction) {
        return _inside(point.move(direction), rows, columns);
      }).toList()
        ..shuffle(_random);

      if (possible.isEmpty) continue;

      if (_random.nextDouble() < profile.decoyChance) {
        cell.arrows.add(possible.first);
      }
      if (possible.length > 1 &&
          _random.nextDouble() < profile.extraArrowChance) {
        cell.arrows.add(possible[1]);
      }
    }

    // Some solution cells receive an optional exit into the decoy network.
    // The guaranteed solution arrow is never removed.
    for (var i = 0; i < solution.length - 1; i++) {
      if (_random.nextDouble() >= profile.solutionDecoyChance) continue;
      final point = solution[i];
      final next = solution[i + 1];
      final alternatives = ArrowDirection.values.where((direction) {
        final target = point.move(direction);
        return target != next && _inside(target, rows, columns);
      }).toList()
        ..shuffle(_random);

      if (alternatives.isNotEmpty) {
        cells[point.row * columns + point.col].arrows.add(alternatives.first);
      }
    }
  }

  _DifficultyProfile _difficultyProfile(int difficulty) {
    final int d = difficulty.clamp(1, 10).toInt();
    return _DifficultyProfile(
      decoyChance: min(0.82, 0.25 + d * 0.055),
      extraArrowChance: min(0.55, 0.05 + d * 0.035),
      trapChance: min(0.30, 0.06 + d * 0.022),
      solutionDecoyChance: min(0.70, 0.05 + d * 0.06),
    );
  }

  void _lockStartToSolution(
    List<ArrowCell> cells,
    GridPoint start,
    List<GridPoint> solution,
    int columns,
  ) {
    final startCell = cells[start.row * columns + start.col];
    startCell.arrows
      ..clear()
      ..add(_directionBetween(solution[0], solution[1]));
  }

  void _clearFinish(List<ArrowCell> cells, GridPoint finish, int columns) {
    cells[finish.row * columns + finish.col].arrows.clear();
  }

  bool canMove(ArrowPuzzle puzzle, GridPoint from, ArrowDirection direction) {
    if (!puzzle.contains(from)) return false;
    final cell = puzzle.cellAt(from);
    final next = from.move(direction);
    return cell.has(direction) && puzzle.contains(next);
  }

  bool isFinish(ArrowPuzzle puzzle, GridPoint point) => point == puzzle.finish;

  /// Validates the generator's stored solution path.
  bool validateSolution(ArrowPuzzle puzzle) {
    final solution = puzzle.solution;
    if (solution.length < 2) return false;
    if (solution.first != puzzle.start || solution.last != puzzle.finish) {
      return false;
    }

    for (var i = 0; i < solution.length - 1; i++) {
      final from = solution[i];
      final to = solution[i + 1];
      if (!puzzle.contains(from) || !puzzle.contains(to)) return false;

      final rowDistance = (from.row - to.row).abs();
      final colDistance = (from.col - to.col).abs();
      if (rowDistance + colDistance != 1) return false;

      if (!canMove(puzzle, from, _directionBetween(from, to))) return false;
    }
    return true;
  }

  /// Searches the actual board arrows and returns a real route to the finish.
  List<GridPoint>? findSolutionPath(ArrowPuzzle puzzle) {
    final parent = <GridPoint, GridPoint?>{puzzle.start: null};
    final queue = Queue<GridPoint>()..add(puzzle.start);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current == puzzle.finish) {
        return _reconstructPath(parent, puzzle.finish);
      }

      for (final direction in puzzle.cellAt(current).arrows) {
        final next = current.move(direction);
        if (!puzzle.contains(next) || parent.containsKey(next)) continue;
        parent[next] = current;
        queue.add(next);
      }
    }
    return null;
  }

  bool isSolvable(ArrowPuzzle puzzle) => findSolutionPath(puzzle) != null;

  /// Counts up to [limit] distinct routes. Keeping a small cap avoids doing
  /// expensive exhaustive searches on high-difficulty boards.
  int countSolutions(ArrowPuzzle puzzle, {int limit = 2}) {
    if (limit < 1) return 0;
    var found = 0;
    final visited = <GridPoint>{};

    void dfs(GridPoint current) {
      if (found >= limit) return;
      if (current == puzzle.finish) {
        found++;
        return;
      }

      visited.add(current);
      for (final direction in puzzle.cellAt(current).arrows) {
        final next = current.move(direction);
        if (puzzle.contains(next) && !visited.contains(next)) {
          dfs(next);
        }
        if (found >= limit) break;
      }
      visited.remove(current);
    }

    dfs(puzzle.start);
    return found;
  }

  List<GridPoint> _reconstructPath(
    Map<GridPoint, GridPoint?> parent,
    GridPoint finish,
  ) {
    final path = <GridPoint>[];
    GridPoint? current = finish;
    while (current != null) {
      path.add(current);
      current = parent[current];
    }
    return path.reversed.toList(growable: false);
  }

  /// Fingerprint prevents the generator from accepting the same board twice
  /// during retry attempts and gives a stable basis for duplicate detection.
  String _fingerprint(ArrowPuzzle puzzle) {
    final buffer = StringBuffer()
      ..write('${puzzle.rows}x${puzzle.columns}|')
      ..write('${puzzle.start.row},${puzzle.start.col}|')
      ..write('${puzzle.finish.row},${puzzle.finish.col}|');

    for (final cell in puzzle.cells) {
      buffer.write('${cell.row},${cell.col}:');
      final arrows = cell.arrows.map((d) => d.index).toList()..sort();
      buffer.write(arrows.join(','));
      buffer.write(';');
    }
    return buffer.toString();
  }

  ArrowDirection _directionBetween(GridPoint from, GridPoint to) {
    final row = to.row - from.row;
    final col = to.col - from.col;
    if (row == -1 && col == 0) return ArrowDirection.up;
    if (row == 1 && col == 0) return ArrowDirection.down;
    if (row == 0 && col == -1) return ArrowDirection.left;
    if (row == 0 && col == 1) return ArrowDirection.right;
    throw ArgumentError('Points must be adjacent.');
  }

  bool _inside(GridPoint point, int rows, int columns) =>
      point.row >= 0 &&
      point.row < rows &&
      point.col >= 0 &&
      point.col < columns;
}

class _DifficultyProfile {
  const _DifficultyProfile({
    required this.decoyChance,
    required this.extraArrowChance,
    required this.trapChance,
    required this.solutionDecoyChance,
  });

  final double decoyChance;
  final double extraArrowChance;
  final double trapChance;
  final double solutionDecoyChance;
}

extension on ArrowDirection {
  ArrowDirection get opposite {
    switch (this) {
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
}
