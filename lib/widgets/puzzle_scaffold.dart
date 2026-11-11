import 'package:flutter/material.dart';

import '../theme/tessera_colors.dart';
import '../theme/tessera_theme.dart';
import 'clay_button.dart';
import 'studio_background.dart';

/// The frame every puzzle screen shares: the night studio, a header with
/// back and restart, the rule on a small card, the board, then a status
/// line, optional palette and the tool bar.
class PuzzleScaffold extends StatelessWidget {
  const PuzzleScaffold({
    super.key,
    required this.title,
    required this.rule,
    required this.board,
    required this.accent,
    this.onRestart,
    this.status,
    this.palette,
    this.tools = const [],
    this.header,
  });

  final String title;
  final String rule;
  final Widget board;

  /// The puzzle's glaze, used on the title medallion.
  final Color accent;
  final VoidCallback? onRestart;
  final Widget? status;
  final Widget? palette;
  final List<Widget> tools;

  /// Extra content between the rule and the board (the keystone legend).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TesseraColors.night,
      body: StudioBackground(
        glow: 0.55,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Row(
                  children: [
                    ClayIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.6),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: TesseraFonts.display,
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                                height: 1.1,
                                color: TesseraColors.chalk,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ClayIconButton(
                      icon: Icons.replay_rounded,
                      tooltip: 'Start over',
                      onPressed: onRestart,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 6, 28, 0),
                child: Text(
                  rule,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: TesseraFonts.body,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    height: 1.35,
                    color: TesseraColors.chalkSoft,
                  ),
                ),
              ),
              ?header,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _BoardEntrance(child: board),
                ),
              ),
              ?status,
              if (palette != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: palette,
                ),
              if (tools.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 10,
                    children: tools,
                  ),
                )
              else
                const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// A rounded "x / y" counter that sits under the board.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: TesseraColors.emberGlow),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: const TextStyle(
              fontFamily: TesseraFonts.body,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: TesseraColors.chalk,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// The board settles onto the shelf when the screen opens.
class _BoardEntrance extends StatelessWidget {
  const _BoardEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 40),
          child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
        ),
      ),
    );
  }
}
