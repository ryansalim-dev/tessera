import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../game/kiln_path/kiln_path_game.dart';
import '../theme/tessera_colors.dart';
import '../widgets/solved_card.dart';

/// Hosts a [KilnPathGame] with its actions as Flutter widgets.
class KilnPathScreen extends StatefulWidget {
  const KilnPathScreen({
    super.key,
    required this.seed,
    required this.difficulty,
    this.title = 'Kiln Path',
    this.onSolved,
  });

  final int seed;
  final Difficulty difficulty;
  final String title;

  /// Called once when the puzzle is solved, with the hints used.
  final ValueChanged<int>? onSolved;

  @override
  State<KilnPathScreen> createState() => _KilnPathScreenState();
}

class _KilnPathScreenState extends State<KilnPathScreen> {
  late final KilnPathGame _game = KilnPathGame(
    board: KilnPathBoard(
      const KilnPathGenerator().generate(widget.seed, widget.difficulty),
    ),
  );

  @override
  void initState() {
    super.initState();
    _game.solved.addListener(_onSolvedChanged);
  }

  void _onSolvedChanged() {
    if (_game.solved.value) {
      widget.onSolved?.call(_game.hintsUsed.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = _game.board.puzzle.cellCount;
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
                'Drag one line from 1 through every tile, '
                'passing the numbers in order.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: TesseraColors.inkSoft),
              ),
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GameWidget<KilnPathGame>(
                    game: _game,
                    overlayBuilderMap: {
                      KilnPathGame.solvedOverlay: (context, game) => SolvedCard(
                        hintsUsed: game.hintsUsed.value,
                        clue: ShadedGridClue(
                          shaded: game.board.puzzle.keystoneShading(),
                        ),
                      ),
                    },
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: _game.lineLength,
              builder: (context, length, _) => Text(
                '$length / $total tiles',
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
                  TextButton.icon(
                    onPressed: _game.undo,
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo'),
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
