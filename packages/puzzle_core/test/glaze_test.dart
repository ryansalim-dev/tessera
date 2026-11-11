import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  const generator = GlazeGenerator();

  group('GlazeGenerator', () {
    test('is deterministic for the same seed', () {
      final a = generator.generate(42, Difficulty.steady);
      final b = generator.generate(42, Difficulty.steady);
      expect(a.givens, b.givens);
      expect(a.solution, b.solution);
    });

    test('different seeds give different puzzles', () {
      final a = generator.generate(1, Difficulty.gentle);
      final b = generator.generate(2, Difficulty.gentle);
      expect(a.solution, isNot(b.solution));
    });

    for (final difficulty in Difficulty.values) {
      test('every ${difficulty.name} board is uniquely solvable', () {
        for (var seed = 1; seed <= 15; seed++) {
          final p = generator.generate(seed * 7919, difficulty);
          final solver = GlazeSolver(p.layout);
          expect(solver.countSolutions(p.givens), 1, reason: 'seed $seed');
          expect(solver.solve(p.givens), p.solution);
          expect(
              p.givenCount,
              greaterThanOrEqualTo(
                  GlazeGenerator.targetGivens(p.layout, difficulty)));
        }
      });
    }

    test('solution is a valid grid', () {
      for (final layout in GlazeLayout.values) {
        final p = generator.generate(99, Difficulty.gentle, layout: layout);
        final board = GlazeBoard(p);
        for (var i = 0; i < p.layout.cellCount; i++) {
          if (board.canEdit(i)) board.place(i, p.solution[i]);
        }
        expect(board.isSolved, isTrue, reason: layout.name);
      }
    });

    test('layout follows difficulty', () {
      expect(generator.generate(5, Difficulty.gentle).size, 6);
      expect(generator.generate(5, Difficulty.fierce).size, 9);
    });
  });

  group('GlazeBoard', () {
    late GlazePuzzle puzzle;
    late GlazeBoard board;

    setUp(() {
      puzzle = generator.generate(2026, Difficulty.gentle);
      board = GlazeBoard(puzzle);
    });

    int firstEmpty() => puzzle.givens.indexOf(0);

    test('givens cannot be edited', () {
      final given = puzzle.givens.indexWhere((v) => v != 0);
      expect(board.place(given, 1), isFalse);
      expect(board.clear(given), isFalse);
      expect(board.valueAt(given), puzzle.givens[given]);
    });

    test('flags conflicting tiles', () {
      final i = firstEmpty();
      final peer = puzzle.peers(i).firstWhere((p) => puzzle.givens[p] != 0);
      board.place(i, puzzle.givens[peer]);
      expect(board.conflicts(), containsAll([i, peer]));
      board.clear(i);
      expect(board.conflicts(), isEmpty);
    });

    test('hint points out mistakes first', () {
      final i = firstEmpty();
      final wrong = puzzle.solution[i] % puzzle.size + 1;
      board.place(i, wrong);
      final hint = board.hint()!;
      expect(hint.reason, GlazeHintReason.mistake);
      expect(hint.index, i);
      expect(hint.value, puzzle.solution[i]);
    });

    test('following hints solves the board', () {
      var steps = 0;
      while (!board.isSolved) {
        final hint = board.hint()!;
        expect(hint.value, puzzle.solution[hint.index]);
        board.place(hint.index, hint.value);
        expect(++steps, lessThanOrEqualTo(puzzle.layout.cellCount));
      }
      expect(board.hint(), isNull);
    });

    test('reset restores givens', () {
      board.place(firstEmpty(), 1);
      board.reset();
      expect(board.cells, puzzle.givens);
    });
  });
}
