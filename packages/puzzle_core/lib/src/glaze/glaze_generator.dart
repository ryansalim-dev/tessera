import '../difficulty.dart';
import '../seeded_random.dart';
import 'glaze_puzzle.dart';
import 'glaze_solver.dart';

/// Deterministic Glaze generator: same seed and difficulty, same puzzle.
///
/// Builds a random full grid, then removes givens in a random order while the
/// puzzle stays uniquely solvable, stopping at the difficulty's target count.
///
/// TODO(M3): grade difficulty by the solving techniques needed rather than by
/// given count.
class GlazeGenerator {
  const GlazeGenerator();

  GlazePuzzle generate(int seed, Difficulty difficulty, {GlazeLayout? layout}) {
    final l = layout ?? GlazeLayout.forDifficulty(difficulty);
    final rng = SeededRandom(seed);
    final solver = GlazeSolver(l);

    final digits = [for (var d = 1; d <= l.size; d++) d];
    rng.shuffle(digits);
    final solution = solver.solve(List.filled(l.cellCount, 0), order: digits)!;

    final givens = List.of(solution);
    final order = [for (var i = 0; i < l.cellCount; i++) i];
    rng.shuffle(order);
    final target = targetGivens(l, difficulty);
    var count = l.cellCount;
    for (final i in order) {
      if (count <= target) break;
      final keep = givens[i];
      givens[i] = 0;
      if (solver.countSolutions(givens) == 1) {
        count--;
      } else {
        givens[i] = keep;
      }
    }

    return GlazePuzzle(
      layout: l,
      givens: givens,
      solution: solution,
      seed: seed,
      difficulty: difficulty,
    );
  }

  /// Lower bound on givens. Generation stops removing at this count; it may
  /// end higher if no further cell can be removed without losing uniqueness.
  static int targetGivens(GlazeLayout layout, Difficulty d) => switch (layout) {
        GlazeLayout.six => switch (d) {
            Difficulty.gentle => 18,
            Difficulty.steady => 14,
            Difficulty.tricky => 11,
            Difficulty.fierce => 8,
          },
        GlazeLayout.nine => switch (d) {
            Difficulty.gentle => 40,
            Difficulty.steady => 34,
            Difficulty.tricky => 30,
            Difficulty.fierce => 26,
          },
      };
}
