import '../difficulty.dart';

/// An immutable Pebbles puzzle.
///
/// A `size x size` grid is split into `size` grout regions. The player sets
/// one pebble in every row, every column and every region, and no two
/// pebbles may touch, not even diagonally.
///
/// Cells are indexed row-major.
class PebblesPuzzle {
  PebblesPuzzle({
    required this.size,
    required List<int> regions,
    required List<int> solution,
    this.seed,
    this.difficulty,
  })  : regions = List.unmodifiable(regions),
        solution = List.unmodifiable(List.of(solution)..sort()) {
    if (regions.length != size * size) {
      throw ArgumentError('Region grid length must be ${size * size}.');
    }
    if (regions.any((r) => r < 0 || r >= size)) {
      throw ArgumentError('Region ids must be 0..${size - 1}.');
    }
    if (!isValidPlacement(solution.toSet())) {
      throw ArgumentError('Solution breaks the rules.');
    }
  }

  final int size;

  /// Region id `0..size-1` per cell.
  final List<int> regions;

  /// The cells holding pebbles in the unique solution, ascending.
  final List<int> solution;

  final int? seed;
  final Difficulty? difficulty;

  int get cellCount => size * size;
  int row(int index) => index ~/ size;
  int col(int index) => index % size;
  int region(int index) => regions[index];

  /// Whether two different cells touch, including diagonally.
  bool touches(int a, int b) =>
      a != b && (row(a) - row(b)).abs() <= 1 && (col(a) - col(b)).abs() <= 1;

  /// Exactly one pebble per row, column and region, none touching.
  bool isValidPlacement(Set<int> pebbles) {
    if (pebbles.length != size) return false;
    final rows = <int>{}, cols = <int>{}, regs = <int>{};
    for (final p in pebbles) {
      if (!rows.add(row(p)) || !cols.add(col(p)) || !regs.add(region(p))) {
        return false;
      }
    }
    for (final a in pebbles) {
      for (final b in pebbles) {
        if (touches(a, b)) return false;
      }
    }
    return true;
  }

  /// Pebbles in the top-left `window x window` corner, as a row-major mask
  /// over that window. They become no-entry tiles in the keystone.
  List<bool> keystoneNoEntry([int window = 5]) {
    final w = window < size ? window : size;
    final s = solution.toSet();
    return [
      for (var r = 0; r < w; r++)
        for (var c = 0; c < w; c++) s.contains(r * size + c),
    ];
  }

  static int sizeFor(Difficulty d) => switch (d) {
        Difficulty.gentle => 5,
        Difficulty.steady => 6,
        Difficulty.tricky => 7,
        Difficulty.fierce => 8,
      };
}
