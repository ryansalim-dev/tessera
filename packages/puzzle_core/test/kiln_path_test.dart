import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

const serpentine = [0, 1, 2, 5, 4, 3, 6, 7, 8];

void main() {
  const generator = KilnPathGenerator();

  group('KilnPathGenerator', () {
    test('is deterministic for the same seed', () {
      final a = generator.generate(42, Difficulty.steady);
      final b = generator.generate(42, Difficulty.steady);
      expect(a.checkpoints, b.checkpoints);
      expect(a.solution, b.solution);
    });

    test('different seeds give different lines', () {
      final a = generator.generate(1, Difficulty.gentle);
      final b = generator.generate(2, Difficulty.gentle);
      expect(a.solution, isNot(b.solution));
    });

    test('random paths cover the grid in single steps', () {
      for (final n in [4, 5, 7]) {
        final path = KilnPathGenerator.randomPath(n, SeededRandom(n));
        expect(path.toSet(), hasLength(n * n));
        for (var i = 1; i < path.length; i++) {
          final a = path[i - 1], b = path[i];
          expect((a ~/ n - b ~/ n).abs() + (a % n - b % n).abs(), 1);
        }
      }
    });

    for (final difficulty in Difficulty.values) {
      test('every ${difficulty.name} board has a unique line', () {
        for (var seed = 1; seed <= 15; seed++) {
          final p = generator.generate(seed * 7919, difficulty);
          final solver = KilnPathSolver(p.size);
          expect(p.size, KilnPathPuzzle.sizeFor(difficulty));
          expect(solver.countSolutions(p.checkpoints), 1, reason: 'seed $seed');
          expect(solver.solve(p.checkpoints), p.solution);
          expect(
              p.checkpointCount,
              greaterThanOrEqualTo(
                  KilnPathGenerator.targetCheckpoints(difficulty)));
        }
      });
    }

    test('fewer checkpoints on harder days', () {
      double average(Difficulty d) {
        var total = 0;
        for (var seed = 1; seed <= 10; seed++) {
          total += generator.generate(seed, d).checkpointCount;
        }
        return total / 10;
      }

      expect(average(Difficulty.fierce), lessThan(average(Difficulty.tricky)));
    });
  });

  group('KilnPathSolver', () {
    test('finds both lines when the board is ambiguous', () {
      // A 3x3 with only opposite corners marked has two mirror-image lines.
      final grid = List.filled(9, 0)
        ..[0] = 1
        ..[8] = 2;
      expect(KilnPathSolver(3).countSolutions(grid, limit: 10), 2);
    });

    test('respects checkpoint order', () {
      // Serpentine on 3x3: 0 1 2 / 5 4 3 / 6 7 8.
      final grid = List.filled(9, 0)
        ..[0] = 1
        ..[2] = 2
        ..[8] = 3;
      expect(KilnPathSolver(3).solve(grid), serpentine);
    });

    test('reports no solution for an impossible board', () {
      // Opposite colours on a 3x3 checkerboard cannot be the two ends.
      final grid = List.filled(9, 0)
        ..[0] = 1
        ..[1] = 2;
      expect(KilnPathSolver(3).countSolutions(grid), 0);
    });
  });

  group('KilnPathPuzzle', () {
    test('rejects a solution that skips a checkpoint', () {
      expect(
        () => KilnPathPuzzle(
          size: 2,
          checkpoints: [1, 3, 0, 2],
          solution: [0, 1, 3, 2],
        ),
        throwsArgumentError,
      );
    });

    test('bends are the corners of the line', () {
      final p = KilnPathPuzzle(
        size: 3,
        checkpoints: [1, 0, 0, 0, 0, 0, 0, 0, 2],
        solution: serpentine,
      );
      expect(p.bends, {2, 5, 3, 6});
      expect(p.keystoneShading(3),
          [false, false, true, true, false, true, true, false, false]);
    });
  });

  group('KilnPathBoard', () {
    late KilnPathPuzzle puzzle;
    late KilnPathBoard board;

    setUp(() {
      puzzle = generator.generate(2026, Difficulty.steady);
      board = KilnPathBoard(puzzle);
    });

    test('starts on checkpoint 1', () {
      expect(board.path, [puzzle.start]);
      expect(board.checkpointAt(board.head), 1);
      expect(board.nextCheckpoint, 2);
    });

    test('only steps to free orthogonal neighbours', () {
      final far = List.generate(puzzle.cellCount, (i) => i).firstWhere(
          (c) => !puzzle.areNeighbours(puzzle.start, c) && c != puzzle.start);
      expect(board.moveTo(far), isFalse);
      expect(board.moveTo(puzzle.solution[1]), isTrue);
      expect(board.head, puzzle.solution[1]);
    });

    test('cannot enter a checkpoint out of order', () {
      // Serpentine 0 1 2 / 5 4 3 / 6 7 8 with checkpoint 3 next to the start.
      final b = KilnPathBoard(KilnPathPuzzle(
        size: 3,
        checkpoints: [1, 0, 2, 3, 0, 0, 0, 0, 4],
        solution: serpentine,
      ));
      expect(b.canStep(3), isFalse);
      expect(b.moveTo(3), isFalse);
      expect(b.moveTo(1), isTrue);
      expect(b.moveTo(2), isTrue);
      expect(b.nextCheckpoint, 3);
    });

    test('the line stops at the last checkpoint', () {
      final b = KilnPathBoard(KilnPathPuzzle(
        size: 3,
        checkpoints: [1, 0, 0, 0, 0, 0, 0, 0, 2],
        solution: [0, 3, 6, 7, 4, 1, 2, 5, 8],
      ));
      // Walk 0 1 2 5 8: reaching checkpoint 2 early ends the line.
      for (final c in [1, 2, 5, 8]) {
        expect(b.moveTo(c), isTrue);
      }
      expect(b.canStep(7), isFalse);
      expect(b.nextCheckpoint, isNull);
      expect(b.isSolved, isFalse);
    });

    test('stepping back onto the line cuts it there', () {
      for (var i = 1; i <= 4; i++) {
        board.moveTo(puzzle.solution[i]);
      }
      expect(board.length, 5);
      expect(board.moveTo(puzzle.solution[2]), isTrue);
      expect(board.path, puzzle.solution.take(3));
      expect(board.undo(), isTrue);
      expect(board.length, 2);
      board.reset();
      expect(board.path, [puzzle.start]);
      expect(board.undo(), isFalse);
    });

    test('hint cuts back mistakes first', () {
      final b = KilnPathBoard(KilnPathPuzzle(
        size: 3,
        checkpoints: [1, 0, 0, 0, 0, 0, 0, 0, 2],
        solution: serpentine,
      ));
      b
        ..moveTo(3)
        ..moveTo(4);
      final hint = b.hint()!;
      expect(hint.reason, KilnPathHintReason.mistake);
      expect(hint.keep, 1);
      expect(hint.cell, 1);
      b.apply(hint);
      expect(b.path, [0, 1]);
      expect(b.hint()!.reason, KilnPathHintReason.nextStep);
    });

    test('following hints solves the board', () {
      var steps = 0;
      while (!board.isSolved) {
        board.apply(board.hint()!);
        expect(++steps, lessThanOrEqualTo(puzzle.cellCount));
      }
      expect(board.path, puzzle.solution);
      expect(board.nextCheckpoint, isNull);
      expect(board.hint(), isNull);
    });
  });
}
