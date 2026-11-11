import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../game/pebbles/pebbles_game.dart';
import '../theme/tessera_colors.dart';
import '../theme/puzzle_style.dart';
import '../widgets/clay_button.dart';
import '../widgets/puzzle_scaffold.dart';
import '../widgets/solved_card.dart';

/// Hosts a [PebblesGame] with its actions as Flutter widgets.
class PebblesScreen extends StatefulWidget {
  const PebblesScreen({
    super.key,
    required this.seed,
    required this.difficulty,
    this.title = 'Pebbles',
    this.onSolved,
  });

  final int seed;
  final Difficulty difficulty;
  final String title;

  /// Called once when the puzzle is solved, with the hints used.
  final ValueChanged<int>? onSolved;

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
    final total = _game.board.size;
    return PuzzleScaffold(
      title: widget.title,
      rule:
          'One pebble in every row, column and region. '
          'Pebbles never touch, not even at the corners.',
      accent: PuzzleKind.pebbles.accent,
      onRestart: _game.restart,
      board: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: GameWidget<PebblesGame>(
            game: _game,
            overlayBuilderMap: {
              PebblesGame.solvedOverlay: (context, game) => SolvedCard(
                hintsUsed: game.hintsUsed.value,
                clue: ShadedGridClue(
                  shaded: game.board.puzzle.keystoneNoEntry(),
                  color: TesseraColors.chalk,
                ),
              ),
            },
          ),
        ),
      ),
      status: ValueListenableBuilder<int>(
        valueListenable: _game.pebbleCount,
        builder: (context, count, _) =>
            StatusPill(icon: Icons.circle, text: '$count / $total pebbles'),
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
