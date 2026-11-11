import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../game/glaze/glaze_game.dart';
import '../theme/tessera_colors.dart';

/// Hosts a [GlazeGame] with the glaze palette and actions as Flutter widgets.
class GlazeScreen extends StatefulWidget {
  const GlazeScreen({
    super.key,
    required this.seed,
    required this.difficulty,
    this.title = 'Glaze',
  });

  final int seed;
  final Difficulty difficulty;
  final String title;

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
  Widget build(BuildContext context) {
    final size = _game.board.size;
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
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GameWidget<GlazeGame>(
                    game: _game,
                    overlayBuilderMap: {
                      GlazeGame.solvedOverlay: (context, game) =>
                          _SolvedCard(game: game),
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  for (var v = 1; v <= size; v++)
                    Expanded(
                      child: _GlazeButton(value: v, game: _game),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: _game.erase,
                    icon: const Icon(Icons.backspace_outlined),
                    label: const Text('Erase'),
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

class _GlazeButton extends StatelessWidget {
  const _GlazeButton({required this.value, required this.game});

  final int value;
  final GlazeGame game;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: AspectRatio(
        aspectRatio: 0.85,
        child: Material(
          color: TesseraColors.glaze(value),
          borderRadius: BorderRadius.circular(10),
          elevation: 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => game.placeGlaze(value),
            child: Center(
              child: Text(
                '$value',
                semanticsLabel: 'Glaze $value',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: TesseraColors.onGlaze(value),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SolvedCard extends StatelessWidget {
  const _SolvedCard({required this.game});

  final GlazeGame game;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final clue = game.board.puzzle.keystoneDiagonal;
    final hints = game.hintsUsed.value;
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fired!',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hints == 0
                    ? 'No hints. Gold glaze earned.'
                    : 'Solved with $hints hint${hints == 1 ? '' : 's'}.',
                style: text.bodyMedium?.copyWith(color: TesseraColors.inkSoft),
              ),
              const SizedBox(height: 16),
              Text('Keystone clue', style: text.labelLarge),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final v in clue)
                    Container(
                      margin: const EdgeInsets.all(2),
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: TesseraColors.glaze(v),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$v',
                        style: TextStyle(
                          color: TesseraColors.onGlaze(v),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Back to tray'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
