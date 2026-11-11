import '../difficulty.dart';
import '../seeded_random.dart';
import 'kiln_path_puzzle.dart';
import 'kiln_path_solver.dart';

/// Deterministic Kiln Path generator: same seed and difficulty, same puzzle.
///
/// Builds a random Hamiltonian path with the backbite move, places a dense
/// set of checkpoints along it, then removes checkpoints in a random order
/// while the line stays unique, stopping at the difficulty's target.
class KilnPathGenerator {
  const KilnPathGenerator();

  KilnPathPuzzle generate(int seed, Difficulty difficulty, {int? size}) {
    final n = size ?? KilnPathPuzzle.sizeFor(difficulty);
    final rng = SeededRandom(seed);
    final path = randomPath(n, rng);
    final solver = KilnPathSolver(n);

    // Path positions that carry a checkpoint. Both ends always do.
    final marked = <int>{0, path.length - 1};
    for (var i = 2; i < path.length - 1; i += 2) {
      marked.add(i);
    }
    if (solver.countSolutions(_number(n, path, marked)) != 1) {
      marked.addAll([for (var i = 0; i < path.length; i++) i]);
    }

    final removable = [
      for (final i in marked)
        if (i != 0 && i != path.length - 1) i,
    ]..sort();
    rng.shuffle(removable);
    final target = targetCheckpoints(difficulty);
    for (final i in removable) {
      if (marked.length <= target) break;
      marked.remove(i);
      if (solver.countSolutions(_number(n, path, marked)) != 1) marked.add(i);
    }

    return KilnPathPuzzle(
      size: n,
      checkpoints: _number(n, path, marked),
      solution: path,
      seed: seed,
      difficulty: difficulty,
    );
  }

  /// Numbers the marked path positions 1, 2, 3... in path order.
  static List<int> _number(int n, List<int> path, Set<int> marked) {
    final grid = List.filled(n * n, 0);
    var k = 0;
    for (var i = 0; i < path.length; i++) {
      if (marked.contains(i)) grid[path[i]] = ++k;
    }
    return grid;
  }

  /// A random Hamiltonian path on an `n x n` grid.
  ///
  /// Starts from a serpentine and applies the backbite move: pick an end,
  /// join it to a random grid neighbour already on the path, and reverse the
  /// segment between them so the path stays a single line.
  static List<int> randomPath(int n, SeededRandom rng) {
    final path = <int>[
      for (var r = 0; r < n; r++)
        for (var c = 0; c < n; c++) r * n + (r.isEven ? c : n - 1 - c),
    ];
    final position = List.filled(n * n, 0);
    void reindex(int from, int to) {
      for (var i = from; i <= to; i++) {
        position[path[i]] = i;
      }
    }

    reindex(0, path.length - 1);
    final moves = 20 * n * n;
    for (var m = 0; m < moves; m++) {
      if (rng.nextInt(2) == 1) {
        _reverse(path, 0, path.length - 1);
        reindex(0, path.length - 1);
      }
      final head = path[0];
      final options = <int>[
        if (head ~/ n > 0) head - n,
        if (head % n < n - 1) head + 1,
        if (head ~/ n < n - 1) head + n,
        if (head % n > 0) head - 1,
      ];
      final x = options[rng.nextInt(options.length)];
      final j = position[x];
      if (j <= 1) continue; // Already joined to the head.
      _reverse(path, 0, j - 1);
      reindex(0, j - 1);
    }
    return path;
  }

  static void _reverse(List<int> list, int from, int to) {
    while (from < to) {
      final t = list[from];
      list[from++] = list[to];
      list[to--] = t;
    }
  }

  /// Lower bound on checkpoints (the two ends count). Generation stops removing at this count; it
  /// may end higher if no further checkpoint can go without losing
  /// uniqueness.
  ///
  /// Fierce has no floor: it removes every checkpoint it can. On a 7x7 grid
  /// that lands around 11, which is why tricky stops a few above it.
  static int targetCheckpoints(Difficulty d) => switch (d) {
        Difficulty.gentle => 9,
        Difficulty.steady => 10,
        Difficulty.tricky => 14,
        Difficulty.fierce => 2,
      };
}
