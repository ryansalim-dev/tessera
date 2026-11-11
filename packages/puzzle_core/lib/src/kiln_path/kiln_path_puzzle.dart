import '../difficulty.dart';

/// An immutable Kiln Path puzzle.
///
/// The player draws one unbroken firing line through every tile of a
/// `size x size` grid, moving between orthogonal neighbours, starting on
/// checkpoint 1 and passing every numbered checkpoint in order. The last
/// checkpoint is where the line ends.
///
/// Cells are indexed row-major.
class KilnPathPuzzle {
  KilnPathPuzzle({
    required this.size,
    required List<int> checkpoints,
    required List<int> solution,
    this.seed,
    this.difficulty,
  })  : checkpoints = List.unmodifiable(checkpoints),
        solution = List.unmodifiable(solution) {
    final cells = size * size;
    if (checkpoints.length != cells) {
      throw ArgumentError('Checkpoint grid length must be $cells.');
    }
    if (solution.length != cells || solution.toSet().length != cells) {
      throw ArgumentError('Solution must visit each of the $cells cells once.');
    }
    for (var i = 1; i < solution.length; i++) {
      if (!areNeighbours(solution[i - 1], solution[i])) {
        throw ArgumentError('Solution steps $i-1 -> $i are not adjacent.');
      }
    }
    var expected = 1;
    for (final cell in solution) {
      final n = checkpoints[cell];
      if (n == 0) continue;
      if (n != expected) {
        throw ArgumentError('Checkpoint $n is out of order on the solution.');
      }
      expected++;
    }
    if (checkpoints[solution.first] != 1 ||
        checkpoints[solution.last] != expected - 1) {
      throw ArgumentError('The line must start on 1 and end on the last '
          'checkpoint.');
    }
  }

  final int size;

  /// Checkpoint number per cell, `1..checkpointCount`, or `0` for none.
  final List<int> checkpoints;

  /// The unique solution: cell indices in the order the line visits them.
  final List<int> solution;

  final int? seed;
  final Difficulty? difficulty;

  int get cellCount => size * size;
  int get checkpointCount => checkpoints.where((n) => n != 0).length;
  int get start => solution.first;
  int get end => solution.last;

  int row(int index) => index ~/ size;
  int col(int index) => index % size;

  bool areNeighbours(int a, int b) {
    final dr = (row(a) - row(b)).abs(), dc = (col(a) - col(b)).abs();
    return dr + dc == 1;
  }

  Iterable<int> neighbours(int index) sync* {
    final r = row(index), c = col(index);
    if (r > 0) yield index - size;
    if (c < size - 1) yield index + 1;
    if (r < size - 1) yield index + size;
    if (c > 0) yield index - 1;
  }

  /// Cells where the firing line turns a corner. Solving Kiln Path reveals
  /// these to the keystone as shaded cells (see the design doc).
  Set<int> get bends => {
        for (var i = 1; i < solution.length - 1; i++)
          if (row(solution[i - 1]) != row(solution[i + 1]) &&
              col(solution[i - 1]) != col(solution[i + 1]))
            solution[i],
      };

  /// The bends that fall in the top-left `window x window` corner, as a
  /// row-major mask over that window. This is the keystone clue.
  List<bool> keystoneShading([int window = 5]) {
    final w = window < size ? window : size;
    final b = bends;
    return [
      for (var r = 0; r < w; r++)
        for (var c = 0; c < w; c++) b.contains(r * size + c),
    ];
  }

  static int sizeFor(Difficulty d) => switch (d) {
        Difficulty.gentle => 5,
        Difficulty.steady => 6,
        Difficulty.tricky || Difficulty.fierce => 7,
      };
}
