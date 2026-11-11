import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

/// 3x3 plate: seam 1 runs 0 1 2 5 8, seam 2 runs 3 4 7 6.
SeamsPuzzle _small() => SeamsPuzzle(
      size: 3,
      endpoints: [1, 0, 0, 2, 0, 0, 2, 0, 1],
      seams: [
        [0, 1, 2, 5, 8],
        [3, 4, 7, 6],
      ],
    );

void main() {
  const generator = SeamsGenerator();

  group('SeamsGenerator', () {
    test('is deterministic for the same seed', () {
      final a = generator.generate(42, Difficulty.steady);
      final b = generator.generate(42, Difficulty.steady);
      expect(a.endpoints, b.endpoints);
      expect(a.seams, b.seams);
    });

    for (final difficulty in Difficulty.values) {
      test('every ${difficulty.name} plate has one answer', () {
        for (var seed = 1; seed <= 10; seed++) {
          final p = generator.generate(seed * 7919, difficulty);
          expect(p.size, SeamsPuzzle.sizeFor(difficulty));
          expect(p.pairCount, SeamsGenerator.pairCount(p.size, difficulty));
          final solver = SeamsSolver(p.size);
          expect(solver.countSolutions(p.endpoints), 1, reason: 'seed $seed');
          expect(solver.solve(p.endpoints), p.solutionOwners);
        }
      });
    }
  });

  group('SeamsSolver', () {
    test('finds the small plate', () {
      final p = _small();
      expect(SeamsSolver(3).solve(p.endpoints), p.solutionOwners);
    });

    test('needs the whole plate covered', () {
      // 1 at 0 and 1, 2 at 7 and 8: short seams leave tiles uncovered, and
      // there is no way to bend them to fill the rest.
      expect(SeamsSolver(3).countSolutions([1, 1, 0, 0, 0, 0, 0, 2, 2]), 0);
    });

    test('counts more than one answer', () {
      // One pair in opposite corners of a 3x3 snakes two mirror ways.
      expect(
        SeamsSolver(3).countSolutions([1, 0, 0, 0, 0, 0, 0, 0, 1], limit: 5),
        2,
      );
    });
  });

  group('SeamsPuzzle', () {
    test('rejects seams that skip a tile', () {
      expect(
        () => SeamsPuzzle(
          size: 2,
          endpoints: [1, 0, 0, 1],
          seams: [
            [0, 3],
          ],
        ),
        throwsArgumentError,
      );
    });

    test('keystone shape is the longest seam\'s steps', () {
      // 0 -> 1 -> 2 right, right; 2 -> 5 -> 8 down, down.
      expect(_small().keystoneSeamShape, [1, 1, 2, 2]);
    });
  });

  group('SeamsBoard', () {
    test('draws a seam from a shard and joins it', () {
      final b = SeamsBoard(_small());
      expect(b.begin(0), isTrue);
      for (final c in [1, 2, 5]) {
        expect(b.extend(c), isTrue);
      }
      expect(b.isJoined(1), isFalse);
      expect(b.extend(8), isTrue);
      expect(b.isJoined(1), isTrue);
      expect(b.extend(7), isFalse, reason: 'a joined seam stops');
    });

    test('cannot run onto another pair\'s shard', () {
      final b = SeamsBoard(_small())..begin(0);
      expect(b.extend(3), isFalse);
    });

    test('drawing over another seam cuts it', () {
      final b = SeamsBoard(_small())
        ..begin(3)
        ..extend(4)
        ..extend(5)
        ..end();
      expect(b.seam(2), [3, 4, 5]);
      b
        ..begin(8)
        ..extend(5);
      expect(b.seam(2), [3, 4]);
      expect(b.seam(1), [8, 5]);
    });

    test('drawing back cuts your own seam', () {
      final b = SeamsBoard(_small())
        ..begin(0)
        ..extend(1)
        ..extend(2);
      expect(b.extend(1), isTrue);
      expect(b.seam(1), [0, 1]);
      b
        ..end()
        ..begin(1);
      expect(b.active, 1);
    });

    test('hints fix wrong seams, then lay missing ones', () {
      final b = SeamsBoard(_small())
        ..begin(3)
        ..extend(4)
        ..extend(5)
        ..end();
      final hint = b.hint()!;
      expect(hint.pair, 2);
      expect(hint.reason, SeamsHintReason.mistake);
      b.apply(hint);
      expect(b.seam(2), [3, 4, 7, 6]);
      expect(b.hint()!.reason, SeamsHintReason.reveal);
    });

    test('following hints solves a generated plate', () {
      final p = generator.generate(2026, Difficulty.tricky);
      final b = SeamsBoard(p);
      var steps = 0;
      while (!b.isSolved) {
        b.apply(b.hint()!);
        expect(++steps, lessThanOrEqualTo(p.pairCount));
      }
      expect(b.joinedCount, p.pairCount);
      b.reset();
      expect(b.joinedCount, 0);
    });
  });
}
