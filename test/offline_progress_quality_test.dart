import 'package:flutter_test/flutter_test.dart';

import '../lib/services/level_progress_service.dart';
import '../lib/services/player_progress_service.dart';

void main() {
  group('offline progress quality', () {
    test('XP level calculation is deterministic', () {
      final service = PlayerProgressService.instance;
      expect(service.levelForXp(0), 1);
      expect(service.levelForXp(99), 1);
      expect(service.levelForXp(100), 2);
      expect(service.levelForXp(999), 10);
    });

    test('level progress validation bounds are documented by constants', () {
      expect(LevelProgressService.maxLevel, 1000);
      expect(LevelProgressService.maxScore, greaterThan(0));
      expect(LevelProgressService.maxTimeSeconds, greaterThan(0));
    });
  });
}
