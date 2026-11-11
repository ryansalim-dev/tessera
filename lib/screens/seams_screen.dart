import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../game/seams/seams_game.dart';
import '../theme/tessera_colors.dart';
import '../theme/puzzle_style.dart';
import '../widgets/clay_button.dart';
import '../widgets/puzzle_scaffold.dart';
import '../widgets/solved_card.dart';

/// Hosts a [SeamsGame] with its actions as Flutter widgets.
class SeamsScreen extends StatefulWidget {
  const SeamsScreen({
    super.key,
    required this.seed,
    required this.difficulty,
    this.title = 'Seams',
    this.onSolved,
  });

  final int seed;
  final Difficulty difficulty;
  final String title;

  /// Called once when the puzzle is solved, with the hints used.
  final ValueChanged<int>? onSolved;

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
    final total = _game.board.puzzle.pairCount;
    return PuzzleScaffold(
      title: widget.title,
      rule:
          'Join each pair of matching shards with a seam. '
          'Seams never cross, and together they fill the plate.',
      accent: PuzzleKind.seams.accent,
      onRestart: _game.restart,
      board: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: GameWidget<SeamsGame>(
            game: _game,
            overlayBuilderMap: {
              SeamsGame.solvedOverlay: (context, game) => SolvedCard(
                hintsUsed: game.hintsUsed.value,
                clue: SeamShapeClue(steps: game.board.puzzle.keystoneSeamShape),
              ),
            },
          ),
        ),
      ),
      status: ValueListenableBuilder<int>(
        valueListenable: _game.joined,
        builder: (context, joined, _) => StatusPill(
          icon: Icons.auto_awesome_rounded,
          text: '$joined / $total seams',
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
