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
  int get _totalArrows => _puzzle.cells.where((cell) => cell.arrows.isNotEmpty).length;
  int get _remaining => _totalArrows - _cleared.length;

  @override
  void initState() {
    super.initState();
    _winController = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _wrongController = AnimationController(vsync: this, duration: const Duration(milliseconds: 330));
    _clearController = AnimationController(vsync: this, duration: const Duration(milliseconds: 430));
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
    _puzzle = ArrowPuzzleEngine(random: random).generate(difficulty: _difficulty);
    _solution = _engine.findSolutionPath(_puzzle) ?? <GridPoint>[];
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
      if (mounted && !_finished && !_paused) setState(() => _seconds++);
    });
  }

  int _score() => max(100, 1000 + (_difficulty * 250) - (_moves * 5) - (_seconds * 2));

  Future<void> _completeLevel() async {
    _finished = true;
    _timer?.cancel();
    await _feedback.win();
    await _winController.forward();
    final score = _score();
    await LevelProgressService.instance.completeLevel(level: widget.level, score: score, timeSeconds: _seconds);
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
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Level ${widget.level} • ${_difficultyName()}'),
          const SizedBox(height: 10),
          Text('Score: $score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Time: ${_formatTime(_seconds)}'),
          Text('Moves: $_moves'),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _restart(); }, child: const Text('REPLAY')),
          FilledButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('LEVELS')),
        ],
      ),
    );
  }

  Future<void> _showWrongAnimation(GridPoint point) async {
    if (!mounted) return;
    setState(() { _wrongPoint = point; _message = '🔒 Blocked! Clear the arrow in front first.'; });
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
      _message = _remaining <= 1 ? '✨ One more arrow!' : '✓ Cleared! Find the next free arrow';
    });
    await _clearController.forward(from: 0);
    if (!mounted) return;
    setState(() => _clearingPoint = null);
  }

  Future<void> _tapArrow(GridPoint point) async {
    if (_finished || _paused || _cleared.contains(point) || _clearingPoint != null) return;
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
        setState(() => _message = '💔 No hearts left — restarting this level…');
        await Future<void>.delayed(const Duration(milliseconds: 650));
        if (!mounted) return;
        setState(_newPuzzle);
      }
      return;
    }
    unawaited(_feedback.clearArrow());
    await _showClearAnimation(point);
    if (_cleared.length >= _totalArrows) await _completeLevel();
  }

  bool _consumeHint() {
    if (_freeHints <= 0) return false;
    setState(() => _freeHints--);
    return true;
  }

  void _nextHint() {
    if (!_consumeHint()) { setState(() => _message = 'No free hints left.'); return; }
    final next = _solution.where((p) => !_cleared.contains(p)).firstOrNull;
    if (next != null) setState(() { _hintPath..clear()..add(next); _message = '💡 This arrow can be cleared now'; });
  }

  void _pathHint() {
    if (!_consumeHint()) { setState(() => _message = 'No free hints left.'); return; }
    setState(() { _hintPath..clear()..addAll(_solution.where((p) => !_cleared.contains(p))); _message = '💡 Valid clearing order highlighted'; });
  }

  void _fullSolutionHint() {
    if (_coins < 5) { setState(() => _message = 'Need 5 coins for a full solution hint.'); return; }
    setState(() { _coins -= 5; _hintPath..clear()..addAll(_solution.where((p) => !_cleared.contains(p))); _message = '💡 Full solution highlighted'; });
  }

  Future<void> _rewardAdHint() async {
    if (_rewardAdLoading) return;
    setState(() { _rewardAdLoading = true; _message = 'Loading Reward Ad…'; });
    final shown = await _ads.showRewarded(onReward: (_) {
      if (!mounted) return;
      final next = _solution.where((p) => !_cleared.contains(p)).firstOrNull;
      setState(() { _freeHints++; if (next != null) _hintPath..clear()..add(next); _message = '🎁 +1 hint!'; });
    });
    if (!mounted) return;
    setState(() { _rewardAdLoading = false; if (!shown) _message = 'Reward Ad is not ready. Try again shortly.'; });
  }

  Future<void> _showHintMenu() async {
    if (_finished || _paused) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(child: Wrap(children: [
        const ListTile(title: Text('💡 Helpful Hints', style: TextStyle(fontWeight: FontWeight.bold))),
        ListTile(leading: const Icon(Icons.lightbulb_outline), title: const Text('Next free arrow'), subtitle: Text('Free hints: $_freeHints'), onTap: () { Navigator.pop(sheetContext); _nextHint(); }),
        ListTile(leading: const Icon(Icons.route), title: const Text('Show clear path'), subtitle: const Text('Highlights a valid clearing order'), onTap: () { Navigator.pop(sheetContext); _pathHint(); }),
        ListTile(leading: const Icon(Icons.monetization_on_outlined), title: const Text('Full solution'), subtitle: const Text('Costs 5 coins'), onTap: () { Navigator.pop(sheetContext); _fullSolutionHint(); }),
        ListTile(leading: const Icon(Icons.ondemand_video), title: const Text('Reward Ad → Hint'), subtitle: const Text('+1 hint after watching the ad'), onTap: () { Navigator.pop(sheetContext); _rewardAdHint(); }),
      ])),
    );
  }

  Future<void> _pauseResume() async {
    if (_finished) return;
    if (_paused) { setState(() { _paused = false; _message = 'Game resumed'; }); return; }
    setState(() { _paused = true; _message = 'Game paused'; });
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('⏸ Paused'),
        content: const Text('Your timer is paused.'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _restart(); }, child: const Text('RESTART')),
          FilledButton(onPressed: () { Navigator.pop(context); if (mounted) setState(() => _paused = false); }, child: const Text('RESUME')),
        ],
      ),
    );
  }

  void _restart() => setState(_newPuzzle);

  String _difficultyName() {
    if (_difficulty <= 5) return 'MEDIUM';
    if (_difficulty <= 8) return 'HARD';
    return 'EXTREME';
  }

  String _formatTime(int seconds) => '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5EA),
        elevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
        title: Text('Level ${widget.level}', style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _showHintMenu, icon: const Icon(Icons.lightbulb_outline_rounded)),
          IconButton(onPressed: _pauseResume, icon: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded)),
          IconButton(onPressed: _restart, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            const SizedBox(height: 4),
            Text('CLEAR\nTHE BOARD', textAlign: TextAlign.center, style: TextStyle(fontSize: 34, height: .95, fontWeight: FontWeight.w900, color: scheme.onSurface)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const SizedBox(width: 60),
              Text('Level ${widget.level}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Padding(padding: const EdgeInsets.only(right: 12), child: IconButton(onPressed: _showHintMenu, icon: const Icon(Icons.settings_outlined))),
            ]),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: Row(children: [
              _Pill(icon: Icons.arrow_forward_rounded, text: '$_remaining'),
              const Spacer(),
              Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (index) {
                final alive = index < _hearts;
                return Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child), child: Icon(alive ? Icons.favorite_rounded : Icons.heart_broken_rounded, key: ValueKey('$index-$alive'), color: alive ? Colors.redAccent : Colors.grey, size: 25)));
              })),
              const Spacer(),
              _Pill(text: _difficultyName()),
            ])),
            Padding(padding: const EdgeInsets.fromLTRB(18, 8, 18, 0), child: Row(children: [Text('⏱ ${_formatTime(_seconds)}', style: const TextStyle(fontWeight: FontWeight.w600)), const Spacer(), Text('🪙 $_coins', style: const TextStyle(fontWeight: FontWeight.w700))])),
            Expanded(child: Center(child: AspectRatio(
              aspectRatio: _puzzle.columns / _puzzle.rows,
              child: Padding(padding: const EdgeInsets.all(12), child: AnimatedBuilder(
                animation: Listenable.merge([_wrongController, _clearController]),
                builder: (context, child) => Transform.translate(
                  offset: Offset(_wrongPoint == null ? 0 : sin(_wrongController.value * pi * 6) * 7, 0),
                  child: CustomPaint(
                    painter: _ArrowBoardPainter(puzzle: _puzzle, cleared: _cleared, hints: _hintPath, wrongPoint: _wrongPoint, wrongProgress: _wrongController.value, clearingPoint: _clearingPoint, clearProgress: _clearController.value),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _puzzle.rows * _puzzle.columns,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _puzzle.columns),
                      itemBuilder: (_, index) {
                        final point = GridPoint(index ~/ _puzzle.columns, index % _puzzle.columns);
                        final hasArrow = _puzzle.cellAt(point).arrows.isNotEmpty;
                        return GestureDetector(behavior: HitTestBehavior.opaque, onTap: hasArrow ? () => _tapArrow(point) : null, child: const SizedBox.expand());
                      },
                    ),
                  ),
                ),
              ),
            ))),
            Text(_message, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 18), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_RoundButton(icon: Icons.lightbulb_outline_rounded, badge: _freeHints, onTap: _showHintMenu), _RoundButton(icon: Icons.grid_3x3_rounded, onTap: _restart)])),
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Best ${_bestTime == null ? '--:--' : _formatTime(_bestTime!)}  •  Score $_bestScore', style: TextStyle(color: scheme.onSurfaceVariant))),
          ]),
          if (_finished) Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(animation: _winController, builder: (_, __) => Center(child: Transform.scale(scale: 1 + _winController.value * .2, child: Opacity(opacity: 1 - _winController.value * .1, child: const Icon(Icons.celebration, size: 110))))))),
          if (_wrongPoint != null) Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(animation: _wrongController, builder: (_, __) => Container(color: Colors.red.withValues(alpha: (1 - _wrongController.value) * .10))))),
          if (_paused) const Positioned.fill(child: ColoredBox(color: Colors.black26)),
          if (_rewardAdLoading) const Positioned.fill(child: ColoredBox(color: Colors.black12)),
        ]),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({this.icon, required this.text});
  final IconData? icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)), child: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) Icon(icon, size: 17), if (icon != null) const SizedBox(width: 5), Text(text, style: const TextStyle(fontWeight: FontWeight.w700))]));
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, this.badge, this.onTap});
  final IconData icon;
  final int? badge;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [Material(color: Colors.white, elevation: 4, shape: const CircleBorder(), child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: SizedBox(width: 76, height: 76, child: Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary)))), if (badge != null) Positioned(right: -2, top: -4, child: CircleAvatar(radius: 14, child: Text('$badge', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))))]);
}

