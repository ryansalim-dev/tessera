import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tessera_colors.dart';

/// The night studio behind every screen: a deep clay wall lit by the kiln
/// from below, with fixed speckles and slow-drifting embers.
class StudioBackground extends StatefulWidget {
  const StudioBackground({super.key, required this.child, this.glow = 1});

  final Widget child;

  /// How strongly the kiln glows (0 to 1). Puzzle screens dim it a little so
  /// the board stays the brightest thing on screen.
  final double glow;

  @override
  State<StudioBackground> createState() => _StudioBackgroundState();
}

class _StudioBackgroundState extends State<StudioBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(child: CustomPaint(painter: _WallPainter(widget.glow))),
        RepaintBoundary(
          child: IgnorePointer(
            child: CustomPaint(painter: _EmberPainter(_drift, widget.glow)),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _WallPainter extends CustomPainter {
  _WallPainter(this.glow);

  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF140D0B), TesseraColors.night, Color(0xFF2A1812)],
        ).createShader(rect),
    );
    // Kiln glow rising from the bottom.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 1.25),
          radius: 1.1,
          colors: [
            TesseraColors.ember.withValues(alpha: 0.42 * glow),
            TesseraColors.terracotta.withValues(alpha: 0.12 * glow),
            Colors.transparent,
          ],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );
    // A cool window light from the top left.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-1.1, -1.1),
          radius: 1.2,
          colors: [
            TesseraColors.cobalt.withValues(alpha: 0.22),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
    // Clay speckle.
    final rnd = math.Random(11);
    final dot = Paint();
    final count = (size.width * size.height / 900).clamp(0, 1600).toInt();
    for (var i = 0; i < count; i++) {
      dot.color = (i.isEven ? Colors.white : Colors.black).withValues(
        alpha: 0.025 + rnd.nextDouble() * 0.04,
      );
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.5 + rnd.nextDouble() * 1.4,
        dot,
      );
    }
    // Vignette.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.0,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
          stops: const [0.6, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_WallPainter old) => old.glow != glow;
}

class _EmberPainter extends CustomPainter {
  _EmberPainter(this.t, this.glow) : super(repaint: t);

  final Animation<double> t;
  final double glow;
  static final _embers = List.generate(22, (i) {
    final r = math.Random(i * 31 + 5);
    return (
      r.nextDouble(),
      r.nextDouble(),
      0.6 + r.nextDouble() * 1.8,
      0.4 + r.nextDouble() * 0.9,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (glow <= 0) return;
    final p = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (final (x0, phase, r, speed) in _embers) {
      final life = (t.value * speed + phase) % 1.0;
      final y = size.height * (1.05 - life * 0.75);
      final x = size.width * x0 + math.sin((life + phase) * math.pi * 4) * 14;
      final a = math.sin(life * math.pi) * 0.7 * glow;
      p.color = TesseraColors.emberGlow.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), r, p);
    }
  }

  @override
  bool shouldRepaint(_EmberPainter old) => false;
}
