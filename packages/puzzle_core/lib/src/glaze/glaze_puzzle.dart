import '../difficulty.dart';

/// Box layout for a Glaze grid. Size is `boxRows * boxCols`.
enum GlazeLayout {
  /// 6x6 with 2x3 boxes. Used for gentle and steady days.
  six(2, 3),

  /// 9x9 with 3x3 boxes. Used for tricky and fierce days.
  nine(3, 3);

  const GlazeLayout(this.boxRows, this.boxCols);

  final int boxRows;
  final int boxCols;

  int get size => boxRows * boxCols;
  int get cellCount => size * size;

  static GlazeLayout forDifficulty(Difficulty d) => switch (d) {
        Difficulty.gentle || Difficulty.steady => GlazeLayout.six,
        Difficulty.tricky || Difficulty.fierce => GlazeLayout.nine,
      };
}

/// An immutable Glaze puzzle: the givens and the unique solution.
///
/// Cells are indexed row-major. Values are `1..size`; `0` means empty.
class GlazePuzzle {
  GlazePuzzle({
    required this.layout,
    required List<int> givens,
    required List<int> solution,
    this.seed,
    this.difficulty,
  })  : givens = List.unmodifiable(givens),
        solution = List.unmodifiable(solution) {
    if (givens.length != layout.cellCount ||
        solution.length != layout.cellCount) {
      throw ArgumentError('Grid length must be ${layout.cellCount}.');
    }
    for (var i = 0; i < givens.length; i++) {
      if (givens[i] != 0 && givens[i] != solution[i]) {
        throw ArgumentError('Given at $i disagrees with the solution.');
      }
    }
  }

  final GlazeLayout layout;
  final List<int> givens;
  final List<int> solution;
  final int? seed;
  final Difficulty? difficulty;

  int get size => layout.size;
  int get givenCount => givens.where((v) => v != 0).length;

  int row(int index) => index ~/ size;
  int col(int index) => index % size;
  int box(int index) =>
      (row(index) ~/ layout.boxRows) * (size ~/ layout.boxCols) +
      col(index) ~/ layout.boxCols;

  /// The cells on the main diagonal. Solving Glaze reveals these digits to
  /// the keystone (see the design doc).
  List<int> get keystoneDiagonal =>
      [for (var i = 0; i < size; i++) solution[i * size + i]];

  /// Every cell that shares a row, column or box with [index].
  Iterable<int> peers(int index) sync* {
    final r = row(index), c = col(index), b = box(index);
    for (var i = 0; i < layout.cellCount; i++) {
      if (i != index && (row(i) == r || col(i) == c || box(i) == b)) yield i;
    }
  }
}
