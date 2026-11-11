/// Pure-Dart puzzle core for Tessera.
///
/// Owns rules, deterministic generation and solving for every puzzle type.
/// Must never import Flutter or Flame so it stays fully unit-testable and can
/// run in a CLI (for example the nightly pre-generation job).
library;

export 'src/cutouts/cutouts.dart';
export 'src/daily.dart';
export 'src/difficulty.dart';
export 'src/glaze/glaze.dart';
export 'src/keystone/keystone.dart';
export 'src/kiln_path/kiln_path.dart';
export 'src/pebbles/pebbles.dart';
export 'src/progress/progress.dart';
export 'src/puzzle_kind.dart';
export 'src/seams/seams.dart';
export 'src/shards/shards.dart';
export 'src/seeded_random.dart';
