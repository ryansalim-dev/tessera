import 'dart:typed_data';

import '../difficulty.dart';
import '../puzzle_kind.dart';

/// The day's keystone: a 5x5 grid where every row and column holds each
/// glaze 1-5 once.
///
/// Its givens come from the day's tray. Each solved puzzle reveals the
/// keystone tiles under its clue (the Glaze diagonal, the Kiln Path bends,
/// the Pebbles positions, and so on). With every clue the grid has exactly
/// one answer. Starting early with fewer clues is allowed: the keystone then
/// lends a few extra tiles so the answer stays unique, and the gold glaze is
/// only for a full-clue solve.
class KeystonePuzzle {
  KeystonePuzzle({
    required List<int> solution,
    required Map<PuzzleKind, Set<int>> clues,
    required Set<int> base,
    required List<int> lendOrder,
    this.difficulty,
  })  : solution = List.unmodifiable(solution),
        clues = Map.unmodifiable({
          for (final e in clues.entries) e.key: Set<int>.unmodifiable(e.value),
        }),
        base = Set.unmodifiable(base),
        lendOrder = List.unmodifiable(lendOrder) {
    if (solution.length != cellCount) {
      throw ArgumentError('Keystone solution must have $cellCount tiles.');
    }
    if (KeystoneSolver.countSolutions(_grid(allGivens)) != 1) {
      throw ArgumentError('Keystone must be unique with every clue.');
    }
  }

  static const size = 5;
  static const cellCount = size * size;

  /// Digits `1..5`, row-major.
  final List<int> solution;

  /// Tiles each tray puzzle reveals.
  final Map<PuzzleKind, Set<int>> clues;

  /// Tiles given from the start, whatever the player has solved.
  final Set<int> base;

  /// The order tiles are lent in when the player starts early.
  final List<int> lendOrder;

  final Difficulty? difficulty;

  Set<int> get allGivens => {...base, for (final c in clues.values) ...c};

  /// The tray puzzle that revealed [cell], if any (for colouring its rim).
  PuzzleKind? sourceOf(int cell) {
    for (final e in clues.entries) {
      if (e.value.contains(cell)) return e.key;
    }
    return null;
  }

  /// Givens for a player who has solved [solved]: the base, the clues they
  /// earned, and as many lent tiles as it takes to make the answer unique.
  KeystoneGivens givensFor(Set<PuzzleKind> solved) {
    final earned = {
      ...base,
      for (final k in solved)
        if (clues[k] != null) ...clues[k]!,
    };
    final lent = <int>{};
    for (final cell in lendOrder) {
      if (KeystoneSolver.countSolutions(_grid({...earned, ...lent})) == 1) {
        break;
      }
      if (!earned.contains(cell)) lent.add(cell);
    }
    return KeystoneGivens(
      grid: _grid({...earned, ...lent}),
      lent: lent,
      fullClues: clues.keys.every(solved.contains),
    );
  }

  List<int> _grid(Set<int> cells) => [
        for (var i = 0; i < cellCount; i++) cells.contains(i) ? solution[i] : 0,
      ];
}

/// What the player starts the keystone with.
class KeystoneGivens {
  KeystoneGivens({
    required List<int> grid,
    required Set<int> lent,
    required this.fullClues,
  })  : grid = List.unmodifiable(grid),
        lent = Set.unmodifiable(lent);

  /// Digit per tile, `0` where the player fills it in.
  final List<int> grid;

  /// Tiles the keystone lent because clues were missing.
  final Set<int> lent;

  /// Whether every tray clue was collected (needed for the gold glaze).
  final bool fullClues;
}

/// Backtracking solver for the 5x5 keystone Latin square.
abstract final class KeystoneSolver {
  static const _n = KeystonePuzzle.size;

  /// Counts solutions of [grid] (`0` = empty), stopping at [limit].
  static int countSolutions(List<int> grid, {int limit = 2}) {
    final rows = Int32List(_n), cols = Int32List(_n);
    final cells = Int32List.fromList(grid);
    for (var i = 0; i < cells.length; i++) {
      final v = cells[i];
      if (v == 0) continue;
      final bit = 1 << v;
      if ((rows[i ~/ _n] | cols[i % _n]) & bit != 0) return 0;
      rows[i ~/ _n] |= bit;
      cols[i % _n] |= bit;
    }
    var count = 0;
    void search() {
      if (count >= limit) return;
      var best = -1, bestOptions = 0, bestCount = 99;
      for (var i = 0; i < cells.length; i++) {
        if (cells[i] != 0) continue;
        final options = 0x3E & ~(rows[i ~/ _n] | cols[i % _n]);
        var k = 0;
        for (var x = options; x != 0; x &= x - 1) {
          k++;
        }
        if (k < bestCount) {
          best = i;
          bestOptions = options;
          bestCount = k;
          if (k <= 1) break;
        }
      }
      if (best == -1) {
        count++;
        return;
      }
      for (var v = 1; v <= _n && count < limit; v++) {
        final bit = 1 << v;
        if (bestOptions & bit == 0) continue;
        cells[best] = v;
        rows[best ~/ _n] |= bit;
        cols[best % _n] |= bit;
        search();
        rows[best ~/ _n] &= ~bit;
        cols[best % _n] &= ~bit;
        cells[best] = 0;
      }
    }

    search();
    return count;
  }
}
