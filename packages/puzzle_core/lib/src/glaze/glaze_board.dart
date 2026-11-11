import 'glaze_puzzle.dart';
import 'glaze_solver.dart';

/// Why a hint was offered.
enum GlazeHintReason {
  /// A placed glaze does not match the solution.
  mistake,

  /// Only one glaze fits this tile given what is on the board.
  onlyOption,

  /// Fallback: reveal a tile.
  reveal,
}

class GlazeHint {
  const GlazeHint(this.index, this.value, this.reason);

  final int index;
  final int value;
  final GlazeHintReason reason;

  @override
  String toString() => 'GlazeHint($index=$value, ${reason.name})';
}

/// The player's in-progress board for one [GlazePuzzle].
class GlazeBoard {
  GlazeBoard(this.puzzle) : _cells = List.of(puzzle.givens);

  final GlazePuzzle puzzle;
  final List<int> _cells;

  int get size => puzzle.size;
  List<int> get cells => List.unmodifiable(_cells);
  int valueAt(int index) => _cells[index];
  bool isGiven(int index) => puzzle.givens[index] != 0;
  bool canEdit(int index) => !isGiven(index);

  /// Places [value] at [index]. Returns false if the tile is a given.
  bool place(int index, int value) {
    if (isGiven(index)) return false;
    RangeError.checkValueInInterval(value, 1, size, 'value');
    _cells[index] = value;
    return true;
  }

  bool clear(int index) {
    if (isGiven(index)) return false;
    _cells[index] = 0;
    return true;
  }

  void reset() => _cells.setAll(0, puzzle.givens);

  /// Tiles that share a row, column or box with an equal glaze.
  Set<int> conflicts() {
    final out = <int>{};
    for (var i = 0; i < _cells.length; i++) {
      final v = _cells[i];
      if (v == 0) continue;
      for (final p in puzzle.peers(i)) {
        if (_cells[p] == v) {
          out
            ..add(i)
            ..add(p);
        }
      }
    }
    return out;
  }

  bool get isFull => !_cells.contains(0);

  /// Full with no conflicts. Generation guarantees a unique solution, so this
  /// is equivalent to matching [GlazePuzzle.solution].
  bool get isSolved => isFull && conflicts().isEmpty;

  GlazeHint? hint() {
    for (var i = 0; i < _cells.length; i++) {
      if (_cells[i] != 0 && _cells[i] != puzzle.solution[i]) {
        return GlazeHint(i, puzzle.solution[i], GlazeHintReason.mistake);
      }
    }
    final solver = GlazeSolver(puzzle.layout);
    for (var i = 0; i < _cells.length; i++) {
      if (_cells[i] != 0) continue;
      final options = solver.candidatesAt(_cells, i);
      if (options.length == 1) {
        return GlazeHint(i, options.single, GlazeHintReason.onlyOption);
      }
    }
    final empty = _cells.indexOf(0);
    if (empty == -1) return null;
    return GlazeHint(empty, puzzle.solution[empty], GlazeHintReason.reveal);
  }
}
