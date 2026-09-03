import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../lib/engine/arrow_puzzle_engine.dart';

void main() {
  group('ArrowPuzzleEngine', () {
    test('generates a solvable easy puzzle', () {
      final engine = ArrowPuzzleEngine(random: Random(101));
      final puzzle = engine.generate(difficulty: 1);

      expect(engine.validateSolution(puzzle), isTrue);
      expect(engine.isSolvable(puzzle), isTrue);
      expect(puzzle.solution.first, puzzle.start);
      expect(puzzle.solution.last, puzzle.finish);
    });

    test('generates larger hard and extreme puzzles', () {
      final engine = ArrowPuzzleEngine(random: Random(2026));
      final hard = engine.generate(difficulty: 6);
      final extreme = engine.generate(difficulty: 10);

      expect(engine.isSolvable(hard), isTrue);
      expect(engine.isSolvable(extreme), isTrue);
      expect(extreme.rows * extreme.columns,
          greaterThan(hard.rows * hard.columns));
    });

    test('solution search works independently of stored solution', () {
      final engine = ArrowPuzzleEngine(random: Random(303));
      final puzzle = engine.generate(difficulty: 5);
      final discovered = engine.findSolutionPath(puzzle);

      expect(discovered, isNotNull);
      expect(discovered!.first, puzzle.start);
      expect(discovered.last, puzzle.finish);
      expect(discovered.length, greaterThanOrEqualTo(2));
    });
  });
}
