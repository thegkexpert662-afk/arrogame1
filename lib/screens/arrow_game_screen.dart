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
    _puzzle = ArrowPuzzleEngine(random: random).generate(difficulty: _difficulty);
    _player = _puzzle.start;
    _visited..clear()..add(_player);
    _hintPath.clear();
    _seconds = 0;
    _moves = 0;
    _finished = false;
    _paused = false;
    _showFullSolution = false;
    _message = 'Follow the arrows to reach FINISH';
    _winController.reset();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_finished && !_paused) setState(() => _seconds++);
    });
  }

  int _score() => max(100, 1000 + (_difficulty * 250) - (_moves * 8) - (_seconds * 2));

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
            Text('Score: $score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Time: ${_formatTime(_seconds)}'),
            Text('Moves: $_moves'),
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

  Future<void> _tapCell(GridPoint target) async {
    if (_finished || _paused || target == _player) return;
    final rowDelta = target.row - _player.row;
    final colDelta = target.col - _player.col;
    if (rowDelta.abs() + colDelta.abs() != 1) {
      setState(() => _message = 'Move to a nearby arrow cell');
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
        child: Wrap(children: [
          const ListTile(title: Text('💡 Hint System', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(leading: const Icon(Icons.arrow_forward), title: const Text('Next correct move'), subtitle: Text('Free hints: $_freeHints'), onTap: () { Navigator.pop(sheetContext); _nextMoveHint(); }),
          ListTile(leading: const Icon(Icons.route), title: const Text('Correct path highlight'), subtitle: const Text('Shows the route from your position'), onTap: () { Navigator.pop(sheetContext); _pathHint(); }),
          ListTile(leading: const Icon(Icons.lightbulb), title: const Text('Full solution hint'), subtitle: const Text('Costs 5 coins'), onTap: () { Navigator.pop(sheetContext); _fullSolutionHint(); }),
          ListTile(leading: const Icon(Icons.ondemand_video), title: const Text('Reward Ad → Hint'), subtitle: const Text('+1 hint after watching the ad'), onTap: () { Navigator.pop(sheetContext); _rewardAdHint(); }),
          ListTile(leading: const Icon(Icons.monetization_on_outlined), title: const Text('Reward Ad → Coins'), subtitle: const Text('+20 coins after watching the ad'), onTap: () { Navigator.pop(sheetContext); _rewardAdCoins(); }),
        ]),
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
      setState(() { _hintPath..clear()..add(next); _message = '💡 Hint: move to the highlighted cell'; });
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
        _hintPath..clear()..addAll(_puzzle.solution.skip(index + 1));
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
      _hintPath..clear()..addAll(_puzzle.solution);
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
        if (index >= 0 && index + 1 < _puzzle.solution.length) {
          setState(() {
            _freeHints++;
            _hintPath..clear()..add(_puzzle.solution[index + 1]);
            _message = '🎁 +1 hint!';
          });
        } else {
          setState(() { _freeHints++; _message = '🎁 +1 hint!'; });
        }
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
      setState(() { _paused = false; _message = 'Game resumed'; });
      return;
    }
    setState(() { _paused = true; _message = 'Game paused'; });
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('⏸ Paused'),
        content: const Text('Your timer is paused.'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _restart(); }, child: const Text('RESTART')),
          FilledButton(onPressed: () { Navigator.pop(context); setState(() => _paused = false); }, child: const Text('RESUME')),
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

  String _formatTime(int seconds) => '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

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
        actions: [
          IconButton(tooltip: 'Hint', onPressed: _showHintMenu, icon: const Icon(Icons.lightbulb_outline)),
          IconButton(tooltip: _paused ? 'Resume' : 'Pause', onPressed: _pauseResume, icon: Icon(_paused ? Icons.play_arrow : Icons.pause)),
          IconButton(tooltip: 'Restart', onPressed: _restart, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 6), child: Row(children: [
              Chip(label: Text(_difficultyName())), const SizedBox(width: 6), Text('⏱ ${_formatTime(_seconds)}'), const Spacer(), Text('Moves $_moves', style: const TextStyle(fontWeight: FontWeight.bold)),
            ])),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3), child: Row(children: [Expanded(child: Text(_message)), Text('🪙 $_coins', style: const TextStyle(fontWeight: FontWeight.bold))])),
            Expanded(child: Center(child: AspectRatio(aspectRatio: _puzzle.columns / _puzzle.rows, child: Padding(padding: const EdgeInsets.all(10), child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(), itemCount: _puzzle.rows * _puzzle.columns,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _puzzle.columns),
              itemBuilder: (context, index) {
                final point = GridPoint(index ~/ _puzzle.columns, index % _puzzle.columns);
                final cell = _puzzle.cellAt(point);
                final isPlayer = point == _player;
                final isStart = point == _puzzle.start;
                final isFinish = point == _puzzle.finish;
                final isVisited = _visited.contains(point);
                final isHint = _hintPath.contains(point) || (_showFullSolution && _puzzle.solution.contains(point));
                return GestureDetector(
                  onTap: () => _tapCell(point),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 220), margin: const EdgeInsets.all(2), decoration: BoxDecoration(
                    color: isPlayer ? Colors.blue : isHint ? Colors.amber.shade100 : isFinish ? Colors.green.shade100 : isStart ? Colors.blue.shade50 : isVisited ? Colors.blue.withValues(alpha: 0.10) : Colors.white,
                    borderRadius: BorderRadius.circular(8), border: Border.all(color: isHint ? Colors.amber : Colors.black12, width: isHint ? 2 : 1),
                  ), child: Stack(alignment: Alignment.center, children: [
                    if (cell.arrows.isNotEmpty) Wrap(alignment: WrapAlignment.center, spacing: 1, runSpacing: -5, children: cell.arrows.map((d) => Text(d.symbol, style: TextStyle(fontSize: cell.arrows.length == 1 ? 22 : 14, fontWeight: FontWeight.w700, color: isPlayer ? Colors.white : Colors.black87))).toList()),
                    if (isStart) const Positioned(left: 3, top: 2, child: Text('S', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                    if (isFinish) const Positioned(right: 3, top: 2, child: Text('F', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                    if (isPlayer) const Icon(Icons.circle, size: 10, color: Colors.white),
                  ])),
                );
              },
            ))))),
            Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [Text('Best time: ${_bestTime == null ? '--:--' : _formatTime(_bestTime!)}'), Text('Best score: $_bestScore')])),
          ]),
          if (_finished) Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(animation: _winController, builder: (_, __) => Center(child: Transform.scale(scale: 1 + (_winController.value * .25), child: Opacity(opacity: 1 - (_winController.value * .15), child: const Icon(Icons.celebration, size: 110))))))),
          if (_paused) Positioned.fill(child: Container(color: Colors.black26)),
          if (_rewardAdLoading) Positioned.fill(child: Container(color: Colors.black12, child: const Center(child: Card(child: Padding(padding: EdgeInsets.all(18), child: Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 12), Text('Loading ad…')])))))),
        ]),
      ),
    );
  }
}
