import 'glaze_puzzle.dart';

/// Bitmask backtracking solver used for generation (uniqueness checks) and
/// for filling a fresh solution grid.
class GlazeSolver {
  GlazeSolver(this.layout)
      : _size = layout.size,
        _full = (1 << (layout.size + 1)) - 2;

  final GlazeLayout layout;
  final int _size;
  final int _full;

  int _box(int r, int c) =>
      (r ~/ layout.boxRows) * (_size ~/ layout.boxCols) + c ~/ layout.boxCols;

  /// Counts solutions of [grid] (0 = empty), stopping at [limit].
  int countSolutions(List<int> grid, {int limit = 2}) {
    final state = _State.from(this, grid);
    if (state == null) return 0;
    var count = 0;
    void search() {
      if (count >= limit) return;
      final cell = state.bestEmptyCell();
      if (cell == -1) {
        count++;
        return;
      }
      var options = state.candidates(cell);
      while (options != 0 && count < limit) {
        final bit = options & -options;
        options ^= bit;
        state.place(cell, bit);
        search();
        state.unplace(cell, bit);
      }
    }

    search();
    return count;
  }

  /// Returns one solution, or null if none. If [order] is given, digits are
  /// tried in that order (used to randomize full-grid generation).
  List<int>? solve(List<int> grid, {List<int>? order}) {
    final state = _State.from(this, grid);
    if (state == null) return null;
    final digits = order ?? [for (var d = 1; d <= _size; d++) d];
    bool search() {
      final cell = state.bestEmptyCell();
      if (cell == -1) return true;
      final options = state.candidates(cell);
      for (final d in digits) {
        final bit = 1 << d;
        if (options & bit == 0) continue;
        state.place(cell, bit);
        if (search()) return true;
        state.unplace(cell, bit);
      }
      return false;
    }

    return search() ? state.values() : null;
  }

  /// Candidate digits for [index] given the other filled cells of [grid].
  Set<int> candidatesAt(List<int> grid, int index) {
    final r = index ~/ _size, c = index % _size, b = _box(r, c);
    var used = 0;
    for (var i = 0; i < grid.length; i++) {
      if (i == index || grid[i] == 0) continue;
      final ri = i ~/ _size, ci = i % _size;
      if (ri == r || ci == c || _box(ri, ci) == b) used |= 1 << grid[i];
    }
    return {
      for (var d = 1; d <= _size; d++)
        if (used & (1 << d) == 0) d,
    };
  }
}

class _State {
  _State(this.s)
      : rows = List.filled(s._size, 0),
        cols = List.filled(s._size, 0),
        boxes = List.filled(s._size, 0),
        cells = List.filled(s._size * s._size, 0);

  final GlazeSolver s;
  final List<int> rows, cols, boxes, cells;

  static _State? from(GlazeSolver solver, List<int> grid) {
    final st = _State(solver);
    for (var i = 0; i < grid.length; i++) {
      final v = grid[i];
      if (v == 0) continue;
      final bit = 1 << v;
      final r = i ~/ solver._size, c = i % solver._size, b = solver._box(r, c);
      if ((st.rows[r] | st.cols[c] | st.boxes[b]) & bit != 0) return null;
      st.place(i, bit);
    }
    return st;
  }

  int candidates(int i) {
    final r = i ~/ s._size, c = i % s._size;
    return s._full & ~(rows[r] | cols[c] | boxes[s._box(r, c)]);
  }

  void place(int i, int bit) {
    final r = i ~/ s._size, c = i % s._size;
    rows[r] |= bit;
    cols[c] |= bit;
    boxes[s._box(r, c)] |= bit;
    cells[i] = bit;
  }

  void unplace(int i, int bit) {
    final r = i ~/ s._size, c = i % s._size;
    rows[r] &= ~bit;
    cols[c] &= ~bit;
    boxes[s._box(r, c)] &= ~bit;
    cells[i] = 0;
  }

  /// Empty cell with the fewest candidates, or -1 when full.
  int bestEmptyCell() {
    var best = -1, bestCount = 1 << 30;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != 0) continue;
      final n = _popCount(candidates(i));
      if (n < bestCount) {
        best = i;
        bestCount = n;
        if (n <= 1) break;
      }
    }
    return best;
  }

  List<int> values() =>
      [for (final bit in cells) bit == 0 ? 0 : bit.bitLength - 1];

  static int _popCount(int x) {
    var n = 0;
    while (x != 0) {
      x &= x - 1;
      n++;
    }
    return n;
  }
}
