import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/arrow.dart';
import '../engine/arrow_puzzle_engine.dart';

const _pageBg = Color(0xFF061522);
const _panel = Color(0xFF0B2133);
const _line = Color(0xFF23557D);
const _text = Color(0xFFEAF6FF);
const _muted = Color(0xFFAFC4D5);

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late ArrowPuzzleEngine engine;
  late AnimationController exitController;
  Timer? timer;
  int level = 1;
  PuzzleDifficulty difficulty = PuzzleDifficulty.normal;
  int lives = 3;
  int elapsedSeconds = 0;
  int? hintIndex;
  Arrow? exiting;
  bool busy = false;
  bool configured = false;

  @override
  void initState() {
    super.initState();
    exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !busy) setState(() => elapsedSeconds++);
    });
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
      difficulty = _parseDifficulty(
        args['difficulty'] is String ? args['difficulty'] as String : null,
      );
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
      Navigator.pushReplacementNamed(
        context,
        '/result',
        arguments: {
          'level': level,
          'stars': _stars(),
          'moves': engine.moves,
          'difficulty': ArrowPuzzleEngine.difficultyName(difficulty),
        },
      );
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
        content: const Text('You used all three tries. The puzzle is reset.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      lives = 3;
      elapsedSeconds = 0;
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

  String get _timeText {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    timer?.cancel();
    exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            return Column(
              children: [
                _buildHeader(compact),
                _buildSubHeader(compact),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(compact ? 8 : 18, 4, compact ? 8 : 18, 4),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _buildBoard(),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildControls(compact),
                _buildRules(compact),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool compact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 28, 10, compact ? 12 : 28, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                  children: [
                    TextSpan(text: 'Arrow ', style: TextStyle(color: _text)),
                    TextSpan(text: 'Puzzle', style: TextStyle(color: Color(0xFF24A8FF))),
                  ],
                ),
              ),
            ),
          ),
          if (!compact) ...[
            _statCard('Level', '$level'),
            const SizedBox(width: 8),
            _statCard('Grid', '9 × 9'),
            const SizedBox(width: 8),
            _statCard('Arrows', '${engine.arrows.length}'),
            const SizedBox(width: 8),
            _statCard('Time', _timeText, icon: Icons.timer_outlined),
          ] else
            _statCard('Time', _timeText, icon: Icons.timer_outlined),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, {IconData? icon}) {
    return Container(
      width: icon == null ? 92 : 112,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: _text, size: 18),
                const SizedBox(width: 4),
              ],
              Text(title, style: const TextStyle(color: _muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(bool compact) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 30, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              compact ? 'No touching • No crossing' : 'Connect each arrow to the exit • No touching • No crossing',
              style: const TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.favorite,
                  color: i < lives ? const Color(0xFFFF4D61) : const Color(0xFF314351),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF04121E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _tap(d.localPosition, boardSize),
              child: AnimatedBuilder(
                animation: exitController,
                builder: (context, _) => CustomPaint(
                  painter: ArrowBoardPainter(
                    engine.arrows,
                    hintIndex: hintIndex,
                    exiting: exiting,
                    exitProgress: exitController.value,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls(bool compact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 7 : 22, 4, compact ? 7 : 22, 4),
      child: Row(
        children: [
          _control('Undo', Icons.undo, busy ? null : () => setState(engine.undo)),
          _control('Reset', Icons.refresh, busy ? null : () => setState(() {
                engine.reset();
                lives = 3;
                elapsedSeconds = 0;
                hintIndex = null;
              })),
          _control('Hint', Icons.lightbulb_outline, busy ? null : _hint, badge: 3),
          _control('New Game', Icons.add_circle_outline, busy ? null : () {
            setState(() {
              engine = ArrowPuzzleEngine.forLevel(level, difficulty: difficulty);
              lives = 3;
              elapsedSeconds = 0;
              hintIndex = null;
            });
          }),
        ],
      ),
    );
  }

  Widget _control(String label, IconData icon, VoidCallback? onTap, {int? badge}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: _panel,
              foregroundColor: _text,
              side: const BorderSide(color: _line, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 7),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 23),
                  const SizedBox(width: 7),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3E55),
                        shape: BoxShape.circle,
                      ),
                      child: Text('$badge', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRules(bool compact) {
    return Container(
      margin: EdgeInsets.fromLTRB(compact ? 12 : 150, 4, compact ? 12 : 150, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF092A21),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF009A68), width: 1.3),
      ),
      child: Text(
        'Each arrow: 2–7 points   |   Turns: 90° only   |   No touching   |   No crossing',
        textAlign: TextAlign.center,
        style: TextStyle(color: const Color(0xFFB9F6DD), fontSize: compact ? 10 : 12, fontWeight: FontWeight.w600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class ArrowBoardPainter extends CustomPainter {
  final List<Arrow> arrows;
  final int? hintIndex;
  final Arrow? exiting;
  final double exitProgress;

  ArrowBoardPainter(
    this.arrows, {
    this.hintIndex,
    this.exiting,
    this.exitProgress = 0,
  });

  int get gridSize => arrows.isNotEmpty ? arrows.first.gridSize : 9;

  static const _colors = <Color>[
    Color(0xFFFF3B42),
    Color(0xFF22C7FF),
    Color(0xFF45F51F),
    Color(0xFFFFD21C),
    Color(0xFFB347FF),
    Color(0xFFFF2E9A),
    Color(0xFFFF9215),
    Color(0xFF248BFF),
    Color(0xFF20E0CF),
    Color(0xFF9D63FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final scale = min(size.width, size.height);
    final shaftWidth = max(5.0, min(9.0, scale / 62));
    final headWidth = max(8.0, min(13.0, scale / 44));
    final headLength = max(14.0, min(22.0, scale / 24));

    _drawGrid(canvas, size);

    for (var i = 0; i < arrows.length; i++) {
      final color = _colors[i % _colors.length];
      _drawArrow(
        canvas,
        size,
        arrows[i],
        color,
        i == hintIndex,
        shaftWidth,
        headLength,
        headWidth,
      );
    }

    if (exiting != null) {
      _drawExiting(canvas, size, exiting!, exitProgress, shaftWidth, headLength, headWidth);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final cells = max(2, gridSize - 1);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = _line.withOpacity(.72);

    for (var i = 0; i < gridSize; i++) {
      final t = i / cells;
      final x = t * size.width;
      final y = t * size.height;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  Offset _point(Size size, Arrow a, ArrowPoint p) {
    final cells = max(2, a.gridSize - 1);
    return Offset(p.col * size.width / cells, p.row * size.height / cells);
  }

  void _drawArrow(
    Canvas canvas,
    Size size,
    Arrow a,
    Color color,
    bool highlighted,
    double shaftWidth,
    double headLength,
    double headWidth,
  ) {
    if (!a.isPathArrow || a.path.length < 2) return;

    final points = a.path.map((p) => _point(size, a, p)).toList();
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = shaftWidth + (highlighted ? 10 : 6)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withOpacity(highlighted ? .35 : .10);
    canvas.drawPath(path, glow);

    final shaft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = shaftWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas.drawPath(path, shaft);

    final start = points.first;
    canvas.drawCircle(start, shaftWidth * .95, Paint()..color = color);

    final end = points.last;
    final before = points[points.length - 2];
    final delta = end - before;
    if (delta.distance > 0) {
      _drawHead(canvas, end, delta / delta.distance, Paint()..color = color, headLength, headWidth);
    }
  }

  void _drawExiting(
    Canvas canvas,
    Size size,
    Arrow a,
    double progress,
    double shaftWidth,
    double headLength,
    double headWidth,
  ) {
    if (!a.isPathArrow || a.path.length < 2) return;
    final color = _colors[(int.tryParse(a.id.split('_').last) ?? 0) % _colors.length];
    final points = a.path.map((p) => _point(size, a, p)).toList();
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) path.lineTo(points[i].dx, points[i].dy);

    final end = points.last;
    final before = points[points.length - 2];
    final delta = end - before;
    final direction = delta.distance > 0 ? delta / delta.distance : const Offset(1, 0);

    canvas.save();
    canvas.translate(direction.dx * size.width * progress, direction.dy * size.height * progress);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = shaftWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.drawCircle(points.first, shaftWidth * .95, Paint()..color = color);
    _drawHead(canvas, end, direction, Paint()..color = color, headLength, headWidth);
    canvas.restore();
  }

  void _drawHead(
    Canvas canvas,
    Offset end,
    Offset direction,
    Paint paint,
    double headLength,
    double headWidth,
  ) {
    final perp = Offset(-direction.dy, direction.dx);
    final back = end - direction * headLength;
    final p1 = back + perp * headWidth;
    final p2 = back - perp * headWidth;
    final triangle = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(triangle, paint);
  }

  @override
  bool shouldRepaint(covariant ArrowBoardPainter oldDelegate) => true;
}
