import 'package:flutter/material.dart';

import '../services/daily_challenge_service.dart';
import '../services/level_progress_service.dart';
import '../services/player_progress_service.dart';
import '../services/theme_service.dart';
import 'arrow_game_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key, this.onThemeChanged});
  final ValueChanged<ThemeMode>? onThemeChanged;
  @override State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  static const int totalLevels = 1000;
  int _unlocked = 1; bool _loading = true;
  PlayerProgress? _progress; late final DailyChallenge _daily;
  ThemeMode _themeMode = ThemeMode.light; ArrowStyle _arrowStyle = ArrowStyle.classic; GameBackground _background = GameBackground.clean;

  @override void initState() { super.initState(); _daily = DailyChallengeService.instance.today(); _loadProgress(); }

  Future<void> _loadProgress() async {
    final unlocked = await LevelProgressService.instance.unlockedLevel();
    final progress = await PlayerProgressService.instance.load();
    final mode = await ThemeService.instance.themeMode();
    final style = await ThemeService.instance.arrowStyle();
    final bg = await ThemeService.instance.background();
    if (!mounted) return;
    setState(() { _unlocked = unlocked.clamp(1, totalLevels); _progress = progress; _themeMode = mode; _arrowStyle = style; _background = bg; _loading = false; });
    widget.onThemeChanged?.call(mode);
  }

  String _difficulty(int level) => level <= 25 ? 'EASY' : level <= 100 ? 'MEDIUM' : level <= 500 ? 'HARD' : 'EXTREME';

  Future<void> _claimDaily() async {
    final before = await PlayerProgressService.instance.load();
    if (before.lastDaily == DateTime.now().toIso8601String().substring(0, 10)) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daily reward already claimed today.'))); return; }
    final after = await PlayerProgressService.instance.dailyReward();
    if (!mounted) return; setState(() => _progress = after);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🎁 Daily reward claimed! Streak ${after.streak}')));
  }

  Future<void> _openDailyChallenge() async { await Navigator.push(context, MaterialPageRoute(builder: (_) => ArrowGameScreen(level: _daily.difficulty))); _loadProgress(); }

  Future<void> _openThemes() async {
    final playerLevel = _progress?.playerLevel ?? 1;
    await showModalBottomSheet<void>(context: context, builder: (sheet) => StatefulBuilder(builder: (sheet, refresh) => SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const ListTile(title: Text('🎨 Themes & Styles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
      SegmentedButton<ThemeMode>(segments: const [ButtonSegment(value: ThemeMode.light, label: Text('☀️ Light')), ButtonSegment(value: ThemeMode.dark, label: Text('🌙 Dark'))], selected: {_themeMode}, onSelectionChanged: (v) async { final mode = v.first; await ThemeService.instance.setThemeMode(mode); setState(() => _themeMode = mode); refresh(); widget.onThemeChanged?.call(mode); }),
      const SizedBox(height: 12),
      Align(alignment: Alignment.centerLeft, child: Text('Arrow styles', style: Theme.of(context).textTheme.titleMedium)),
      Wrap(spacing: 8, children: ArrowStyle.values.map((style) => OutlinedButton.icon(onPressed: () async { final ok = await ThemeService.instance.isArrowStyleUnlocked(style, playerLevel); if (!ok) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🔒 Unlock at Player Level ${(style.index + 1) * 3}'))); return; } await ThemeService.instance.setArrowStyle(style); setState(() => _arrowStyle = style); refresh(); }, icon: Icon(_arrowStyle == style ? Icons.check : Icons.arrow_forward), label: Text(style.name))).toList()),
      const SizedBox(height: 8),
      Align(alignment: Alignment.centerLeft, child: Text('Backgrounds', style: Theme.of(context).textTheme.titleMedium)),
      Wrap(spacing: 8, children: GameBackground.values.map((bg) => OutlinedButton.icon(onPressed: () async { final ok = await ThemeService.instance.isBackgroundUnlocked(bg, playerLevel); if (!ok) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🔒 Unlock at Player Level ${(bg.index + 1) * 5}'))); return; } await ThemeService.instance.setBackground(bg); setState(() => _background = bg); refresh(); }, icon: Icon(_background == bg ? Icons.check : Icons.wallpaper), label: Text(bg.name))).toList()),
    ]))));
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Levels'), actions: [IconButton(tooltip: 'Themes', onPressed: _openThemes, icon: const Icon(Icons.palette_outlined))]),
    body: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 4), child: Row(children: [Expanded(child: Text('Player Level ${_progress!.playerLevel}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold))), Text('🪙 ${_progress!.coins}  •  ${_progress!.xp} XP')])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Row(children: [Expanded(child: Card(child: ListTile(leading: const Icon(Icons.card_giftcard), title: const Text('Daily Reward'), subtitle: Text('🔥 Streak ${_progress!.streak}'), onTap: _claimDaily))), const SizedBox(width: 8), Expanded(child: Card(child: ListTile(leading: const Icon(Icons.today), title: const Text('Daily Challenge'), subtitle: Text('Lv ${_daily.difficulty} • +${_daily.rewardCoins} coins'), onTap: _openDailyChallenge)))])),
      Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 8), child: Row(children: [const Expanded(child: Text('Choose a level', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))), Text('$_unlocked / $totalLevels unlocked')])),
      Expanded(child: GridView.builder(padding: const EdgeInsets.all(14), itemCount: totalLevels, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.9), itemBuilder: (context, index) { final level = index + 1; final unlocked = level <= _unlocked; return FutureBuilder<bool>(future: LevelProgressService.instance.isCompleted(level), builder: (context, snapshot) { final completed = snapshot.data ?? false; return InkWell(borderRadius: BorderRadius.circular(14), onTap: unlocked ? () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => ArrowGameScreen(level: level))); _loadProgress(); } : null, child: Container(decoration: BoxDecoration(color: unlocked ? Theme.of(context).cardColor : Colors.grey.shade200, borderRadius: BorderRadius.circular(14), border: Border.all(color: unlocked ? Colors.blue.shade100 : Colors.black12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(unlocked ? (completed ? Icons.check_circle : Icons.play_circle_fill) : Icons.lock, color: unlocked ? Colors.blue : Colors.grey, size: 28), const SizedBox(height: 5), Text('$level', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), const SizedBox(height: 3), Text(_difficulty(level), style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant))]))); }); }))
    ]),
  );
}
