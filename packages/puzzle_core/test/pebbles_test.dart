import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  const generator = PebblesGenerator();

  group('PebblesGenerator', () {
    test('is deterministic for the same seed', () {
      final a = generator.generate(42, Difficulty.steady);
      final b = generator.generate(42, Difficulty.steady);
      expect(a.regions, b.regions);
      expect(a.solution, b.solution);
    });

    test('different seeds give different boards', () {
      final a = generator.generate(1, Difficulty.gentle);
      final b = generator.generate(2, Difficulty.gentle);
      expect(a.regions, isNot(b.regions));
    });

    for (final difficulty in Difficulty.values) {
      test('every ${difficulty.name} board has one answer', () {
        for (var seed = 1; seed <= 15; seed++) {
          final p = generator.generate(seed * 7919, difficulty);
          expect(p.size, PebblesPuzzle.sizeFor(difficulty));
          final solver = PebblesSolver(p.size);
          expect(solver.countSolutions(p.regions), 1, reason: 'seed $seed');
          expect(solver.solutions(p.regions).single, p.solution);
        }
      });
    }

    test('regions are connected and each holds one pebble', () {
      for (var seed = 1; seed <= 10; seed++) {
        final p = generator.generate(seed, Difficulty.fierce);
        for (var r = 0; r < p.size; r++) {
          final cells = [
            for (var c = 0; c < p.cellCount; c++)
              if (p.regions[c] == r) c,
          ];
          final seen = {cells.first};
          final stack = [cells.first];
          while (stack.isNotEmpty) {
            final c = stack.removeLast();
            for (final nb in cells) {
              final adj =
                  (p.row(c) - p.row(nb)).abs() + (p.col(c) - p.col(nb)).abs() ==
                      1;
              if (adj && seen.add(nb)) stack.add(nb);
            }
          }
          expect(seen, hasLength(cells.length), reason: 'seed $seed r$r');
          expect(p.solution.where((c) => p.regions[c] == r), hasLength(1));
        }
      }
    });
  });

  group('PebblesPuzzle', () {
    test('rejects touching pebbles', () {
      // 4x4, one region per row; pebbles on the diagonal touch.
      expect(
        () => PebblesPuzzle(
          size: 4,
          regions: [for (var i = 0; i < 16; i++) i ~/ 4],
          solution: [0, 5, 10, 15],
        ),
        throwsArgumentError,
      );
    });

    test('keystone no-entry mask marks pebbles in the corner window', () {
      final p = generator.generate(3, Difficulty.gentle);
      final mask = p.keystoneNoEntry();
      expect(mask, hasLength(25));
      expect(mask.where((m) => m), hasLength(5));
    });
  });

  group('PebblesBoard', () {
    late PebblesPuzzle puzzle;
    late PebblesBoard board;

    setUp(() {
      puzzle = generator.generate(2026, Difficulty.steady);
      board = PebblesBoard(puzzle);
    });

    test('tap cycles empty, pebble, dot', () {
      expect(board.cycle(0), PebbleMark.pebble);
      expect(board.cycle(0), PebbleMark.dot);
      expect(board.cycle(0), PebbleMark.empty);
    });

    test('flags touching and same-line pebbles', () {
      board
        ..set(0, PebbleMark.pebble)
        ..set(puzzle.size + 1, PebbleMark.pebble);
      expect(board.conflicts(), {0, puzzle.size + 1});
      board.set(puzzle.size + 1, PebbleMark.empty);
      board.set(3, PebbleMark.pebble);
      expect(board.conflicts(), {0, 3});
      board.set(3, PebbleMark.dot);
      expect(board.conflicts(), isEmpty);
    });

    test('hint fixes mistakes first', () {
      final wrong = List.generate(puzzle.cellCount, (i) => i)
          .firstWhere((c) => !puzzle.solution.contains(c));
      board
        ..set(wrong, PebbleMark.pebble)
        ..set(puzzle.solution.last, PebbleMark.dot);
      var hint = board.hint()!;
      expect(hint.reason, PebblesHintReason.mistake);
      board.apply(hint);
      hint = board.hint()!;
      expect(hint.reason, PebblesHintReason.mistake);
      board.apply(hint);
      expect(board.markAt(wrong), PebbleMark.dot);
      expect(board.markAt(puzzle.solution.last), PebbleMark.pebble);
    });

    test('following hints solves the board', () {
      var steps = 0;
      while (!board.isSolved) {
        board.apply(board.hint()!);
        expect(++steps, lessThanOrEqualTo(puzzle.size));
      }
      expect(board.pebbles, puzzle.solution.toSet());
      expect(board.hint(), isNull);
      board.reset();
      expect(board.pebbles, isEmpty);
    });
  });
}
