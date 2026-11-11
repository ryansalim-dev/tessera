import '../difficulty.dart';
import '../kiln_path/kiln_path_generator.dart';
import '../seeded_random.dart';
import 'seams_puzzle.dart';
import 'seams_solver.dart';

/// Deterministic Seams generator: same seed and difficulty, same puzzle.
///
/// Draws a random line through every tile (the Kiln Path backbite walk),
/// cuts it into seams, and keeps the first cut whose shards admit only one
/// way to lay the seams.
class SeamsGenerator {
  const SeamsGenerator();

  SeamsPuzzle generate(int seed, Difficulty difficulty, {int? size}) {
    final n = size ?? SeamsPuzzle.sizeFor(difficulty);
    final rng = SeededRandom(seed);
    final solver = SeamsSolver(n);
    final pairs = pairCount(n, difficulty);
    while (true) {
      final line = KilnPathGenerator.randomPath(n, rng);
      for (var attempt = 0; attempt < 20; attempt++) {
        final seams = _cut(line, pairs, rng);
        if (seams == null) continue;
        final endpoints = List.filled(n * n, 0);
        for (var i = 0; i < seams.length; i++) {
          endpoints[seams[i].first] = i + 1;
          endpoints[seams[i].last] = i + 1;
        }
        if (solver.countSolutions(endpoints) == 1) {
          return SeamsPuzzle(
            size: n,
            endpoints: endpoints,
            seams: seams,
            seed: seed,
            difficulty: difficulty,
          );
        }
      }
    }
  }

  /// Splits [line] into [pairs] runs of at least 3 tiles.
  static List<List<int>>? _cut(List<int> line, int pairs, SeededRandom rng) {
    const minLen = 3;
    final spare = line.length - pairs * minLen;
    if (spare < 0) return null;
    // Distribute the spare tiles at random over the runs.
    final lengths = List.filled(pairs, minLen);
    for (var i = 0; i < spare; i++) {
      lengths[rng.nextInt(pairs)]++;
    }
    final out = <List<int>>[];
    var at = 0;
    for (final len in lengths) {
      out.add(line.sublist(at, at + len));
      at += len;
    }
    return out;
  }

  static int pairCount(int size, Difficulty d) => switch (d) {
        Difficulty.gentle => 5,
        Difficulty.steady => 6,
        Difficulty.tricky => 8,
        Difficulty.fierce => 7,
      };
}
