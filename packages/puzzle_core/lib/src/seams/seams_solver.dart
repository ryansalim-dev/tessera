import 'dart:typed_data';

/// Depth-first solver for Seams (Numberlink with full coverage), used to
/// prove uniqueness at generation time.
///
/// Routes one pair at a time from its first shard. Pruning: every
/// unfinished pair must still be able to reach its partner through free
/// tiles, every free tile must stay reachable from some unfinished pair,
/// and no free tile may be left with fewer than two ways in and out.
class SeamsSolver {
  SeamsSolver(this.size)
      : _cells = size * size,
        _neighbours = [
          for (var i = 0; i < size * size; i++)
            [
              if (i ~/ size > 0) i - size,
              if (i % size < size - 1) i + 1,
              if (i ~/ size < size - 1) i + size,
              if (i % size > 0) i - 1,
            ],
        ];

  final int size;
  final int _cells;
  final List<List<int>> _neighbours;

  int countSolutions(List<int> endpoints, {int limit = 2}) {
    var count = 0;
    _search(endpoints, (_) => ++count < limit);
    return count;
  }

  /// One solution as pair id per cell, or null.
  List<int>? solve(List<int> endpoints) {
    List<int>? found;
    _search(endpoints, (owner) {
      found = List.of(owner);
      return false;
    });
    return found;
  }

  void _search(List<int> endpoints, bool Function(List<int>) onSolution) {
    var pairs = 0;
    for (final e in endpoints) {
      if (e > pairs) pairs = e;
    }
    final starts = List.filled(pairs + 1, -1),
        ends = List.filled(pairs + 1, -1);
    for (var i = 0; i < _cells; i++) {
      final e = endpoints[i];
      if (e == 0) continue;
      if (starts[e] == -1) {
        starts[e] = i;
      } else {
        ends[e] = i;
      }
    }
    for (var p = 1; p <= pairs; p++) {
      if (starts[p] == -1 || ends[p] == -1) return;
    }

    // owner: pair id, 0 = free.
    final owner = Int32List.fromList(endpoints);
    final heads = List.of(starts);
    final done = List.filled(pairs + 1, false);
    var free = owner.where((o) => o == 0).length;
    final comp = Int32List(_cells);
    final stack = Int32List(_cells);
    var stop = false;

    // Is [cell] an open terminal (a head or the far shard of an unfinished
    // pair)?
    bool isTerminal(int cell) {
      final p = owner[cell];
      if (p == 0 || done[p]) return false;
      return heads[p] == cell || ends[p] == cell;
    }

    bool feasible() {
      // Dead ends: a free tile needs two free-or-terminal neighbours.
      for (var c = 0; c < _cells; c++) {
        if (owner[c] != 0) continue;
        var ways = 0;
        for (final nb in _neighbours[c]) {
          if (owner[nb] == 0 || isTerminal(nb)) ways++;
        }
        if (ways < 2) return false;
      }
      // Label free components.
      comp.fillRange(0, _cells, -1);
      var label = 0;
      for (var c = 0; c < _cells; c++) {
        if (owner[c] != 0 || comp[c] != -1) continue;
        var top = 0;
        stack[top++] = c;
        comp[c] = label;
        while (top > 0) {
          final x = stack[--top];
          for (final nb in _neighbours[x]) {
            if (owner[nb] == 0 && comp[nb] == -1) {
              comp[nb] = label;
              stack[top++] = nb;
            }
          }
        }
        label++;
      }
      // Each unfinished pair: head and end touch, or share a component.
      // Each component must be touched by some unfinished pair at both its
      // head and its end (otherwise nothing can fill it).
      final served = List.filled(label, false);
      for (var p = 1; p <= pairs; p++) {
        if (done[p]) continue;
        final h = heads[p], e = ends[p];
        var adjacent = false;
        final hComps = <int>{};
        for (final nb in _neighbours[h]) {
          if (nb == e) adjacent = true;
          if (owner[nb] == 0) hComps.add(comp[nb]);
        }
        var shared = false;
        for (final nb in _neighbours[e]) {
          if (owner[nb] == 0 && hComps.contains(comp[nb])) {
            shared = true;
            served[comp[nb]] = true;
          }
        }
        if (!adjacent && !shared) return false;
      }
      return !served.contains(false);
    }

    void route(int p) {
      if (stop) return;
      while (p <= pairs && done[p]) {
        p++;
      }
      if (p > pairs) {
        if (free == 0 && !onSolution(owner)) stop = true;
        return;
      }
      final h = heads[p];
      for (final nb in _neighbours[h]) {
        if (nb == ends[p]) {
          done[p] = true;
          if (feasible()) route(p + 1);
          done[p] = false;
        } else if (owner[nb] == 0) {
          owner[nb] = p;
          heads[p] = nb;
          free--;
          if (feasible()) route(p);
          free++;
          heads[p] = h;
          owner[nb] = 0;
        }
        if (stop) return;
      }
    }

    if (feasible()) route(1);
  }
}
