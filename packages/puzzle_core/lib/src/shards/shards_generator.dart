import '../difficulty.dart';
import '../seeded_random.dart';
import 'shards_puzzle.dart';

/// Deterministic Shards generator: same seed and difficulty, same puzzle.
///
/// Chips a few tiles off the plate's rim, then breaks the plate into shards
/// by growing each from the most hemmed-in free tile, so no tile is left
/// stranded. Shards are handed out turned at random.
class ShardsGenerator {
  const ShardsGenerator();

  ShardsPuzzle generate(int seed, Difficulty difficulty) {
    final rng = SeededRandom(seed);
    final n = ShardsPuzzle.sizeFor(difficulty);
    final (minSize, maxSize, chips) = shapeFor(difficulty);
    while (true) {
      final plate = _plate(n, chips, rng);
      final pieces = _breakUp(n, plate, minSize, maxSize, rng);
      if (pieces == null) continue;
      final shards = <ShardShape>[];
      final solution = <ShardPlacement>[];
      for (final piece in pieces) {
        final base = ShardShape([for (final c in piece) (c ~/ n, c % n)]);
        // Hand it out turned by t; turning back by 4 - t restores it.
        final t = rng.nextInt(4);
        shards.add(base.rotated(t));
        final minR = piece.map((c) => c ~/ n).reduce((a, b) => a < b ? a : b);
        final minC = piece.map((c) => c % n).reduce((a, b) => a < b ? a : b);
        solution.add(ShardPlacement((4 - t) % 4, minR, minC));
      }
      // Shuffle the tray order.
      final order = [for (var i = 0; i < shards.length; i++) i];
      rng.shuffle(order);
      return ShardsPuzzle(
        size: n,
        plate: plate,
        shards: [for (final i in order) shards[i]],
        solution: [for (final i in order) solution[i]],
        seed: seed,
        difficulty: difficulty,
      );
    }
  }

  /// (smallest shard, largest shard, rim tiles chipped off) per difficulty.
  static (int, int, int) shapeFor(Difficulty d) => switch (d) {
        Difficulty.gentle => (3, 5, 0),
        Difficulty.steady => (4, 5, 1),
        Difficulty.tricky => (4, 6, 2),
        Difficulty.fierce => (3, 4, 4),
      };

  /// A square plate with [chips] corner-ish rim tiles removed.
  static List<bool> _plate(int n, int chips, SeededRandom rng) {
    final plate = List.filled(n * n, true);
    final rim = [
      for (var i = 0; i < n * n; i++)
        if (i ~/ n == 0 || i ~/ n == n - 1 || i % n == 0 || i % n == n - 1) i,
    ];
    rng.shuffle(rim);
    for (final c in rim.take(chips)) {
      plate[c] = false;
    }
    return plate;
  }

  static List<List<int>>? _breakUp(
    int n,
    List<bool> plate,
    int minSize,
    int maxSize,
    SeededRandom rng,
  ) {
    final owner = List.filled(n * n, -1);
    Iterable<int> free(int c) sync* {
      for (final nb in _orthogonal(n, c)) {
        if (plate[nb] && owner[nb] == -1) yield nb;
      }
    }

    final pieces = <List<int>>[];
    while (true) {
      // Start from the free tile with the fewest free neighbours.
      var start = -1, best = 5;
      for (var c = 0; c < n * n; c++) {
        if (!plate[c] || owner[c] != -1) continue;
        final k = free(c).length;
        if (k < best || (k == best && rng.nextInt(2) == 0)) {
          start = c;
          best = k;
        }
      }
      if (start == -1) break;
      final target = minSize + rng.nextInt(maxSize - minSize + 1);
      final piece = [start];
      owner[start] = pieces.length;
      while (piece.length < target) {
        final frontier = {for (final c in piece) ...free(c)}.toList()..sort();
        if (frontier.isEmpty) break;
        // Prefer the frontier tile that is most hemmed in, so the piece
        // swallows corners instead of leaving them stranded.
        frontier.sort((a, b) => free(a).length - free(b).length);
        final pick = rng.nextInt(3) == 0
            ? frontier[rng.nextInt(frontier.length)]
            : frontier.first;
        owner[pick] = pieces.length;
        piece.add(pick);
      }
      if (piece.length < minSize) {
        // Too small: fold it into a touching piece if that stays in range.
        final neighbours = {
          for (final c in piece)
            for (final nb in _orthogonal(n, c))
              if (owner[nb] != -1 && owner[nb] != pieces.length) owner[nb],
        };
        final into = neighbours
            .where((p) => pieces[p].length + piece.length <= maxSize + 1)
            .toList();
        if (into.isEmpty) return null;
        final p = into[rng.nextInt(into.length)];
        for (final c in piece) {
          owner[c] = p;
        }
        pieces[p].addAll(piece);
        continue;
      }
      pieces.add(piece);
    }
    return pieces;
  }

  static Iterable<int> _orthogonal(int n, int c) sync* {
    final r = c ~/ n, k = c % n;
    if (r > 0) yield c - n;
    if (k < n - 1) yield c + 1;
    if (r < n - 1) yield c + n;
    if (k > 0) yield c - 1;
  }
}
