import '../cutouts/cutouts_generator.dart';
import '../daily.dart';
import '../difficulty.dart';
import '../kiln_path/kiln_path_generator.dart';
import '../pebbles/pebbles_generator.dart';
import '../puzzle_kind.dart';
import '../seams/seams_generator.dart';
import '../seeded_random.dart';
import '../shards/shards_generator.dart';
import 'keystone_puzzle.dart';

/// Builds the day's keystone from the day's tray.
///
/// Each tray puzzle's own answer gives a 5x5 picture (its keystone clue).
/// A few tiles of that picture become the tiles the puzzle reveals. Base
/// givens are added only if the clues together still leave more than one
/// answer.
class KeystoneBuilder {
  const KeystoneBuilder();

  KeystonePuzzle forDay(PuzzleDay day) {
    final tray = DailyTray.forDay(day);
    return build(
      seed: day.seed,
      difficulty: day.difficulty,
      pictures: {
        for (final kind in tray.kinds)
          kind: cluePicture(kind, day.seedFor(kind), day.difficulty),
      },
    );
  }

  /// Builds a keystone from each puzzle's 5x5 clue picture (row-major).
  KeystonePuzzle build({
    required int seed,
    required Difficulty difficulty,
    required Map<PuzzleKind, List<bool>> pictures,
  }) {
    final rng = SeededRandom(seed ^ 0x6B657973); // 'keys'
    final solution = _randomLatinSquare(rng);
    final perClue = revealsPerClue(difficulty);

    // Each puzzle reveals up to [perClue] tiles of its picture, never one
    // already revealed by another puzzle, so every clue adds something.
    final taken = <int>{};
    final clues = <PuzzleKind, Set<int>>{};
    for (final e in pictures.entries) {
      final cells = [
        for (var i = 0; i < KeystonePuzzle.cellCount; i++)
          if (e.value[i] && !taken.contains(i)) i,
      ];
      rng.shuffle(cells);
      if (cells.isEmpty) {
        // A blank picture still reveals something: any free tile.
        cells.addAll([
          for (var i = 0; i < KeystonePuzzle.cellCount; i++)
            if (!taken.contains(i)) i,
        ]);
        rng.shuffle(cells);
      }
      final reveal = cells.take(perClue).toSet();
      clues[e.key] = reveal;
      taken.addAll(reveal);
    }

    // Base givens only if the clues alone are not enough.
    final rest = [
      for (var i = 0; i < KeystonePuzzle.cellCount; i++)
        if (!taken.contains(i)) i,
    ];
    rng.shuffle(rest);
    final base = <int>{};
    List<int> grid() => [
          for (var i = 0; i < KeystonePuzzle.cellCount; i++)
            taken.contains(i) || base.contains(i) ? solution[i] : 0,
        ];
    for (final cell in rest) {
      if (KeystoneSolver.countSolutions(grid()) == 1) break;
      base.add(cell);
    }
    // Trim base tiles that turned out not to be needed.
    for (final cell in base.toList()) {
      base.remove(cell);
      if (KeystoneSolver.countSolutions(grid()) != 1) base.add(cell);
    }

    // Tiles are lent, when starting early, from the clue tiles first (so a
    // lent tile is one a puzzle would have revealed), then the rest.
    final lendOrder = [
      for (final c in clues.values) ...c,
      ...rest.where((c) => !base.contains(c)),
    ];
    return KeystonePuzzle(
      solution: solution,
      clues: clues,
      base: base,
      lendOrder: lendOrder,
      difficulty: difficulty,
    );
  }

  /// Tiles each solved puzzle reveals.
  static int revealsPerClue(Difficulty d) => switch (d) {
        Difficulty.gentle => 3,
        Difficulty.steady => 3,
        Difficulty.tricky => 2,
        Difficulty.fierce => 2,
      };

  /// A puzzle's 5x5 clue picture, taken from its answer.
  static List<bool> cluePicture(PuzzleKind kind, int seed, Difficulty d) {
    const n = KeystonePuzzle.size;
    switch (kind) {
      case PuzzleKind.glaze:
        // The diagonal the Glaze solve highlights.
        return [for (var i = 0; i < n * n; i++) i ~/ n == i % n];
      case PuzzleKind.kilnPath:
        return _fit(
            const KilnPathGenerator().generate(seed, d).keystoneShading());
      case PuzzleKind.pebbles:
        return _fit(
            const PebblesGenerator().generate(seed, d).keystoneNoEntry());
      case PuzzleKind.seams:
        final steps =
            const SeamsGenerator().generate(seed, d).keystoneSeamShape;
        return _trace(steps);
      case PuzzleKind.cutouts:
        return _fit(const CutoutsGenerator().generate(seed, d).keystoneStamp());
      case PuzzleKind.shards:
        return _fit(const ShardsGenerator().generate(seed, d).keystoneShard());
    }
  }

  /// Pads or crops a square row-major mask to 5x5.
  static List<bool> _fit(List<bool> mask) {
    const n = KeystonePuzzle.size;
    var w = 1;
    while (w * w < mask.length) {
      w++;
    }
    return [
      for (var r = 0; r < n; r++)
        for (var c = 0; c < n; c++) r < w && c < w && mask[r * w + c],
    ];
  }

  /// The tiles a seam shape covers, drawn from the top-left and clipped.
  static List<bool> _trace(List<int> steps) {
    const n = KeystonePuzzle.size;
    var x = 0, y = 0;
    final points = [(0, 0)];
    for (final s in steps) {
      switch (s) {
        case 0:
          y--;
        case 1:
          x++;
        case 2:
          y++;
        default:
          x--;
      }
      points.add((x, y));
    }
    final minX = points.map((p) => p.$1).reduce((a, b) => a < b ? a : b);
    final minY = points.map((p) => p.$2).reduce((a, b) => a < b ? a : b);
    final out = List.filled(n * n, false);
    for (final (px, py) in points) {
      final cx = px - minX, cy = py - minY;
      if (cx < n && cy < n) out[cy * n + cx] = true;
    }
    return out;
  }

  /// A random 5x5 Latin square: a shuffled cyclic square, then rows,
  /// columns and symbols permuted.
  static List<int> _randomLatinSquare(SeededRandom rng) {
    const n = KeystonePuzzle.size;
    final rows = [for (var i = 0; i < n; i++) i];
    final cols = [for (var i = 0; i < n; i++) i];
    final symbols = [for (var i = 1; i <= n; i++) i];
    rng
      ..shuffle(rows)
      ..shuffle(cols)
      ..shuffle(symbols);
    return [
      for (var r = 0; r < n; r++)
        for (var c = 0; c < n; c++) symbols[(rows[r] + cols[c]) % n],
    ];
  }
}
