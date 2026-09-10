import 'dart:math';
import 'package:flutter/material.dart';
import '../models/arrow.dart';

enum PuzzleDifficulty { easy, normal, hard, expert }

class ArrowPuzzleEngine {
  List<Arrow> arrows;
  final List<List<Arrow>> _history = <List<Arrow>>[];
  final List<Arrow> _initial;
  final int level;
  final PuzzleDifficulty difficulty;
  bool completed = false;
  int moves = 0;

  ArrowPuzzleEngine(List<Arrow> source, {this.level = 1, this.difficulty = PuzzleDifficulty.normal})
      : arrows = source.map((e) => e.copy()).toList(growable: true),
        _initial = source.map((e) => e.copy()).toList(growable: false);

  int get initialCount => _initial.length;

  factory ArrowPuzzleEngine.forLevel(int level, {PuzzleDifficulty difficulty = PuzzleDifficulty.normal}) {
    final safeLevel = max(1, min(100, level));
    return ArrowPuzzleEngine(_generate(safeLevel, difficulty), level: safeLevel, difficulty: difficulty);
  }

  factory ArrowPuzzleEngine.demo(int level) => ArrowPuzzleEngine.forLevel(level, difficulty: PuzzleDifficulty.hard);

  static List<Arrow> _generate(int level, PuzzleDifficulty difficulty) {
    final random = Random(level * 7919 + difficulty.index * 104729);
    final grid = switch (difficulty) {
      PuzzleDifficulty.easy => 9,
      PuzzleDifficulty.normal => 10,
      PuzzleDifficulty.hard => 11,
      PuzzleDifficulty.expert => 12,
    };
    final count = switch (difficulty) {
      PuzzleDifficulty.easy => min(18, 9 + level ~/ 8),
      PuzzleDifficulty.normal => min(28, 13 + level ~/ 5),
      PuzzleDifficulty.hard => min(34, 17 + level ~/ 4),
      PuzzleDifficulty.expert => min(40, 21 + level ~/ 3),
    };
    final maxTurns = switch (difficulty) {
      PuzzleDifficulty.easy => 1,
      PuzzleDifficulty.normal => 2,
      PuzzleDifficulty.hard => 3,
      PuzzleDifficulty.expert => 4,
    };
    final maxSteps = switch (difficulty) {
      PuzzleDifficulty.easy => 3,
      PuzzleDifficulty.normal => 5,
      PuzzleDifficulty.hard => 7,
      PuzzleDifficulty.expert => 9,
    };
    final cell = 1.0 / (grid - 1);

    // Generate many candidates and keep only boards that have a legal
    // removal order. The random seed makes every level deterministic.
    for (var attempt = 0; attempt < 700; attempt++) {
      final result = <Arrow>[];
      final occupiedPoints = <String>{};
      final occupiedEdges = <String>{};

      for (var i = 0; i < count; i++) {
        Arrow? candidate;
        for (var trial = 0; trial < 120; trial++) {
          final path = _makePath(random, grid, maxTurns, maxSteps);
          if (path == null || path.length < 2) continue;
          if (!_fits(path, occupiedPoints, occupiedEdges)) continue;

          final last = path.last;
          final previous = path[path.length - 2];
          final finalDirection = Arrow.directionBetween(previous, last);
          candidate = Arrow(
            'L${level}_$i',
            path.first.col * cell,
            path.first.row * cell,
            (path.length - 1) * cell,
            finalDirection,
            path: path,
            gridSize: grid,
          );
          _reserve(path, occupiedPoints, occupiedEdges);
          break;
        }
        if (candidate == null) break;
        result.add(candidate);
      }

      if (result.length >= max(5, (count * .70).floor()) && _isSolvable(result)) {
        return result;
      }
    }

    return _fallback(level, difficulty, grid, cell);
  }

  static List<ArrowPoint>? _makePath(Random random, int grid, int maxTurns, int maxSteps) {
    var row = random.nextInt(grid);
    var col = random.nextInt(grid);
    final path = <ArrowPoint>[ArrowPoint(row, col)];
    var direction = ArrowDirection.values[random.nextInt(4)];
    final turns = random.nextInt(maxTurns + 1);

    for (var segment = 0; segment <= turns; segment++) {
      final steps = 1 + random.nextInt(maxSteps);
      for (var s = 0; s < steps; s++) {
        final nr = row + direction.vector.dy.toInt();
        final nc = col + direction.vector.dx.toInt();
        if (nr < 0 || nr >= grid || nc < 0 || nc >= grid) {
          return _pointsOutward(path, row, col, direction, grid);
        }
        row = nr;
        col = nc;
        path.add(ArrowPoint(row, col));
      }

      if (segment < turns) {
        final perpendicular = <ArrowDirection>[
          if (direction == ArrowDirection.up || direction == ArrowDirection.down) ...[
            ArrowDirection.left,
            ArrowDirection.right,
          ] else ...[
            ArrowDirection.up,
            ArrowDirection.down,
          ],
        ];
        direction = perpendicular[random.nextInt(perpendicular.length)];
      }
    }

    // Continue the last segment until it reaches an edge. This guarantees
    // that the arrowhead points outward and can leave the board.
    while (true) {
      if (_isOutwardBoundary(row, col, direction, grid)) return path;
      final nr = row + direction.vector.dy.toInt();
      final nc = col + direction.vector.dx.toInt();
      if (nr < 0 || nr >= grid || nc < 0 || nc >= grid) return path;
      row = nr;
      col = nc;
      path.add(ArrowPoint(row, col));
    }
  }

