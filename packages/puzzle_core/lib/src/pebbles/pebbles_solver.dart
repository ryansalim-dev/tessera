/// Row-by-row backtracking solver for Pebbles (one pebble per row, column
/// and region, none touching). Used to prove uniqueness at generation time.
class PebblesSolver {
  PebblesSolver(this.size);

  final int size;

  /// Counts solutions for [regions], stopping at [limit].
  int countSolutions(List<int> regions, {int limit = 2}) {
    var count = 0;
    _search(regions, (_) => ++count < limit);
    return count;
  }

  /// All solutions up to [limit], each as ascending cell indices.
  List<List<int>> solutions(List<int> regions, {int limit = 2}) {
    final out = <List<int>>[];
    _search(regions, (cols) {
      out.add([for (var r = 0; r < size; r++) r * size + cols[r]]);
      return out.length < limit;
    });
    return out;
  }

  void _search(List<int> regions, bool Function(List<int> cols) onSolution) {
    final cols = List.filled(size, -1);
    var usedCols = 0, usedRegions = 0;
    var stop = false;

    // Every region still without a pebble needs a cell in rows >= r whose
    // column is still free.
    bool regionsReachable(int r) {
      var reachable = 0;
      for (var rr = r; rr < size; rr++) {
        for (var c = 0; c < size; c++) {
          if (usedCols & (1 << c) == 0) {
            reachable |= 1 << regions[rr * size + c];
          }
        }
      }
      final need = ((1 << size) - 1) & ~usedRegions;
      return reachable & need == need;
    }

    void place(int r) {
      if (stop) return;
      if (r == size) {
        if (!onSolution(cols)) stop = true;
        return;
      }
      if (!regionsReachable(r)) return;
      final prev = r > 0 ? cols[r - 1] : -10;
      for (var c = 0; c < size; c++) {
        if (usedCols & (1 << c) != 0) continue;
        if ((c - prev).abs() <= 1) continue;
        final reg = regions[r * size + c];
        if (usedRegions & (1 << reg) != 0) continue;
        cols[r] = c;
        usedCols |= 1 << c;
        usedRegions |= 1 << reg;
        place(r + 1);
        usedCols &= ~(1 << c);
        usedRegions &= ~(1 << reg);
        if (stop) return;
      }
      cols[r] = -1;
    }

    place(0);
  }
}
