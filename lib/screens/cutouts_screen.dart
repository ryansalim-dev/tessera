import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../game/cutouts/cutouts_game.dart';
import '../theme/tessera_colors.dart';
import '../widgets/solved_card.dart';

/// Hosts a [CutoutsGame] with its actions as Flutter widgets.
class CutoutsScreen extends StatefulWidget {
  const CutoutsScreen({
    super.key,
    required this.seed,
    required this.difficulty,
    this.title = 'Cutouts',
    this.onSolved,
  });

  final int seed;
  final Difficulty difficulty;
  final String title;

  /// Called once when the puzzle is solved, with the hints used.
  final ValueChanged<int>? onSolved;

  @override
  State<CutoutsScreen> createState() => _CutoutsScreenState();
}

class _CutoutsScreenState extends State<CutoutsScreen> {
  late final CutoutsGame _game = CutoutsGame(
    board: CutoutsBoard(
      const CutoutsGenerator().generate(widget.seed, widget.difficulty),
    ),
  );

  @override
  void initState() {
    super.initState();
    _game.solved.addListener(_onSolvedChanged);
  }

  void _onSolvedChanged() {
    if (_game.solved.value) {
      widget.onSolved?.call(_game.hintsUsed.value + _game.mistakes.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
                'The clay is folded along the red lines, then stamped '
                'through every layer. Which sheet do you get when you '
                'unfold it?',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: TesseraColors.inkSoft),
              ),
            ),
            Expanded(
              child: GameWidget<CutoutsGame>(
                game: _game,
                overlayBuilderMap: {
                  CutoutsGame.solvedOverlay: (context, game) => SolvedCard(
                    hintsUsed: game.hintsUsed.value + game.mistakes.value,
                    clue: ShadedGridClue(
                      shaded: game.board.puzzle.keystoneStamp(),
                      color: TesseraColors.cobalt,
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
                    valueListenable: _game.mistakes,
                    builder: (context, m, _) => Text(
                      m == 0 ? 'No cracks' : '$m crack${m == 1 ? '' : 's'}',
                      style: text.titleSmall?.copyWith(
                        color: TesseraColors.inkSoft,
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
