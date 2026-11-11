import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../game/seams/seams_game.dart';
import '../theme/tessera_colors.dart';
import '../widgets/solved_card.dart';

/// Hosts a [SeamsGame] with its actions as Flutter widgets.
class SeamsScreen extends StatefulWidget {
  const SeamsScreen({
    super.key,
    required this.seed,
    required this.difficulty,
    this.title = 'Seams',
  });

  final int seed;
  final Difficulty difficulty;
  final String title;

  @override
  State<SeamsScreen> createState() => _SeamsScreenState();
}

class _SeamsScreenState extends State<SeamsScreen> {
  late final SeamsGame _game = SeamsGame(
    board: SeamsBoard(
      const SeamsGenerator().generate(widget.seed, widget.difficulty),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = _game.board.puzzle.pairCount;
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
                'Join each pair of matching shards with a seam. '
                'Seams never cross, and together they fill the plate.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: TesseraColors.inkSoft),
              ),
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GameWidget<SeamsGame>(
                    game: _game,
                    overlayBuilderMap: {
                      SeamsGame.solvedOverlay: (context, game) => SolvedCard(
                        hintsUsed: game.hintsUsed.value,
                        clue: SeamShapeClue(
                          steps: game.board.puzzle.keystoneSeamShape,
                        ),
                      ),
                    },
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: _game.joined,
              builder: (context, joined, _) => Text(
                '$joined / $total seams',
                style: text.titleSmall?.copyWith(
                  color: TesseraColors.inkSoft,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
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
