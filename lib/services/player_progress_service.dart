import 'package:shared_preferences/shared_preferences.dart';

class PlayerProgress {
  const PlayerProgress({required this.coins, required this.xp, required this.playerLevel, required this.streak, required this.lastDaily, required this.achievements});
  final int coins;
  final int xp;
  final int playerLevel;
  final int streak;
  final String? lastDaily;
  final Set<String> achievements;
}

class PlayerProgressService {
  PlayerProgressService._();
  static final instance = PlayerProgressService._();
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<PlayerProgress> load() async => PlayerProgress(
    coins: await _prefs.getInt('coins') ?? 20,
    xp: await _prefs.getInt('xp') ?? 0,
    playerLevel: await _prefs.getInt('player_level') ?? 1,
    streak: await _prefs.getInt('streak') ?? 0,
    lastDaily: await _prefs.getString('last_daily'),
    achievements: (await _prefs.getStringList('achievements') ?? <String>[]).toSet(),
  );

  int levelForXp(int xp) => (xp ~/ 100) + 1;

  Future<PlayerProgress> award({int coins = 0, int xp = 0, String? achievement}) async {
    final p = await load();
    final newXp = p.xp + xp;
    final achievements = {...p.achievements};
    if (achievement != null) achievements.add(achievement);
    await _prefs.setInt('coins', p.coins + coins);
    await _prefs.setInt('xp', newXp);
    await _prefs.setInt('player_level', levelForXp(newXp));
    await _prefs.setStringList('achievements', achievements.toList());
    return load();
  }

  Future<PlayerProgress> dailyReward() async {
    final p = await load();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (p.lastDaily == today) return p;
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    final streak = p.lastDaily == yesterday ? p.streak + 1 : 1;
    await _prefs.setString('last_daily', today);
    await _prefs.setInt('streak', streak);
    final reward = 10 + (streak.clamp(1, 7) * 5);
    return award(coins: reward, xp: 25, achievement: streak >= 7 ? '7_day_streak' : null);
  }
}
