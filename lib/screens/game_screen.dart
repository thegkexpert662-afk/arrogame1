import 'dart:math';
import 'package:flutter/material.dart';
import '../app_widgets.dart';
import '../models/arrow.dart';
import '../engine/arrow_puzzle_engine.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late ArrowPuzzleEngine engine;
  late AnimationController exitController;
  int level = 1;
  PuzzleDifficulty difficulty = PuzzleDifficulty.normal;
  int lives = 3;
  int? hintIndex;
  Arrow? exiting;
  bool busy = false;
  bool configured = false;

  @override
  void initState() {
    super.initState();
    exitController = AnimationController(vsync: this, duration: const Duration(milliseconds: 230));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (configured) return;
    configured = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final rawLevel = args['level'];
      level = rawLevel is int ? rawLevel.clamp(1, 100) : 1;
      difficulty = _parseDifficulty(args['difficulty'] is String ? args['difficulty'] as String : null);
    }
    engine = ArrowPuzzleEngine.forLevel(level, difficulty: difficulty);
  }

  PuzzleDifficulty _parseDifficulty(String? value) => switch (value) {
        'Easy' => PuzzleDifficulty.easy,
        'Hard' => PuzzleDifficulty.hard,
        'Expert' => PuzzleDifficulty.expert,
        _ => PuzzleDifficulty.normal,
      };

  Future<void> _move(int index) async {
    if (busy || !mounted || index < 0 || index >= engine.arrows.length) return;
    final selected = engine.arrows[index].copy();
    if (!engine.canMove(index)) {
      setState(() {
        lives = max(0, lives - 1);
        hintIndex = null;
      });
      if (lives == 0) await _outOfLives();
      return;
    }

    final removed = engine.removeArrow(index);
    if (removed == null) return;
    setState(() {
      busy = true;
      exiting = selected;
      hintIndex = null;
    });
    exitController.reset();
    await exitController.forward();
    if (!mounted) return;
    setState(() {
      exiting = null;
      busy = false;
    });
    if (engine.completed) {
      Navigator.pushReplacementNamed(context, '/result', arguments: {
        'level': level,
        'stars': _stars(),
        'moves': engine.moves,
        'difficulty': ArrowPuzzleEngine.difficultyName(difficulty),
      });
    }
  }

  int _stars() {
    final limit = switch (difficulty) {
      PuzzleDifficulty.easy => engine.initialCount + 2,
      PuzzleDifficulty.normal => engine.initialCount + 4,
      PuzzleDifficulty.hard => engine.initialCount + 6,
      PuzzleDifficulty.expert => engine.initialCount + 8,
    };
    if (engine.moves <= limit && lives == 3) return 3;
    if (lives >= 2) return 2;
    return 1;
  }

  Future<void> _outOfLives() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('Try again'),
        content: const Text('You used all three tries. The puzzle is reset so you can try a new order.'),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
      ),
    );
    if (!mounted) return;
    setState(() {
      lives = 3;
      engine.reset();
      hintIndex = null;
    });
  }

  void _hint() {
    if (busy) return;
    final index = engine.hintIndex();
    setState(() => hintIndex = index);
    if (index != null) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted && hintIndex == index) setState(() => hintIndex = null);
      });
    }
  }

  void _tap(Offset position, Size size) {
    if (busy) return;
    for (var i = engine.arrows.length - 1; i >= 0; i--) {
      if (engine.hitTest(i, position, size)) {
        _move(i);
        return;
      }
    }
  }

  @override
  void dispose() {
    exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: brown), onPressed: () => Navigator.pop(context)),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(children: [
            Text('Level $level', style: const TextStyle(color: brown, fontWeight: FontWeight.w800)),
            Text(ArrowPuzzleEngine.difficultyName(difficulty), style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.palette_outlined, color: brown), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings_outlined, color: brown), onPressed: () => Navigator.pushNamed(context, '/settings')),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Row(children: [
              ...List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(right: 7),
                child: Icon(Icons.water_drop, color: i < lives ? blue : Colors.black12, size: 31),
              )),
              const Spacer(),
              IconButton(
                tooltip: 'Hint',
                icon: Icon(Icons.lightbulb_outline, color: hintIndex == null ? brown : orange, size: 30),
                onPressed: busy ? null : _hint,
              ),
            ]),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
              child: LayoutBuilder(builder: (context, constraints) {
                final boardSize = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => _tap(d.localPosition, boardSize),
                  child: AnimatedBuilder(
                    animation: exitController,
                    builder: (context, _) => CustomPaint(
                      painter: ArrowBoardPainter(engine.arrows, hintIndex: hintIndex, exiting: exiting, exitProgress: exitController.value),
                      child: const SizedBox.expand(),
                    ),
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 12),
            child: Row(children: [
              softButton('Undo', Icons.undo, busy ? null : () => setState(engine.undo)),
              softButton('Reset', Icons.refresh, busy ? null : () => setState(() { engine.reset(); lives = 3; hintIndex = null; })),
              softButton('Hint', Icons.lightbulb_outline, busy ? null : _hint),
            ]),
          ),
        ]),
      ),
    );
  }
}

class ArrowBoardPainter extends CustomPainter {
  final List<Arrow> arrows;
  final int? hintIndex;
  final Arrow? exiting;
  final double exitProgress;

  ArrowBoardPainter(this.arrows, {this.hintIndex, this.exiting, this.exitProgress = 0});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final base = Paint()..style = PaintingStyle.stroke..strokeWidth = max(1.5, min(2.2, size.shortestSide / 190))..strokeCap = StrokeCap.round..color = brown;
    final head = Paint()..style = PaintingStyle.stroke..strokeWidth = max(2.2, min(3.4, size.shortestSide / 115))..strokeCap = StrokeCap.round..color = orange;
    final hintPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = max(4, min(6.5, size.shortestSide / 55))..strokeCap = StrokeCap.round..color = orange.withOpacity(.30);

    for (var i = 0; i < arrows.length; i++) {
      _drawArrow(canvas, size, arrows[i], i == hintIndex ? hintPaint : base, head);
    }

    if (exiting != null) {
      final a = exiting!;
      final v = a.direction.vector;
      final scale = min(size.width, size.height);
      final start = Offset(a.x * size.width, a.y * size.height) + v * scale * exitProgress;
      final end = start + v * a.length * scale;
      canvas.drawLine(start, end, head);
      _drawHead(canvas, end, v, head, size.shortestSide);
    }
  }

  void _drawArrow(Canvas canvas, Size size, Arrow a, Paint shaft, Paint head) {
    final scale = min(size.width, size.height);
    final start = Offset(a.x * size.width, a.y * size.height);
    final v = a.direction.vector;
    final end = start + v * a.length * scale;
    canvas.drawLine(start, end, shaft);
    _drawHead(canvas, end, v, head, size.shortestSide);
  }

  void _drawHead(Canvas canvas, Offset end, Offset v, Paint paint, double shortestSide) {
    final perp = Offset(-v.dy, v.dx);
    final headLength = max(8.0, min(14.0, shortestSide / 32));
    final headWidth = max(4.5, min(7.0, shortestSide / 65));
    final back = end - v * headLength;
    canvas.drawLine(end, back + perp * headWidth, paint);
    canvas.drawLine(end, back - perp * headWidth, paint);
  }

  @override
  bool shouldRepaint(covariant ArrowBoardPainter oldDelegate) => true;
}
