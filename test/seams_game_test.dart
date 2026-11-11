import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:tessera/game/seams/seams_game.dart';

SeamsGame _newGame() => SeamsGame(
  board: SeamsBoard(const SeamsGenerator().generate(7, Difficulty.gentle)),
  haptics: false,
);

void main() {
  final seamsGame = FlameTester<SeamsGame>(
    _newGame,
    createGameWidget: (game) => GameWidget(
      game: game,
      overlayBuilderMap: {SeamsGame.solvedOverlay: (_, _) => const SizedBox()},
    ),
  );

  seamsGame.testGameWidget(
    'maps points back to cells',
    verify: (game, tester) async {
      final board = game.boardComponent;
      for (var i = 0; i < game.board.puzzle.cellCount; i++) {
        expect(board.cellAt(board.tileAt(i).position), i);
      }
    },
  );

  seamsGame.testGameWidget(
    'dragging from a shard to its partner joins the seam',
    verify: (game, tester) async {
      final seam = game.board.puzzle.seams.first;
      final board = game.boardComponent;
      Offset at(int cell) => board.tileAt(cell).absoluteCenter.toOffset();

      final gesture = await tester.startGesture(at(seam.first));
      await tester.pump();
      for (final cell in seam.skip(1)) {
        await gesture.moveTo(at(cell));
        await tester.pump();
      }
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 500));
      expect(game.board.seam(1), seam);
      expect(game.board.isJoined(1), isTrue);
      expect(game.joined.value, 1);
      expect(game.board.active, isNull);
    },
  );

  seamsGame.testGameWidget(
    'solving fires the plate and shows the solved overlay',
    verify: (game, tester) async {
      final p = game.board.puzzle;
      for (final seam in p.seams) {
        expect(game.begin(seam.first), isTrue);
        for (final cell in seam.skip(1)) {
          game.extend(cell);
        }
        game.end();
      }
      expect(game.solved.value, isTrue);
      expect(game.joined.value, p.pairCount);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(game.overlays.isActive(SeamsGame.solvedOverlay), isTrue);

      game.restart();
      expect(game.solved.value, isFalse);
      expect(game.joined.value, 0);
    },
  );

  seamsGame.testGameWidget(
    'hints lay whole seams',
    verify: (game, tester) async {
      game.useHint();
      expect(game.hintsUsed.value, 1);
      expect(game.joined.value, 1);
    },
  );
}
