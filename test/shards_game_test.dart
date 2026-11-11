import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:tessera/game/shards/shards_game.dart';

ShardsGame _newGame() => ShardsGame(
  board: ShardsBoard(const ShardsGenerator().generate(7, Difficulty.gentle)),
  haptics: false,
);

void main() {
  final shardsGame = FlameTester<ShardsGame>(
    _newGame,
    createGameWidget: (game) => GameWidget(
      game: game,
      overlayBuilderMap: {ShardsGame.solvedOverlay: (_, _) => const SizedBox()},
    ),
  );

  shardsGame.testGameWidget(
    'shards start in the tray below the plate',
    verify: (game, tester) async {
      final plateBottom = game.plate.position.y + game.plate.size.y;
      for (final s in game.shards) {
        expect(game.board.isPlaced(s.index), isFalse);
        expect(s.position.y, greaterThan(plateBottom));
        expect(s.scale.x, closeTo(game.trayScale, 1e-6));
        expect(
          s.position.y + s.size.y * s.scale.y,
          lessThanOrEqualTo(game.size.y),
        );
      }
    },
  );

  shardsGame.testGameWidget(
    'dragging a turned shard onto its spot sets it',
    verify: (game, tester) async {
      final p = game.board.puzzle;
      final shard = game.shards.first;
      final target = p.solution[0];
      // Tap to turn it into the solution's orientation first.
      for (var t = 0; t < target.turns % 4; t++) {
        await tester.tapAt(shard.absoluteCenter.toOffset());
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(game.board.turnsOf(0), target.turns % 4);

      // Grab the shard's first tile and drop it on the matching plate tile.
      final (r0, c0) = shard.shape.cells.first;
      final grab = shard.absolutePositionOf(
        Vector2((c0 + 0.5) * game.cell, (r0 + 0.5) * game.cell),
      );
      final dropAt =
          game.cellTopLeft(target.row + r0, target.col + c0) +
          Vector2.all(game.cell / 2);
      final gesture = await tester.startGesture(grab.toOffset());
      await tester.pump();
      // Move past the drag slop first, then to the spot.
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump();
      await gesture.moveTo(dropAt.toOffset());
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300));

      expect(game.board.placementOf(0), target);
      expect(game.placed.value, 1);
      expect(shard.scale.x, 1);
    },
  );

  shardsGame.testGameWidget(
    'a drop off the plate goes back to the tray',
    verify: (game, tester) async {
      expect(game.drop(0, Vector2(-500, -500)), isFalse);
      expect(game.board.isPlaced(0), isFalse);
    },
  );

  shardsGame.testGameWidget(
    'hints rebuild the plate and fire it',
    verify: (game, tester) async {
      while (!game.solved.value) {
        game.useHint();
      }
      expect(game.placed.value, game.board.shardCount);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(game.overlays.isActive(ShardsGame.solvedOverlay), isTrue);
      game.restart();
      expect(game.placed.value, 0);
    },
  );
}
