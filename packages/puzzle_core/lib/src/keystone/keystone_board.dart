import 'keystone_puzzle.dart';

/// The player's in-progress keystone.
class KeystoneBoard {
  KeystoneBoard(this.puzzle, this.givens) : _cells = List.of(givens.grid);

  final KeystonePuzzle puzzle;
  final KeystoneGivens givens;
  final List<int> _cells;

  static const size = KeystonePuzzle.size;

  List<int> get cells => List.unmodifiable(_cells);
  int valueAt(int cell) => _cells[cell];
  bool isGiven(int cell) => givens.grid[cell] != 0;

  bool place(int cell, int value) {
    if (isGiven(cell)) return false;
    RangeError.checkValueInInterval(value, 1, size, 'value');
    _cells[cell] = value;
    return true;
  }

  bool clear(int cell) {
    if (isGiven(cell)) return false;
    _cells[cell] = 0;
    return true;
  }

  void reset() => _cells.setAll(0, givens.grid);

  /// Tiles sharing a row or column with an equal glaze.
  Set<int> conflicts() {
    final out = <int>{};
    for (var i = 0; i < _cells.length; i++) {
      final v = _cells[i];
      if (v == 0) continue;
      for (var j = i + 1; j < _cells.length; j++) {
        final same = i ~/ size == j ~/ size || i % size == j % size;
        if (same && _cells[j] == v) {
          out
            ..add(i)
            ..add(j);
        }
      }
    }
    return out;
  }

  bool get isSolved => !_cells.contains(0) && conflicts().isEmpty;

  /// The cell and digit to fix or fill next.
  (int, int)? hint() {
    for (var i = 0; i < _cells.length; i++) {
      if (_cells[i] != 0 && _cells[i] != puzzle.solution[i]) {
        return (i, puzzle.solution[i]);
      }
    }
    final i = _cells.indexOf(0);
    return i == -1 ? null : (i, puzzle.solution[i]);
  }
}
