import '../difficulty.dart';
import '../seeded_random.dart';
import 'cutouts_puzzle.dart';

/// Deterministic Cutouts generator: same seed and difficulty, same puzzle.
///
/// Picks folds and stamps, unfolds them for the answer, and builds three
/// distractors from the mistakes people actually make: forgetting to unfold
/// the last fold, mirroring across the wrong axis, and nudging a stamp.
class CutoutsGenerator {
  const CutoutsGenerator();

  CutoutsPuzzle generate(int seed, Difficulty difficulty) {
    final rng = SeededRandom(seed);
    final (size, foldCount, stampCount) = shapeFor(difficulty);
    while (true) {
      var sheet = FoldedSheet.flat(size);
      final folds = <Fold>[];
      for (var i = 0; i < foldCount; i++) {
        final options = Fold.values.where(sheet.canFold).toList();
        // Alternate axes where possible so the sheet stays squarish.
        final preferred = folds.isEmpty
            ? options
            : options
                .where((f) => f.isVertical != folds.last.isVertical)
                .toList();
        final pool = preferred.isEmpty ? options : preferred;
        final f = pool[rng.nextInt(pool.length)];
        folds.add(f);
        sheet = sheet.fold(f);
      }
      final visible = [
        for (var y = sheet.y0; y < sheet.y1; y++)
          for (var x = sheet.x0; x < sheet.x1; x++) y * size + x,
      ];
      rng.shuffle(visible);
      final stamps = visible.take(stampCount).toList()..sort();
      final truth = sheet.punch(stamps);

      final distractors = _distractors(size, folds, stamps, rng)
          .where((d) => d.isNotEmpty && !_same(d, truth))
          .toList();
      final unique = <Set<int>>[];
      for (final d in distractors) {
        if (!unique.any((u) => _same(u, d))) unique.add(d);
      }
      if (unique.length < 3) continue;
      rng.shuffle(unique);
      final options = [truth, ...unique.take(3)];
      final order = [0, 1, 2, 3];
      rng.shuffle(order);
      return CutoutsPuzzle(
        size: size,
        folds: folds,
        stamps: stamps,
        options: [for (final i in order) options[i]],
        answer: order.indexOf(0),
        seed: seed,
        difficulty: difficulty,
      );
    }
  }

  /// (sheet size, folds, stamps) per difficulty.
  static (int, int, int) shapeFor(Difficulty d) => switch (d) {
        Difficulty.gentle => (4, 1, 2),
        Difficulty.steady => (4, 2, 2),
        Difficulty.tricky => (6, 2, 3),
        Difficulty.fierce => (8, 3, 3),
      };

  static List<Set<int>> _distractors(
    int size,
    List<Fold> folds,
    List<int> stamps,
    SeededRandom rng,
  ) {
    Set<int> unfold(List<Fold> fs, List<int> st) {
      var s = FoldedSheet.flat(size);
      for (final f in fs) {
        s = s.fold(f);
      }
      return s.punch(st);
    }

    final out = <Set<int>>[];
    var sheet = FoldedSheet.flat(size);
    for (final f in folds) {
      sheet = sheet.fold(f);
    }

    // 1. Forgot to unfold the last fold.
    if (folds.length > 1) {
      out.add(unfold(folds.sublist(0, folds.length - 1), stamps));
    } else {
      out.add(stamps.toSet());
    }

    // 2. Mirrored the whole result across the wrong axis.
    final truth = unfold(folds, stamps);
    out.add(
        {for (final c in truth) (c ~/ size) * size + (size - 1 - c % size)});
    out.add({for (final c in truth) (size - 1 - c ~/ size) * size + c % size});

    // 3. Folded one step along the wrong axis.
    for (var i = 0; i < folds.length; i++) {
      final swapped = List.of(folds);
      swapped[i] = switch (folds[i]) {
        Fold.leftOverRight => Fold.topOverBottom,
        Fold.rightOverLeft => Fold.bottomOverTop,
        Fold.topOverBottom => Fold.leftOverRight,
        Fold.bottomOverTop => Fold.rightOverLeft,
      };
      try {
        var s = FoldedSheet.flat(size);
        for (final f in swapped) {
          s = s.fold(f);
        }
        // Map each stamp to the same position within the new visible
        // rectangle.
        final moved = [
          for (final st in stamps)
            (s.y0 + (st ~/ size - sheet.y0) % s.height) * size +
                s.x0 +
                (st % size - sheet.x0) % s.width,
        ];
        out.add(s.punch(moved));
      } on StateError {
        // That axis could not be folded at that point; skip.
      }
    }

    // 4. Nudged one stamp to a neighbouring tile of the folded sheet.
    for (var k = 0; k < stamps.length; k++) {
      final st = stamps[k];
      final nbs = [
        st - size,
        st + size,
        if (st % size > 0) st - 1,
        if (st % size < size - 1) st + 1,
      ].where((c) => c >= 0 && c < size * size && sheet.isVisible(c));
      for (final nb in nbs) {
        if (stamps.contains(nb)) continue;
        out.add(sheet.punch([...stamps]..[k] = nb));
      }
    }
    rng.shuffle(out);
    return out;
  }

  static bool _same(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);
}
