import 'package:flutter/material.dart';
import '../app_widgets.dart';
import '../engine/arrow_puzzle_engine.dart';
import '../services/progress_store.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashState();
}
class _SplashState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/intro');
    });
  }
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: bg,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.alt_route_rounded, color: orange, size: 86),
      SizedBox(height: 14),
      Text('Arro Puzzal', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: brown)),
      SizedBox(height: 5),
      Text('Follow the arrows. Clear the path.', style: TextStyle(color: brown)),
    ])),
  );
}

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    body: SafeArea(child: Padding(padding: const EdgeInsets.all(28), child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.alt_route, color: orange, size: 100),
        const SizedBox(height: 20),
        const Text('Arro Puzzal', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: brown)),
        const SizedBox(height: 12),
        const Text('Move each arrow in the direction it points and take it outside the board. Find the correct order and clear every arrow.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: brown, height: 1.5)),
        const SizedBox(height: 35),
        primary(context, 'Start Game', () => Navigator.pushReplacementNamed(context, '/home')),
      ],
    ))),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    body: SafeArea(child: Padding(padding: const EdgeInsets.all(22), child: Column(
      children: [
        const Spacer(),
        const Icon(Icons.alt_route, color: orange, size: 72),
        const SizedBox(height: 8),
        const Text('Arro Puzzal', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: brown)),
        const Text('Follow the arrows • Clear the path', style: TextStyle(color: brown)),
        const SizedBox(height: 32),
        primary(context, 'Play', () => Navigator.pushNamed(context, '/difficulty')),
        const SizedBox(height: 12),
        Row(children: [
          softButton('Daily', Icons.today, () => Navigator.pushNamed(context, '/daily')),
          softButton('How to Play', Icons.help_outline, () => Navigator.pushNamed(context, '/how')),
          softButton('Settings', Icons.settings_outlined, () => Navigator.pushNamed(context, '/settings')),
        ]),
        const SizedBox(height: 20),
        FutureBuilder<int>(future: ProgressStore.dailyStreak(), builder: (c, s) => Text('Daily Streak  🔥  ${s.data ?? 0}', style: const TextStyle(color: brown, fontWeight: FontWeight.bold))),
        const Spacer(),
      ],
    ))),
  );
}

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final data = [
      ('Easy', 'Learn the mechanic', Icons.sentiment_satisfied_alt),
      ('Normal', 'Build your rhythm', Icons.tune),
      ('Hard', 'Dense and complex paths', Icons.auto_awesome),
      ('Expert', 'Maximum order challenge', Icons.bolt),
    ];
    return AppScaffold(title: 'Choose Difficulty', body: ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final x = data[i];
        return Card(color: Colors.white, child: ListTile(
          contentPadding: const EdgeInsets.all(18),
          leading: CircleAvatar(backgroundColor: const Color(0xFFFFE5C5), child: Icon(x.$3, color: brown)),
          title: Text(x.$1, style: const TextStyle(color: brown, fontSize: 20, fontWeight: FontWeight.bold)),
          subtitle: Text(x.$2, style: const TextStyle(color: brown)),
          trailing: const Icon(Icons.chevron_right, color: brown),
          onTap: () => Navigator.pushNamed(context, '/levels', arguments: x.$1),
        ));
      },
    ));
  }
}

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});
  @override State<LevelSelectScreen> createState() => _LevelSelectState();
}
class _LevelSelectState extends State<LevelSelectScreen> {
  int unlocked = 1;
  String difficulty = 'Normal';
  final Map<int, int> stars = {};

