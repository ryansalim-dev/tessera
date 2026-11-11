import '../difficulty.dart';

/// An immutable Seams puzzle (Numberlink family).
///
/// A `size x size` plate has pairs of matching shards. The player joins each
/// pair with one gold seam of orthogonal steps; seams never cross or share a
/// tile, and together they cover the whole plate.
///
/// Cells are indexed row-major.
class SeamsPuzzle {
  SeamsPuzzle({
    required this.size,
    required List<int> endpoints,
    required List<List<int>> seams,
    this.seed,
    this.difficulty,
  })  : endpoints = List.unmodifiable(endpoints),
        seams = List.unmodifiable(
            [for (final s in seams) List<int>.unmodifiable(s)]) {
    final cells = size * size;
    if (endpoints.length != cells) {
      throw ArgumentError('Endpoint grid length must be $cells.');
    }
    final covered = <int>{};
    for (var i = 0; i < seams.length; i++) {
      final s = seams[i];
      final id = i + 1;
      if (s.length < 2 || endpoints[s.first] != id || endpoints[s.last] != id) {
        throw ArgumentError('Seam $id must run between its two shards.');
      }
      for (var k = 0; k < s.length; k++) {
        if (!covered.add(s[k])) {
          throw ArgumentError('Seams overlap at ${s[k]}.');
        }
        if (k > 0 && !areNeighbours(s[k - 1], s[k])) {
          throw ArgumentError('Seam $id has a gap at step $k.');
        }
        if (k > 0 && k < s.length - 1 && endpoints[s[k]] != 0) {
          throw ArgumentError('Seam $id runs over a shard.');
        }
      }
    }
    if (covered.length != cells) {
      throw ArgumentError('Seams must cover the whole plate.');
    }
  }

  final int size;

  /// Pair id `1..pairCount` on the two shard cells of each pair, else `0`.
  final List<int> endpoints;

  /// The unique solution: seam `i` (pair id `i + 1`) as cells from one shard
  /// to the other.
  final List<List<int>> seams;

  final int? seed;
  final Difficulty? difficulty;

  int get cellCount => size * size;
  int get pairCount => seams.length;
  int row(int index) => index ~/ size;
  int col(int index) => index % size;

  bool areNeighbours(int a, int b) =>
      (row(a) - row(b)).abs() + (col(a) - col(b)).abs() == 1;

  Iterable<int> neighbours(int index) sync* {
    final r = row(index), c = col(index);
    if (r > 0) yield index - size;
    if (c < size - 1) yield index + 1;
    if (r < size - 1) yield index + size;
    if (c > 0) yield index - 1;
  }

  /// Pair id covering each cell in the solution.
  List<int> get solutionOwners {
    final out = List.filled(cellCount, 0);
    for (var i = 0; i < seams.length; i++) {
      for (final c in seams[i]) {
        out[c] = i + 1;
      }
    }
    return out;
  }

  /// The longest seam's shape, as the turn sequence the keystone must
  /// contain: each entry is the step direction (0 up, 1 right, 2 down,
  /// 3 left). Solving Seams reveals this shape to the keystone.
  List<int> get keystoneSeamShape {
    var longest = seams.first;
    for (final s in seams) {
      if (s.length > longest.length) longest = s;
    }
    return [
      for (var k = 1; k < longest.length; k++)
        switch (longest[k] - longest[k - 1]) {
          final d when d == -size => 0,
          1 => 1,
          final d when d == size => 2,
          _ => 3,
        },
    ];
  }

  static int sizeFor(Difficulty d) => switch (d) {
        Difficulty.gentle => 5,
        Difficulty.steady => 6,
        Difficulty.tricky || Difficulty.fierce => 7,
      };
}
