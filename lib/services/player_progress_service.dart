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

  static const int maxCoins = 1000000;
  static const int maxXp = 100000000;
  static const int maxStreak = 3650;

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<PlayerProgress> load() async {
    final rawCoins = await _prefs.getInt('coins') ?? 20;
    final rawXp = await _prefs.getInt('xp') ?? 0;
    final rawLevel = await _prefs.getInt('player_level') ?? 1;
    final rawStreak = await _prefs.getInt('streak') ?? 0;

    final coins = rawCoins.clamp(0, maxCoins).toInt();
    final xp = rawXp.clamp(0, maxXp).toInt();
    final streak = rawStreak.clamp(0, maxStreak).toInt();
    final playerLevel = levelForXp(xp).clamp(1, 1000000).toInt();

    // Repair values that may have been corrupted or manually changed locally.
    if (rawCoins != coins) await _prefs.setInt('coins', coins);
    if (rawXp != xp) await _prefs.setInt('xp', xp);
    if (rawLevel != playerLevel) await _prefs.setInt('player_level', playerLevel);
    if (rawStreak != streak) await _prefs.setInt('streak', streak);

    return PlayerProgress(
      coins: coins,
      xp: xp,
      playerLevel: playerLevel,
      streak: streak,
      lastDaily: await _prefs.getString('last_daily'),
      achievements: (await _prefs.getStringList('achievements') ?? <String>[]).toSet(),
    );
  }

  int levelForXp(int xp) => (xp.clamp(0, maxXp).toInt() ~/ 100) + 1;

  Future<PlayerProgress> award({int coins = 0, int xp = 0, String? achievement}) async {
    // Rewards are trusted only when they are non-negative and within a safe
    // per-operation limit. This is a basic local anti-cheat boundary, not a
    // substitute for server-side validation.
    if (coins < 0 || xp < 0 || coins > 10000 || xp > 10000) {
      return load();
    }

    final p = await load();
    final newCoins = (p.coins + coins).clamp(0, maxCoins).toInt();
    final newXp = (p.xp + xp).clamp(0, maxXp).toInt();
    final achievements = {...p.achievements};
    if (achievement != null && achievement.length <= 64) achievements.add(achievement);

    await _prefs.setInt('coins', newCoins);
    await _prefs.setInt('xp', newXp);
    await _prefs.setInt('player_level', levelForXp(newXp));
    await _prefs.setStringList('achievements', achievements.toList());
    return load();
  }

  Future<PlayerProgress> dailyReward() async {
    final p = await load();
    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);
    if (p.lastDaily == today) return p;

    final yesterday = now.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    final streak = (p.lastDaily == yesterday ? p.streak + 1 : 1).clamp(1, maxStreak).toInt();
    await _prefs.setString('last_daily', today);
    await _prefs.setInt('streak', streak);

    final reward = 10 + (streak.clamp(1, 7).toInt() * 5);
    return award(coins: reward, xp: 25, achievement: streak >= 7 ? '7_day_streak' : null);
  }
}