class _ArrowBoardPainter extends CustomPainter {
  const _ArrowBoardPainter({required this.puzzle, required this.cleared, required this.hints, this.wrongPoint, this.wrongProgress = 1, this.clearingPoint, this.clearProgress = 0});
  final ArrowPuzzle puzzle;
  final Set<GridPoint> cleared;
  final Set<GridPoint> hints;
  final GridPoint? wrongPoint;
  final double wrongProgress;
  final GridPoint? clearingPoint;
  final double clearProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / puzzle.columns;
    final cellH = size.height / puzzle.rows;
    final unit = min(cellW, cellH);

    for (var r = 0; r < puzzle.rows; r++) {
      for (var c = 0; c < puzzle.columns; c++) {
        final p = GridPoint(r, c);
        if (cleared.contains(p) && p != clearingPoint) continue;
        final cell = puzzle.cellAt(p);
        if (cell.arrows.isEmpty) continue;
        final direction = cell.arrows.first;
        final isClearing = p == clearingPoint;
        final isWrong = p == wrongPoint;
        final highlighted = hints.contains(p);

        final pulse = isWrong ? sin(wrongProgress * pi) : 0.0;
        final color = isWrong
            ? Color.lerp(const Color(0xFF4B4137), const Color(0xFFD83A3A), pulse)!
            : highlighted
                ? const Color(0xFFE24A4A)
                : const Color(0xFF4B4137);
        var opacity = 1.0;
        var shift = Offset.zero;
        if (isClearing) {
          final eased = Curves.easeInCubic.transform(clearProgress);
          opacity = 1 - clearProgress;
          shift = Offset(direction.colDelta * unit * 1.1 * eased, direction.rowDelta * unit * 1.1 * eased);
        }

        final stroke = Paint()
          ..color = color.withValues(alpha: opacity)
          ..strokeWidth = max(2.0, unit * .065)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        final center = Offset((p.col + .5) * cellW, (p.row + .5) * cellH) + shift;
        final ux = direction.colDelta.toDouble();
        final uy = direction.rowDelta.toDouble();
        final side = Offset(-uy, ux);

        // Keep the entire visual mark inside its own tile. No path is allowed
        // to travel through neighbouring tiles, so arrows never cut/cross.
        final tail = center - Offset(ux, uy) * unit * .34;
        final bend = center - Offset(ux, uy) * unit * .10 + side * unit * .22;
        final end = center - Offset(ux, uy) * unit * .10;
        final localPath = Path()..moveTo(tail.dx, tail.dy)..lineTo(bend.dx, bend.dy)..lineTo(end.dx, end.dy);
        canvas.drawPath(localPath, stroke);

        final headBack = center - Offset(ux, uy) * unit * .28;
        final head = Path()
          ..moveTo(center.dx + ux * unit * .03, center.dy + uy * unit * .03)
          ..lineTo(headBack.dx + side.dx * unit * .16, headBack.dy + side.dy * unit * .16)
          ..lineTo(headBack.dx - side.dx * unit * .16, headBack.dy - side.dy * unit * .16)
          ..close();
        canvas.drawPath(head, Paint()..color = color.withValues(alpha: opacity));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArrowBoardPainter oldDelegate) =>
      oldDelegate.puzzle != puzzle || oldDelegate.cleared != cleared || oldDelegate.hints != hints || oldDelegate.wrongPoint != wrongPoint || oldDelegate.wrongProgress != wrongProgress || oldDelegate.clearingPoint != clearingPoint || oldDelegate.clearProgress != clearProgress;
}
