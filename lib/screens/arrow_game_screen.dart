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
  final GameplayFeedbackService _feedback = GameplayFeedbackService.instance;
  final AdService _ads = AdService.instance;

  late ArrowPuzzle _puzzle;
  late List<GridPoint> _solution;
  final Set<GridPoint> _cleared = <GridPoint>{};
  final Set<GridPoint> _hints = <GridPoint>{};

  Timer? _timer;
  int _seconds = 0;
  int _moves = 0;
  int _freeHints = 3;
  int _coins = 20;
  int _hearts = 3;
  bool _finished = false;
  bool _paused = false;
  bool _rewardAdLoading = false;
  GridPoint? _wrongPoint;
  GridPoint? _clearingPoint;
  String _message = 'Tap a free arrow to clear it';

  late final AnimationController _winController;
  late final AnimationController _wrongController;
  late final AnimationController _clearController;

  int get _difficulty => min(10, 6 + ((widget.level - 1) ~/ 10));
  int get _totalArrows =>
      _puzzle.cells.where((cell) => cell.arrows.isNotEmpty).length;
  int get _remaining => max(0, _totalArrows - _cleared.length);
  String get _difficultyName => _difficulty <= 8 ? 'HARD' : 'EXTREME';

  @override
  void initState() {
    super.initState();
    _winController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _wrongController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 330),
    );
    _clearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 430),
    );
    _newPuzzle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _winController.dispose();
    _wrongController.dispose();
    _clearController.dispose();
    super.dispose();
  }

  void _newPuzzle() {
    _timer?.cancel();
    final random = Random(widget.level * 1000003 + _difficulty);
    _puzzle = ArrowPuzzleEngine(
      random: random,
    ).generate(difficulty: _difficulty);
    _solution = _engine.findSolutionPath(_puzzle);
    _cleared.clear();
    _hints.clear();
    _wrongPoint = null;
    _clearingPoint = null;
    _seconds = 0;
    _moves = 0;
    _hearts = 3;
    _feedback.resetLives();
    _finished = false;
    _paused = false;
    _message = 'Tap a free arrow to clear it';
    _winController.reset();
    _wrongController.reset();
    _clearController.reset();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_finished && !_paused) {
        setState(() => _seconds++);
      }
    });
  }

  int _score() =>
      max(100, 1000 + (_difficulty * 250) - (_moves * 5) - (_seconds * 2));

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

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🎉 Level Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Level ${widget.level} • $_difficultyName'),
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
              Navigator.pop(dialogContext);
              setState(_newPuzzle);
            },
            child: const Text('REPLAY'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('LEVELS'),
          ),
        ],
      ),
    );
  }

  Future<void> _tapArrow(GridPoint point) async {
    if (_finished ||
        _paused ||
        _cleared.contains(point) ||
        _clearingPoint != null) {
      return;
    }
    if (_puzzle.cellAt(point).arrows.isEmpty) return;

    if (!_engine.canClear(_puzzle, point, _cleared)) {
      await _feedback.wrongMove();
      if (!mounted) return;
      setState(() {
        _hearts = _feedback.lives;
        _wrongPoint = point;
        _message = '🔒 Blocked — clear the arrow in front first';
      });
      await _wrongController.forward(from: 0);
      if (!mounted) return;
      setState(() => _wrongPoint = null);
      if (_hearts <= 0) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (mounted) setState(_newPuzzle);
      }
      return;
    }

    unawaited(_feedback.clearArrow());
    setState(() {
      _clearingPoint = point;
      _cleared.add(point);
      _hints.remove(point);
      _moves++;
      _message = _remaining <= 1
          ? '✨ One more arrow!'
          : '✓ Cleared! Find the next free arrow';
    });
    await _clearController.forward(from: 0);
    if (!mounted) return;
    setState(() => _clearingPoint = null);
    if (_cleared.length >= _totalArrows) {
      await _completeLevel();
    }
  }

  bool _useFreeHint() {
    if (_freeHints <= 0) return false;
    setState(() => _freeHints--);
    return true;
  }

  GridPoint? _nextSolutionPoint() {
    for (final point in _solution) {
      if (!_cleared.contains(point)) return point;
    }
    return null;
  }

  void _nextHint() {
    if (!_useFreeHint()) {
      setState(() => _message = 'No free hints left.');
      return;
    }
    final next = _nextSolutionPoint();
    if (next == null) return;
    setState(() {
      _hints
        ..clear()
        ..add(next);
      _message = '💡 This arrow can be cleared now';
    });
  }

  void _pathHint() {
    if (!_useFreeHint()) {
      setState(() => _message = 'No free hints left.');
      return;
    }
    setState(() {
      _hints
        ..clear()
        ..addAll(_solution.where((point) => !_cleared.contains(point)));
      _message = '💡 Valid clearing order highlighted';
    });
  }

  void _fullSolutionHint() {
    if (_coins < 5) {
      setState(() => _message = 'Need 5 coins for a full solution hint.');
      return;
    }
    final remaining = _solution.where((point) => !_cleared.contains(point));
    setState(() {
      _coins -= 5;
      _hints
        ..clear()
        ..addAll(remaining);
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
        final next = _nextSolutionPoint();
        setState(() {
          _freeHints++;
          if (next != null) {
            _hints
              ..clear()
              ..add(next);
          }
          _message = '🎁 +1 hint!';
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _rewardAdLoading = false;
      if (!shown) _message = 'Reward Ad is not ready. Try again shortly.';
    });
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
                '💡 Helpful Hints',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: const Text('Next free arrow'),
              subtitle: Text('Free hints: $_freeHints'),
              onTap: () {
                Navigator.pop(sheetContext);
                _nextHint();
              },
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('Show clear path'),
              subtitle: const Text('Highlights a valid clearing order'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pathHint();
              },
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on_outlined),
              title: const Text('Full solution'),
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
          ],
        ),
      ),
    );
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('⏸ Paused'),
        content: const Text('Your timer is paused.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(_newPuzzle);
            },
            child: const Text('RESTART'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (mounted) setState(() => _paused = false);
            },
            child: const Text('RESUME'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5EA),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          'Level ${widget.level}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showHintMenu,
            icon: const Icon(Icons.lightbulb_outline_rounded),
          ),
          IconButton(
            onPressed: _pauseResume,
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
          ),
          IconButton(
            onPressed: () => setState(_newPuzzle),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 4),
            const Text(
              'CLEAR\nTHE BOARD',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                height: .95,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  _Pill(icon: Icons.arrow_forward_rounded, text: '$_remaining'),
                  const Spacer(),
                  _Hearts(count: _hearts),
                  const Spacer(),
                  _Pill(text: _difficultyName),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: Row(
                children: [
                  Text(
                    '⏱ ${_formatTime(_seconds)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '🪙 $_coins',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: _puzzle.columns / _puzzle.rows,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _wrongController,
                        _clearController,
                      ]),
                      builder: (context, _) => Transform.translate(
                        offset: Offset(
                          _wrongPoint == null
                              ? 0
                              : sin(_wrongController.value * pi * 6) * 7,
                          0,
                        ),
                        child: CustomPaint(
                          painter: _ArrowBoardPainter(
                            puzzle: _puzzle,
                            cleared: _cleared,
                            hints: _hints,
                            wrongPoint: _wrongPoint,
                            wrongProgress: _wrongController.value,
                            clearingPoint: _clearingPoint,
                            clearProgress: _clearController.value,
                          ),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _puzzle.rows * _puzzle.columns,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _puzzle.columns,
                                ),
                            itemBuilder: (_, index) {
                              final point = GridPoint(
                                index ~/ _puzzle.columns,
                                index % _puzzle.columns,
                              );
                              final hasArrow = _puzzle
                                  .cellAt(point)
                                  .arrows
                                  .isNotEmpty;
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: hasArrow ? () => _tapArrow(point) : null,
                                child: const SizedBox.expand(),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Text(
                _message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({this.icon, required this.text});

  final IconData? icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 17), const SizedBox(width: 5)],
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Hearts extends StatelessWidget {
  const _Hearts({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final alive = index < count;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            alive ? Icons.favorite_rounded : Icons.heart_broken_rounded,
            color: alive ? Colors.redAccent : Colors.grey,
            size: 25,
          ),
        );
      }),
    );
  }
}

