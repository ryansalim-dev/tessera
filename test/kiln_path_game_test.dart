import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:tessera/game/kiln_path/kiln_path_game.dart';

KilnPathGame _newGame() => KilnPathGame(
  board: KilnPathBoard(
    const KilnPathGenerator().generate(7, Difficulty.gentle),
  ),
  haptics: false,
);

void main() {
  final kilnGame = FlameTester<KilnPathGame>(
    _newGame,
    createGameWidget: (game) => GameWidget(
      game: game,
      overlayBuilderMap: {
        KilnPathGame.solvedOverlay: (_, _) => const SizedBox(),
      },
    ),
  );

  kilnGame.testGameWidget(
    'lays out one tile per cell and maps points back to cells',
    verify: (game, tester) async {
      final board = game.boardComponent;
      final cells = game.board.puzzle.cellCount;
      for (var i = 0; i < cells; i++) {
        expect(board.cellAt(board.tileAt(i).position), i);
      }
      final last = board.tileAt(cells - 1);
      expect(
        last.position.x + last.size.x / 2,
        lessThanOrEqualTo(board.size.x),
      );
    },
  );

  kilnGame.testGameWidget(
    'dragging along the solution draws the line',
    verify: (game, tester) async {
      final s = game.board.puzzle.solution;
      final board = game.boardComponent;
      Offset at(int cell) => board.tileAt(cell).absoluteCenter.toOffset();

      final gesture = await tester.startGesture(at(s[0]));
      await tester.pump();
      for (var i = 1; i <= 4; i++) {
        await gesture.moveTo(at(s[i]));
        await tester.pump();
      }
      expect(game.board.path, s.take(5));
      expect(game.lineLength.value, 5);

      // Dragging back over the line cuts it.
      await gesture.moveTo(at(s[2]));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 500));
      expect(game.board.path, s.take(3));
    },
  );

  kilnGame.testGameWidget(
    'a tap in a straight line from the head walks there',
    verify: (game, tester) async {
      final p = game.board.puzzle;
      final s = p.solution;
      // Find the first straight run of 3+ steps in the solution.
      var i = 0;
      while (i + 2 < s.length &&
          !((p.row(s[i]) == p.row(s[i + 2])) ||
              (p.col(s[i]) == p.col(s[i + 2])))) {
        i++;
      }
      for (var k = 1; k <= i; k++) {
        game.moveTo(s[k]);
      }
      expect(game.board.length, i + 1);
      expect(game.moveTo(s[i + 2]), isTrue);
      expect(game.board.path, s.take(i + 3));
    },
  );

  kilnGame.testGameWidget(
    'solving fires the board and shows the solved overlay',
    verify: (game, tester) async {
      final s = game.board.puzzle.solution;
      for (var i = 1; i < s.length; i++) {
        expect(game.moveTo(s[i]), isTrue, reason: 'step $i');
      }
      expect(game.solved.value, isTrue);
      expect(game.moveTo(s[1]), isFalse, reason: 'locked once solved');
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(game.overlays.isActive(KilnPathGame.solvedOverlay), isTrue);

      game.restart();
      expect(game.solved.value, isFalse);
      expect(game.board.path, [s.first]);
    },
  );

  kilnGame.testGameWidget(
    'hints and undo',
    verify: (game, tester) async {
      final s = game.board.puzzle.solution;
      game.useHint();
      game.useHint();
      expect(game.hintsUsed.value, 2);
      expect(game.board.path, s.take(3));
      expect(game.undo(), isTrue);
      expect(game.board.path, s.take(2));
    },
  );
}
