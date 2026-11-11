import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:tessera/game/pebbles/pebbles_game.dart';

PebblesGame _newGame() => PebblesGame(
  board: PebblesBoard(const PebblesGenerator().generate(7, Difficulty.steady)),
  haptics: false,
);

void main() {
  final pebblesGame = FlameTester<PebblesGame>(
    _newGame,
    createGameWidget: (game) => GameWidget(
      game: game,
      overlayBuilderMap: {
        PebblesGame.solvedOverlay: (_, _) => const SizedBox(),
      },
    ),
  );

  pebblesGame.testGameWidget(
    'tapping a tile cycles pebble, dot, empty',
    verify: (game, tester) async {
      final tile = game.boardComponent.tileAt(0);
      Future<void> tap() async {
        await tester.tapAt(tile.absoluteCenter.toOffset());
        await tester.pump(const Duration(milliseconds: 300));
      }

      await tap();
      expect(game.board.markAt(0), PebbleMark.pebble);
      expect(game.pebbleCount.value, 1);
      await tap();
      expect(game.board.markAt(0), PebbleMark.dot);
      expect(game.pebbleCount.value, 0);
      await tap();
      expect(game.board.markAt(0), PebbleMark.empty);
    },
  );

  pebblesGame.testGameWidget(
    'touching pebbles are flagged',
    verify: (game, tester) async {
      final n = game.board.size;
      game
        ..tapTile(0)
        ..tapTile(n + 1);
      expect(game.conflicts, {0, n + 1});
    },
  );

  pebblesGame.testGameWidget(
    'solving fires the board and shows the solved overlay',
    verify: (game, tester) async {
      for (final cell in game.board.puzzle.solution) {
        game.tapTile(cell);
      }
      expect(game.solved.value, isTrue);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(game.overlays.isActive(PebblesGame.solvedOverlay), isTrue);

      game.restart();
      expect(game.solved.value, isFalse);
      expect(game.board.pebbles, isEmpty);
    },
  );

  pebblesGame.testGameWidget(
    'hints place pebbles',
    verify: (game, tester) async {
      game.useHint();
      expect(game.hintsUsed.value, 1);
      expect(game.pebbleCount.value, 1);
    },
  );
}
