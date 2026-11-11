/// The puzzle types in Tessera. Names are Tessera's own; the rule families
/// behind them are genre-standard.
enum PuzzleKind {
  /// Latin-square fill with boxes (sudoku family).
  glaze('Glaze', 'Fill every row, column and box with each glaze once.'),

  /// Hamiltonian path through numbered checkpoints.
  kilnPath('Kiln Path', 'One unbroken firing line through every tile.'),

  /// Star Battle style placement.
  pebbles('Pebbles', 'Set pebbles in the grout so none touch.'),

  /// Numberlink.
  seams('Seams', 'Join matching shards with gold seams.'),

  /// Paper fold and punch.
  cutouts('Cutouts', 'Fold the clay, stamp it, picture it unfolded.'),

  /// Polyomino tiling.
  shards('Shards', 'Rebuild the plate from its shards.');

  const PuzzleKind(this.title, this.tagline);

  final String title;
  final String tagline;

  /// Types that have a playable implementation in this build.
  bool get isPlayable => switch (this) {
        glaze || kilnPath || pebbles => true,
        _ => false,
      };
}
