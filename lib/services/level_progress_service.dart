import 'package:shared_preferences/shared_preferences.dart';

class LevelProgressService {
  LevelProgressService._();
  static final LevelProgressService instance = LevelProgressService._();

  static const _unlockedKey = 'unlocked_level';
  static const _completedPrefix = 'completed_';
  static const _scorePrefix = 'score_';
  static const _timePrefix = 'time_';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<int> unlockedLevel() async => await _prefs.getInt(_unlockedKey) ?? 1;

  Future<bool> isUnlocked(int level) async => level <= await unlockedLevel();

  Future<void> completeLevel({required int level, required int score, required int timeSeconds}) async {
    final currentUnlocked = await unlockedLevel();
    if (level + 1 > currentUnlocked) {
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
      await _prefs.getBool('$_completedPrefix$level') ?? false;

  Future<int?> bestScore(int level) async => await _prefs.getInt('$_scorePrefix$level');

  Future<int?> bestTime(int level) async => await _prefs.getInt('$_timePrefix$level');
}