  static List<ArrowPoint>? _pointsOutward(List<ArrowPoint> path, int row, int col, ArrowDirection direction, int grid) {
    return _isOutwardBoundary(row, col, direction, grid) ? path : null;
  }

  static bool _isOutwardBoundary(int row, int col, ArrowDirection direction, int grid) {
    return (direction == ArrowDirection.up && row == 0) ||
        (direction == ArrowDirection.down && row == grid - 1) ||
        (direction == ArrowDirection.left && col == 0) ||
        (direction == ArrowDirection.right && col == grid - 1);
  }

  static bool _fits(List<ArrowPoint> path, Set<String> points, Set<String> edges) {
    for (var i = 0; i < path.length; i++) {
      final p = path[i];
      if (points.contains('${p.row}:${p.col}')) return false;
      if (i == 0) continue;
      final a = path[i - 1];
      final b = path[i];
      final edge = _edgeKey(a, b);
      if (edges.contains(edge)) return false;
      // Orthogonal segments can only cross on a grid point. Since every
      // visited point is reserved, crossings and touching are rejected.
      if (points.contains('${a.row}:${a.col}') && i > 1) return false;
    }
    return true;
  }

  static void _reserve(List<ArrowPoint> path, Set<String> points, Set<String> edges) {
    for (var i = 0; i < path.length; i++) {
      final p = path[i];
      points.add('${p.row}:${p.col}');
      if (i > 0) edges.add(_edgeKey(path[i - 1], p));
    }
  }

  static String _edgeKey(ArrowPoint a, ArrowPoint b) {
    final first = '${a.row}:${a.col}';
    final second = '${b.row}:${b.col}';
    return first.compareTo(second) < 0 ? '$first|$second' : '$second|$first';
  }

  static List<Arrow> _fallback(int level, PuzzleDifficulty difficulty, int grid, double cell) {
    final result = <Arrow>[];
    final count = switch (difficulty) {
      PuzzleDifficulty.easy => 8,
      PuzzleDifficulty.normal => 12,
      PuzzleDifficulty.hard => 16,
      PuzzleDifficulty.expert => 20,
    };

    // Guaranteed valid 90-degree paths arranged in separate rows/columns.
    for (var i = 0; i < count; i++) {
      final row = min(grid - 2, 1 + (i * 2) % max(1, grid - 2));
      final col = i.isEven ? 1 : grid - 2;
      final horizontal = i.isEven;
      final path = <ArrowPoint>[];
      if (horizontal) {
        for (var c = col; c < grid; c++) path.add(ArrowPoint(row, c));
      } else {
        for (var r = row; r >= 0; r--) path.add(ArrowPoint(r, col));
      }
      if (path.length >= 2) {
        final direction = Arrow.directionBetween(path[path.length - 2], path.last);
        result.add(Arrow('safe_${level}_$i', path.first.col * cell, path.first.row * cell, (path.length - 1) * cell, direction, path: path, gridSize: grid));
      }
    }
    return result;
  }

  bool canMove(int index) {
    if (index < 0 || index >= arrows.length || completed) return false;
    return _pathClear(arrows[index], index, arrows);
  }

  Arrow? removeArrow(int index) {
    if (!canMove(index)) return null;
    final removed = arrows[index].copy();
    _history.add(arrows.map((e) => e.copy()).toList(growable: true));
    arrows.removeAt(index);
    moves++;
    completed = arrows.isEmpty;
    return removed;
  }

  bool moveArrow(int index) => removeArrow(index) != null;

  int? hintIndex() {
    for (var i = 0; i < arrows.length; i++) {
      if (canMove(i)) return i;
    }
    return null;
  }

  bool _pathClear(Arrow a, int index, List<Arrow> source) {
    if (!a.isPathArrow) return _straightPathClear(a, index, source);
    final last = a.path.last;
    final previous = a.path[a.path.length - 2];
    final direction = Arrow.directionBetween(previous, last);
    final start = Offset(last.col.toDouble(), last.row.toDouble());
    final end = start + direction.vector * 1000;

    for (var i = 0; i < source.length; i++) {
      if (i == index) continue;
      final b = source[i];
      if (b.isPathArrow) {
        for (var s = 1; s < b.path.length; s++) {
          final c = b.path[s - 1];
          final d = b.path[s];
          if (_segmentsNear(start, end, Offset(c.col.toDouble(), c.row.toDouble()), Offset(d.col.toDouble(), d.row.toDouble()), .28)) return false;
        }
      } else {
        final bs = Offset(b.x, b.y);
        final be = bs + b.direction.vector * b.length;
        if (_segmentsNear(start, end, bs, be, .04)) return false;
      }
    }
    return true;
  }

