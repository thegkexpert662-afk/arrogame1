import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/arrow_puzzle_engine.dart';
import '../models/arrow_direction.dart';
import '../services/ad_service.dart';
import '../services/gameplay_feedback_service.dart';
import '../services/level_progress_service.dart';

class ArrowGameScreen extends StatefulWidget {
  const ArrowGameScreen({super.key, required this.level});
  final int level;

  @override
  State<ArrowGameScreen> createState() => _ArrowGameScreenState();
}

class _ArrowGameScreenState extends State<ArrowGameScreen>
    with TickerProviderStateMixin {
  final ArrowPuzzleEngine _engine = ArrowPuzzleEngine();
  final _feedback = GameplayFeedbackService.instance;
  final _ads = AdService.instance;
  late ArrowPuzzle _puzzle;
  late GridPoint _player;
  final List<GridPoint> _visited = [];
  final Set<GridPoint> _hintPath = {};
  Timer? _timer;
  int _seconds = 0;
  int _moves = 0;
  int _freeHints = 3;
  int _coins = 20;
  int _bestScore = 0;
  int? _bestTime;
  bool _finished = false;
  bool _paused = false;
  bool _showFullSolution = false;
  bool _rewardAdLoading = false;
  String _message = 'Follow the arrows to reach FINISH';
  late AnimationController _winController;

  int get _difficulty => min(10, ((widget.level - 1) ~/ 100) + 1);

  @override
  void initState() {
    super.initState();
    _winController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadLevel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _winController.dispose();
    super.dispose();
  }

  Future<void> _loadLevel() async {
    final score = await LevelProgressService.instance.bestScore(widget.level);
    final time = await LevelProgressService.instance.bestTime(widget.level);
    if (!mounted) return;
    setState(() {
      _bestScore = score ?? 0;
      _bestTime = time;
      _newPuzzle();
    });
  }

  void _newPuzzle() {
    _timer?.cancel();
    final random = Random(widget.level * 1000003 + _difficulty);
    _puzzle = ArrowPuzzleEngine(random: random).generate(
      difficulty: _difficulty,
    );
    _player = _puzzle.start;
    _visited
      ..clear()
      ..add(_player);
    _hintPath.clear();
    _seconds = 0;
    _moves = 0;
    _finished = false;
    _paused = false;
    _showFullSolution = false;
    _message = 'Follow the arrows to reach FINISH';
    _winController.reset();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_finished && !_paused) {
        setState(() => _seconds++);
      }
    });
  }

  int _score() => max(
        100,
        1000 + (_difficulty * 250) - (_moves * 8) - (_seconds * 2),
      );

  Future<void> _completeLevel() async {
    _finished = true;
    _timer?.cancel();
    await _feedback.win();
    await _winController.forward();
    final score = _score();
    await LevelProgressService.instance.completeLevel(
      level: widget.level,
      score: score,
      timeSeconds: _seconds,
    );
    await _ads.showInterstitialAfterLevel();
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
            const SizedBox(height: 10),
            Text(
              'Score: $score',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text('Time: ${_formatTime(_seconds)}'),
            Text('Moves: $_moves'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restart();
            },
            child: const Text('REPLAY'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('LEVELS'),
          ),
        ],
      ),
    );
  }

  void _restart() => setState(_newPuzzle);

  Future<void> _tapCell(GridPoint target) async {
    if (_finished || _paused || target == _player) return;
    final rowDelta = target.row - _player.row;
    final colDelta = target.col - _player.col;
    if (rowDelta.abs() + colDelta.abs() != 1) {
      setState(() => _message = 'Tap the next arrow cell');
      return;
    }

    final direction = _directionFor(_player, target);
    if (!_engine.canMove(_puzzle, _player, direction)) {
      await _feedback.wrongMove();
      if (!mounted) return;
      setState(() => _message = '❌ Wrong direction! Try another route.');
      return;
    }

    await _feedback.correctMove();
    if (!mounted) return;
    setState(() {
      _player = target;
      _visited.add(target);
      _hintPath.remove(target);
      _moves++;
      _message = target == _puzzle.finish ? '🎉 Level complete!' : '✓ Good move!';
    });
    if (target == _puzzle.finish) await _completeLevel();
  }

  Future<void> _showHintMenu() async {
    if (_finished || _paused) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text(
                '💡 Hint System',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.arrow_forward),
              title: const Text('Next correct move'),
              subtitle: Text('Free hints: $_freeHints'),
              onTap: () {
                Navigator.pop(sheetContext);
                _nextMoveHint();
              },
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('Correct path highlight'),
              subtitle: const Text('Shows the route from your position'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pathHint();
              },
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('Full solution hint'),
              subtitle: const Text('Costs 5 coins'),
              onTap: () {
                Navigator.pop(sheetContext);
                _fullSolutionHint();
              },
            ),
            ListTile(
              leading: const Icon(Icons.ondemand_video),
              title: const Text('Reward Ad → Hint'),
              subtitle: const Text('+1 hint after watching the ad'),
              onTap: () {
                Navigator.pop(sheetContext);
                _rewardAdHint();
              },
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on_outlined),
              title: const Text('Reward Ad → Coins'),
              subtitle: const Text('+20 coins after watching the ad'),
              onTap: () {
                Navigator.pop(sheetContext);
                _rewardAdCoins();
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _consumeHint() {
    if (_freeHints > 0) {
      setState(() => _freeHints--);
      return true;
    }
    return false;
  }

  void _nextMoveHint() {
    if (!_consumeHint()) {
      setState(() => _message = 'No free hints left. Use coins or Reward Ad.');
      return;
    }
    final index = _puzzle.solution.indexOf(_player);
    if (index >= 0 && index + 1 < _puzzle.solution.length) {
      final next = _puzzle.solution[index + 1];
      setState(() {
        _hintPath
          ..clear()
          ..add(next);
        _message = '💡 Hint: highlighted cell is your next move';
      });
    }
  }

  void _pathHint() {
    if (!_consumeHint()) {
      setState(() => _message = 'No free hints left. Use coins or Reward Ad.');
      return;
    }
    final index = _puzzle.solution.indexOf(_player);
    if (index >= 0) {
      setState(() {
        _hintPath
          ..clear()
          ..addAll(_puzzle.solution.skip(index + 1));
        _message = '💡 Correct path highlighted';
      });
    }
  }

  void _fullSolutionHint() {
    if (_coins < 5) {
      setState(() => _message = 'Need 5 coins for a full solution hint.');
      return;
    }
    setState(() {
      _coins -= 5;
      _showFullSolution = true;
      _hintPath
        ..clear()
        ..addAll(_puzzle.solution);
      _message = '💡 Full solution highlighted';
    });
  }

  Future<void> _rewardAdHint() async {
    if (_rewardAdLoading) return;
    setState(() {
      _rewardAdLoading = true;
      _message = 'Loading Reward Ad…';
    });
    final shown = await _ads.showRewarded(
      onReward: (_) {
        if (!mounted) return;
        final index = _puzzle.solution.indexOf(_player);
        setState(() {
          _freeHints++;
          if (index >= 0 && index + 1 < _puzzle.solution.length) {
            _hintPath
              ..clear()
              ..add(_puzzle.solution[index + 1]);
          }
          _message = '🎁 +1 hint!';
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _rewardAdLoading = false;
      if (!shown) _message = 'Reward Ad is not ready. Please try again shortly.';
    });
  }

  Future<void> _rewardAdCoins() async {
    if (_rewardAdLoading) return;
    setState(() {
      _rewardAdLoading = true;
      _message = 'Loading Reward Ad…';
    });
    final shown = await _ads.showRewarded(
      onReward: (_) {
        if (!mounted) return;
        setState(() {
          _coins += 20;
          _message = '🎁 +20 coins!';
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _rewardAdLoading = false;
      if (!shown) _message = 'Reward Ad is not ready. Please try again shortly.';
    });
  }

  Future<void> _pauseResume() async {
    if (_finished) return;
    if (_paused) {
      setState(() {
        _paused = false;
        _message = 'Game resumed';
      });
      return;
    }
    setState(() {
      _paused = true;
      _message = 'Game paused';
    });
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('⏸ Paused'),
        content: const Text('Your timer is paused.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restart();
            },
            child: const Text('RESTART'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) setState(() => _paused = false);
            },
            child: const Text('RESUME'),
          ),
        ],
      ),
    );
  }

  String _difficultyName() {
    if (widget.level <= 25) return 'EASY';
    if (widget.level <= 100) return 'MEDIUM';
    if (widget.level <= 500) return 'HARD';
    return 'EXTREME';
  }

  String _formatTime(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

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
      backgroundColor: const Color(0xFFF8F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F6),
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
        ),
        title: Text(
          'Level ${widget.level}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Hint',
            onPressed: _showHintMenu,
            icon: const Icon(Icons.lightbulb_outline_rounded),
          ),
          IconButton(
            tooltip: _paused ? 'Resume' : 'Pause',
            onPressed: _pauseResume,
            icon: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
          ),
          IconButton(
            tooltip: 'Restart',
            onPressed: _restart,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 4),
                Text(
                  'CLEAR THE BOARD',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 56),
                    Text(
                      'Level ${widget.level}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: IconButton(
                        onPressed: _showHintMenu,
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                  child: Row(
                    children: [
                      _InfoPill(icon: Icons.arrow_forward_rounded, text: '$_moves'),
                      const Spacer(),
                      const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 25),
                      const SizedBox(width: 5),
                      const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 25),
                      const SizedBox(width: 5),
                      const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 25),
                      const Spacer(),
                      _InfoPill(text: _difficultyName()),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
                  child: Row(
                    children: [
                      Text('⏱ ${_formatTime(_seconds)}'),
                      const Spacer(),
                      Text('🪙 $_coins', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Center(
                          child: AspectRatio(
                            aspectRatio: _puzzle.columns / _puzzle.rows,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (details) {
                                final box = context.findRenderObject() as RenderBox;
                                final local = box.globalToLocal(details.globalPosition);
                                final cellWidth = box.size.width / _puzzle.columns;
                                final cellHeight = box.size.height / _puzzle.rows;
                                final col = (local.dx / cellWidth).floor();
                                final row = (local.dy / cellHeight).floor();
                                if (row >= 0 && row < _puzzle.rows && col >= 0 && col < _puzzle.columns) {
                                  _tapCell(GridPoint(row, col));
                                }
                              },
                              child: CustomPaint(
                                painter: _ArrowBoardPainter(
                                  puzzle: _puzzle,
                                  player: _player,
                                  visited: _visited.toSet(),
                                  hints: _hintPath,
                                  showFullSolution: _showFullSolution,
                                  primary: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundAction(
                      icon: Icons.lightbulb_outline_rounded,
                      badge: _freeHints,
                      onTap: _showHintMenu,
                    ),
                    const SizedBox(width: 28),
                    _RoundAction(
                      icon: Icons.grid_3x3_rounded,
                      onTap: _restart,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Best ${_bestTime == null ? '--:--' : _formatTime(_bestTime!)}  •  $_bestScore pts',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
              ],
            ),
            if (_finished)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _winController,
                    builder: (_, __) => Center(
                      child: Transform.scale(
                        scale: 1 + (_winController.value * .25),
                        child: Opacity(
                          opacity: 1 - (_winController.value * .15),
                          child: const Icon(Icons.celebration, size: 110),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_paused) Positioned.fill(child: Container(color: Colors.black26)),
            if (_rewardAdLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black12,
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Loading ad…'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({this.icon, required this.text});
  final IconData? icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 19),
            const SizedBox(width: 6),
          ],
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap, this.badge});
  final IconData icon;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: 2,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 66,
              height: 66,
              child: Icon(icon, size: 31, color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
        if (badge != null && badge! > 0)
          Positioned(
            right: -2,
            top: -4,
            child: CircleAvatar(
              radius: 13,
              child: Text('$badge', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}

class _ArrowBoardPainter extends CustomPainter {
  const _ArrowBoardPainter({
    required this.puzzle,
    required this.player,
    required this.visited,
    required this.hints,
    required this.showFullSolution,
    required this.primary,
  });

  final ArrowPuzzle puzzle;
  final GridPoint player;
  final Set<GridPoint> visited;
  final Set<GridPoint> hints;
  final bool showFullSolution;
  final Color primary;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / puzzle.columns;
    final cellH = size.height / puzzle.rows;

    final dotPaint = Paint()
      ..color = const Color(0xFFD3D6D8)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0xFF10245B)
      ..strokeWidth = max(3.0, min(cellW, cellH) * .075)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final visitedPaint = Paint()
      ..color = primary.withValues(alpha: .22)
      ..strokeWidth = max(5.0, min(cellW, cellH) * .11)
      ..strokeCap = StrokeCap.round;
    final hintPaint = Paint()
      ..color = const Color(0xFF58B8FF)
      ..strokeWidth = max(5.0, min(cellW, cellH) * .12)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var r = 0; r < puzzle.rows; r++) {
      for (var c = 0; c < puzzle.columns; c++) {
        canvas.drawCircle(Offset((c + .5) * cellW, (r + .5) * cellH), 2.5, dotPaint);
      }
    }

    Offset center(GridPoint p) => Offset((p.col + .5) * cellW, (p.row + .5) * cellH);

    // Draw the visited route underneath the arrows.
    for (var i = 0; i < puzzle.solution.length - 1; i++) {
      final a = puzzle.solution[i];
      final b = puzzle.solution[i + 1];
      if (visited.contains(a) && visited.contains(b)) {
        canvas.drawLine(center(a), center(b), visitedPaint);
      }
    }

    // Draw each directed segment with a clean rounded line and arrowhead.
    for (final cell in puzzle.cells) {
      final from = GridPoint(cell.row, cell.col);
      for (final direction in cell.arrows) {
        final to = from.move(direction);
        if (!puzzle.contains(to)) continue;
        final a = center(from);
        final b = center(to);
        final isHint = hints.contains(from) || hints.contains(to) ||
            (showFullSolution && puzzle.solution.contains(from));
        final paint = isHint ? hintPaint : linePaint;
        canvas.drawLine(a, b, paint);
        _drawArrowHead(canvas, b, direction, paint);
      }
    }

    // Start marker and finish marker, kept subtle like the reference UI.
    final start = center(puzzle.start);
    final finish = center(puzzle.finish);
    final markerPaint = Paint()..color = primary;
    canvas.drawCircle(start, max(5, min(cellW, cellH) * .11), markerPaint);
    final finishPaint = Paint()
      ..color = const Color(0xFF45B66A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(finish, max(6, min(cellW, cellH) * .13), finishPaint);

    if (player != puzzle.start && player != puzzle.finish) {
      canvas.drawCircle(center(player), max(4, min(cellW, cellH) * .08), markerPaint);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset tip, ArrowDirection direction, Paint base) {
    final length = 9.0;
    final width = 6.0;
    final vector = switch (direction) {
      ArrowDirection.up => const Offset(0, -1),
      ArrowDirection.down => const Offset(0, 1),
      ArrowDirection.left => const Offset(-1, 0),
      ArrowDirection.right => const Offset(1, 0),
    };
    final side = Offset(-vector.dy, vector.dx);
    final p1 = tip - vector * length + side * width;
    final p2 = tip - vector * length - side * width;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    final fill = Paint()
      ..color = base.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant _ArrowBoardPainter oldDelegate) =>
      oldDelegate.puzzle != puzzle ||
      oldDelegate.player != player ||
      oldDelegate.visited.length != visited.length ||
      oldDelegate.hints.length != hints.length ||
      oldDelegate.showFullSolution != showFullSolution ||
      oldDelegate.primary != primary;
}
