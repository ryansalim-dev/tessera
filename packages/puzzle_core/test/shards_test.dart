import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  const generator = ShardsGenerator();

  group('ShardShape', () {
    final ell = ShardShape([(0, 0), (1, 0), (2, 0), (2, 1)]);

    test('normalises and compares by cells', () {
      expect(ShardShape([(5, 5), (6, 5), (7, 5), (7, 6)]), ell);
      expect([ell.rows, ell.cols], [3, 2]);
    });

    test('four quarter turns come back around', () {
      expect(ell.rotated(4), ell);
      expect(ell.rotated(1), isNot(ell));
      expect(ell.rotated(1).rotated(3), ell);
      expect([ell.rotated(1).rows, ell.rotated(1).cols], [2, 3]);
    });
  });

  group('ShardsGenerator', () {
    test('is deterministic for the same seed', () {
      final a = generator.generate(42, Difficulty.tricky);
      final b = generator.generate(42, Difficulty.tricky);
      expect(a.plate, b.plate);
      expect(a.shards, b.shards);
      expect(a.solution, b.solution);
    });

    for (final difficulty in Difficulty.values) {
      test('${difficulty.name} shards rebuild the plate', () {
        final (minSize, maxSize, chips) = ShardsGenerator.shapeFor(difficulty);
        for (var seed = 1; seed <= 20; seed++) {
          // The constructor checks the solution covers the plate exactly.
          final p = generator.generate(seed * 7919, difficulty);
          expect(p.size, ShardsPuzzle.sizeFor(difficulty));
          expect(p.plateArea, p.cellCount - chips);
          for (final s in p.shards) {
            expect(s.size, inInclusiveRange(minSize, maxSize + 1));
          }
        }
      });
    }
  });

  group('ShardsBoard', () {
    late ShardsPuzzle puzzle;
    late ShardsBoard board;

    setUp(() {
      puzzle = generator.generate(2026, Difficulty.steady);
      board = ShardsBoard(puzzle);
    });

    test('placing at the solution spots solves it', () {
      for (var i = 0; i < board.shardCount; i++) {
        expect(board.place(i, puzzle.solution[i]), isTrue, reason: 'shard $i');
      }
      expect(board.isSolved, isTrue);
      expect(board.owners.where((o) => o == -1),
          hasLength(puzzle.cellCount - puzzle.plateArea));
    });

    test('rejects overlaps and overhangs', () {
      board.place(0, puzzle.solution[0]);
      final cells = puzzle.cellsFor(0, puzzle.solution[0])!;
      // Another shard dropped onto shard 0's first tile overlaps it.
      final r = cells.first ~/ puzzle.size, c = cells.first % puzzle.size;
      final overlapping = [
        for (var t = 0; t < 4; t++)
          for (var dr = -3; dr <= 0; dr++)
            for (var dc = -3; dc <= 0; dc++)
              if (puzzle
                      .cellsFor(1, ShardPlacement(t, r + dr, c + dc))
                      ?.contains(cells.first) ??
                  false)
                ShardPlacement(t, r + dr, c + dc),
      ];
      expect(overlapping, isNotEmpty);
      expect(board.place(1, overlapping.first), isFalse);
      expect(board.place(1, ShardPlacement(0, puzzle.size, 0)), isFalse);
    });

    test('turning a tray shard and lifting a placed one', () {
      board.turn(2);
      expect(board.turnsOf(2), 1);
      board.place(0, puzzle.solution[0]);
      expect(board.isPlaced(0), isTrue);
      board.lift(0);
      expect(board.isPlaced(0), isFalse);
      expect(board.turnsOf(0), puzzle.solution[0].turns % 4);
    });

    test('following hints solves the board, fixing misplaced shards', () {
      // Put shard 0 somewhere it fits but is wrong, if there is such a spot.
      outer:
      for (var t = 0; t < 4; t++) {
        for (var r = 0; r < puzzle.size; r++) {
          for (var c = 0; c < puzzle.size; c++) {
            final p = ShardPlacement(t, r, c);
            final cells = puzzle.cellsFor(0, p);
            final want = puzzle.cellsFor(0, puzzle.solution[0])!;
            if (cells != null && !cells.toSet().containsAll(want)) {
              board.place(0, p);
              break outer;
            }
          }
        }
      }
      var steps = 0;
      while (!board.isSolved) {
        board.apply(board.hint()!);
        expect(++steps, lessThanOrEqualTo(3 * board.shardCount));
      }
      expect(board.hint(), isNull);
      board.reset();
      expect(board.placedCount, 0);
    });

    test('keystone outline is the biggest shard', () {
      final mask = puzzle.keystoneShard();
      final biggest =
          puzzle.shards.map((s) => s.size).reduce((a, b) => a > b ? a : b);
      expect(mask.where((m) => m), hasLength(biggest));
    });
  });
}