class _ArrowBoardPainter extends CustomPainter {
  _ArrowBoardPainter({
    required this.puzzle,
    required this.cleared,
    required this.hints,
    required this.wrongPoint,
    required this.wrongProgress,
    required this.clearingPoint,
    required this.clearProgress,
  });

  final ArrowPuzzle puzzle;
  final Set<GridPoint> cleared;
  final Set<GridPoint> hints;
  final GridPoint? wrongPoint;
  final double wrongProgress;
  final GridPoint? clearingPoint;
  final double clearProgress;

  Offset _center(GridPoint p, double w, double h) =>
      Offset(p.col * w + w / 2, p.row * h + h / 2);

  @override
  void paint(Canvas canvas, Size size) {
    if (puzzle.rows <= 0 || puzzle.columns <= 0) return;

    final w = size.width / puzzle.columns;
    final h = size.height / puzzle.rows;
    final unit = min(w, h);
    const baseColor = Color(0xFF102A43);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF8F5EA),
    );

    for (var row = 0; row < puzzle.rows; row++) {
      for (var col = 0; col < puzzle.columns; col++) {
        final origin = GridPoint(row, col);
        final cell = puzzle.cellAt(origin);
        if (cell.arrows.isEmpty || cleared.contains(origin)) continue;

        final points = puzzle.paths[origin];
        if (points == null || points.length < 2) continue;

        final isHint = hints.contains(origin);
        final isWrong = wrongPoint == origin;
        final isClearing = clearingPoint == origin;
        var color = baseColor;
        if (isHint) color = Colors.amber.shade700;
        if (isWrong) color = Colors.redAccent;

        final stroke = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit * .14
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color;

        if (isWrong) {
          stroke.strokeWidth *= 1 + sin(wrongProgress * pi) * .28;
        }
        if (isClearing) {
          stroke.strokeWidth *= 1 - clearProgress * .55;
          stroke.color = baseColor.withValues(alpha: 1 - clearProgress);
        }

        final path = Path();
        final first = _center(points.first, w, h);
        path.moveTo(first.dx, first.dy);
        for (final point in points.skip(1)) {
          final next = _center(point, w, h);
          path.lineTo(next.dx, next.dy);
        }
        canvas.drawPath(path, stroke);

        final tip = _center(points.last, w, h);
        final previous = _center(points[points.length - 2], w, h);
        final delta = tip - previous;
        final distance = delta.distance;
        if (distance == 0) continue;

        final direction = delta / distance;
        final side = Offset(-direction.dy, direction.dx);
        final head = unit * .33;
        final headPath = Path()
          ..moveTo(
            tip.dx + direction.dx * head * .58,
            tip.dy + direction.dy * head * .58,
          )
          ..lineTo(
            tip.dx - direction.dx * head + side.dx * head * .62,
            tip.dy - direction.dy * head + side.dy * head * .62,
          )
          ..lineTo(
            tip.dx - direction.dx * head - side.dx * head * .62,
            tip.dy - direction.dy * head - side.dy * head * .62,
          )
          ..close();

        canvas.drawPath(
          headPath,
          Paint()
            ..style = PaintingStyle.fill
            ..color = stroke.color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArrowBoardPainter oldDelegate) => true;
}
