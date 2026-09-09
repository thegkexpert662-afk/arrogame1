import 'package:shared_preferences/shared_preferences.dart';

class ProgressStore {
  static const _levelKey = 'unlocked_level';
  static const _starsPrefix = 'stars_';
  static const _soundKey = 'sound';
  static const _vibrationKey = 'vibration';
  static const _dailyDateKey = 'daily_date';
  static const _streakKey = 'daily_streak';

  static Future<int> unlockedLevel() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_levelKey) ?? 1;
  }

  static Future<void> unlockThrough(int level) async {
    final p = await SharedPreferences.getInstance();
    final current = p.getInt(_levelKey) ?? 1;
    if (level > current) await p.setInt(_levelKey, level);
  }

  static Future<int> stars(int level) async {
    final p = await SharedPreferences.getInstance();
    return p.getInt('$_starsPrefix$level') ?? 0;
  }

  static Future<void> saveStars(int level, int value) async {
    final p = await SharedPreferences.getInstance();
    final current = p.getInt('$_starsPrefix$level') ?? 0;
    if (value > current) await p.setInt('$_starsPrefix$level', value);
  }

  static Future<bool> sound() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_soundKey) ?? true;
  }

  static Future<bool> vibration() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_vibrationKey) ?? true;
  }

  static Future<void> setSound(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_soundKey, value);
  }

  static Future<void> setVibration(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_vibrationKey, value);
  }

  static Future<int> dailyStreak() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_streakKey) ?? 0;
  }

  static Future<int> claimDaily() async {
    final p = await SharedPreferences.getInstance();
    final today = _day(DateTime.now());
    final last = p.getString(_dailyDateKey);
    var streak = p.getInt(_streakKey) ?? 0;
    if (last == today) return streak;
    final yesterday = _day(DateTime.now().subtract(const Duration(days: 1)));
    streak = last == yesterday ? streak + 1 : 1;
    await p.setString(_dailyDateKey, today);
    await p.setInt(_streakKey, streak);
    return streak;
  }

  static String _day(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
