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
  widgets/                Shared widgets (solved card, keystone clue previews)
packages/puzzle_core/     Pure Dart: rules, seeded generation, solvers. No Flutter.
  lib/src/daily.dart      PuzzleDay (date -> seed, weekly difficulty), DailyTray
  lib/src/glaze/          Glaze (sudoku family): generator, solver, board, hints
  lib/src/kiln_path/      Kiln Path (Hamiltonian path): backbite generator,
                          pruned DFS uniqueness solver, board, hints
```

The rule is that `puzzle_core` never imports Flutter or Flame, so every rule,
generator and solver is unit-testable and can run from a CLI (for the planned
nightly pre-generation job).

## Puzzle types

| Name | Rule family | Status |
| --- | --- | --- |
| Glaze | Sudoku family, 6x6 (gentle/steady) and 9x9 (tricky/fierce) | Playable |
| Kiln Path | Hamiltonian path with checkpoints, 5x5 to 7x7 | Playable |
| Pebbles | Star Battle style placement | Planned (M3) |
| Seams | Numberlink | Planned (M3) |
| Cutouts | Paper fold and punch | Planned (M3) |
| Shards | Polyomino tiling | Planned (M3) |

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
