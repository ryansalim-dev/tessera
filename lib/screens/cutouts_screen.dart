import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../game/cutouts/cutouts_game.dart';
import '../theme/tessera_colors.dart';
import '../theme/puzzle_style.dart';
import '../widgets/clay_button.dart';
import '../widgets/puzzle_scaffold.dart';
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
    return PuzzleScaffold(
      title: widget.title,
      rule:
          'The clay is folded along the glowing lines, then stamped '
          'through every layer. Which sheet do you get when you unfold it?',
      accent: PuzzleKind.cutouts.accent,
      onRestart: _game.restart,
      board: GameWidget<CutoutsGame>(
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
      status: ValueListenableBuilder<int>(
        valueListenable: _game.mistakes,
        builder: (context, m, _) => StatusPill(
          icon: m == 0 ? Icons.verified_rounded : Icons.heart_broken_rounded,
          text: m == 0 ? 'No cracks' : '$m crack${m == 1 ? '' : 's'}',
        ),
      ),
      tools: [
        ValueListenableBuilder<int>(
          valueListenable: _game.hintsUsed,
          builder: (context, used, _) => ToolButton(
            icon: Icons.lightbulb_rounded,
            label: 'Hint',
            badge: used,
            color: TesseraColors.terracotta,
            onPressed: _game.useHint,
          ),
        ),
      ],
    );
  }
}
