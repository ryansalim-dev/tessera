import '../difficulty.dart';

/// A shard shape: a set of `(row, col)` offsets, normalised so the smallest
/// row and column are 0.
class ShardShape {
  ShardShape(Iterable<(int, int)> cells) : cells = _normalise(cells);

  final List<(int, int)> cells;

  int get size => cells.length;
  int get rows => cells.map((c) => c.$1).reduce((a, b) => a > b ? a : b) + 1;
  int get cols => cells.map((c) => c.$2).reduce((a, b) => a > b ? a : b) + 1;

  /// Turned a quarter clockwise [turns] times.
  ShardShape rotated(int turns) {
    var out = cells;
    for (var t = 0; t < turns % 4; t++) {
      out = [for (final (r, c) in out) (c, -r)];
    }
    return ShardShape(out);
  }

  bool contains(int r, int c) => cells.contains((r, c));

  static List<(int, int)> _normalise(Iterable<(int, int)> cells) {
    final list = cells.toList();
    final minR = list.map((c) => c.$1).reduce((a, b) => a < b ? a : b);
    final minC = list.map((c) => c.$2).reduce((a, b) => a < b ? a : b);
    return [for (final (r, c) in list) (r - minR, c - minC)]
      ..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
  }

  @override
  bool operator ==(Object other) =>
      other is ShardShape &&
      other.cells.length == cells.length &&
      Iterable.generate(cells.length).every((i) => other.cells[i] == cells[i]);

  @override
  int get hashCode => Object.hashAll(cells);

  @override
  String toString() => 'ShardShape($cells)';
}

/// Where a shard sits on the plate: its rotation and the cell its `(0, 0)`
/// offset lands on.
class ShardPlacement {
  const ShardPlacement(this.turns, this.row, this.col);

  final int turns;
  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is ShardPlacement &&
      other.turns % 4 == turns % 4 &&
      other.row == row &&
      other.col == col;

  @override
  int get hashCode => Object.hash(turns % 4, row, col);

  @override
  String toString() => 'ShardPlacement(turns $turns, $row, $col)';
}

/// An immutable Shards puzzle (polyomino tiling).
///
/// A broken plate (a silhouette on a `size x size` grid) must be rebuilt
/// from its shards. Shards can be turned but not flipped, and together they
/// cover the plate exactly.
class ShardsPuzzle {
  ShardsPuzzle({
    required this.size,
    required List<bool> plate,
    required List<ShardShape> shards,
    required List<ShardPlacement> solution,
    this.seed,
    this.difficulty,
  })  : plate = List.unmodifiable(plate),
        shards = List.unmodifiable(shards),
        solution = List.unmodifiable(solution) {
    if (plate.length != size * size) {
      throw ArgumentError('Plate grid length must be ${size * size}.');
    }
    if (shards.length != solution.length) {
      throw ArgumentError('Every shard needs a solution placement.');
    }
    final covered = <int>{};
    for (var i = 0; i < shards.length; i++) {
      final cells = cellsFor(i, solution[i]);
      if (cells == null) throw ArgumentError('Shard $i is off the plate.');
      for (final c in cells) {
        if (!covered.add(c)) throw ArgumentError('Shards overlap at $c.');
      }
    }
    if (covered.length != plateArea) {
      throw ArgumentError('Shards must cover the plate exactly.');
    }
  }

  final int size;

  /// Whether each grid cell is part of the plate.
  final List<bool> plate;

  /// Shard shapes, as handed to the player (already turned at random).
  final List<ShardShape> shards;

  /// One way to rebuild the plate. Other tilings also count as solved.
  final List<ShardPlacement> solution;

  final int? seed;
  final Difficulty? difficulty;

  int get cellCount => size * size;
  int get plateArea => plate.where((p) => p).length;

  /// Plate cells shard [index] covers at [placement], or null if any falls
  /// off the plate.
  List<int>? cellsFor(int index, ShardPlacement placement) {
    final shape = shards[index].rotated(placement.turns);
    final out = <int>[];
    for (final (r, c) in shape.cells) {
      final rr = placement.row + r, cc = placement.col + c;
      if (rr < 0 || cc < 0 || rr >= size || cc >= size) return null;
      final cell = rr * size + cc;
      if (!plate[cell]) return null;
      out.add(cell);
    }
    return out;
  }

  /// The biggest shard as a row-major mask over a `window x window` box.
  /// Solving Shards reveals this outline to the keystone.
  List<bool> keystoneShard([int window = 5]) {
    var biggest = shards.first;
    for (final s in shards) {
      if (s.size > biggest.size) biggest = s;
    }
    return [
      for (var r = 0; r < window; r++)
        for (var c = 0; c < window; c++) biggest.contains(r, c),
    ];
  }

  static int sizeFor(Difficulty d) => switch (d) {
        Difficulty.gentle => 4,
        Difficulty.steady => 5,
        Difficulty.tricky => 6,
        Difficulty.fierce => 6,
      };
}
