import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../game/kiln_path/kiln_path_game.dart';
import '../theme/tessera_colors.dart';
import '../theme/puzzle_style.dart';
import '../widgets/clay_button.dart';
import '../widgets/puzzle_scaffold.dart';
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
    final total = _game.board.puzzle.cellCount;
    return PuzzleScaffold(
      title: widget.title,
      rule:
          'Drag one line from 1 through every tile, '
          'passing the numbers in order.',
      accent: PuzzleKind.kilnPath.accent,
      onRestart: _game.restart,
      board: Center(
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
      status: ValueListenableBuilder<int>(
        valueListenable: _game.lineLength,
        builder: (context, length, _) => StatusPill(
          icon: Icons.local_fire_department_rounded,
          text: '$length / $total tiles',
        ),
      ),
      tools: [
        ToolButton(
          icon: Icons.undo_rounded,
          label: 'Undo',
          onPressed: _game.undo,
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
