import '../difficulty.dart';

/// Which edge of the current sheet is folded over onto the other half.
enum Fold {
  /// Left half over onto the right half.
  leftOverRight,

  /// Right half over onto the left half.
  rightOverLeft,

  /// Top half down onto the bottom half.
  topOverBottom,

  /// Bottom half up onto the top half.
  bottomOverTop;

  bool get isVertical => this == leftOverRight || this == rightOverLeft;
}

/// The visible part of a folded sheet: a rectangle of the original grid,
/// and for each visible cell, every original cell stacked under it.
class FoldedSheet {
  FoldedSheet._(this.size, this.x0, this.y0, this.x1, this.y1, this._layers);

  /// A flat `size x size` sheet.
  factory FoldedSheet.flat(int size) => FoldedSheet._(
        size,
        0,
        0,
        size,
        size,
        {
          for (var i = 0; i < size * size; i++) i: {i},
        },
      );

  final int size;

  /// Visible rectangle `[x0, x1) x [y0, y1)` in original coordinates.
  final int x0, y0, x1, y1;

  final Map<int, Set<int>> _layers;

  int get width => x1 - x0;
  int get height => y1 - y0;

  /// Original cells stacked under visible [cell] (an original index).
  Set<int> layersAt(int cell) => Set.unmodifiable(_layers[cell] ?? const {});

  bool isVisible(int cell) {
    final x = cell % size, y = cell ~/ size;
    return x >= x0 && x < x1 && y >= y0 && y < y1;
  }

  bool canFold(Fold f) => f.isVertical ? width.isEven : height.isEven;

  FoldedSheet fold(Fold f) {
    if (!canFold(f)) throw StateError('Cannot fold an odd edge in half.');
    final layers = <int, Set<int>>{};
    var nx0 = x0, ny0 = y0, nx1 = x1, ny1 = y1;
    switch (f) {
      case Fold.leftOverRight:
        nx0 = x0 + width ~/ 2;
      case Fold.rightOverLeft:
        nx1 = x0 + width ~/ 2;
      case Fold.topOverBottom:
        ny0 = y0 + height ~/ 2;
      case Fold.bottomOverTop:
        ny1 = y0 + height ~/ 2;
    }
    for (var y = ny0; y < ny1; y++) {
      for (var x = nx0; x < nx1; x++) {
        final mx = f.isVertical ? x0 + x1 - 1 - x : x;
        final my = f.isVertical ? y : y0 + y1 - 1 - y;
        layers[y * size + x] = {
          ..._layers[y * size + x]!,
          ..._layers[my * size + mx]!,
        };
      }
    }
    return FoldedSheet._(size, nx0, ny0, nx1, ny1, layers);
  }

  /// Holes in the unfolded sheet after stamping [stamps] (visible cells).
  Set<int> punch(Iterable<int> stamps) => {
        for (final s in stamps) ..._layers[s]!,
      };
}

/// An immutable Cutouts puzzle.
///
/// A square clay sheet is folded in half a few times, then stamped through
/// every layer. The player picks which of four unfolded sheets is the real
/// result.
class CutoutsPuzzle {
  CutoutsPuzzle({
    required this.size,
    required List<Fold> folds,
    required List<int> stamps,
    required List<Set<int>> options,
    required this.answer,
    this.seed,
    this.difficulty,
  })  : folds = List.unmodifiable(folds),
        stamps = List.unmodifiable(stamps),
        options = List.unmodifiable(
            [for (final o in options) Set<int>.unmodifiable(o)]) {
    final folded = foldedSheet;
    if (stamps.isEmpty || !stamps.every(folded.isVisible)) {
      throw ArgumentError('Stamps must sit on the folded sheet.');
    }
    final truth = folded.punch(stamps);
    if (answer < 0 ||
        answer >= options.length ||
        !_same(options[answer], truth)) {
      throw ArgumentError('The answer option is not the unfolded result.');
    }
    for (var i = 0; i < options.length; i++) {
      for (var j = i + 1; j < options.length; j++) {
        if (_same(options[i], options[j])) {
          throw ArgumentError('Options $i and $j are the same.');
        }
      }
    }
  }

  final int size;
  final List<Fold> folds;

  /// Cells of the folded sheet that were stamped (original indices).
  final List<int> stamps;

  /// Candidate unfolded sheets, as sets of hole cells.
  final List<Set<int>> options;

  /// Index into [options] of the real result.
  final int answer;

  final int? seed;
  final Difficulty? difficulty;

  int get cellCount => size * size;

  /// The sheet after each fold, starting flat.
  List<FoldedSheet> get stages {
    final out = [FoldedSheet.flat(size)];
    for (final f in folds) {
      out.add(out.last.fold(f));
    }
    return out;
  }

  FoldedSheet get foldedSheet => stages.last;

  Set<int> get holes => options[answer];

  /// Holes in the top-left `window x window` corner, as a row-major mask.
  /// Solving Cutouts reveals this stamp pattern to the keystone.
  List<bool> keystoneStamp([int window = 5]) {
    final w = window < size ? window : size;
    return [
      for (var r = 0; r < w; r++)
        for (var c = 0; c < w; c++) holes.contains(r * size + c),
    ];
  }

  static bool _same(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);
}
