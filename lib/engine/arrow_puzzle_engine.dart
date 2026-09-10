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
      PuzzleDifficulty.easy => min(9, 7 + level ~/ 30),
      PuzzleDifficulty.normal => min(11, 8 + level ~/ 25),
      PuzzleDifficulty.hard => min(13, 9 + level ~/ 20),
      PuzzleDifficulty.expert => min(15, 10 + level ~/ 15),
    };
    final count = switch (difficulty) {
      PuzzleDifficulty.easy => min(22, 7 + level ~/ 4),
      PuzzleDifficulty.normal => min(38, 12 + level ~/ 3),
      PuzzleDifficulty.hard => min(52, 18 + level ~/ 2),
      PuzzleDifficulty.expert => min(68, 24 + level),
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

    for (var attempt = 0; attempt < 450; attempt++) {
      final result = <Arrow>[];
      final occupied = <String>{};

      for (var i = 0; i < count; i++) {
        Arrow? candidate;
        for (var tryArrow = 0; tryArrow < 80; tryArrow++) {
          final path = _makePath(random, grid, maxTurns, maxSteps, occupied);
          if (path == null || path.length < 2) continue;
          final points = path.map((p) => '${p.row}:${p.col}').toList();
          final last = path.last;
          final prev = path[path.length - 2];
          final finalDirection = Arrow.directionBetween(prev, last);
          final key = points.join('|');
          if (occupied.contains(key)) continue;
          candidate = Arrow(
            'L${level}_$i',
            last.col * cell,
            last.row * cell,
            (path.length - 1) * cell,
            finalDirection,
            path: path,
          );
          // Reserve a small clearance around every path point. This makes
          // the dense board look close-packed while preventing touching.
          final expanded = <String>{};
          for (final p in path) {
            for (var dr = -1; dr <= 1; dr++) {
              for (var dc = -1; dc <= 1; dc++) {
                expanded.add('${p.row + dr}:${p.col + dc}');
              }
            }
          }
          if (expanded.any(occupied.contains)) {
            candidate = null;
            continue;
          }
          occupied.addAll(expanded);
          break;
        }
        if (candidate == null) break;
        result.add(candidate);
      }

      if (result.length >= max(3, count * 0.75).floor() && _isSolvable(result)) {
        return result;
      }
    }

    return _fallback(level, difficulty, grid, cell);
  }

  static List<ArrowPoint>? _makePath(
    Random random,
    int grid,
    int maxTurns,
    int maxSteps,
    Set<String> occupied,
  ) {
    var row = random.nextInt(grid);
    var col = random.nextInt(grid);
    final path = <ArrowPoint>[ArrowPoint(row, col)];
    var direction = ArrowDirection.values[random.nextInt(4)];
    var turns = random.nextInt(maxTurns + 1);

    for (var segment = 0; segment <= turns; segment++) {
      final steps = 1 + random.nextInt(maxSteps);
      for (var s = 0; s < steps; s++) {
        final nr = row + direction.vector.dy.toInt();
        final nc = col + direction.vector.dx.toInt();
        if (nr < 0 || nr >= grid || nc < 0 || nc >= grid) {
          // A path ending on the boundary is useful because its final
          // direction can point out of the board.
          if (path.length >= 2 && (row == 0 || row == grid - 1 || col == 0 || col == grid - 1)) {
            return path;
          }
          return null;
        }
        final key = '$nr:$nc';
        if (occupied.contains(key) || path.any((p) => p.row == nr && p.col == nc)) return null;
        row = nr;
        col = nc;
        path.add(ArrowPoint(row, col));
      }
      if (segment < turns) {
        final choices = ArrowDirection.values.where((d) => d != direction && d.vector.dx != -direction.vector.dx && d.vector.dy != -direction.vector.dy).toList();
        direction = choices[random.nextInt(choices.length)];
      }
    }

    // Extend the final segment to the nearest boundary when possible.
    while (row > 0 && row < grid - 1 && col > 0 && col < grid - 1) {
      final nr = row + direction.vector.dy.toInt();
      final nc = col + direction.vector.dx.toInt();
      if (nr < 0 || nr >= grid || nc < 0 || nc >= grid) break;
      if (occupied.contains('$nr:$nc') || path.any((p) => p.row == nr && p.col == nc)) return null;
      row = nr;
      col = nc;
      path.add(ArrowPoint(row, col));
    }
    if (row == 0 || row == grid - 1 || col == 0 || col == grid - 1) return path;
    return null;
  }

  static List<Arrow> _fallback(int level, PuzzleDifficulty difficulty, int grid, double cell) {
    final result = <Arrow>[];
    final count = switch (difficulty) {
      PuzzleDifficulty.easy => 8,
      PuzzleDifficulty.normal => 14,
      PuzzleDifficulty.hard => 20,
      PuzzleDifficulty.expert => 28,
    };
    for (var i = 0; i < count; i++) {
      final row = i % grid;
      final fromLeft = i.isEven;
      final direction = fromLeft ? ArrowDirection.right : ArrowDirection.left;
      final endCol = fromLeft ? grid - 1 : 0;
      final startCol = fromLeft ? 0 : grid - 1;
      final path = <ArrowPoint>[];
      final step = fromLeft ? 1 : -1;
      for (var c = startCol;; c += step) {
        path.add(ArrowPoint(row, c));
        if (c == endCol) break;
      }
      result.add(Arrow('safe_${level}_$i', startCol * cell, row * cell, (path.length - 1) * cell, direction, path: path));
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
    if (a.path.length < 2) return _straightPathClear(a, index, source);
    final last = a.path.last;
    final previous = a.path[a.path.length - 2];
    final direction = Arrow.directionBetween(previous, last);
    final start = Offset(last.col.toDouble(), last.row.toDouble());
    final end = start + direction.vector * 1000;
    for (var i = 0; i < source.length; i++) {
      if (i == index) continue;
      final b = source[i];
      for (var s = 1; s < b.path.length; s++) {
        final c = b.path[s - 1];
        final d = b.path[s];
        if (_segmentsNear(start, end, Offset(c.col.toDouble(), c.row.toDouble()), Offset(d.col.toDouble(), d.row.toDouble()), .30)) return false;
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
      final bs = Offset(b.x, b.y);
      final be = bs + b.direction.vector * b.length;
      if (_segmentsNear(start, end, bs, be, .040)) return false;
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
    final scale = min(size.width, size.height);
    final p = Offset(pos.dx / size.width * (size.width / scale), pos.dy / size.height * (size.height / scale));
    if (a.path.length >= 2) {
      for (var i = 1; i < a.path.length; i++) {
        final s = Offset(a.path[i - 1].col / max(1, _gridFor(a)), a.path[i - 1].row / max(1, _gridFor(a)));
        final e = Offset(a.path[i].col / max(1, _gridFor(a)), a.path[i].row / max(1, _gridFor(a)));
        if (_distanceToSegment(p, s, e) < 0.035) return true;
      }
      return false;
    }
    final start = Offset(a.x, a.y);
    final end = start + a.direction.vector * a.length;
    final threshold = 28 / scale;
    return _distanceToSegment(Offset(pos.dx / size.width, pos.dy / size.height), start, end) < threshold;
  }

  int _gridFor(Arrow a) {
    var maxPoint = 1;
    for (final p in a.path) {
      maxPoint = max(maxPoint, max(p.row, p.col));
    }
    return maxPoint;
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
    if (a.path.length >= 2) {
      final last = a.path.last;
      final previous = a.path[a.path.length - 2];
      final direction = Arrow.directionBetween(previous, last);
      final start = Offset(last.col.toDouble(), last.row.toDouble());
      final end = start + direction.vector * 1000;
      for (var i = 0; i < source.length; i++) {
        if (i == index) continue;
        final b = source[i];
        for (var s = 1; s < b.path.length; s++) {
          final c = b.path[s - 1];
          final d = b.path[s];
          if (_staticSegmentsNear(start, end, Offset(c.col.toDouble(), c.row.toDouble()), Offset(d.col.toDouble(), d.row.toDouble()), .30)) return false;
        }
      }
      return true;
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
