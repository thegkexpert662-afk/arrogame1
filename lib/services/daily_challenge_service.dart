import 'dart:math';

class DailyChallenge {
  const DailyChallenge({required this.seed, required this.difficulty, required this.title, required this.rewardCoins, required this.rewardXp});
  final int seed;
  final int difficulty;
  final String title;
  final int rewardCoins;
  final int rewardXp;
}

class DailyChallengeService {
  DailyChallengeService._();
  static final instance = DailyChallengeService._();

  DailyChallenge today() {
    final now = DateTime.now();
    final daySeed = now.year * 10000 + now.month * 100 + now.day;
    final difficulty = min(10, 1 + ((daySeed ~/ 7) % 10));
    return DailyChallenge(
      seed: daySeed,
      difficulty: difficulty,
      title: 'Daily Arrow Challenge',
      rewardCoins: 30 + difficulty * 3,
      rewardXp: 50 + difficulty * 5,
    );
  }
}
