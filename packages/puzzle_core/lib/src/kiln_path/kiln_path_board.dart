import 'kiln_path_puzzle.dart';

/// Why a hint was offered.
enum KilnPathHintReason {
  /// The line strayed from the solution; it is cut back before the hint.
  mistake,

  /// The next tile along the line.
  nextStep,
}

class KilnPathHint {
  const KilnPathHint(this.keep, this.cell, this.reason);

  /// How many cells of the current line are kept before [cell] is added.
  final int keep;

  /// The cell the line should step to next.
  final int cell;

  final KilnPathHintReason reason;

  @override
  String toString() => 'KilnPathHint(keep $keep, then $cell, ${reason.name})';
}

/// The player's in-progress firing line for one [KilnPathPuzzle].
///
/// The line always starts on checkpoint 1. It grows one orthogonal step at a
/// time and may only enter a checkpoint when that checkpoint is next in
/// order. Stepping onto a cell already on the line cuts the line back to it,
/// which is how the player undoes moves.
class KilnPathBoard {
  KilnPathBoard(this.puzzle) : _path = [puzzle.start];

  final KilnPathPuzzle puzzle;
  final List<int> _path;

  int get size => puzzle.size;
  List<int> get path => List.unmodifiable(_path);
  int get head => _path.last;
  int get length => _path.length;
  bool contains(int cell) => _path.contains(cell);
  int checkpointAt(int cell) => puzzle.checkpoints[cell];

  /// The number of the next checkpoint the line must reach, or null once the
  /// last one is reached.
  int? get nextCheckpoint {
    var reached = 0;
    for (final c in _path) {
      final n = puzzle.checkpoints[c];
      if (n > reached) reached = n;
    }
    return reached < puzzle.checkpointCount ? reached + 1 : null;
  }

  /// Whether the head may step onto [cell] right now.
  bool canStep(int cell) {
    if (!puzzle.areNeighbours(head, cell) || _path.contains(cell)) return false;
    if (head == puzzle.end) return false;
    final n = puzzle.checkpoints[cell];
    return n == 0 || n == nextCheckpoint;
  }

  /// Steps onto [cell], or cuts the line back if [cell] is already on it.
  /// Returns false if nothing changed.
  bool moveTo(int cell) {
    final at = _path.indexOf(cell);
    if (at != -1) return truncateTo(at + 1);
    if (!canStep(cell)) return false;
    _path.add(cell);
    return true;
  }

  /// Keeps the first [count] cells of the line (at least the start).
  bool truncateTo(int count) {
    final keep = count < 1 ? 1 : count;
    if (keep >= _path.length) return false;
    _path.removeRange(keep, _path.length);
    return true;
  }

  /// Takes back the last step.
  bool undo() => truncateTo(_path.length - 1);

  void reset() => truncateTo(1);

  /// Every cell covered and the line ends on the last checkpoint. Moves
  /// already enforce checkpoint order, so this matches the unique solution.
  bool get isSolved =>
      _path.length == puzzle.cellCount && _path.last == puzzle.end;

  KilnPathHint? hint() {
    if (isSolved) return null;
    final s = puzzle.solution;
    var k = 0;
    while (k < _path.length && _path[k] == s[k]) {
      k++;
    }
    return KilnPathHint(
      k,
      s[k],
      k < _path.length
          ? KilnPathHintReason.mistake
          : KilnPathHintReason.nextStep,
    );
  }

  /// Applies [hint]: cuts the line back to the right prefix, then steps.
  void apply(KilnPathHint hint) {
    truncateTo(hint.keep);
    moveTo(hint.cell);
  }
}
