import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/arrow_puzzle_engine.dart';
import '../models/arrow_direction.dart';
import '../services/ad_service.dart';
import '../services/gameplay_feedback_service.dart';
import '../services/level_progress_service.dart';

extension _ArrowDirectionVector on ArrowDirection {
  Offset get vector {
    switch (this) {
      case ArrowDirection.up:
        return const Offset(0, -1);
      case ArrowDirection.down:
        return const Offset(0, 1);
      case ArrowDirection.left:
        return const Offset(-1, 0);
      case ArrowDirection.right:
        return const Offset(1, 0);
    }
  }
}

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
  late List<GridPoint> _solution;
  final Set<GridPoint> _cleared = <GridPoint>{};
  final Set<GridPoint> _hintPath = <GridPoint>{};
  Timer? _timer;
  int _seconds = 0;
  int _moves = 0;
  int _freeHints = 3;
  int _coins = 20;
  int _hearts = 3;
  int _bestScore = 0;
  int? _bestTime;
  bool _finished = false;
  bool _paused = false;
  bool _rewardAdLoading = false;
  GridPoint? _wrongPoint;
  GridPoint? _clearingPoint;
  String _message = 'Tap a free arrow to clear it';
  late AnimationController _winController;
  late AnimationController _wrongController;
  late AnimationController _clearController;

  int get _difficulty => min(10, 6 + ((widget.level - 1) ~/ 10));
  int get _totalArrows =>
      _puzzle.cells.where((cell) => cell.arrows.isNotEmpty).length;
  int get _remaining => _totalArrows - _cleared.length;

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
    _loadLevel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _winController.dispose();
    _wrongController.dispose();
    _clearController.dispose();
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
    _solution = _engine.findSolutionPath(_puzzle);
    _cleared.clear();
    _hintPath.clear();
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
    setState(() {
      _bestScore = max(_bestScore, score);
      _bestTime = _bestTime == null ? _seconds : min(_bestTime!, _seconds);
    });
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🎉 Level Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Level ${widget.level} • ${_difficultyName}'),
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
              _restart();
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

  Future<void> _showWrongAnimation(GridPoint point) async {
    if (!mounted) return;
    setState(() {
      _wrongPoint = point;
      _message = '🔒 Blocked! Clear the arrow in front first.';
    });
    await _wrongController.forward(from: 0);
    if (!mounted) return;
    setState(() => _wrongPoint = null);
  }

  Future<void> _showClearAnimation(GridPoint point) async {
    if (!mounted) return;
    setState(() {
      _clearingPoint = point;
      _cleared.add(point);
      _hintPath.remove(point);
      _moves++;
      _message = _remaining <= 1
          ? '✨ One more arrow!'
          : '✓ Cleared! Find the next free arrow';
    });
    await _clearController.forward(from: 0);
    if (!mounted) return;
    setState(() => _clearingPoint = null);
  }

  Future<void> _tapArrow(GridPoint point) async {
    if (_finished || _paused || _cleared.contains(point) || _clearingPoint != null) {
      return;
    }
    final cell = _puzzle.cellAt(point);
    if (cell.arrows.isEmpty) return;

    if (!_engine.canClear(_puzzle, point, _cleared)) {
      await _feedback.wrongMove();
      if (!mounted) return;
      setState(() => _hearts = _feedback.lives);
      await _showWrongAnimation(point);
      if (!mounted) return;
      if (_hearts <= 0) {
        await Future<void>.delayed(const Duration(milliseconds: 220));
        if (!mounted) return;
        setState(
          () => _message = '💔 No hearts left — restarting this level…',
        );
        await Future<void>.delayed(const Duration(milliseconds: 650));
        if (!mounted) return;
        setState(_newPuzzle);
      }
      return;
    }

    unawaited(_feedback.clearArrow());
    await _showClearAnimation(point);
    if (_cleared.length >= _totalArrows) {
      await _completeLevel();
    }
  }

  bool _consumeHint() {
    if (_freeHints <= 0) return false;
    setState(() => _freeHints--);
    return true;
  }

  void _nextHint() {
    if (!_consumeHint()) {
      setState(() => _message = 'No free hints left.');
      return;
    }
    final next = _solution
        .where((point) => !_cleared.contains(point))
        .firstOrNull;
    if (next != null) {
      setState(() {
        _hintPath
          ..clear()
          ..add(next);
        _message = '💡 This arrow can be cleared now';
      });
    }
  }

  void _pathHint() {
    if (!_consumeHint()) {
      setState(() => _message = 'No free hints left.');
      return;
    }
    setState(() {
      _hintPath
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
    setState(() {
      _coins -= 5;
      _hintPath
        ..clear()
        ..addAll(_solution.where((point) => !_cleared.contains(point)));
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
        final next = _solution
            .where((point) => !_cleared.contains(point))
            .firstOrNull;
        setState(() {
          _freeHints++;
          if (next != null) {
            _hintPath
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
              _restart();
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

  void _restart() => setState(_newPuzzle);

  String get _difficultyName {
    if (_difficulty <= 5) return 'MEDIUM';
    if (_difficulty <= 8) return 'HARD';
    return 'EXTREME';
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
            onPressed: _restart,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 4),
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CLEAR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'THE BOARD',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  _Pill(
                    icon: Icons.arrow_forward_rounded,
                    text: '$_remaining',
                  ),
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
                    padding: const EdgeInsets.all(12),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _wrongController,
                        _clearController,
                      ]),
                      builder: (context, child) {
                        return Transform.translate(
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
                              hints: _hintPath,
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
                        );
                      },
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
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
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

  @override
  void paint(Canvas canvas, Size size) {
    if (puzzle.rows <= 0 || puzzle.columns <= 0) return;

    final cellWidth = size.width / puzzle.columns;
    final cellHeight = size.height / puzzle.rows;

    final backgroundPaint = Paint()..color = const Color(0xFFF8F5EA);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    for (var row = 0; row < puzzle.rows; row++) {
      for (var col = 0; col < puzzle.columns; col++) {
        final point = GridPoint(row, col);
        final cell = puzzle.cellAt(point);

        if (cell.arrows.isEmpty || cleared.contains(point)) continue;

        final center = Offset(
          col * cellWidth + cellWidth / 2,
          row * cellHeight + cellHeight / 2,
        );
        final direction = cell.arrows.first;

        final isHint = hints.contains(point);
        final isWrong = wrongPoint == point;
        final isClearing = clearingPoint == point;

        final length = min(cellWidth, cellHeight) * 0.72;
        final start = center - direction.vector * (length * 0.38);
        final end = center + direction.vector * (length * 0.38);

        final pathPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = min(cellWidth, cellHeight) * 0.13
          ..strokeCap = StrokeCap.round
          ..color = isHint
              ? Colors.amber.shade700
              : isWrong
                  ? Colors.redAccent
                  : const Color(0xFF102A43);

        if (isClearing) {
          pathPaint.strokeWidth *= 1 - clearProgress * 0.55;
          pathPaint.color = const Color(0xFF102A43).withValues(
            alpha: 1 - clearProgress,
          );
        }

        if (isWrong) {
          pathPaint.strokeWidth *= 1 + sin(wrongProgress * pi) * 0.25;
        }

        canvas.drawLine(start, end, pathPaint);

        final headSize = min(cellWidth, cellHeight) * 0.25;
        final tip = end + direction.vector * headSize * 0.45;
        final perpendicular = Offset(
          -direction.vector.dy,
          direction.vector.dx,
        );

        final arrowPath = Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(
            tip.dx - direction.vector.dx * headSize +
                perpendicular.dx * headSize * 0.62,
            tip.dy - direction.vector.dy * headSize +
                perpendicular.dy * headSize * 0.62,
          )
          ..lineTo(
            tip.dx - direction.vector.dx * headSize -
                perpendicular.dx * headSize * 0.62,
            tip.dy - direction.vector.dy * headSize -
                perpendicular.dy * headSize * 0.62,
          )
          ..close();

        final fillPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = pathPaint.color;
        canvas.drawPath(arrowPath, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArrowBoardPainter oldDelegate) {
    return oldDelegate.puzzle != puzzle ||
        oldDelegate.cleared != cleared ||
        oldDelegate.hints != hints ||
        oldDelegate.wrongPoint != wrongPoint ||
        oldDelegate.wrongProgress != wrongProgress ||
        oldDelegate.clearingPoint != clearingPoint ||
        oldDelegate.clearProgress != clearProgress;
  }
}
