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

class ArrowPuzzleEngine {
  ArrowPuzzleEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  ArrowPuzzle generate({int? rows, int? columns, int difficulty = 1}) {
    final size = _sizeForDifficulty(difficulty);
    final r = rows ?? size.$1;
    final c = columns ?? size.$2;

    if (r < 3 || c < 3) {
      throw ArgumentError('Arrow puzzle must be at least 3x3.');
    }

    for (var attempt = 0; attempt < 100; attempt++) {
      final start = GridPoint(_random.nextInt(r), 0);
      final finish = GridPoint(_random.nextInt(r), c - 1);
      if (start == finish) continue;

      final solution = _makeSolutionPath(r, c, start, finish);
      if (solution.length < 3) continue;

      final cells = List<ArrowCell>.generate(
        r * c,
        (index) => ArrowCell(row: index ~/ c, col: index % c),
      );

      _addSolutionDirections(cells, solution, c);
      _addExtraRoutesAndTraps(cells, r, c, solution, difficulty);
      _ensureStartHasSolutionOnly(cells, start, solution, c);

      final puzzle = ArrowPuzzle(
        rows: r,
        columns: c,
        cells: cells,
        start: start,
        finish: finish,
        solution: solution,
      );

      if (validateSolution(puzzle)) return puzzle;
    }

    throw StateError('Could not generate a valid arrow puzzle.');
  }

  (int, int) _sizeForDifficulty(int difficulty) {
    if (difficulty <= 2) return (6, 8);
    if (difficulty <= 5) return (8, 10);
    if (difficulty <= 8) return (10, 13);
    return (12, 16);
  }

  List<GridPoint> _makeSolutionPath(int rows, int columns, GridPoint start, GridPoint finish) {
    final path = <GridPoint>[start];
    var current = start;
    var guard = 0;

    while (current != finish && guard++ < rows * columns * 4) {
      final candidates = <GridPoint>[];
      for (final direction in ArrowDirection.values) {
        final next = current.move(direction);
        if (!next.equals(finish) && !path.contains(next) && _inside(next, rows, columns)) {
          candidates.add(next);
        } else if (next == finish) {
          candidates.add(next);
        }
      }
      if (candidates.isEmpty) return <GridPoint>[];

      candidates.shuffle(_random);
      final preferred = candidates.where((point) {
        final distance = (point.row - finish.row).abs() + (point.col - finish.col).abs();
        final currentDistance = (current.row - finish.row).abs() + (current.col - finish.col).abs();
        return distance <= currentDistance || _random.nextDouble() < 0.18;
      }).toList();
      current = (preferred.isNotEmpty ? preferred : candidates).first;
      path.add(current);
    }

    return current == finish ? path : <GridPoint>[];
  }

  void _addSolutionDirections(List<ArrowCell> cells, List<GridPoint> solution, int columns) {
    for (var i = 0; i < solution.length - 1; i++) {
      final from = solution[i];
      final to = solution[i + 1];
      final direction = _directionBetween(from, to);
      cells[from.row * columns + from.col].arrows.add(direction);
    }
  }

  void _addExtraRoutesAndTraps(
    List<ArrowCell> cells,
    int rows,
    int columns,
    List<GridPoint> solution,
    int difficulty,
  ) {
    final solutionSet = solution.toSet();
    final extraChance = min(0.55, 0.16 + difficulty * 0.045);

    for (final cell in cells) {
      final point = GridPoint(cell.row, cell.col);
      if (point == solution.last) continue;

      final possible = ArrowDirection.values.where((direction) {
        final next = point.move(direction);
        return _inside(next, rows, columns);
      }).toList()
        ..shuffle(_random);

      if (!solutionSet.contains(point) && possible.isNotEmpty) {
        cell.arrows.add(possible.first);
        if (_random.nextDouble() < extraChance && possible.length > 1) {
          cell.arrows.add(possible[1]);
        }
      } else if (_random.nextDouble() < extraChance && possible.isNotEmpty) {
        final direction = possible.firstWhere(
          (d) => point.move(d) != (solutionSet.contains(point) ? solution.last : point),
          orElse: () => possible.first,
        );
        cell.arrows.add(direction);
      }
    }
  }

  void _ensureStartHasSolutionOnly(
    List<ArrowCell> cells,
    GridPoint start,
    List<GridPoint> solution,
    int columns,
  ) {
    final startCell = cells[start.row * columns + start.col];
    startCell.arrows.clear();
    startCell.arrows.add(_directionBetween(solution[0], solution[1]));
  }

  bool canMove(ArrowPuzzle puzzle, GridPoint from, ArrowDirection direction) {
    if (!puzzle.contains(from)) return false;
    final cell = puzzle.cellAt(from);
    final next = from.move(direction);
    return cell.has(direction) && puzzle.contains(next);
  }

  bool isFinish(ArrowPuzzle puzzle, GridPoint point) => point == puzzle.finish;

  bool validateSolution(ArrowPuzzle puzzle) {
    var current = puzzle.start;
    final visited = <GridPoint>{};

    for (var i = 0; i < puzzle.rows * puzzle.columns * 2; i++) {
      if (current == puzzle.finish) return true;
      if (!visited.add(current)) return false;

      final next = puzzle.solution.length > visited.length
          ? puzzle.solution[visited.length]
          : null;
      if (next == null) return false;

      final direction = _directionBetween(current, next);
      if (!canMove(puzzle, current, direction)) return false;
      current = next;
    }
    return false;
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
      point.row >= 0 && point.row < rows && point.col >= 0 && point.col < columns;
}

extension on GridPoint {
  bool equals(GridPoint other) => row == other.row && col == other.col;
}
