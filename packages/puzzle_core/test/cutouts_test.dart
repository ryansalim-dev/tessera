import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  const generator = CutoutsGenerator();

  group('FoldedSheet', () {
    test('folding left over right stacks mirrored columns', () {
      final s = FoldedSheet.flat(4).fold(Fold.leftOverRight);
      expect([s.x0, s.x1, s.y0, s.y1], [2, 4, 0, 4]);
      // Cell (row 0, col 2) now also holds (row 0, col 1).
      expect(s.layersAt(2), {2, 1});
      expect(s.layersAt(3), {3, 0});
      expect(s.isVisible(0), isFalse);
    });

    test('two folds stack four layers', () {
      final s =
          FoldedSheet.flat(4).fold(Fold.rightOverLeft).fold(Fold.bottomOverTop);
      expect([s.x0, s.x1, s.y0, s.y1], [0, 2, 0, 2]);
      expect(s.layersAt(0), {0, 3, 12, 15});
      expect(s.punch([5]), {5, 6, 9, 10});
    });

    test('an odd edge cannot be folded', () {
      final s = FoldedSheet.flat(6).fold(Fold.leftOverRight);
      expect(s.canFold(Fold.leftOverRight), isFalse);
      expect(() => s.fold(Fold.rightOverLeft), throwsStateError);
      expect(s.canFold(Fold.topOverBottom), isTrue);
    });
  });

  group('CutoutsGenerator', () {
    test('is deterministic for the same seed', () {
      final a = generator.generate(42, Difficulty.tricky);
      final b = generator.generate(42, Difficulty.tricky);
      expect(a.folds, b.folds);
      expect(a.stamps, b.stamps);
      expect(a.answer, b.answer);
    });

    for (final difficulty in Difficulty.values) {
      test('${difficulty.name}: four distinct options, one true', () {
        final (size, folds, stamps) = CutoutsGenerator.shapeFor(difficulty);
        final answers = <int>{};
        for (var seed = 1; seed <= 30; seed++) {
          final p = generator.generate(seed * 7919, difficulty);
          expect(p.size, size);
          expect(p.folds, hasLength(folds));
          expect(p.stamps, hasLength(stamps));
          expect(p.options, hasLength(4));
          expect(p.holes, p.foldedSheet.punch(p.stamps));
          answers.add(p.answer);
        }
        // The answer is not always in the same slot.
        expect(answers.length, greaterThan(1));
      });
    }
  });

  group('CutoutsBoard', () {
    late CutoutsPuzzle puzzle;
    late CutoutsBoard board;

    setUp(() {
      puzzle = generator.generate(2026, Difficulty.steady);
      board = CutoutsBoard(puzzle);
    });

    test('a wrong pick is ruled out and counted', () {
      final wrong = (puzzle.answer + 1) % 4;
      expect(board.pick(wrong), isFalse);
      expect(board.ruledOut, {wrong});
      expect(board.mistakes, 1);
      expect(board.pick(wrong), isFalse);
      expect(board.mistakes, 1, reason: 'repeat picks are ignored');
    });

    test('the right pick solves it', () {
      expect(board.pick(puzzle.answer), isTrue);
      expect(board.isSolved, isTrue);
      expect(board.hint(), isNull);
      board.reset();
      expect(board.isSolved, isFalse);
    });

    test('hints rule out every wrong option, never the answer', () {
      for (var i = 0; i < 3; i++) {
        final h = board.hint()!;
        expect(h, isNot(puzzle.answer));
        board.apply(h);
      }
      expect(board.hint(), isNull);
      expect(board.ruledOut, hasLength(3));
    });
  });
}
