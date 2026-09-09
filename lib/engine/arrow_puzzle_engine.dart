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
    final base = switch (difficulty) {
      PuzzleDifficulty.easy => 5,
      PuzzleDifficulty.normal => 8,
      PuzzleDifficulty.hard => 11,
      PuzzleDifficulty.expert => 14,
    };
    final growth = switch (difficulty) {
      PuzzleDifficulty.easy => min(5, level ~/ 5),
      PuzzleDifficulty.normal => min(8, level ~/ 4),
      PuzzleDifficulty.hard => min(13, level ~/ 3),
      PuzzleDifficulty.expert => min(16, level ~/ 2),
    };
    final count = min(30, base + growth);
    final minLength = difficulty == PuzzleDifficulty.easy ? .10 : .065;
    final maxLength = difficulty == PuzzleDifficulty.easy ? .25 : .22;

    // Bounded generation keeps slower/older phones responsive.
    for (var attempt = 0; attempt < 180; attempt++) {
      final result = <Arrow>[];
      for (var i = 0; i < count; i++) {
        final direction = ArrowDirection.values[random.nextInt(4)];
        final length = minLength + random.nextDouble() * (maxLength - minLength);
        const margin = .07;
        final x = margin + random.nextDouble() * (1 - margin * 2);
        final y = margin + random.nextDouble() * (1 - margin * 2);
        result.add(Arrow('L${level}_$i', x, y, length, direction));
      }
      if (_isSolvable(result)) return result;
    }

    // Deterministic guaranteed-safe fallback.
    final result = <Arrow>[];
    final lanes = max(5, min(count, 30));
    for (var i = 0; i < lanes; i++) {
      final y = .10 + (i / max(1, lanes - 1)) * .80;
      final direction = i.isEven ? ArrowDirection.right : ArrowDirection.left;
      final x = direction == ArrowDirection.right ? .10 : .90;
      result.add(Arrow('safe_${level}_$i', x, y, .13 + (i % 4) * .018, direction));
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
    final v = a.direction.vector;
    final start = Offset(a.x, a.y);
    final end = start + v * _exitDistance(a);
    for (var i = 0; i < source.length; i++) {
      if (i == index) continue;
      final b = source[i];
      final bs = Offset(b.x, b.y);
      final be = bs + b.direction.vector * b.length;
      if (_segmentsNear(start, end, bs, be, .040)) return false;
    }
    return true;
  }

  double _exitDistance(Arrow a) => switch (a.direction) {
        ArrowDirection.right => 1 - a.x,
        ArrowDirection.left => a.x,
        ArrowDirection.down => 1 - a.y,
        ArrowDirection.up => a.y,
      };

  bool _segmentsNear(Offset a, Offset b, Offset c, Offset d, double limit) {
    return _distanceToSegment(a, c, d) < limit ||
        _distanceToSegment(b, c, d) < limit ||
        _distanceToSegment(c, a, b) < limit ||
        _distanceToSegment(d, a, b) < limit;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared <= 0.0000001) return (p - a).distance;
    final t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / lengthSquared;
    final u = t.clamp(0.0, 1.0).toDouble();
    return (p - Offset(a.dx + u * dx, a.dy + u * dy)).distance;
  }

  bool hitTest(int index, Offset pos, Size size) {
    if (index < 0 || index >= arrows.length || size.width <= 0 || size.height <= 0) return false;
    final a = arrows[index];
    final scale = min(size.width, size.height);
    final normalized = Offset(pos.dx / size.width, pos.dy / size.height);
    final start = Offset(a.x, a.y);
    final end = start + a.direction.vector * a.length;
    final threshold = 28 / scale;
    return _distanceToSegment(normalized, start, end) < threshold;
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
    final v = a.direction.vector;
    final start = Offset(a.x, a.y);
    final exit = switch (a.direction) {
      ArrowDirection.right => 1 - a.x,
      ArrowDirection.left => a.x,
      ArrowDirection.down => 1 - a.y,
      ArrowDirection.up => a.y,
    };
    final end = start + v * exit;
    for (var i = 0; i < source.length; i++) {
      if (i == index) continue;
      final b = source[i];
      final bs = Offset(b.x, b.y);
      final be = bs + b.direction.vector * b.length;
      if (_staticSegmentsNear(start, end, bs, be, .040)) return false;
    }
    return true;
  }

  static bool _staticSegmentsNear(Offset a, Offset b, Offset c, Offset d, double limit) {
    return _staticDistance(a, c, d) < limit ||
        _staticDistance(b, c, d) < limit ||
        _staticDistance(c, a, b) < limit ||
        _staticDistance(d, a, b) < limit;
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
