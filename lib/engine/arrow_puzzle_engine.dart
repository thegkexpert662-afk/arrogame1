import 'dart:math';
import 'package:flutter/material.dart';
import '../models/arrow.dart';
import '../models/arrow_template.dart';
import '../levels/level_catalog.dart';

enum PuzzleDifficulty { easy, normal, hard, expert }

class ArrowPuzzleEngine {
  List<Arrow> arrows;
  final List<List<Arrow>> _history = <List<Arrow>>[];
  final List<Arrow> _initial;
  final int level;
  final PuzzleDifficulty difficulty;
  bool completed = false;
  int moves = 0;

  ArrowPuzzleEngine(
    List<Arrow> source, {
    this.level = 1,
    this.difficulty = PuzzleDifficulty.normal,
  })  : arrows = source.map((e) => e.copy()).toList(growable: true),
        _initial = source.map((e) => e.copy()).toList(growable: false);

  int get initialCount => _initial.length;

  int get gridSize => arrows.isNotEmpty ? arrows.first.gridSize : levelConfigFor(level).gridSize;

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
    final config = levelConfigFor(level);
    final random = Random(level * 7919 + difficulty.index * 104729);
    final difficultyBonus = switch (difficulty) {
      PuzzleDifficulty.easy => -2,
      PuzzleDifficulty.normal => 0,
      PuzzleDifficulty.hard => 2,
      PuzzleDifficulty.expert => 4,
    };
    final count = max(6, min(24, config.arrowCount + difficultyBonus));

    final eligible = arrowTemplates.where(config.accepts).toList(growable: false);
    final templates = eligible.isNotEmpty ? eligible : arrowTemplates;

    for (var boardTry = 0; boardTry < 1000; boardTry++) {
      final result = <Arrow>[];
      final occupiedPoints = <String>{};
      final occupiedEdges = <String>{};

      for (var i = 0; i < count; i++) {
        Arrow? candidate;
        for (var trial = 0; trial < 400; trial++) {
          final template = templates[random.nextInt(templates.length)];
          final path = _placeTemplate(template, config.gridSize, random);
          if (path == null || !_fits(path, occupiedPoints, occupiedEdges)) continue;

          final first = path.first;
          final last = path.last;
          final direction = Arrow.directionBetween(path[path.length - 2], last);
          final cell = 1.0 / (config.gridSize - 1);
          candidate = Arrow(
            'L${level}_$i',
            first.col * cell,
            first.row * cell,
            (path.length - 1) * cell,
            direction,
            path: path,
            gridSize: config.gridSize,
          );
          _reserve(path, occupiedPoints, occupiedEdges);
          break;
        }

        if (candidate == null) break;
        result.add(candidate);
      }

      if (result.length == count && _isSolvable(result)) return result;
    }

    return _fallback(level, config, count);
  }

  /// Reuses an existing template by rotating it and moving it to a free
  /// position. This gives every level different layouts without making a
  /// separate screen or hard-coding 100 different boards.
  static List<ArrowPoint>? _placeTemplate(
    ArrowTemplate template,
    int grid,
    Random random,
  ) {
    var points = template.path.map((p) => ArrowPoint(p.row, p.col)).toList();
    final rotation = random.nextInt(4);

    for (var r = 0; r < rotation; r++) {
      points = points.map((p) => ArrowPoint(p.col, -p.row)).toList();
    }

    final minRow = points.map((p) => p.row).reduce(min);
    final minCol = points.map((p) => p.col).reduce(min);
    points = points
        .map((p) => ArrowPoint(p.row - minRow, p.col - minCol))
        .toList();

    final maxRow = points.map((p) => p.row).reduce(max);
    final maxCol = points.map((p) => p.col).reduce(max);
    if (maxRow >= grid || maxCol >= grid) return null;

    final rowOffset = random.nextInt(grid - maxRow);
    final colOffset = random.nextInt(grid - maxCol);
    return points
        .map((p) => ArrowPoint(p.row + rowOffset, p.col + colOffset))
        .toList(growable: false);
  }

  static String _pointKey(ArrowPoint p) => '${p.row}:${p.col}';

  static String _edgeKey(ArrowPoint a, ArrowPoint b) {
    final aKey = _pointKey(a);
    final bKey = _pointKey(b);
    return aKey.compareTo(bKey) < 0 ? '$aKey|$bKey' : '$bKey|$aKey';
  }

  /// Adjacent arrows are allowed, but sharing a point or exact grid edge is not.
  /// Crossing is also rejected by the solvability/path-clear checks.
  static bool _fits(
    List<ArrowPoint> path,
    Set<String> occupiedPoints,
    Set<String> occupiedEdges,
  ) {
    for (var i = 0; i < path.length; i++) {
      if (occupiedPoints.contains(_pointKey(path[i]))) return false;
      if (i > 0 && occupiedEdges.contains(_edgeKey(path[i - 1], path[i]))) return false;
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

  static List<Arrow> _fallback(int level, LevelConfig config, int count) {
    final cell = 1.0 / (config.gridSize - 1);
    final paths = <List<ArrowPoint>>[];
    for (var r = 0; r < config.gridSize - 2; r += 2) {
      paths.add(<ArrowPoint>[
        ArrowPoint(r, 0),
        ArrowPoint(r, 1),
        ArrowPoint(r, 2),
      ]);
      if (paths.length >= count) break;
    }

    return List.generate(count, (i) {
      final path = paths[i % paths.length];
      final last = path.last;
      final direction = Arrow.directionBetween(path[path.length - 2], last);
      return Arrow(
        'safe_${level}_$i',
        path.first.col * cell,
        path.first.row * cell,
        (path.length - 1) * cell,
        direction,
        path: path,
        gridSize: config.gridSize,
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
          )) return false;
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
            ) < .40) return true;
      }
      return false;
    }
    final p = Offset(pos.dx / size.width, pos.dy / size.height);
    return _distanceToSegment(
          p,
          Offset(a.x, a.y),
          Offset(a.x, a.y) + a.direction.vector * a.length,
        ) < 28 / min(size.width, size.height);
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
