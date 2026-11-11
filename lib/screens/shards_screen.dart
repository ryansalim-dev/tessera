import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../game/shards/shards_game.dart';
import '../theme/tessera_colors.dart';
import '../theme/puzzle_style.dart';
import '../widgets/clay_button.dart';
import '../widgets/puzzle_scaffold.dart';
import '../widgets/solved_card.dart';

/// Hosts a [ShardsGame] with its actions as Flutter widgets.
class ShardsScreen extends StatefulWidget {
  const ShardsScreen({
    super.key,
    required this.seed,
    required this.difficulty,
    this.title = 'Shards',
    this.onSolved,
  });

  final int seed;
  final Difficulty difficulty;
  final String title;

  /// Called once when the puzzle is solved, with the hints used.
  final ValueChanged<int>? onSolved;

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
    final total = _game.board.shardCount;
    return PuzzleScaffold(
      title: widget.title,
      rule:
          'Drag every shard onto the plate to rebuild it. '
          'Tap a shard to turn it.',
      accent: PuzzleKind.shards.accent,
      onRestart: _game.restart,
      board: GameWidget<ShardsGame>(
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
      status: ValueListenableBuilder<int>(
        valueListenable: _game.placed,
        builder: (context, placed, _) => StatusPill(
          icon: Icons.extension_rounded,
          text: '$placed / $total shards',
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
