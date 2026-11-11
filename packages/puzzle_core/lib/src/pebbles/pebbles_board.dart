import 'pebbles_puzzle.dart';

/// What the player has put on a tile.
enum PebbleMark {
  empty,

  /// A pebble.
  pebble,

  /// A grout dot: the player's note that no pebble goes here.
  dot,
}

enum PebblesHintReason {
  /// A pebble sits where none belongs, or a dot covers a pebble's tile.
  mistake,

  /// Reveal a pebble.
  reveal,
}

class PebblesHint {
  const PebblesHint(this.cell, this.mark, this.reason);

  final int cell;

  /// What the tile should hold after the hint.
  final PebbleMark mark;
  final PebblesHintReason reason;

  @override
  String toString() => 'PebblesHint($cell=${mark.name}, ${reason.name})';
}

/// The player's in-progress tiles for one [PebblesPuzzle].
class PebblesBoard {
  PebblesBoard(this.puzzle)
      : _marks = List.filled(puzzle.cellCount, PebbleMark.empty);

  final PebblesPuzzle puzzle;
  final List<PebbleMark> _marks;

  int get size => puzzle.size;
  List<PebbleMark> get marks => List.unmodifiable(_marks);
  PebbleMark markAt(int cell) => _marks[cell];

  Set<int> get pebbles => {
        for (var i = 0; i < _marks.length; i++)
          if (_marks[i] == PebbleMark.pebble) i,
      };

  void set(int cell, PebbleMark mark) => _marks[cell] = mark;

  /// Tap cycle: empty -> pebble -> dot -> empty.
  PebbleMark cycle(int cell) {
    final next = switch (_marks[cell]) {
      PebbleMark.empty => PebbleMark.pebble,
      PebbleMark.pebble => PebbleMark.dot,
      PebbleMark.dot => PebbleMark.empty,
    };
    _marks[cell] = next;
    return next;
  }

  void reset() => _marks.fillRange(0, _marks.length, PebbleMark.empty);

  /// Pebbles that break a rule: touching another pebble, or sharing a row,
  /// column or region with another pebble.
  Set<int> conflicts() {
    final p = pebbles.toList();
    final out = <int>{};
    for (var i = 0; i < p.length; i++) {
      for (var j = i + 1; j < p.length; j++) {
        final a = p[i], b = p[j];
        if (puzzle.touches(a, b) ||
            puzzle.row(a) == puzzle.row(b) ||
            puzzle.col(a) == puzzle.col(b) ||
            puzzle.region(a) == puzzle.region(b)) {
          out
            ..add(a)
            ..add(b);
        }
      }
    }
    return out;
  }

  /// Valid full placement. Generation guarantees a unique solution, so this
  /// matches [PebblesPuzzle.solution].
  bool get isSolved => puzzle.isValidPlacement(pebbles);

  PebblesHint? hint() {
    if (isSolved) return null;
    final truth = puzzle.solution.toSet();
    for (var i = 0; i < _marks.length; i++) {
      if (_marks[i] == PebbleMark.pebble && !truth.contains(i)) {
        return PebblesHint(i, PebbleMark.dot, PebblesHintReason.mistake);
      }
      if (_marks[i] == PebbleMark.dot && truth.contains(i)) {
        return PebblesHint(i, PebbleMark.pebble, PebblesHintReason.mistake);
      }
    }
    for (final cell in puzzle.solution) {
      if (_marks[cell] != PebbleMark.pebble) {
        return PebblesHint(cell, PebbleMark.pebble, PebblesHintReason.reveal);
      }
    }
    return null;
  }

  void apply(PebblesHint hint) => _marks[hint.cell] = hint.mark;
}
