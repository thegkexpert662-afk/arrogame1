import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/arrow_puzzle_engine.dart';
import '../models/arrow_direction.dart';
import '../services/level_progress_service.dart';

class ArrowGameScreen extends StatefulWidget {
  const ArrowGameScreen({super.key, required this.level});

  final int level;

  @override
  State<ArrowGameScreen> createState() => _ArrowGameScreenState();
}

class _ArrowGameScreenState extends State<ArrowGameScreen> {
  final ArrowPuzzleEngine _engine = ArrowPuzzleEngine();
  late ArrowPuzzle _puzzle;
  late GridPoint _player;
  final List<GridPoint> _visited = [];
  Timer? _timer;
  int _seconds = 0;
  int _moves = 0;
  int _bestScore = 0;
  int? _bestTime;
  bool _finished = false;
  String _message = 'Follow the arrows to reach FINISH';

  int get _difficulty => min(10, ((widget.level - 1) ~/ 100) + 1);

  @override
  void initState() {
    super.initState();
    _loadLevel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLevel() async {
    final savedScore = await LevelProgressService.instance.bestScore(widget.level);
    final savedTime = await LevelProgressService.instance.bestTime(widget.level);
    if (!mounted) return;
    setState(() {
      _bestScore = savedScore ?? 0;
      _bestTime = savedTime;
      _newPuzzle();
    });
  }

  void _newPuzzle() {
    _timer?.cancel();
    final random = Random(widget.level * 1000003 + _difficulty);
    _puzzle = ArrowPuzzleEngine(random: random).generate(difficulty: _difficulty);
    _player = _puzzle.start;
    _visited
      ..clear()
      ..add(_player);
    _seconds = 0;
    _moves = 0;
    _finished = false;
    _message = 'Follow the arrows to reach FINISH';
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_finished) setState(() => _seconds++);
    });
  }

  int _score() {
    final base = 1000 + (_difficulty * 250);
    final score = base - (_moves * 8) - (_seconds * 2);
    return max(100, score);
  }

  Future<void> _completeLevel() async {
    _finished = true;
    _timer?.cancel();
    final score = _score();
    await LevelProgressService.instance.completeLevel(
      level: widget.level,
      score: score,
      timeSeconds: _seconds,
    );
    if (!mounted) return;
    setState(() {
      _bestScore = max(_bestScore, score);
      _bestTime = _bestTime == null ? _seconds : min(_bestTime!, _seconds);
    });
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Level Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Level ${widget.level} • ${_difficultyName()}'),
            const SizedBox(height: 12),
            Text('Score: $score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Time: ${_formatTime(_seconds)}'),
            Text('Moves: $_moves'),
            if (widget.level < 1000) const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('Next level unlocked!'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _restart(); }, child: const Text('REPLAY')),
          FilledButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('LEVELS')),
        ],
      ),
    );
  }

  void _restart() => setState(_newPuzzle);

  void _tapCell(GridPoint target) {
    if (_finished || target == _player) return;
    final rowDelta = target.row - _player.row;
    final colDelta = target.col - _player.col;
    if (rowDelta.abs() + colDelta.abs() != 1) {
      setState(() => _message = 'Move to a nearby arrow cell');
      return;
    }

    final direction = _directionFor(_player, target);
    if (!_engine.canMove(_puzzle, _player, direction)) {
      setState(() => _message = 'Wrong direction! Try another route.');
      return;
    }

    setState(() {
      _player = target;
      _visited.add(target);
      _moves++;
      _message = target == _puzzle.finish ? 'Level complete!' : 'Good move!';
    });

    if (target == _puzzle.finish) _completeLevel();
  }

  String _difficultyName() {
    if (widget.level <= 25) return 'EASY';
    if (widget.level <= 100) return 'MEDIUM';
    if (widget.level <= 500) return 'HARD';
    return 'EXTREME';
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  ArrowDirection _directionFor(GridPoint from, GridPoint to) {
    final dr = to.row - from.row;
    final dc = to.col - from.col;
    if (dr == -1) return ArrowDirection.up;
    if (dr == 1) return ArrowDirection.down;
    if (dc == -1) return ArrowDirection.left;
    return ArrowDirection.right;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: Text('Level ${widget.level}'),
        actions: [IconButton(tooltip: 'Replay', onPressed: _restart, icon: const Icon(Icons.refresh))],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(
                children: [
                  Chip(label: Text(_difficultyName())),
                  const SizedBox(width: 6),
                  Text('Time ${_formatTime(_seconds)}'),
                  const Spacer(),
                  Text('Moves $_moves', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text(_message)),
                  if (_bestScore > 0) Text('Best $_bestScore', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: _puzzle.columns / _puzzle.rows,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _puzzle.rows * _puzzle.columns,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _puzzle.columns),
                      itemBuilder: (context, index) {
                        final point = GridPoint(index ~/ _puzzle.columns, index % _puzzle.columns);
                        final cell = _puzzle.cellAt(point);
                        final isPlayer = point == _player;
                        final isStart = point == _puzzle.start;
                        final isFinish = point == _puzzle.finish;
                        final isVisited = _visited.contains(point);
                        return GestureDetector(
                          onTap: () => _tapCell(point),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isPlayer ? Colors.blue : isFinish ? Colors.green.shade100 : isStart ? Colors.blue.shade50 : isVisited ? Colors.blue.withValues(alpha: 0.08) : Colors.white,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (cell.arrows.isNotEmpty)
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 1,
                                    runSpacing: -5,
                                    children: cell.arrows.map((d) => Text(d.symbol, style: TextStyle(fontSize: cell.arrows.length == 1 ? 22 : 14, fontWeight: FontWeight.w700, color: isPlayer ? Colors.white : Colors.black87))).toList(),
                                  ),
                                if (isStart) const Positioned(left: 3, top: 2, child: Text('S', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                                if (isFinish) const Positioned(right: 3, top: 2, child: Text('F', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                                if (isPlayer) const Icon(Icons.circle, size: 10, color: Colors.white),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('Best time: ${_bestTime == null ? '--:--' : _formatTime(_bestTime!)}'),
                  Text('Score: ${_score()}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
