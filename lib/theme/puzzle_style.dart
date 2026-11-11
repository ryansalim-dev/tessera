import 'dart:ui';

import 'package:puzzle_core/puzzle_core.dart';

import 'tessera_colors.dart';

/// Each puzzle type's signature glaze, used on its home tile and header.
extension PuzzleStyle on PuzzleKind {
  Color get accent => switch (this) {
    PuzzleKind.glaze => TesseraColors.celadon,
    PuzzleKind.kilnPath => TesseraColors.terracotta,
    PuzzleKind.pebbles => const Color(0xFF4A4A57),
    PuzzleKind.seams => TesseraColors.gold,
    PuzzleKind.cutouts => TesseraColors.cobalt,
    PuzzleKind.shards => const Color(0xFF7A4E6E),
  };
}
