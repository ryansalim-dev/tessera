/// Pure-Dart puzzle core for Tessera.
///
/// Owns rules, deterministic generation and solving for every puzzle type.
/// Must never import Flutter or Flame so it stays fully unit-testable and can
/// run in a CLI (for example the nightly pre-generation job).
library;

export 'src/daily.dart';
export 'src/difficulty.dart';
export 'src/glaze/glaze.dart';
export 'src/kiln_path/kiln_path.dart';
export 'src/puzzle_kind.dart';
export 'src/seeded_random.dart';
