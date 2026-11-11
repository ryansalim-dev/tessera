# Tessera

A daily logic-puzzle studio. Every puzzle you solve is fired into a glazed tile,
and each day's tiles lock together into one final **keystone** puzzle built from
your own answers.

Built with Flutter + [Flame](https://flame-engine.org). iOS and Android.

## Layout

```
lib/                      Flutter app shell + Flame game layer
  app.dart                MaterialApp, theme
  theme/                  Studio palette (clay, terracotta, celadon, cobalt, gold)
  screens/                Today's tray, one screen per puzzle (Flutter widgets)
  game/glaze/             GlazeGame (FlameGame), board and tile components
  game/kiln_path/         KilnPathGame: drag-to-draw firing line, tiles, line overlay
  game/pebbles/           PebblesGame: tap-to-cycle tiles, region borders
  game/seams/             SeamsGame: drag seams between shards, kintsugi lines
  game/cutouts/           CutoutsGame: folding story strip and four tappable options
  game/shards/            ShardsGame: plate, draggable and turnable shards, tray
  game/keystone/          KeystoneGame: 5x5 keystone, rims show which solve revealed a tile
  widgets/                Shared widgets (solved card, keystone clue previews)
packages/puzzle_core/     Pure Dart: rules, seeded generation, solvers. No Flutter.
  lib/src/daily.dart      PuzzleDay (date -> seed, weekly difficulty), DailyTray
  lib/src/glaze/          Glaze (sudoku family): generator, solver, board, hints
  lib/src/kiln_path/      Kiln Path (Hamiltonian path): backbite generator,
                          pruned DFS uniqueness solver, board, hints
  lib/src/pebbles/        Pebbles (Star Battle): grown regions, reshaped until
                          the answer is unique; row-by-row solver, board, hints
  lib/src/seams/          Seams (Numberlink): a Hamiltonian line cut into seams,
                          kept only when the pruned solver finds one answer
  lib/src/cutouts/        Cutouts (fold and punch): FoldedSheet layer model,
                          distractors from real mistakes, board, hints
  lib/src/shards/         Shards (polyomino tiling): chipped plate broken into
                          shards from its most hemmed-in tiles, board, hints
  lib/src/keystone/       Keystone: 5x5 Latin square whose givens come from the
                          day's solves; lends tiles for an early start
```

The rule is that `puzzle_core` never imports Flutter or Flame, so every rule,
generator and solver is unit-testable and can run from a CLI (for the planned
nightly pre-generation job).

## Puzzle types

| Name | Rule family | Status |
| --- | --- | --- |
| Glaze | Sudoku family, 6x6 (gentle/steady) and 9x9 (tricky/fierce) | Playable |
| Kiln Path | Hamiltonian path with checkpoints, 5x5 to 7x7 | Playable |
| Pebbles | Star Battle style placement, one per row/column/region, 5x5 to 8x8 | Playable |
| Seams | Numberlink, full coverage, 5x5 to 7x7 | Playable |
| Cutouts | Fold and punch, pick the unfolded sheet from four | Playable |
| Shards | Polyomino tiling: drag and turn shards to rebuild the plate | Playable |

## The keystone

Every puzzle exposes a 5x5 clue picture taken from its own answer: the Glaze
diagonal, Kiln Path's bends, Pebbles' positions, the longest seam's shape, the
Cutouts stamp pattern and the biggest shard. The keystone is a 5x5 grid where
every row and column holds each glaze once, and each solved tray puzzle reveals
two or three keystone tiles inside its picture. With all four clues the answer
is unique (base givens are added only when it would not be). Starting early is
allowed: `KeystonePuzzle.givensFor` lends extra tiles until the answer is
unique, and only a full-clue, hint-free solve earns the gold glaze.

Solved puzzles are remembered for the session only; persistence is M2.

## Daily puzzles

Every player gets the same set: `PuzzleDay` hashes `tessera:yyyy-mm-dd` (and the
puzzle type) with FNV-1a into a seed, and generation uses its own xorshift PRNG
rather than `dart:math`'s `Random`, whose sequence isn't guaranteed stable across
SDKs. Both are pinned by tests, because changing them changes everyone's daily set.
Difficulty ramps from gentle on Monday to fierce on Sunday.

## Running

```sh
flutter pub get
flutter run                       # iOS simulator or Android emulator
flutter test                      # app + Flame component tests
cd packages/puzzle_core && dart test   # core rules and generators
```
