import 'shards_puzzle.dart';

enum ShardsHintReason {
  /// A shard was moved into its place, clearing shards in the way.
  place,
}

class ShardsHint {
  const ShardsHint(this.shard, this.placement);

  final int shard;
  final ShardPlacement placement;

  @override
  String toString() => 'ShardsHint(shard $shard at $placement)';
}

/// The player's progress on one [ShardsPuzzle]: which shards are on the
/// plate and where, and how each tray shard is turned.
class ShardsBoard {
  ShardsBoard(this.puzzle)
      : _placed = List.filled(puzzle.shards.length, null),
        _turns = List.filled(puzzle.shards.length, 0);

  final ShardsPuzzle puzzle;
  final List<ShardPlacement?> _placed;
  final List<int> _turns;

  int get shardCount => puzzle.shards.length;
  ShardPlacement? placementOf(int shard) => _placed[shard];
  bool isPlaced(int shard) => _placed[shard] != null;
  int get placedCount => _placed.where((p) => p != null).length;

  /// How the shard is turned (on the plate or in the tray).
  int turnsOf(int shard) => _placed[shard]?.turns ?? _turns[shard];

  /// Owning shard per plate cell, or -1.
  List<int> get owners {
    final out = List.filled(puzzle.cellCount, -1);
    for (var i = 0; i < _placed.length; i++) {
      final p = _placed[i];
      if (p == null) continue;
      for (final c in puzzle.cellsFor(i, p)!) {
        out[c] = i;
      }
    }
    return out;
  }

  /// Whether [shard] fits at [placement] without leaving the plate or
  /// overlapping another placed shard.
  bool fits(int shard, ShardPlacement placement) {
    final cells = puzzle.cellsFor(shard, placement);
    if (cells == null) return false;
    final o = owners;
    return cells.every((c) => o[c] == -1 || o[c] == shard);
  }

  /// Puts [shard] on the plate at [placement] if it fits.
  bool place(int shard, ShardPlacement placement) {
    if (!fits(shard, placement)) return false;
    _placed[shard] = placement;
    _turns[shard] = placement.turns % 4;
    return true;
  }

  /// Back to the tray, keeping its turn.
  void lift(int shard) {
    final p = _placed[shard];
    if (p != null) _turns[shard] = p.turns % 4;
    _placed[shard] = null;
  }

  /// Turns a tray shard a quarter clockwise. Placed shards turn in place if
  /// the new orientation still fits; otherwise they go back to the tray.
  void turn(int shard) {
    final p = _placed[shard];
    if (p == null) {
      _turns[shard] = (_turns[shard] + 1) % 4;
      return;
    }
    final next = ShardPlacement((p.turns + 1) % 4, p.row, p.col);
    _placed[shard] = null;
    if (!place(shard, next)) _turns[shard] = next.turns;
  }

  void reset() {
    _placed.fillRange(0, _placed.length, null);
    _turns.fillRange(0, _turns.length, 0);
  }

  /// Every shard placed. Placement already forbids overlaps and overhangs,
  /// and the shards' area equals the plate's, so the plate is covered.
  bool get isSolved => _placed.every((p) => p != null);

  /// Moves one shard into its solution place: first a shard that is on the
  /// plate in the wrong spot, otherwise one still in the tray.
  ShardsHint? hint() {
    if (isSolved) return null;
    for (var i = 0; i < _placed.length; i++) {
      final p = _placed[i];
      if (p != null && !_samePlace(i, p)) {
        return ShardsHint(i, puzzle.solution[i]);
      }
    }
    for (var i = 0; i < _placed.length; i++) {
      if (_placed[i] == null) return ShardsHint(i, puzzle.solution[i]);
    }
    return null;
  }

  /// Applies [hint], lifting any shard in the way back to the tray.
  void apply(ShardsHint hint) {
    final cells = puzzle.cellsFor(hint.shard, hint.placement)!.toSet();
    final o = owners;
    for (final c in cells) {
      if (o[c] != -1 && o[c] != hint.shard) lift(o[c]);
    }
    _placed[hint.shard] = null;
    place(hint.shard, hint.placement);
  }

  /// Same covered cells as the solution (symmetric shards can match at a
  /// different turn).
  bool _samePlace(int shard, ShardPlacement p) {
    final a = puzzle.cellsFor(shard, p)!.toSet();
    final b = puzzle.cellsFor(shard, puzzle.solution[shard])!;
    return a.length == b.length && a.containsAll(b);
  }
}
