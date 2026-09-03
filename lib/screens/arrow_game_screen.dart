import 'package:flutter/material.dart';

import '../engine/arrow_puzzle_engine.dart';
import '../models/arrow_direction.dart';

class ArrowGameScreen extends StatefulWidget {
  const ArrowGameScreen({super.key});

  @override
  State<ArrowGameScreen> createState() => _ArrowGameScreenState();
}

class _ArrowGameScreenState extends State<ArrowGameScreen> {
  final ArrowPuzzleEngine _engine = ArrowPuzzleEngine();
  late ArrowPuzzle _puzzle;
  late GridPoint _player;
  final List<GridPoint> _visited = [];
  int _moves = 0;
  String _message = 'Follow the arrows to reach FINISH';

  @override
  void initState() {
    super.initState();
    _newLevel();
  }

  void _newLevel() {
    _puzzle = _engine.generate(difficulty: 1);
    _player = _puzzle.start;
    _visited
      ..clear()
      ..add(_player);
    _moves = 0;
    _message = 'Follow the arrows to reach FINISH';
  }

  void _tapCell(GridPoint target) {
    if (target == _player) return;
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

    if (target == _puzzle.finish) {
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Level Complete'),
            content: Text('Moves: $_moves'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(_newLevel);
                },
                child: const Text('NEXT LEVEL'),
              ),
            ],
          ),
        );
      });
    }
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
        title: const Text('Arrow Puzzle'),
        actions: [
          IconButton(
            tooltip: 'Restart',
            onPressed: () => setState(_newLevel),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(child: Text(_message, style: const TextStyle(fontSize: 15))),
                  Text('Moves $_moves', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _puzzle.columns,
                      ),
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
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isPlayer
                                  ? Colors.blue
                                  : isFinish
                                      ? Colors.green.shade100
                                      : isStart
                                          ? Colors.blue.shade50
                                          : isVisited
                                              ? Colors.blue.withValues(alpha: 0.08)
                                              : Colors.white,
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
                                    children: cell.arrows
                                        .map((d) => Text(
                                              d.symbol,
                                              style: TextStyle(
                                                fontSize: cell.arrows.length == 1 ? 22 : 14,
                                                fontWeight: FontWeight.w700,
                                                color: isPlayer ? Colors.white : Colors.black87,
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                if (isStart)
                                  const Positioned(
                                    left: 3,
                                    top: 2,
                                    child: Text('S', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                if (isFinish)
                                  const Positioned(
                                    right: 3,
                                    top: 2,
                                    child: Text('F', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                if (isPlayer)
                                  const Icon(Icons.circle, size: 10, color: Colors.white),
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: Text('Tap an adjacent cell. Only cells allowed by the arrow are valid.', textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
