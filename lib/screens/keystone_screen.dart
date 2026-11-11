import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../game/keystone/keystone_game.dart';
import '../theme/tessera_colors.dart';
import '../theme/tessera_theme.dart';
import '../widgets/clay_button.dart';
import '../widgets/glaze_palette.dart';
import '../widgets/puzzle_scaffold.dart';
import '../widgets/solved_card.dart';

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
    final lent = _game.board.givens.lent.length;
    return PuzzleScaffold(
      title: 'Keystone',
      rule:
          'Every row and column holds each glaze once. '
          'Rimmed tiles came from your solves.',
      accent: TesseraColors.gold,
      onRestart: _game.restart,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(
          children: [
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
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '$lent tile${lent == 1 ? '' : 's'} lent (dashed rims). '
                  'Collect every clue for the gold glaze.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: TesseraFonts.body,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: TesseraColors.chalkSoft,
                  ),
                ),
              ),
          ],
        ),
      ),
      board: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: GameWidget<KeystoneGame>(
            game: _game,
            overlayBuilderMap: {
              KeystoneGame.solvedOverlay: (context, game) {
                final gold =
                    game.board.givens.fullClues && game.hintsUsed.value == 0;
                return CelebrationCard(
                  title: 'Keystone set',
                  gold: gold,
                  subtitle: gold
                      ? 'Every clue, no hints. Gold glaze earned.'
                      : "Today's tile is fired.",
                );
              },
            },
          ),
        ),
      ),
      palette: GlazePalette(
        count: KeystonePuzzle.size,
        onPick: _game.placeGlaze,
      ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
      decoration: BoxDecoration(
        color: collected
            ? color.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            collected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: TesseraFonts.body,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: TesseraColors.chalk,
            ),
          ),
        ],
      ),
    );
  }
}
