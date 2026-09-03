import 'package:shared_preferences/shared_preferences.dart';

class LevelProgressService {
  LevelProgressService._();
  static final LevelProgressService instance = LevelProgressService._();

  static const int maxLevel = 1000;
  static const int maxScore = 1000000;
  static const int maxTimeSeconds = 86400;
  static const _unlockedKey = 'unlocked_level';
  static const _completedPrefix = 'completed_';
  static const _scorePrefix = 'score_';
  static const _timePrefix = 'time_';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<int> unlockedLevel() async {
    final raw = await _prefs.getInt(_unlockedKey) ?? 1;
    final value = raw.clamp(1, maxLevel).toInt();
    if (raw != value) await _prefs.setInt(_unlockedKey, value);
    return value;
  }

  Future<bool> isUnlocked(int level) async =>
      level >= 1 && level <= await unlockedLevel();

  Future<void> completeLevel({required int level, required int score, required int timeSeconds}) async {
    // Only plausible local results are accepted. This is basic anti-cheat and
    // corruption protection; competitive/server validation would be stronger.
    if (level < 1 || level > maxLevel || score < 0 || score > maxScore || timeSeconds < 0 || timeSeconds > maxTimeSeconds) {
      return;
    }

    final currentUnlocked = await unlockedLevel();
    if (level + 1 > currentUnlocked && level < maxLevel) {
      await _prefs.setInt(_unlockedKey, level + 1);
    }

    await _prefs.setBool('$_completedPrefix$level', true);

    final oldScore = await bestScore(level);
    if (oldScore == null || score > oldScore) {
      await _prefs.setInt('$_scorePrefix$level', score);
    }

    final oldTime = await bestTime(level);
    if (oldTime == null || timeSeconds < oldTime) {
      await _prefs.setInt('$_timePrefix$level', timeSeconds);
    }
  }

  Future<bool> isCompleted(int level) async =>
      level >= 1 && level <= maxLevel &&
      await _prefs.getBool('$_completedPrefix$level') == true;

  Future<int?> bestScore(int level) async {
    if (level < 1 || level > maxLevel) return null;
    final value = await _prefs.getInt('$_scorePrefix$level');
    if (value == null || value < 0 || value > maxScore) return null;
    return value;
  }

  Future<int?> bestTime(int level) async {
    if (level < 1 || level > maxLevel) return null;
    final value = await _prefs.getInt('$_timePrefix$level');
    if (value == null || value < 0 || value > maxTimeSeconds) return null;
    return value;
  }
}
