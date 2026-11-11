import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../game/glaze/glaze_game.dart';
import '../theme/tessera_colors.dart';
import '../widgets/clay_button.dart';
import '../widgets/glaze_palette.dart';
import '../widgets/puzzle_scaffold.dart';
import '../widgets/solved_card.dart';

/// Hosts a [GlazeGame] with the glaze palette and actions as Flutter widgets.
class GlazeScreen extends StatefulWidget {
  const GlazeScreen({
    super.key,
    required this.seed,
    required this.difficulty,
    this.title = 'Glaze',
    this.onSolved,
  });

  final int seed;
  final Difficulty difficulty;
  final String title;

  /// Called once when the puzzle is solved, with the hints used.
  final ValueChanged<int>? onSolved;

  @override
  State<GlazeScreen> createState() => _GlazeScreenState();
}

class _GlazeScreenState extends State<GlazeScreen> {
  late final GlazeGame _game = GlazeGame(
    board: GlazeBoard(
      const GlazeGenerator().generate(widget.seed, widget.difficulty),
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
    final size = _game.board.size;
    return PuzzleScaffold(
      title: widget.title,
      rule: 'Fill every row, column and box with each glaze once.',
      accent: TesseraColors.celadon,
      onRestart: _game.restart,
      board: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: GameWidget<GlazeGame>(
            game: _game,
            overlayBuilderMap: {
              GlazeGame.solvedOverlay: (context, game) => SolvedCard(
                hintsUsed: game.hintsUsed.value,
                clue: GlazeDigitsClue(
                  digits: game.board.puzzle.keystoneDiagonal,
                ),
              ),
            },
          ),
        ),
      ),
      palette: GlazePalette(count: size, onPick: _game.placeGlaze),
      tools: [
        ToolButton(
          icon: Icons.backspace_rounded,
          label: 'Erase',
          onPressed: _game.erase,
        ),
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
