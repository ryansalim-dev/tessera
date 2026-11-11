import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:tessera/game/keystone/keystone_game.dart';
import 'package:tessera/theme/tessera_colors.dart';

final _day = PuzzleDay(2026, 11, 11);

KeystoneGame _newGame({Set<PuzzleKind> solved = const {}}) {
  final puzzle = const KeystoneBuilder().forDay(_day);
  return KeystoneGame(
    board: KeystoneBoard(puzzle, puzzle.givensFor(solved)),
    rims: {
      for (final (i, k) in DailyTray.forDay(_day).kinds.indexed)
        k: TesseraColors.glazes[i],
    },
    haptics: false,
  );
}

void main() {
  final keystone = FlameTester<KeystoneGame>(
    _newGame,
    createGameWidget: (game) => GameWidget(
      game: game,
      overlayBuilderMap: {
        KeystoneGame.solvedOverlay: (_, _) => const SizedBox(),
      },
    ),
  );

  keystone.testGameWidget(
    'tapping a tile and a glaze fills it; givens stay put',
    verify: (game, tester) async {
      final b = game.board;
      final empty = b.cells.indexOf(0);
      await tester.tapAt(game.tiles[empty].absoluteCenter.toOffset());
      await tester.pump(const Duration(milliseconds: 300));
      expect(game.selected.value, empty);
      game.placeGlaze(3);
      expect(b.valueAt(empty), 3);
      game.erase();
      expect(b.valueAt(empty), 0);

      final given = b.givens.grid.indexWhere((v) => v != 0);
      game
        ..selectTile(given)
        ..placeGlaze(1);
      expect(b.valueAt(given), b.givens.grid[given]);
    },
  );

  keystone.testGameWidget(
    'solving assembles the mosaic and shows the overlay',
    verify: (game, tester) async {
      final s = game.board.puzzle.solution;
      for (var i = 0; i < s.length; i++) {
        if (!game.board.isGiven(i)) {
          game
            ..selectTile(i)
            ..placeGlaze(s[i]);
        }
      }
      expect(game.solved.value, isTrue);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(game.overlays.isActive(KeystoneGame.solvedOverlay), isTrue);
    },
  );
}