  bool _straightPathClear(Arrow a, int index, List<Arrow> source) {
    final start = Offset(a.x, a.y);
    final end = start + a.direction.vector * 1000;
    for (var i = 0; i < source.length; i++) {
      if (i == index) continue;
      final b = source[i];
      if (b.isPathArrow) {
        for (var s = 1; s < b.path.length; s++) {
          final c = b.path[s - 1];
          final d = b.path[s];
          if (_segmentsNear(start, end, Offset(c.col.toDouble(), c.row.toDouble()), Offset(d.col.toDouble(), d.row.toDouble()), .28)) return false;
        }
      } else {
        final bs = Offset(b.x, b.y);
        final be = bs + b.direction.vector * b.length;
        if (_segmentsNear(start, end, bs, be, .04)) return false;
      }
    }
    return true;
  }

  bool _segmentsNear(Offset a, Offset b, Offset c, Offset d, double limit) {
    return _distanceToSegment(a, c, d) < limit || _distanceToSegment(b, c, d) < limit || _distanceToSegment(c, a, b) < limit || _distanceToSegment(d, a, b) < limit;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final l = dx * dx + dy * dy;
    if (l <= 0.0000001) return (p - a).distance;
    final t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / l;
    final u = t.clamp(0.0, 1.0).toDouble();
    return (p - Offset(a.dx + u * dx, a.dy + u * dy)).distance;
  }

  bool hitTest(int index, Offset pos, Size size) {
    if (index < 0 || index >= arrows.length || size.width <= 0 || size.height <= 0) return false;
    final a = arrows[index];
    if (a.isPathArrow) {
      final grid = max(1, a.gridSize - 1);
      final p = Offset(pos.dx / size.width * grid, pos.dy / size.height * grid);
      for (var i = 1; i < a.path.length; i++) {
        final s = Offset(a.path[i - 1].col.toDouble(), a.path[i - 1].row.toDouble());
        final e = Offset(a.path[i].col.toDouble(), a.path[i].row.toDouble());
        if (_distanceToSegment(p, s, e) < .34) return true;
      }
      return false;
    }
    final scale = min(size.width, size.height);
    final normalized = Offset(pos.dx / size.width, pos.dy / size.height);
    final start = Offset(a.x, a.y);
    final end = start + a.direction.vector * a.length;
    return _distanceToSegment(normalized, start, end) < 28 / scale;
  }

  void undo() {
    if (_history.isEmpty) return;
    arrows = _history.removeLast().map((e) => e.copy()).toList(growable: true);
    completed = false;
    if (moves > 0) moves--;
  }

  void reset() {
    arrows = _initial.map((e) => e.copy()).toList(growable: true);
    _history.clear();
    completed = false;
    moves = 0;
  }

  bool validateSolvable() => _isSolvable(arrows);

  static bool _isSolvable(List<Arrow> source) {
    var remaining = source.map((e) => e.copy()).toList(growable: true);
    while (remaining.isNotEmpty) {
      var found = -1;
      for (var i = 0; i < remaining.length; i++) {
        if (_staticPathClear(remaining[i], i, remaining)) {
          found = i;
          break;
        }
      }
      if (found < 0) return false;
      remaining.removeAt(found);
    }
    return true;
  }

  static bool _staticPathClear(Arrow a, int index, List<Arrow> source) {
    final start = a.isPathArrow ? Offset(a.path.last.col.toDouble(), a.path.last.row.toDouble()) : Offset(a.x, a.y);
    final direction = a.isPathArrow ? Arrow.directionBetween(a.path[a.path.length - 2], a.path.last) : a.direction;
    final end = start + direction.vector * 1000;

    for (var i = 0; i < source.length; i++) {
      if (i == index) continue;
      final b = source[i];
      if (b.isPathArrow) {
        for (var s = 1; s < b.path.length; s++) {
          final c = b.path[s - 1];
          final d = b.path[s];
          if (_staticSegmentsNear(start, end, Offset(c.col.toDouble(), c.row.toDouble()), Offset(d.col.toDouble(), d.row.toDouble()), .28)) return false;
        }
      } else {
        final bs = Offset(b.x, b.y);
        final be = bs + b.direction.vector * b.length;
        if (_staticSegmentsNear(start, end, bs, be, .04)) return false;
      }
    }
    return true;
  }

  static bool _staticSegmentsNear(Offset a, Offset b, Offset c, Offset d, double limit) {
    return _staticDistance(a, c, d) < limit || _staticDistance(b, c, d) < limit || _staticDistance(c, a, b) < limit || _staticDistance(d, a, b) < limit;
  }

  static double _staticDistance(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final l = dx * dx + dy * dy;
    if (l <= 0.0000001) return (p - a).distance;
    final t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / l;
    final u = t.clamp(0.0, 1.0).toDouble();
    return (p - Offset(a.dx + u * dx, a.dy + u * dy)).distance;
  }

  static String difficultyName(PuzzleDifficulty d) => switch (d) {
        PuzzleDifficulty.easy => 'Easy',
        PuzzleDifficulty.normal => 'Normal',
        PuzzleDifficulty.hard => 'Hard',
        PuzzleDifficulty.expert => 'Expert',
      };
}
