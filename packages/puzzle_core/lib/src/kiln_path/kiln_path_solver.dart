import 'dart:typed_data';

/// Depth-first solver for Kiln Path grids, used to prove uniqueness at
/// generation time.
///
/// Pruning: checkpoints must be entered in order, the last checkpoint may
/// only be entered as the final step, the unvisited cells must stay
/// connected, and no unvisited cell may be left with too few open
/// neighbours to be passed through.
class KilnPathSolver {
  KilnPathSolver(this.size)
      : _cells = size * size,
        _neighbours = _buildNeighbours(size);

  final int size;
  final int _cells;
  final List<List<int>> _neighbours;

  static List<List<int>> _buildNeighbours(int n) => [
        for (var i = 0; i < n * n; i++)
          [
            if (i ~/ n > 0) i - n,
            if (i % n < n - 1) i + 1,
            if (i ~/ n < n - 1) i + n,
            if (i % n > 0) i - 1,
          ],
      ];

  /// Counts solutions for [checkpoints] (`0` = none), stopping at [limit].
  int countSolutions(List<int> checkpoints, {int limit = 2}) {
    var count = 0;
    _search(checkpoints, (_) {
      count++;
      return count < limit;
    });
    return count;
  }

  /// One solution as a list of cells, or null if none.
  List<int>? solve(List<int> checkpoints) {
    List<int>? found;
    _search(checkpoints, (path) {
      found = List.of(path);
      return false;
    });
    return found;
  }

  /// Calls [onSolution] for each solution; it returns false to stop.
  void _search(List<int> checkpoints, bool Function(List<int>) onSolution) {
    var last = 0, start = -1, end = -1;
    for (var i = 0; i < _cells; i++) {
      final n = checkpoints[i];
      if (n == 1) start = i;
      if (n > last) {
        last = n;
        end = i;
      }
    }
    if (start == -1 || last < 2) return;

    final visited = Uint8List(_cells);
    final path = <int>[start];
    visited[start] = 1;
    final stack = Int32List(_cells);
    final seen = Uint8List(_cells);
    var stop = false;

    // Unvisited cells reachable from [head] without passing visited cells.
    bool connected(int head, int remaining) {
      seen.fillRange(0, _cells, 0);
      var top = 0, reached = 0;
      for (final nb in _neighbours[head]) {
        if (visited[nb] == 0 && seen[nb] == 0) {
          seen[nb] = 1;
          stack[top++] = nb;
        }
      }
      while (top > 0) {
        final c = stack[--top];
        reached++;
        for (final nb in _neighbours[c]) {
          if (visited[nb] == 0 && seen[nb] == 0) {
            seen[nb] = 1;
            stack[top++] = nb;
          }
        }
      }
      return reached == remaining;
    }

    // Every unvisited cell other than [end] needs two ways in and out (the
    // head counts as one); one with a single way must be the next step.
    bool degreesOk(int head) {
      var forced = 0;
      for (var c = 0; c < _cells; c++) {
        if (visited[c] != 0 || c == end) continue;
        var free = 0;
        var touchesHead = false;
        for (final nb in _neighbours[c]) {
          if (visited[nb] == 0) {
            free++;
          } else if (nb == head) {
            touchesHead = true;
          }
        }
        final open = free + (touchesHead ? 1 : 0);
        if (open < 2) {
          if (open == 1 && touchesHead) {
            if (++forced > 1) return false;
          } else {
            return false;
          }
        }
      }
      return true;
    }

    void step(int head, int next) {
      if (stop) return;
      final remaining = _cells - path.length;
      if (remaining == 0) {
        if (head == end && !onSolution(path)) stop = true;
        return;
      }
      if (!connected(head, remaining) || !degreesOk(head)) return;
      for (final nb in _neighbours[head]) {
        if (visited[nb] != 0) continue;
        final n = checkpoints[nb];
        if (n != 0 && n != next) continue;
        if (nb == end && remaining != 1) continue;
        visited[nb] = 1;
        path.add(nb);
        step(nb, n != 0 ? next + 1 : next);
        path.removeLast();
        visited[nb] = 0;
        if (stop) return;
      }
    }

    step(start, 2);
  }
}
