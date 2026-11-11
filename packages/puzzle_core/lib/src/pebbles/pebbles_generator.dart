import '../difficulty.dart';
import '../seeded_random.dart';
import 'pebbles_puzzle.dart';
import 'pebbles_solver.dart';

/// Deterministic Pebbles generator: same seed and difficulty, same puzzle.
///
/// Places a random valid set of pebbles, then grows one grout region out of
/// each pebble until the grid is covered. If that leaves more than one
/// answer, it reshapes a region to rule the other answer out, and starts
/// over with fresh regions if reshaping stalls.
class PebblesGenerator {
  const PebblesGenerator();

  PebblesPuzzle generate(int seed, Difficulty difficulty, {int? size}) {
    final n = size ?? PebblesPuzzle.sizeFor(difficulty);
    final rng = SeededRandom(seed);
    final solver = PebblesSolver(n);
    while (true) {
      final pebbles = randomPlacement(n, rng);
      for (var attempt = 0; attempt < 8; attempt++) {
        final regions =
            growRegions(n, pebbles, rng, compact: _compact(difficulty));
        if (_makeUnique(n, regions, pebbles, solver, rng)) {
          return PebblesPuzzle(
            size: n,
            regions: regions,
            solution: List.of(pebbles),
            seed: seed,
            difficulty: difficulty,
          );
        }
      }
    }
  }

  /// Compact (blobby) regions make easier puzzles; stringy ones are harder.
  static double _compact(Difficulty d) => switch (d) {
        Difficulty.gentle => 0.8,
        Difficulty.steady => 0.6,
        Difficulty.tricky => 0.4,
        Difficulty.fierce => 0.25,
      };

  /// One pebble per row and column, none touching, in a random arrangement.
  static List<int> randomPlacement(int n, SeededRandom rng) {
    final cols = List.filled(n, -1);
    final used = List.filled(n, false);
    bool place(int r) {
      if (r == n) return true;
      final order = [for (var c = 0; c < n; c++) c];
      rng.shuffle(order);
      for (final c in order) {
        if (used[c] || (r > 0 && (c - cols[r - 1]).abs() <= 1)) continue;
        cols[r] = c;
        used[c] = true;
        if (place(r + 1)) return true;
        used[c] = false;
      }
      return false;
    }

    place(0);
    return [for (var r = 0; r < n; r++) r * n + cols[r]];
  }

  /// Grows region `i` out of `pebbles[i]` until every cell has a region.
  ///
  /// Each step picks a frontier cell; with probability [compact] it prefers
  /// the frontier cell with the most same-region neighbours, which keeps
  /// regions round.
  static List<int> growRegions(
    int n,
    List<int> pebbles,
    SeededRandom rng, {
    double compact = 0.5,
  }) {
    final regions = List.filled(n * n, -1);
    for (var i = 0; i < pebbles.length; i++) {
      regions[pebbles[i]] = i;
    }
    var left = n * n - pebbles.length;
    final threshold = (compact * 1000).round();
    while (left > 0) {
      // (cell, region, same-region neighbour count)
      final frontier = <(int, int, int)>[];
      for (var c = 0; c < n * n; c++) {
        if (regions[c] != -1) continue;
        final counts = <int, int>{};
        for (final nb in _orthogonal(n, c)) {
          final r = regions[nb];
          if (r != -1) counts[r] = (counts[r] ?? 0) + 1;
        }
        counts.forEach((r, k) => frontier.add((c, r, k)));
      }
      var pick = frontier[rng.nextInt(frontier.length)];
      if (rng.nextInt(1000) < threshold) {
        final best = frontier.map((f) => f.$3).reduce((a, b) => a > b ? a : b);
        final top = frontier.where((f) => f.$3 == best).toList();
        pick = top[rng.nextInt(top.length)];
      }
      regions[pick.$1] = pick.$2;
      left--;
    }
    return regions;
  }

  /// Moves cells between regions until [pebbles] is the only answer.
  /// Returns false if it gives up.
  static bool _makeUnique(
    int n,
    List<int> regions,
    List<int> pebbles,
    PebblesSolver solver,
    SeededRandom rng,
  ) {
    final truth = pebbles.toSet();
    for (var round = 0; round < 4 * n; round++) {
      final found = solver.solutions(regions, limit: 2);
      if (found.length == 1) return true;
      final other = found.firstWhere(
        (s) => !(s.toSet().containsAll(truth)),
      );
      // A pebble of the other answer that is not a true pebble: hand its
      // cell to a neighbouring region that already has a pebble of the
      // other answer, so the other answer doubles up there.
      final wrong = other.where((c) => !truth.contains(c)).toList();
      rng.shuffle(wrong);
      var changed = false;
      for (final cell in wrong) {
        if (truth.contains(cell)) continue;
        final own = regions[cell];
        final options = [
          for (final nb in _orthogonal(n, cell))
            if (regions[nb] != own) regions[nb],
        ];
        rng.shuffle(options);
        for (final target in options) {
          regions[cell] = target;
          if (_connected(n, regions, own)) {
            changed = true;
            break;
          }
          regions[cell] = own;
        }
        if (changed) break;
      }
      if (!changed) return false;
    }
    return solver.countSolutions(regions) == 1;
  }

  static bool _connected(int n, List<int> regions, int region) {
    final cells = [
      for (var c = 0; c < n * n; c++)
        if (regions[c] == region) c,
    ];
    if (cells.isEmpty) return false;
    final seen = {cells.first};
    final stack = [cells.first];
    while (stack.isNotEmpty) {
      final c = stack.removeLast();
      for (final nb in _orthogonal(n, c)) {
        if (regions[nb] == region && seen.add(nb)) stack.add(nb);
      }
    }
    return seen.length == cells.length;
  }

  static Iterable<int> _orthogonal(int n, int c) sync* {
    final r = c ~/ n, k = c % n;
    if (r > 0) yield c - n;
    if (k < n - 1) yield c + 1;
    if (r < n - 1) yield c + n;
    if (k > 0) yield c - 1;
  }
}
