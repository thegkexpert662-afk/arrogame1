import 'dart:math';
import 'package:flutter/material.dart';
import '../models/arrow.dart';

class ArrowPuzzleEngine {
  List<Arrow> arrows;
  final List<List<Arrow>> _history = [];
  final int level;
  bool completed = false;
  int moves = 0;
  ArrowPuzzleEngine(this.arrows, {this.level = 1});
  factory ArrowPuzzleEngine.demo(int level) => ArrowPuzzleEngine([
    Arrow('a', .16, .70, .24, ArrowDirection.right),
    Arrow('b', .40, .70, .22, ArrowDirection.right),
    Arrow('c', .62, .70, .18, ArrowDirection.down),
    Arrow('d', .62, .52, .20, ArrowDirection.up),
    Arrow('e', .30, .42, .24, ArrowDirection.left),
    Arrow('f', .30, .22, .20, ArrowDirection.down),
    Arrow('g', .52, .30, .28, ArrowDirection.right),
    Arrow('h', .78, .28, .22, ArrowDirection.up),
    Arrow('i', .20, .54, .16, ArrowDirection.up),
    Arrow('j', .50, .86, .14, ArrowDirection.down),
  ]);

  bool moveArrow(int index) {
    if (index < 0 || index >= arrows.length) return false;
    final a = arrows[index];
    if (!_pathClear(a, index)) return false;
    _history.add(arrows.map((e) => e.copy()).toList());
    arrows.removeAt(index);
    moves++;
    completed = arrows.isEmpty;
    return true;
  }

  double _exitDistance(Arrow a) => switch (a.direction) {
        ArrowDirection.right => 1 - a.x,
        ArrowDirection.left => a.x,
        ArrowDirection.down => 1 - a.y,
        ArrowDirection.up => a.y,
      };

  bool _pathClear(Arrow a, int index) {
    final v = a.direction.vector;
    final start = Offset(a.x, a.y);
    final end = start + v * _exitDistance(a);
    for (var i = 0; i < arrows.length; i++) {
      if (i == index) continue;
      final b = arrows[i];
      final bs = Offset(b.x, b.y);
      final be = bs + b.direction.vector * b.length;
      if (_segmentsNear(start, end, bs, be, .035)) return false;
    }
    return true;
  }

  bool _segmentsNear(Offset a, Offset b, Offset c, Offset d, double limit) {
    return _distanceToSegment(a, c, d) < limit ||
        _distanceToSegment(b, c, d) < limit ||
        _distanceToSegment(c, a, b) < limit ||
        _distanceToSegment(d, a, b) < limit;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    final l = dx * dx + dy * dy;
    if (l == 0) return (p - a).distance;
    final t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / l;
    final u = t.clamp(0.0, 1.0).toDouble();
    return (p - Offset(a.dx + u * dx, a.dy + u * dy)).distance;
  }

  bool hitTest(int i, Offset pos, Size size) {
    if (i >= arrows.length) return false;
    final a = arrows[i], scale = min(size.width, size.height);
    final s = Offset(a.x * size.width, a.y * size.height);
    final e = s + a.direction.vector * a.length * scale;
    return _distanceToSegment(pos, s, e) < 24;
  }

  void undo() {
    if (_history.isEmpty) return;
    arrows = _history.removeLast();
    completed = false;
    if (moves > 0) moves--;
  }
  void reset() {
    arrows = ArrowPuzzleEngine.demo(level).arrows.map((e) => e.copy()).toList();
    _history.clear(); completed = false; moves = 0;
  }
  void hint() {}

  bool validateSolvable() {
    var test = arrows.map((e) => e.copy()).toList();
    var guard = 0;
    while (test.isNotEmpty && guard++ < 5000) {
      var found = -1;
      for (var i = 0; i < test.length; i++) {
        final probe = ArrowPuzzleEngine(test.map((e) => e.copy()).toList());
        if (probe._pathClear(probe.arrows[i], i)) { found = i; break; }
      }
      if (found < 0) return false;
      test.removeAt(found);
    }
    return test.isEmpty;
  }
}
