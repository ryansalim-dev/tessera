import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:tessera/game/cutouts/cutouts_game.dart';

CutoutsGame _newGame() => CutoutsGame(
  board: CutoutsBoard(const CutoutsGenerator().generate(7, Difficulty.tricky)),
  haptics: false,
);

void main() {
  final cutoutsGame = FlameTester<CutoutsGame>(
    _newGame,
    createGameWidget: (game) => GameWidget(
      game: game,
      overlayBuilderMap: {
        CutoutsGame.solvedOverlay: (_, _) => const SizedBox(),
      },
    ),
  );

  cutoutsGame.testGameWidget(
    'shows every fold stage and four options inside the game',
    verify: (game, tester) async {
      expect(game.stages, hasLength(game.board.puzzle.folds.length + 1));
      expect(game.options, hasLength(4));
      for (final o in game.options) {
        expect(o.position.y + o.size.y / 2, lessThanOrEqualTo(game.size.y));
        expect(o.size.x, greaterThan(0));
      }
    },
  );

  cutoutsGame.testGameWidget(
    'tapping a wrong option cracks it, the right one solves',
    verify: (game, tester) async {
      final answer = game.board.puzzle.answer;
      final wrong = (answer + 1) % 4;
      await tester.tapAt(game.options[wrong].absoluteCenter.toOffset());
      await tester.pump(const Duration(milliseconds: 300));
      expect(game.board.ruledOut, {wrong});
      expect(game.mistakes.value, 1);
      expect(game.solved.value, isFalse);

      await tester.tapAt(game.options[answer].absoluteCenter.toOffset());
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(game.solved.value, isTrue);
      expect(game.overlays.isActive(CutoutsGame.solvedOverlay), isTrue);

      game.restart();
      expect(game.solved.value, isFalse);
      expect(game.board.ruledOut, isEmpty);
    },
  );

  cutoutsGame.testGameWidget(
    'hints rule out wrong options',
    verify: (game, tester) async {
      final h = game.useHint();
      expect(h, isNot(game.board.puzzle.answer));
      expect(game.board.ruledOut, {h});
      expect(game.hintsUsed.value, 1);
    },
  );
}