  @override
  void initState() {
    super.initState();
    _load();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String) difficulty = arg;
  }
  Future<void> _load() async {
    final u = await ProgressStore.unlockedLevel();
    if (!mounted) return;
    setState(() => unlocked = u.clamp(1, 100));
    for (var i = 1; i <= unlocked; i++) {
      stars[i] = await ProgressStore.stars(i);
    }
    if (mounted) setState(() {});
  }
  @override
  Widget build(BuildContext context) => AppScaffold(
    title: '$difficulty • Levels',
    body: GridView.builder(
      padding: const EdgeInsets.all(18),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: 100,
      itemBuilder: (context, i) {
        final level = i + 1;
        final locked = level > unlocked;
        final count = stars[level] ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: locked ? null : () => Navigator.pushNamed(context, '/game', arguments: {'level': level, 'difficulty': difficulty}),
          child: Card(
            color: locked ? Colors.black12 : Colors.white,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(locked ? Icons.lock_outline : Icons.alt_route, color: locked ? Colors.black38 : brown, size: 25),
              const SizedBox(height: 3),
              Text('$level', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: locked ? Colors.black38 : brown)),
              Text('★' * count, style: const TextStyle(fontSize: 11, color: orange)),
            ]),
          ),
        );
      },
    ),
  );
}

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});
  @override State<ResultScreen> createState() => _ResultState();
}
class _ResultState extends State<ResultScreen> {
  late int level;
  late int stars;
  late int moves;
  late String difficulty;
  bool saved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (saved) return;
    final a = ModalRoute.of(context)?.settings.arguments;
    final map = a is Map ? a : const <String, dynamic>{};
    level = map['level'] as int? ?? 1;
    stars = map['stars'] as int? ?? 1;
    moves = map['moves'] as int? ?? 0;
    difficulty = map['difficulty'] as String? ?? 'Normal';
    saved = true;
    _save();
  }
  Future<void> _save() async {
    await ProgressStore.saveStars(level, stars);
    await ProgressStore.unlockThrough(min(100, level + 1));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    body: SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(26), child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.celebration, color: orange, size: 70),
        const SizedBox(height: 10),
        const Text('Level Complete!', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: brown)),
        const SizedBox(height: 8),
        Text('★' * stars + '☆' * (3 - stars), style: const TextStyle(fontSize: 44, color: orange)),
        Text('$moves moves • $difficulty', style: const TextStyle(color: brown, fontSize: 16)),
        const SizedBox(height: 10),
        const Text('All arrows escaped the board.', style: TextStyle(color: brown, fontSize: 18)),
        const SizedBox(height: 30),
        primary(context, 'Next Level', () => Navigator.pushReplacementNamed(context, '/game', arguments: {'level': min(100, level + 1), 'difficulty': difficulty})),
        const SizedBox(height: 12),
        primary(context, 'Level Select', () => Navigator.pushReplacementNamed(context, '/levels', arguments: difficulty)),
        const SizedBox(height: 12),
        TextButton(onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false), child: const Text('Home')),
      ],
    )))),
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsState();
}
class _SettingsState extends State<SettingsScreen> {
  bool sound = true;
  bool vibration = true;
  @override
  void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    final s = await ProgressStore.sound();
    final v = await ProgressStore.vibration();
    if (mounted) setState(() { sound = s; vibration = v; });
  }
  @override
  Widget build(BuildContext context) => AppScaffold(title: 'Settings', body: ListView(padding: const EdgeInsets.all(18), children: [
    Card(color: Colors.white, child: SwitchListTile(title: const Text('Sound'), subtitle: const Text('Game sound effects'), value: sound, onChanged: (v) { setState(() => sound = v); ProgressStore.setSound(v); })),
    Card(color: Colors.white, child: SwitchListTile(title: const Text('Vibration'), subtitle: const Text('Tap and result feedback'), value: vibration, onChanged: (v) { setState(() => vibration = v); ProgressStore.setVibration(v); })),
    const Card(color: Colors.white, child: ListTile(title: Text('Theme'), subtitle: Text('Warm Light'))),
    const Card(color: Colors.white, child: ListTile(title: Text('About'), subtitle: Text('Arro Puzzal • v1.0.0'))),
  ]));
}

class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});
  int _dailyLevel() {
    final now = DateTime.now();
    return ((now.difference(DateTime(now.year)).inDays) % 100) + 1;
  }
  @override
  Widget build(BuildContext context) => AppScaffold(title: 'Daily Puzzle', body: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
    const Icon(Icons.local_fire_department, color: orange, size: 80),
    const Text('Daily Streak', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: brown)),
    const SizedBox(height: 10),
    FutureBuilder<int>(future: ProgressStore.dailyStreak(), builder: (c, s) => Text('${s.data ?? 0} day streak', style: const TextStyle(color: brown, fontSize: 18))),
    const SizedBox(height: 8),
    const Text('A fresh hard puzzle every day.', style: TextStyle(color: brown)),
    const Spacer(),
    primary(context, 'Play Daily Puzzle', () async {
      await ProgressStore.claimDaily();
      if (context.mounted) Navigator.pushNamed(context, '/game', arguments: {'level': _dailyLevel(), 'difficulty': 'Hard'});
    }),
    const Spacer(),
  ])));
}

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});
  @override
  Widget build(BuildContext context) => AppScaffold(title: 'How to Play', body: ListView(padding: const EdgeInsets.all(18), children: [
    for (final item in const [
      ('1', 'Tap an arrow.'),
      ('2', 'It can move only in the direction it points.'),
      ('3', 'If another arrow blocks its route to the edge, clear that blocking arrow first.'),
      ('4', 'Arrow lengths vary: short, medium and long paths can appear.'),
      ('5', 'Levels are generated and checked for a valid solution before they are shown.'),
      ('6', 'Clear the last arrow to complete the level.'),
    ]) Card(color: Colors.white, child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFFFFE5C5), child: Text(item.$1, style: const TextStyle(color: brown, fontWeight: FontWeight.bold))), title: Text(item.$2, style: const TextStyle(color: brown, height: 1.35))))
  ]));
}
