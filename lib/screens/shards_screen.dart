import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../game/shards/shards_game.dart';
import '../theme/tessera_colors.dart';
import '../widgets/solved_card.dart';

/// Hosts a [ShardsGame] with its actions as Flutter widgets.
class ShardsScreen extends StatefulWidget {
  const ShardsScreen({
    super.key,
    required this.seed,
    required this.difficulty,
    this.title = 'Shards',
  });

  final int seed;
  final Difficulty difficulty;
  final String title;

  @override
  State<ShardsScreen> createState() => _ShardsScreenState();
}

class _ShardsScreenState extends State<ShardsScreen> {
  late final ShardsGame _game = ShardsGame(
    board: ShardsBoard(
      const ShardsGenerator().generate(widget.seed, widget.difficulty),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = _game.board.shardCount;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Start over',
            icon: const Icon(Icons.refresh),
            onPressed: _game.restart,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text(
                'Drag every shard onto the plate to rebuild it. '
                'Tap a shard to turn it.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: TesseraColors.inkSoft),
              ),
            ),
            Expanded(
              child: GameWidget<ShardsGame>(
                game: _game,
                overlayBuilderMap: {
                  ShardsGame.solvedOverlay: (context, game) => SolvedCard(
                    hintsUsed: game.hintsUsed.value,
                    clue: ShadedGridClue(
                      shaded: game.board.puzzle.keystoneShard(),
                      color: TesseraColors.gold,
                    ),
                  ),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: _game.placed,
                    builder: (context, placed, _) => Text(
                      '$placed / $total shards',
                      style: text.titleSmall?.copyWith(
                        color: TesseraColors.inkSoft,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: _game.hintsUsed,
                    builder: (context, used, _) => TextButton.icon(
                      onPressed: _game.useHint,
                      icon: const Icon(Icons.lightbulb_outline),
                      label: Text(used == 0 ? 'Hint' : 'Hint ($used)'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
