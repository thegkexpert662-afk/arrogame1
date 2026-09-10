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

  static const int _grid = 9;

  ArrowPuzzleEngine(
    List<Arrow> source, {
    this.level = 1,
    this.difficulty = PuzzleDifficulty.normal,
  })  : arrows = source.map((e) => e.copy()).toList(growable: true),
        _initial = source.map((e) => e.copy()).toList(growable: false);

  int get initialCount => _initial.length;

  factory ArrowPuzzleEngine.forLevel(
    int level, {
    PuzzleDifficulty difficulty = PuzzleDifficulty.normal,
  }) {
    final safe = max(1, min(100, level));
    return ArrowPuzzleEngine(
      _generate(safe, difficulty),
      level: safe,
      difficulty: difficulty,
    );
  }

  factory ArrowPuzzleEngine.demo(int level) =>
      ArrowPuzzleEngine.forLevel(level, difficulty: PuzzleDifficulty.hard);

  static List<Arrow> _generate(int level, PuzzleDifficulty difficulty) {
    final random = Random(level * 7919 + difficulty.index * 104729);
    final count = switch (difficulty) {
      PuzzleDifficulty.easy => 10,
      PuzzleDifficulty.normal => min(16, 12 + level ~/ 12),
      PuzzleDifficulty.hard => min(20, 15 + level ~/ 10),
      PuzzleDifficulty.expert => min(24, 18 + level ~/ 8),
    };

    final turnChance = switch (difficulty) {
      PuzzleDifficulty.easy => .48,
      PuzzleDifficulty.normal => .68,
      PuzzleDifficulty.hard => .82,
      PuzzleDifficulty.expert => .92,
    };

    for (var boardTry = 0; boardTry < 900; boardTry++) {
      final result = <Arrow>[];
      final occupiedPoints = <String>{};
      final occupiedEdges = <String>{};

      for (var i = 0; i < count; i++) {
        Arrow? candidate;
        for (var trial = 0; trial < 300; trial++) {
          final path = _randomPath(random, turnChance);
          if (path == null || !_fits(path, occupiedPoints, occupiedEdges)) {
            continue;
          }

          final first = path.first;
          final last = path.last;
          final direction = Arrow.directionBetween(path[path.length - 2], last);
          final cell = 1.0 / (_grid - 1);
          candidate = Arrow(
            'L${level}_$i',
            first.col * cell,
            first.row * cell,
            (path.length - 1) * cell,
            direction,
            path: path,
            gridSize: _grid,
          );
          _reserve(path, occupiedPoints, occupiedEdges);
          break;
        }

        if (candidate == null) break;
        result.add(candidate);
      }

      if (result.length == count && _isSolvable(result)) {
        return result;
      }
    }

    return _fallback(level, difficulty);
  }

  /// Creates a 2-7 point path. Every move is exactly one grid cell.
  /// Turns are always 90 degrees and never reverse the previous segment.
  static List<ArrowPoint>? _randomPath(Random random, double turnChance) {
    final start = ArrowPoint(random.nextInt(_grid), random.nextInt(_grid));
    final path = <ArrowPoint>[start];
    var row = start.row;
    var col = start.col;
    var direction = ArrowDirection.values[random.nextInt(4)];
    final steps = 1 + random.nextInt(6); // 1-6 moves = 2-7 points.

    for (var i = 0; i < steps; i++) {
      if (i > 0 && random.nextDouble() < turnChance) {
        final turns = (direction == ArrowDirection.up || direction == ArrowDirection.down)
            ? const [ArrowDirection.left, ArrowDirection.right]
            : const [ArrowDirection.up, ArrowDirection.down];
        direction = turns[random.nextInt(2)];
      }

      final nr = row + direction.vector.dy.toInt();
      final nc = col + direction.vector.dx.toInt();
      if (nr < 0 || nr >= _grid || nc < 0 || nc >= _grid) return null;

      final next = ArrowPoint(nr, nc);
      if (path.contains(next)) return null;
      path.add(next);
      row = nr;
      col = nc;
    }

    return path;
  }

  static String _pointKey(ArrowPoint p) => '${p.row}:${p.col}';

  static String _edgeKey(ArrowPoint a, ArrowPoint b) {
    final aKey = _pointKey(a);
    final bKey = _pointKey(b);
    return aKey.compareTo(bKey) < 0 ? '$aKey|$bKey' : '$bKey|$aKey';
  }

  /// Arrows may be adjacent on the grid, but they can never share a point
  /// or a grid edge. This keeps them visually dense while preventing touch/cross.
  static bool _fits(
    List<ArrowPoint> path,
    Set<String> occupiedPoints,
    Set<String> occupiedEdges,
  ) {
    for (var i = 0; i < path.length; i++) {
      if (occupiedPoints.contains(_pointKey(path[i]))) return false;
      if (i > 0 && occupiedEdges.contains(_edgeKey(path[i - 1], path[i]))) {
        return false;
      }
    }
    return true;
  }

  static void _reserve(
    List<ArrowPoint> path,
    Set<String> occupiedPoints,
    Set<String> occupiedEdges,
  ) {
    for (var i = 0; i < path.length; i++) {
      occupiedPoints.add(_pointKey(path[i]));
      if (i > 0) occupiedEdges.add(_edgeKey(path[i - 1], path[i]));
    }
  }

  static List<Arrow> _fallback(int level, PuzzleDifficulty difficulty) {
    final cell = 1.0 / (_grid - 1);
    final templates = <List<ArrowPoint>>[
      [const ArrowPoint(0, 0), const ArrowPoint(0, 2), const ArrowPoint(1, 2)],
      [const ArrowPoint(0, 4), const ArrowPoint(1, 4), const ArrowPoint(1, 6)],
      [const ArrowPoint(0, 8), const ArrowPoint(2, 8), const ArrowPoint(2, 7)],
      [const ArrowPoint(2, 0), const ArrowPoint(3, 0), const ArrowPoint(3, 2), const ArrowPoint(4, 2)],
      [const ArrowPoint(3, 4), const ArrowPoint(4, 4), const ArrowPoint(4, 3), const ArrowPoint(5, 3)],
      [const ArrowPoint(4, 6), const ArrowPoint(4, 8), const ArrowPoint(6, 8)],
      [const ArrowPoint(5, 0), const ArrowPoint(7, 0), const ArrowPoint(7, 2)],
      [const ArrowPoint(6, 4), const ArrowPoint(8, 4), const ArrowPoint(8, 2)],
      [const ArrowPoint(6, 6), const ArrowPoint(7, 6), const ArrowPoint(7, 8)],
      [const ArrowPoint(8, 6), const ArrowPoint(8, 7), const ArrowPoint(7, 7)],
    ];

    final count = switch (difficulty) {
      PuzzleDifficulty.easy => 8,
      PuzzleDifficulty.normal => 10,
      PuzzleDifficulty.hard => 10,
      PuzzleDifficulty.expert => 10,
    };

    return List.generate(count, (i) {
      final path = templates[i % templates.length];
      final last = path.last;
      final direction = Arrow.directionBetween(path[path.length - 2], last);
      return Arrow(
        'safe_${level}_$i',
        path.first.col * cell,
        path.first.row * cell,
        (path.length - 1) * cell,
        direction,
        path: path,
        gridSize: _grid,
      );
    });
  }

  bool canMove(int index) =>
      index >= 0 && index < arrows.length && !completed && _pathClear(arrows[index], index, arrows);

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
    final start = a.isPathArrow
        ? Offset(a.path.last.col.toDouble(), a.path.last.row.toDouble())
        : Offset(a.x, a.y);
    final direction = a.isPathArrow
        ? Arrow.directionBetween(a.path[a.path.length - 2], a.path.last)
        : a.direction;
    final end = start + direction.vector * 1000;

    for (var i = 0; i < source.length; i++) {
      if (i == index) continue;
      final b = source[i];
      if (b.isPathArrow) {
        for (var s = 1; s < b.path.length; s++) {
          final c = b.path[s - 1];
          final d = b.path[s];
          if (_segmentsNear(
            start,
            end,
            Offset(c.col.toDouble(), c.row.toDouble()),
            Offset(d.col.toDouble(), d.row.toDouble()),
            .32,
          )) {
            return false;
          }
        }
      }
    }
    return true;
  }

  bool _isSolvable(List<Arrow> source) {
    var remaining = source.map((e) => e.copy()).toList();
    while (remaining.isNotEmpty) {
      var found = -1;
      for (var i = 0; i < remaining.length; i++) {
        if (_pathClear(remaining[i], i, remaining)) {
          found = i;
          break;
        }
      }
      if (found < 0) return false;
      remaining.removeAt(found);
    }
    return true;
  }

  bool hitTest(int index, Offset pos, Size size) {
    if (index < 0 || index >= arrows.length || size.width <= 0 || size.height <= 0) return false;
    final a = arrows[index];
    if (a.isPathArrow) {
      final p = Offset(
        pos.dx / size.width * (a.gridSize - 1),
        pos.dy / size.height * (a.gridSize - 1),
      );
      for (var i = 1; i < a.path.length; i++) {
        if (_distanceToSegment(
              p,
              Offset(a.path[i - 1].col.toDouble(), a.path[i - 1].row.toDouble()),
              Offset(a.path[i].col.toDouble(), a.path[i].row.toDouble()),
            ) <
            .40) {
          return true;
        }
      }
      return false;
    }
    final p = Offset(pos.dx / size.width, pos.dy / size.height);
    return _distanceToSegment(
          p,
          Offset(a.x, a.y),
          Offset(a.x, a.y) + a.direction.vector * a.length,
        ) <
        28 / min(size.width, size.height);
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final l = dx * dx + dy * dy;
    if (l <= .0000001) return (p - a).distance;
    final t = (((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / l)
        .clamp(0.0, 1.0)
        .toDouble();
    return (p - Offset(a.dx + t * dx, a.dy + t * dy)).distance;
  }

  bool _segmentsNear(Offset a, Offset b, Offset c, Offset d, double limit) =>
      _distanceToSegment(a, c, d) < limit ||
      _distanceToSegment(b, c, d) < limit ||
      _distanceToSegment(c, a, b) < limit ||
      _distanceToSegment(d, a, b) < limit;

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

  static String difficultyName(PuzzleDifficulty d) => switch (d) {
        PuzzleDifficulty.easy => 'Easy',
        PuzzleDifficulty.normal => 'Normal',
        PuzzleDifficulty.hard => 'Hard',
        PuzzleDifficulty.expert => 'Expert',
      };
}
