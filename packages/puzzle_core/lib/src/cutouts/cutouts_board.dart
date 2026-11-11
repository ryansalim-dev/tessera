import 'cutouts_puzzle.dart';

/// The player's picks for one [CutoutsPuzzle].
///
/// Wrong picks are remembered (and shown cracked) so the player can try
/// again; a hint rules out one wrong option.
class CutoutsBoard {
  CutoutsBoard(this.puzzle);

  final CutoutsPuzzle puzzle;
  final Set<int> _ruledOut = {};
  int? _picked;

  /// Options the player picked wrongly or a hint removed.
  Set<int> get ruledOut => Set.unmodifiable(_ruledOut);
  int get mistakes => _mistakes;
  int _mistakes = 0;

  int? get picked => _picked;
  bool get isSolved => _picked == puzzle.answer;

  /// Picks [option]. Returns true if it is the real result.
  bool pick(int option) {
    if (isSolved || _ruledOut.contains(option)) return isSolved;
    if (option == puzzle.answer) {
      _picked = option;
      return true;
    }
    _ruledOut.add(option);
    _mistakes++;
    return false;
  }

  /// The lowest wrong option not yet ruled out, or null.
  int? hint() {
    if (isSolved) return null;
    for (var i = 0; i < puzzle.options.length; i++) {
      if (i != puzzle.answer && !_ruledOut.contains(i)) return i;
    }
    return null;
  }

  void apply(int option) {
    if (option != puzzle.answer) _ruledOut.add(option);
  }

  void reset() {
    _ruledOut.clear();
    _picked = null;
    _mistakes = 0;
  }
}
