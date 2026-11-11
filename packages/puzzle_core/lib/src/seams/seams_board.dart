import 'seams_puzzle.dart';

enum SeamsHintReason {
  /// The seam for this pair was laid wrong and is replaced.
  mistake,

  /// The seam for this pair had not been laid yet.
  reveal,
}

class SeamsHint {
  const SeamsHint(this.pair, this.reason);

  final int pair;
  final SeamsHintReason reason;

  @override
  String toString() => 'SeamsHint(pair $pair, ${reason.name})';
}

/// The player's seams for one [SeamsPuzzle].
///
/// A seam is drawn out of either of its shards. Drawing over a tile of
/// another seam cuts that seam back; drawing back over your own seam cuts it
/// to that tile. A seam is joined once it reaches its partner shard.
class SeamsBoard {
  SeamsBoard(this.puzzle)
      : _seams = List.generate(puzzle.pairCount + 1, (_) => <int>[]);

  final SeamsPuzzle puzzle;

  /// Index 0 is unused so pair ids index directly.
  final List<List<int>> _seams;

  int? _active;

  int get size => puzzle.size;

  /// The pair currently being drawn, if any.
  int? get active => _active;

  List<int> seam(int pair) => List.unmodifiable(_seams[pair]);

  /// Pair id covering [cell] (endpoints always belong to their pair), or 0.
  int ownerAt(int cell) {
    final e = puzzle.endpoints[cell];
    if (e != 0) return e;
    for (var p = 1; p < _seams.length; p++) {
      if (_seams[p].contains(cell)) return p;
    }
    return 0;
  }

  bool isJoined(int pair) {
    final s = _seams[pair];
    return s.length >= 2 &&
        puzzle.endpoints[s.first] == pair &&
        puzzle.endpoints[s.last] == pair &&
        s.first != s.last;
  }

  int get joinedCount => [
        for (var p = 1; p < _seams.length; p++)
          if (isJoined(p)) p
      ].length;

  /// Starts drawing at [cell]: from a shard (restarting that seam) or from a
  /// tile on an existing seam (cutting it there). Returns false otherwise.
  bool begin(int cell) {
    final e = puzzle.endpoints[cell];
    if (e != 0) {
      final s = _seams[e];
      // Grabbing the shard a seam started from restarts it; grabbing the
      // end of a joined seam picks it up from there.
      if (s.isNotEmpty && s.last == cell && s.first != cell) {
        _active = e;
        return true;
      }
      s
        ..clear()
        ..add(cell);
      _active = e;
      return true;
    }
    for (var p = 1; p < _seams.length; p++) {
      final at = _seams[p].indexOf(cell);
      if (at != -1) {
        _seams[p].removeRange(at + 1, _seams[p].length);
        _active = p;
        return true;
      }
    }
    _active = null;
    return false;
  }

  /// Extends the active seam onto [cell]. Returns false if nothing changed.
  bool extend(int cell) {
    final p = _active;
    if (p == null) return false;
    final s = _seams[p];
    final at = s.indexOf(cell);
    if (at != -1) {
      if (at == s.length - 1) return false;
      s.removeRange(at + 1, s.length);
      return true;
    }
    if (isJoined(p)) return false;
    if (!puzzle.areNeighbours(s.last, cell)) return false;
    final e = puzzle.endpoints[cell];
    if (e != 0 && e != p) return false;
    // Cut any other seam that runs through this tile.
    for (var q = 1; q < _seams.length; q++) {
      if (q == p) continue;
      final k = _seams[q].indexOf(cell);
      if (k != -1) _seams[q].removeRange(k, _seams[q].length);
    }
    s.add(cell);
    return true;
  }

  void end() => _active = null;

  void clearSeam(int pair) => _seams[pair].clear();

  void reset() {
    for (final s in _seams) {
      s.clear();
    }
    _active = null;
  }

  /// Every pair joined and every tile covered. Generation guarantees a unique
  /// solution, so this matches [SeamsPuzzle.seams].
  bool get isSolved {
    var covered = 0;
    for (var p = 1; p < _seams.length; p++) {
      if (!isJoined(p)) return false;
      covered += _seams[p].length;
    }
    return covered == puzzle.cellCount;
  }

  bool _matches(int pair) {
    final want = puzzle.seams[pair - 1];
    final have = _seams[pair];
    if (have.length != want.length) return false;
    var forward = true, backward = true;
    for (var i = 0; i < want.length; i++) {
      if (have[i] != want[i]) forward = false;
      if (have[i] != want[want.length - 1 - i]) backward = false;
    }
    return forward || backward;
  }

  /// The first pair whose seam is wrong (a mistake) or missing (a reveal).
  SeamsHint? hint() {
    if (isSolved) return null;
    final truth = puzzle.solutionOwners;
    for (var p = 1; p < _seams.length; p++) {
      final s = _seams[p];
      if (s.any((c) => truth[c] != p)) {
        return SeamsHint(p, SeamsHintReason.mistake);
      }
    }
    for (var p = 1; p < _seams.length; p++) {
      if (!_matches(p)) return SeamsHint(p, SeamsHintReason.reveal);
    }
    return null;
  }

  /// Lays the solution seam for [hint]'s pair, cutting anything in its way.
  void apply(SeamsHint hint) {
    final want = puzzle.seams[hint.pair - 1];
    final cells = want.toSet();
    for (var q = 1; q < _seams.length; q++) {
      if (q == hint.pair) continue;
      final s = _seams[q];
      final k = s.indexWhere(cells.contains);
      if (k != -1) s.removeRange(k, s.length);
    }
    _seams[hint.pair]
      ..clear()
      ..addAll(want);
    _active = null;
  }
}
