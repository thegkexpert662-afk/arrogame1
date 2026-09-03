import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../lib/engine/arrow_puzzle_engine.dart';

void main() {
  group('Safety & Quality', () {
    test('generated puzzles are always solvable across difficulties', () {
      for (var difficulty = 1; difficulty <= 10; difficulty++) {
        final engine = ArrowPuzzleEngine(random: Random(9000 + difficulty));
        for (var attempt = 0; attempt < 5; attempt++) {
          final puzzle = engine.generate(difficulty: difficulty);
          expect(engine.validateSolution(puzzle), isTrue);
          expect(engine.isSolvable(puzzle), isTrue);
          expect(puzzle.solution.first, puzzle.start);
          expect(puzzle.solution.last, puzzle.finish);
        }
      }
    });

    test('solution path only uses valid adjacent moves', () {
      final engine = ArrowPuzzleEngine(random: Random(12345));
      final puzzle = engine.generate(difficulty: 10);
      final path = engine.findSolutionPath(puzzle)!;

      for (var i = 0; i < path.length - 1; i++) {
        final rowDistance = (path[i].row - path[i + 1].row).abs();
        final colDistance = (path[i].col - path[i + 1].col).abs();
        expect(rowDistance + colDistance, 1);
      }
    });

    test('generator produces more than one layout for repeated seeds', () {
      final engine = ArrowPuzzleEngine(random: Random(777));
      final fingerprints = <String>{};
      for (var i = 0; i < 10; i++) {
        final puzzle = engine.generate(difficulty: 5);
        fingerprints.add('${puzzle.start}|${puzzle.finish}|${puzzle.cells.map((c) => c.arrows).join(';')}');
      }
      expect(fingerprints.length, greaterThan(1));
    });
  });
}
