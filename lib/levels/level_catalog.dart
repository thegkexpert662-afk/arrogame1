import '../models/arrow_template.dart';

/// Difficulty and board rules for every playable level.
/// The same reusable arrow templates can be selected again on later levels.
class LevelConfig {
  final int level;
  final int gridSize;
  final int arrowCount;
  final int minTurns;
  final int maxTurns;
  final double turnChance;

  const LevelConfig({
    required this.level,
    required this.gridSize,
    required this.arrowCount,
    required this.minTurns,
    required this.maxTurns,
    required this.turnChance,
  });

  bool accepts(ArrowTemplate template) =>
      template.turns >= minTurns && template.turns <= maxTurns;
}

/// 100 deterministic level configurations.
///
/// Progression:
/// 1-20   : 8-12 arrows, mostly straight/1-turn shapes
/// 21-50  : 12-19 arrows, more turns
/// 51-78  : 15-21 arrows, 1-3 turns
/// 79-100 : 18-24 arrows on a 10x10 board, up to 4 turns
const List<LevelConfig> levelCatalog = <LevelConfig>[
  LevelConfig(level: 1, gridSize: 9, arrowCount: 8, minTurns: 0, maxTurns: 1, turnChance: .35),
  LevelConfig(level: 2, gridSize: 9, arrowCount: 8, minTurns: 0, maxTurns: 1, turnChance: .36),
  LevelConfig(level: 3, gridSize: 9, arrowCount: 8, minTurns: 0, maxTurns: 1, turnChance: .37),
  LevelConfig(level: 4, gridSize: 9, arrowCount: 8, minTurns: 0, maxTurns: 1, turnChance: .38),
  LevelConfig(level: 5, gridSize: 9, arrowCount: 9, minTurns: 0, maxTurns: 1, turnChance: .39),
  LevelConfig(level: 6, gridSize: 9, arrowCount: 9, minTurns: 0, maxTurns: 1, turnChance: .40),
  LevelConfig(level: 7, gridSize: 9, arrowCount: 9, minTurns: 0, maxTurns: 1, turnChance: .41),
  LevelConfig(level: 8, gridSize: 9, arrowCount: 9, minTurns: 0, maxTurns: 1, turnChance: .42),
  LevelConfig(level: 9, gridSize: 9, arrowCount: 10, minTurns: 0, maxTurns: 1, turnChance: .43),
  LevelConfig(level: 10, gridSize: 9, arrowCount: 10, minTurns: 0, maxTurns: 1, turnChance: .44),
  LevelConfig(level: 11, gridSize: 9, arrowCount: 10, minTurns: 0, maxTurns: 1, turnChance: .45),
  LevelConfig(level: 12, gridSize: 9, arrowCount: 10, minTurns: 0, maxTurns: 1, turnChance: .46),
  LevelConfig(level: 13, gridSize: 9, arrowCount: 11, minTurns: 0, maxTurns: 1, turnChance: .47),
  LevelConfig(level: 14, gridSize: 9, arrowCount: 11, minTurns: 0, maxTurns: 1, turnChance: .48),
  LevelConfig(level: 15, gridSize: 9, arrowCount: 11, minTurns: 0, maxTurns: 1, turnChance: .49),
  LevelConfig(level: 16, gridSize: 9, arrowCount: 11, minTurns: 0, maxTurns: 1, turnChance: .50),
  LevelConfig(level: 17, gridSize: 9, arrowCount: 12, minTurns: 0, maxTurns: 1, turnChance: .51),
  LevelConfig(level: 18, gridSize: 9, arrowCount: 12, minTurns: 0, maxTurns: 1, turnChance: .52),
  LevelConfig(level: 19, gridSize: 9, arrowCount: 12, minTurns: 0, maxTurns: 1, turnChance: .53),
  LevelConfig(level: 20, gridSize: 9, arrowCount: 12, minTurns: 0, maxTurns: 1, turnChance: .54),
  LevelConfig(level: 21, gridSize: 9, arrowCount: 12, minTurns: 0, maxTurns: 2, turnChance: .55),
  LevelConfig(level: 22, gridSize: 9, arrowCount: 12, minTurns: 0, maxTurns: 2, turnChance: .56),
  LevelConfig(level: 23, gridSize: 9, arrowCount: 13, minTurns: 0, maxTurns: 2, turnChance: .57),
  LevelConfig(level: 24, gridSize: 9, arrowCount: 13, minTurns: 0, maxTurns: 2, turnChance: .58),
  LevelConfig(level: 25, gridSize: 9, arrowCount: 13, minTurns: 0, maxTurns: 2, turnChance: .59),
  LevelConfig(level: 26, gridSize: 9, arrowCount: 13, minTurns: 0, maxTurns: 2, turnChance: .60),
  LevelConfig(level: 27, gridSize: 9, arrowCount: 14, minTurns: 0, maxTurns: 2, turnChance: .61),
  LevelConfig(level: 28, gridSize: 9, arrowCount: 14, minTurns: 0, maxTurns: 2, turnChance: .62),
  LevelConfig(level: 29, gridSize: 9, arrowCount: 14, minTurns: 0, maxTurns: 2, turnChance: .63),
  LevelConfig(level: 30, gridSize: 9, arrowCount: 14, minTurns: 0, maxTurns: 2, turnChance: .64),
  LevelConfig(level: 31, gridSize: 9, arrowCount: 9, minTurns: 1, maxTurns: 2, turnChance: .65),
  LevelConfig(level: 32, gridSize: 9, arrowCount: 10, minTurns: 1, maxTurns: 2, turnChance: .66),
  LevelConfig(level: 33, gridSize: 9, arrowCount: 10, minTurns: 1, maxTurns: 2, turnChance: .67),
  LevelConfig(level: 34, gridSize: 9, arrowCount: 11, minTurns: 1, maxTurns: 2, turnChance: .68),
  LevelConfig(level: 35, gridSize: 9, arrowCount: 11, minTurns: 1, maxTurns: 2, turnChance: .69),
  LevelConfig(level: 36, gridSize: 9, arrowCount: 12, minTurns: 1, maxTurns: 2, turnChance: .70),
  LevelConfig(level: 37, gridSize: 9, arrowCount: 12, minTurns: 1, maxTurns: 2, turnChance: .71),
  LevelConfig(level: 38, gridSize: 9, arrowCount: 12, minTurns: 1, maxTurns: 2, turnChance: .72),
  LevelConfig(level: 39, gridSize: 9, arrowCount: 13, minTurns: 1, maxTurns: 2, turnChance: .73),
  LevelConfig(level: 40, gridSize: 9, arrowCount: 13, minTurns: 1, maxTurns: 2, turnChance: .74),
  LevelConfig(level: 41, gridSize: 9, arrowCount: 13, minTurns: 1, maxTurns: 2, turnChance: .75),
  LevelConfig(level: 42, gridSize: 9, arrowCount: 14, minTurns: 1, maxTurns: 2, turnChance: .76),
  LevelConfig(level: 43, gridSize: 9, arrowCount: 14, minTurns: 1, maxTurns: 2, turnChance: .77),
  LevelConfig(level: 44, gridSize: 9, arrowCount: 14, minTurns: 1, maxTurns: 2, turnChance: .78),
  LevelConfig(level: 45, gridSize: 9, arrowCount: 15, minTurns: 1, maxTurns: 2, turnChance: .79),
  LevelConfig(level: 46, gridSize: 9, arrowCount: 15, minTurns: 1, maxTurns: 2, turnChance: .80),
  LevelConfig(level: 47, gridSize: 9, arrowCount: 15, minTurns: 1, maxTurns: 2, turnChance: .81),
  LevelConfig(level: 48, gridSize: 9, arrowCount: 16, minTurns: 1, maxTurns: 2, turnChance: .82),
  LevelConfig(level: 49, gridSize: 9, arrowCount: 16, minTurns: 1, maxTurns: 2, turnChance: .83),
  LevelConfig(level: 50, gridSize: 9, arrowCount: 16, minTurns: 1, maxTurns: 2, turnChance: .84),
  LevelConfig(level: 51, gridSize: 9, arrowCount: 15, minTurns: 1, maxTurns: 3, turnChance: .80),
  LevelConfig(level: 52, gridSize: 9, arrowCount: 15, minTurns: 1, maxTurns: 3, turnChance: .81),
  LevelConfig(level: 53, gridSize: 9, arrowCount: 16, minTurns: 1, maxTurns: 3, turnChance: .82),
  LevelConfig(level: 54, gridSize: 9, arrowCount: 16, minTurns: 1, maxTurns: 3, turnChance: .83),
  LevelConfig(level: 55, gridSize: 9, arrowCount: 17, minTurns: 1, maxTurns: 3, turnChance: .84),
  LevelConfig(level: 56, gridSize: 9, arrowCount: 17, minTurns: 1, maxTurns: 3, turnChance: .85),
  LevelConfig(level: 57, gridSize: 9, arrowCount: 18, minTurns: 1, maxTurns: 3, turnChance: .86),
  LevelConfig(level: 58, gridSize: 9, arrowCount: 18, minTurns: 1, maxTurns: 3, turnChance: .87),
  LevelConfig(level: 59, gridSize: 9, arrowCount: 19, minTurns: 1, maxTurns: 3, turnChance: .88),
  LevelConfig(level: 60, gridSize: 9, arrowCount: 19, minTurns: 1, maxTurns: 3, turnChance: .89),
  LevelConfig(level: 61, gridSize: 9, arrowCount: 16, minTurns: 2, maxTurns: 3, turnChance: .84),
  LevelConfig(level: 62, gridSize: 9, arrowCount: 16, minTurns: 2, maxTurns: 3, turnChance: .85),
  LevelConfig(level: 63, gridSize: 9, arrowCount: 17, minTurns: 2, maxTurns: 3, turnChance: .86),
  LevelConfig(level: 64, gridSize: 9, arrowCount: 17, minTurns: 2, maxTurns: 3, turnChance: .87),
  LevelConfig(level: 65, gridSize: 9, arrowCount: 18, minTurns: 2, maxTurns: 3, turnChance: .88),
  LevelConfig(level: 66, gridSize: 9, arrowCount: 18, minTurns: 2, maxTurns: 3, turnChance: .89),
  LevelConfig(level: 67, gridSize: 9, arrowCount: 19, minTurns: 2, maxTurns: 3, turnChance: .90),
  LevelConfig(level: 68, gridSize: 9, arrowCount: 19, minTurns: 2, maxTurns: 3, turnChance: .91),
  LevelConfig(level: 69, gridSize: 9, arrowCount: 20, minTurns: 2, maxTurns: 3, turnChance: .92),
  LevelConfig(level: 70, gridSize: 9, arrowCount: 20, minTurns: 2, maxTurns: 3, turnChance: .93),
  LevelConfig(level: 71, gridSize: 9, arrowCount: 18, minTurns: 2, maxTurns: 4, turnChance: .88),
  LevelConfig(level: 72, gridSize: 9, arrowCount: 18, minTurns: 2, maxTurns: 4, turnChance: .89),
  LevelConfig(level: 73, gridSize: 9, arrowCount: 19, minTurns: 2, maxTurns: 4, turnChance: .90),
  LevelConfig(level: 74, gridSize: 9, arrowCount: 19, minTurns: 2, maxTurns: 4, turnChance: .91),
  LevelConfig(level: 75, gridSize: 9, arrowCount: 20, minTurns: 2, maxTurns: 4, turnChance: .92),
  LevelConfig(level: 76, gridSize: 9, arrowCount: 20, minTurns: 2, maxTurns: 4, turnChance: .93),
  LevelConfig(level: 77, gridSize: 9, arrowCount: 21, minTurns: 2, maxTurns: 4, turnChance: .94),
  LevelConfig(level: 78, gridSize: 9, arrowCount: 21, minTurns: 2, maxTurns: 4, turnChance: .95),
  LevelConfig(level: 79, gridSize: 10, arrowCount: 18, minTurns: 2, maxTurns: 4, turnChance: .90),
  LevelConfig(level: 80, gridSize: 10, arrowCount: 18, minTurns: 2, maxTurns: 4, turnChance: .91),
  LevelConfig(level: 81, gridSize: 10, arrowCount: 19, minTurns: 2, maxTurns: 4, turnChance: .92),
  LevelConfig(level: 82, gridSize: 10, arrowCount: 19, minTurns: 2, maxTurns: 4, turnChance: .93),
  LevelConfig(level: 83, gridSize: 10, arrowCount: 20, minTurns: 2, maxTurns: 4, turnChance: .94),
  LevelConfig(level: 84, gridSize: 10, arrowCount: 20, minTurns: 2, maxTurns: 4, turnChance: .95),
  LevelConfig(level: 85, gridSize: 10, arrowCount: 21, minTurns: 2, maxTurns: 4, turnChance: .96),
  LevelConfig(level: 86, gridSize: 10, arrowCount: 21, minTurns: 2, maxTurns: 4, turnChance: .97),
  LevelConfig(level: 87, gridSize: 10, arrowCount: 22, minTurns: 2, maxTurns: 4, turnChance: .97),
  LevelConfig(level: 88, gridSize: 10, arrowCount: 22, minTurns: 2, maxTurns: 4, turnChance: .98),
  LevelConfig(level: 89, gridSize: 10, arrowCount: 22, minTurns: 2, maxTurns: 4, turnChance: .98),
  LevelConfig(level: 90, gridSize: 10, arrowCount: 22, minTurns: 2, maxTurns: 4, turnChance: .99),
  LevelConfig(level: 91, gridSize: 10, arrowCount: 23, minTurns: 2, maxTurns: 4, turnChance: .99),
  LevelConfig(level: 92, gridSize: 10, arrowCount: 23, minTurns: 2, maxTurns: 4, turnChance: .99),
  LevelConfig(level: 93, gridSize: 10, arrowCount: 23, minTurns: 2, maxTurns: 4, turnChance: .99),
  LevelConfig(level: 94, gridSize: 10, arrowCount: 23, minTurns: 2, maxTurns: 4, turnChance: .99),
  LevelConfig(level: 95, gridSize: 10, arrowCount: 24, minTurns: 2, maxTurns: 4, turnChance: .99),
  LevelConfig(level: 96, gridSize: 10, arrowCount: 24, minTurns: 2, maxTurns: 4, turnChance: .99),
  LevelConfig(level: 97, gridSize: 10, arrowCount: 24, minTurns: 2, maxTurns: 4, turnChance: .99),
  LevelConfig(level: 98, gridSize: 10, arrowCount: 24, minTurns: 2, maxTurns: 4, turnChance: .99),
  LevelConfig(level: 99, gridSize: 10, arrowCount: 24, minTurns: 2, maxTurns: 4, turnChance: .99),
  LevelConfig(level: 100, gridSize: 10, arrowCount: 24, minTurns: 2, maxTurns: 4, turnChance: .99),
];

LevelConfig levelConfigFor(int level) => levelCatalog[(level.clamp(1, 100)) - 1];
