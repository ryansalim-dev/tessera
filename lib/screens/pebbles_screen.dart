import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../game/pebbles/pebbles_game.dart';
import '../theme/tessera_colors.dart';
import '../widgets/solved_card.dart';

/// Hosts a [PebblesGame] with its actions as Flutter widgets.
class PebblesScreen extends StatefulWidget {
  const PebblesScreen({
    super.key,
    required this.seed,
    required this.difficulty,
    this.title = 'Pebbles',
  });

  final int seed;
  final Difficulty difficulty;
  final String title;

  @override
  State<PebblesScreen> createState() => _PebblesScreenState();
}

class _PebblesScreenState extends State<PebblesScreen> {
  late final PebblesGame _game = PebblesGame(
    board: PebblesBoard(
      const PebblesGenerator().generate(widget.seed, widget.difficulty),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = _game.board.size;
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
                'One pebble in every row, column and region. '
                'Pebbles never touch, not even at the corners.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: TesseraColors.inkSoft),
              ),
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GameWidget<PebblesGame>(
                    game: _game,
                    overlayBuilderMap: {
                      PebblesGame.solvedOverlay: (context, game) => SolvedCard(
                        hintsUsed: game.hintsUsed.value,
                        clue: ShadedGridClue(
                          shaded: game.board.puzzle.keystoneNoEntry(),
                          color: TesseraColors.ink,
                        ),
                      ),
                    },
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: _game.pebbleCount,
              builder: (context, count, _) => Text(
                '$count / $total pebbles',
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
