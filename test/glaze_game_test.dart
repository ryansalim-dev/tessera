import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:tessera/game/glaze/glaze_game.dart';

GlazeGame _newGame() => GlazeGame(
  board: GlazeBoard(const GlazeGenerator().generate(7, Difficulty.gentle)),
  haptics: false,
);

void main() {
  final glazeGame = FlameTester<GlazeGame>(
    _newGame,
    createGameWidget: (game) => GameWidget(
      game: game,
      overlayBuilderMap: {GlazeGame.solvedOverlay: (_, _) => const SizedBox()},
    ),
  );

  glazeGame.testGameWidget(
    'lays out one tile per cell inside the board',
    verify: (game, tester) async {
      final board = game.boardComponent;
      expect(board.children.length, game.board.size * game.board.size);
      final last = board.tileAt(game.board.size * game.board.size - 1);
      expect(
        last.position.x + last.size.x / 2,
        lessThanOrEqualTo(board.size.x),
      );
    },
  );

  glazeGame.testGameWidget(
    'tapping a tile selects it and the palette fills it',
    verify: (game, tester) async {
      final index = game.board.puzzle.givens.indexOf(0);
      final tile = game.boardComponent.tileAt(index);
      await tester.tapAt(tile.absoluteCenter.toOffset());
      await tester.pump(const Duration(milliseconds: 500));
      expect(game.selected.value, index);

      game.placeGlaze(2);
      expect(game.board.valueAt(index), 2);
      game.erase();
      expect(game.board.valueAt(index), 0);
    },
  );

  glazeGame.testGameWidget(
    'solving fires the board and shows the solved overlay',
    verify: (game, tester) async {
      final p = game.board.puzzle;
      for (var i = 0; i < p.layout.cellCount; i++) {
        if (!game.board.isGiven(i)) {
          game.selectTile(i);
          game.placeGlaze(p.solution[i]);
        }
      }
      expect(game.solved.value, isTrue);
      // Let the firing cascade play out (under 600 ms).
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(game.overlays.isActive(GlazeGame.solvedOverlay), isTrue);

      game.restart();
      expect(game.solved.value, isFalse);
      expect(game.board.cells, p.givens);
    },
  );
}
