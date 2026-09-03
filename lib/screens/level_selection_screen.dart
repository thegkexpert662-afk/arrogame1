import 'package:flutter/material.dart';

import '../services/daily_challenge_service.dart';
import '../services/level_progress_service.dart';
import '../services/player_progress_service.dart';
import 'arrow_game_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});
  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  static const int totalLevels = 1000;
  int _unlocked = 1;
  bool _loading = true;
  PlayerProgress? _progress;
  late final DailyChallenge _daily;

  @override
  void initState() {
    super.initState();
    _daily = DailyChallengeService.instance.today();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final unlocked = await LevelProgressService.instance.unlockedLevel();
    final progress = await PlayerProgressService.instance.load();
    if (!mounted) return;
    setState(() {
      _unlocked = unlocked.clamp(1, totalLevels);
      _progress = progress;
      _loading = false;
    });
  }

  String _difficulty(int level) {
    if (level <= 25) return 'EASY';
    if (level <= 100) return 'MEDIUM';
    if (level <= 500) return 'HARD';
    return 'EXTREME';
  }

  Future<void> _claimDaily() async {
    final before = await PlayerProgressService.instance.load();
    if (before.lastDaily == DateTime.now().toIso8601String().substring(0, 10)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daily reward already claimed today.')));
      return;
    }
    final after = await PlayerProgressService.instance.dailyReward();
    if (!mounted) return;
    setState(() => _progress = after);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🎁 Daily reward claimed! Streak ${after.streak} • Coins +${after.coins - before.coins}')));
  }

  Future<void> _openDailyChallenge() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ArrowGameScreen(level: _daily.difficulty)));
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Levels')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 4), child: Row(children: [
                Expanded(child: Text('Player Level ${_progress!.playerLevel}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
                Text('🪙 ${_progress!.coins}  •  ${_progress!.xp} XP'),
              ])),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Row(children: [
                Expanded(child: Card(child: ListTile(leading: const Icon(Icons.card_giftcard), title: const Text('Daily Reward'), subtitle: Text('🔥 Streak ${_progress!.streak}'), onTap: _claimDaily))),
                const SizedBox(width: 8),
                Expanded(child: Card(child: ListTile(leading: const Icon(Icons.today), title: const Text('Daily Challenge'), subtitle: Text('Lv ${_daily.difficulty} • +${_daily.rewardCoins} coins'), onTap: _openDailyChallenge))),
              ])),
              Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 8), child: Row(children: [const Expanded(child: Text('Choose a level', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))), Text('$_unlocked / $totalLevels unlocked')])),
              Expanded(child: GridView.builder(
                padding: const EdgeInsets.all(14), itemCount: totalLevels,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.9),
                itemBuilder: (context, index) {
                  final level = index + 1;
                  final unlocked = level <= _unlocked;
                  return FutureBuilder<bool>(
                    future: LevelProgressService.instance.isCompleted(level),
                    builder: (context, snapshot) {
                      final completed = snapshot.data ?? false;
                      return InkWell(borderRadius: BorderRadius.circular(14), onTap: unlocked ? () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => ArrowGameScreen(level: level)));
                        _loadProgress();
                      } : null, child: Container(
                        decoration: BoxDecoration(color: unlocked ? Colors.white : Colors.grey.shade200, borderRadius: BorderRadius.circular(14), border: Border.all(color: unlocked ? Colors.blue.shade100 : Colors.black12)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(unlocked ? (completed ? Icons.check_circle : Icons.play_circle_fill) : Icons.lock, color: unlocked ? Colors.blue : Colors.grey, size: 28),
                          const SizedBox(height: 5), Text('$level', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), const SizedBox(height: 3), Text(_difficulty(level), style: TextStyle(fontSize: 9, color: Colors.grey.shade700)),
                        ]),
                      ));
                    },
                  );
                },
              )),
            ]),
    );
  }
}
