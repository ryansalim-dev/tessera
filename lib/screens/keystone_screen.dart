import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../game/keystone/keystone_game.dart';
import '../theme/tessera_colors.dart';

/// Hosts the day's [KeystoneGame], with a legend of which tray puzzle
/// revealed which tiles.
class KeystoneScreen extends StatefulWidget {
  const KeystoneScreen({
    super.key,
    required this.puzzle,
    required this.tray,
    required this.solved,
  });

  final KeystonePuzzle puzzle;

  /// The day's tray, in tray order (sets the rim colours).
  final List<PuzzleKind> tray;

  /// Tray puzzles solved so far.
  final Set<PuzzleKind> solved;

  @override
  State<KeystoneScreen> createState() => _KeystoneScreenState();
}

class _KeystoneScreenState extends State<KeystoneScreen> {
  late final Map<PuzzleKind, Color> _rims = {
    for (final (i, k) in widget.tray.indexed) k: TesseraColors.glazes[i],
  };

  late final KeystoneGame _game = KeystoneGame(
    board: KeystoneBoard(widget.puzzle, widget.puzzle.givensFor(widget.solved)),
    rims: _rims,
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final lent = _game.board.givens.lent.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keystone'),
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
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Every row and column holds each glaze once. '
                'Rimmed tiles came from your solves.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: TesseraColors.inkSoft),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final kind in widget.tray)
                  _ClueChip(
                    label: kind.title,
                    color: _rims[kind]!,
                    collected: widget.solved.contains(kind),
                  ),
              ],
            ),
            if (lent > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  '$lent tile${lent == 1 ? '' : 's'} lent (dashed rims). '
                  'Collect every clue for the gold glaze.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: TesseraColors.inkSoft),
                ),
              ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GameWidget<KeystoneGame>(
                    game: _game,
                    overlayBuilderMap: {
                      KeystoneGame.solvedOverlay: (context, game) =>
                          _KeystoneSetCard(
                            gold:
                                game.board.givens.fullClues &&
                                game.hintsUsed.value == 0,
                          ),
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  for (var v = 1; v <= KeystonePuzzle.size; v++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Material(
                            color: TesseraColors.glaze(v),
                            borderRadius: BorderRadius.circular(10),
                            elevation: 1,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => _game.placeGlaze(v),
                              child: Center(
                                child: Text(
                                  '$v',
                                  semanticsLabel: 'Glaze $v',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: TesseraColors.onGlaze(v),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
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

class _ClueChip extends StatelessWidget {
  const _ClueChip({
    required this.label,
    required this.color,
    required this.collected,
  });

  final String label;
  final Color color;
  final bool collected;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        collected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: color,
        size: 18,
      ),
      label: Text(label),
      side: BorderSide(color: color, width: 2),
      backgroundColor: TesseraColors.clayLight,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _KeystoneSetCard extends StatelessWidget {
  const _KeystoneSetCard({required this.gold});

  final bool gold;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                color: gold ? TesseraColors.gold : TesseraColors.celadon,
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                'Keystone set',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                gold
                    ? 'Every clue, no hints. Gold glaze earned.'
                    : "Today's tile is fired.",
                style: text.bodyMedium?.copyWith(color: TesseraColors.inkSoft),
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
