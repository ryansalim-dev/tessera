import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  const builder = KeystoneBuilder();

  group('KeystoneBuilder', () {
    test('is deterministic for a day', () {
      final day = PuzzleDay(2026, 11, 11);
      final a = builder.forDay(day), b = builder.forDay(day);
      expect(a.solution, b.solution);
      expect(a.clues, b.clues);
      expect(a.base, b.base);
    });

    test('every day in a month is unique with all clues', () {
      for (var d = 1; d <= 30; d++) {
        final day = PuzzleDay(2026, 11, d);
        // The constructor already enforces uniqueness; check the shape too.
        final k = builder.forDay(day);
        final tray = DailyTray.forDay(day).kinds;
        expect(k.clues.keys.toSet(), tray.toSet(), reason: day.key);
        for (final cells in k.clues.values) {
          expect(cells, isNotEmpty);
          expect(
              cells.length,
              lessThanOrEqualTo(
                  KeystoneBuilder.revealsPerClue(day.difficulty)));
        }
        // No two clues reveal the same tile.
        final all = [for (final c in k.clues.values) ...c];
        expect(all.toSet(), hasLength(all.length));
        final full = k.givensFor(tray.toSet());
        expect(full.lent, isEmpty, reason: day.key);
        expect(full.fullClues, isTrue);
      }
    });

    test('solution is a Latin square', () {
      final k = builder.forDay(PuzzleDay(2026, 11, 13));
      for (var i = 0; i < 5; i++) {
        expect(
            {for (var c = 0; c < 5; c++) k.solution[i * 5 + c]}, hasLength(5));
        expect(
            {for (var r = 0; r < 5; r++) k.solution[r * 5 + i]}, hasLength(5));
      }
    });

    test('Glaze reveals tiles on the diagonal', () {
      final picture =
          KeystoneBuilder.cluePicture(PuzzleKind.glaze, 1, Difficulty.gentle);
      expect([
        for (var i = 0; i < 25; i++)
          if (picture[i]) i
      ], [
        0,
        6,
        12,
        18,
        24
      ]);
    });

    test('every type gives a 5x5 picture', () {
      for (final kind in PuzzleKind.values) {
        for (final d in Difficulty.values) {
          expect(KeystoneBuilder.cluePicture(kind, 99, d), hasLength(25),
              reason: '${kind.name} ${d.name}');
        }
      }
    });
  });

  group('starting early', () {
    final day = PuzzleDay(2026, 11, 11);
    final k = builder.forDay(day);
    final tray = DailyTray.forDay(day).kinds;

    test('with no clues, tiles are lent until the answer is unique', () {
      final g = k.givensFor({});
      expect(g.fullClues, isFalse);
      expect(g.lent, isNotEmpty);
      expect(KeystoneSolver.countSolutions(g.grid), 1);
    });

    test('each clue earned means fewer or equal lent tiles', () {
      var previous = k.givensFor({}).lent.length;
      final solved = <PuzzleKind>{};
      for (final kind in tray) {
        solved.add(kind);
        final g = k.givensFor(solved);
        expect(KeystoneSolver.countSolutions(g.grid), 1);
        expect(g.lent.length, lessThanOrEqualTo(previous));
        previous = g.lent.length;
      }
      expect(previous, 0);
    });
  });

  group('KeystoneBoard', () {
    final k = builder.forDay(PuzzleDay(2026, 11, 11));

    test('givens are fixed, conflicts are flagged', () {
      final b = KeystoneBoard(k, k.givensFor(k.clues.keys.toSet()));
      final given = b.givens.grid.indexWhere((v) => v != 0);
      expect(b.place(given, 1), isFalse);
      final empty = b.cells.indexOf(0);
      final row = empty ~/ 5;
      final rowGiven = [for (var c = 0; c < 5; c++) row * 5 + c]
          .firstWhere((i) => b.isGiven(i), orElse: () => -1);
      if (rowGiven != -1) {
        b.place(empty, b.valueAt(rowGiven));
        expect(b.conflicts(), containsAll([empty, rowGiven]));
      }
    });

    test('following hints solves it', () {
      final b = KeystoneBoard(k, k.givensFor({}));
      b.place(b.cells.indexOf(0), 1);
      var steps = 0;
      while (!b.isSolved) {
        final (cell, value) = b.hint()!;
        b.place(cell, value);
        expect(++steps, lessThanOrEqualTo(26));
      }
      expect(b.cells, k.solution);
      b.reset();
      expect(b.cells, b.givens.grid);
    });
  });

  test('KeystoneSolver counts Latin squares', () {
    expect(KeystoneSolver.countSolutions(List.filled(25, 0)), 2);
    expect(KeystoneSolver.countSolutions([1, 1, ...List.filled(23, 0)]), 0);
  });
}
