import 'package:flutter/material.dart';

import '../juice/juice.dart';
import '../theme/tessera_colors.dart';
import '../theme/tessera_theme.dart';

/// A chunky glazed button that physically presses down: the face sinks onto
/// its fired lip, with a click and a light haptic.
class ClayButton extends StatefulWidget {
  const ClayButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = TesseraColors.shelfLight,
    this.depth = 5,
    this.radius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.tooltip,
    this.semanticLabel,
    this.sound = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final double depth;
  final double radius;
  final EdgeInsets padding;
  final String? tooltip;
  final String? semanticLabel;

  /// Whether pressing plays the button click (callers that play their own
  /// sound turn this off).
  final bool sound;

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
  bool _down = false;

  void _set(bool down) {
    if (widget.onPressed == null || _down == down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final base = enabled
        ? widget.color
        : Color.lerp(widget.color, TesseraColors.night, 0.5)!;
    final lip = Color.lerp(base, Colors.black, 0.42)!;
    final d = widget.depth;
    final sink = _down ? d * 0.75 : 0.0;
    final light = base.computeLuminance() > 0.4;
    final fg = light ? TesseraColors.ink : TesseraColors.chalk;

    Widget button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: enabled
          ? () {
              if (widget.sound) Juice.button();
              widget.onPressed!();
            }
          : null,
      child: Padding(
        padding: EdgeInsets.only(bottom: d),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          transform: Matrix4.translationValues(0, sink, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(base, Colors.white, 0.16)!, base],
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
            ),
            boxShadow: [
              BoxShadow(color: lip, offset: Offset(0, d - sink)),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                offset: Offset(0, d - sink + 3),
                blurRadius: 8,
              ),
            ],
          ),
          padding: widget.padding,
          child: DefaultTextStyle.merge(
            style: TextStyle(
              fontFamily: TesseraFonts.body,
              fontWeight: FontWeight.w800,
              color: fg,
              fontSize: 15,
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: fg, size: 20),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
    button = Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: Opacity(opacity: enabled ? 1 : 0.6, child: button),
    );
    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

/// A round [ClayButton] holding an icon, for the header.
class ClayIconButton extends StatelessWidget {
  const ClayIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color = TesseraColors.shelfLight,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      child: ClayButton(
        onPressed: onPressed,
        tooltip: tooltip,
        color: color,
        radius: 23,
        depth: 4,
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 22),
      ),
    );
  }
}

/// A labelled tool button for the bar under a board ("Hint", "Undo"...).
class ToolButton extends StatelessWidget {
  const ToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = TesseraColors.shelfLight,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  /// Small count shown on the corner (e.g. hints used).
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClayButton(
          onPressed: onPressed,
          color: color,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon), const SizedBox(width: 8), Text(label)],
          ),
        ),
        if (badge != null && badge! > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: TesseraColors.gold,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TesseraColors.night, width: 2),
              ),
              child: Text(
                '${badge!}',
                style: const TextStyle(
                  fontFamily: TesseraFonts.body,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: TesseraColors.ink,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
