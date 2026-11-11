import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tessera_colors.dart';
import '../theme/tessera_theme.dart';
import 'clay_button.dart';

/// The "Fired!" card shown over a solved board, with the keystone clue the
/// puzzle reveals.
class SolvedCard extends StatelessWidget {
  const SolvedCard({super.key, required this.hintsUsed, required this.clue});

  final int hintsUsed;

  /// The keystone clue this puzzle reveals.
  final Widget clue;

  @override
  Widget build(BuildContext context) {
    return CelebrationCard(
      title: 'Fired!',
      gold: hintsUsed == 0,
      subtitle: hintsUsed == 0
          ? 'No hints. Gold glaze earned.'
          : 'Solved with $hintsUsed hint${hintsUsed == 1 ? '' : 's'}.',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'KEYSTONE CLUE',
            style: TextStyle(
              fontFamily: TesseraFonts.body,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.6,
              color: TesseraColors.chalkSoft,
            ),
          ),
          const SizedBox(height: 8),
          clue,
        ],
      ),
    );
  }
}

/// A celebration card: a stamped medallion with light rays, a title, and
/// glaze confetti raining behind it. Scales to fit the board it covers.
class CelebrationCard extends StatefulWidget {
  const CelebrationCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.gold,
    this.footer,
    this.buttonLabel = 'Back to tray',
  });

  final String title;
  final String subtitle;
  final bool gold;
  final Widget? footer;
  final String buttonLabel;

  @override
  State<CelebrationCard> createState() => _CelebrationCardState();
}

class _CelebrationCardState extends State<CelebrationCard>
    with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..forward();

  @override
  void dispose() {
    _in.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medal = widget.gold ? TesseraColors.gold : TesseraColors.celadon;
    final card = CurvedAnimation(
      parent: _in,
      curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
    );
    final stamp = CurvedAnimation(
      parent: _in,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOutBack),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: CurvedAnimation(parent: _in, curve: const Interval(0, 0.3)),
          child: const ColoredBox(color: Color(0x99100A08)),
        ),
        IgnorePointer(child: CustomPaint(painter: _ConfettiPainter(_loop))),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ScaleTransition(
                scale: card,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [TesseraColors.shelfLight, TesseraColors.shelf],
                    ),
                    border: Border.all(
                      color: medal.withValues(alpha: 0.7),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: medal.withValues(alpha: 0.35),
                        blurRadius: 30,
                      ),
                      const BoxShadow(
                        color: Color(0xAA000000),
                        offset: Offset(0, 10),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _loop,
                              builder: (context, _) => Transform.rotate(
                                angle: _loop.value * math.pi / 2,
                                child: CustomPaint(
                                  size: const Size(96, 96),
                                  painter: _RaysPainter(medal),
                                ),
                              ),
                            ),
                            ScaleTransition(
                              scale: Tween(begin: 2.2, end: 1.0).animate(stamp),
                              child: FadeTransition(
                                opacity: stamp.drive(
                                  Tween(begin: 0.0, end: 1.0),
                                ),
                                child: _Medallion(color: medal),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontFamily: TesseraFonts.display,
                          fontWeight: FontWeight.w800,
                          fontSize: 34,
                          height: 1.1,
                          color: TesseraColors.chalk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: TesseraFonts.body,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: TesseraColors.chalkSoft,
                        ),
                      ),
                      if (widget.footer != null) ...[
                        const SizedBox(height: 14),
                        widget.footer!,
                      ],
                      const SizedBox(height: 16),
                      ClayButton(
                        color: TesseraColors.ember,
                        onPressed: () => Navigator.of(context).maybePop(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 12,
                        ),
                        child: Text(widget.buttonLabel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Medallion extends StatelessWidget {
  const _Medallion({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            Color.lerp(color, Colors.white, 0.45)!,
            color,
            Color.lerp(color, Colors.black, 0.3)!,
          ],
          stops: const [0, 0.55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(color, Colors.black, 0.5)!,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.local_fire_department_rounded,
        size: 36,
        color: Color(0xFFFFF8EC),
        shadows: [Shadow(color: Color(0x55000000), offset: Offset(0, 2))],
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.7), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - 0.12) * r, c.dy + math.sin(a - 0.12) * r)
        ..lineTo(c.dx + math.cos(a + 0.12) * r, c.dy + math.sin(a + 0.12) * r)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.color != color;
}

/// Glaze chips raining down once over the card.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t) : super(repaint: t);

  final Animation<double> t;
  static final _bits = List.generate(46, (i) {
    final r = math.Random(i * 7 + 3);
    return (
      r.nextDouble(),
      r.nextDouble() * 0.35,
      0.6 + r.nextDouble() * 0.6,
      TesseraColors.glazes[i % TesseraColors.glazes.length],
      (r.nextDouble() - 0.5) * 12,
      4.0 + r.nextDouble() * 5,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final (x, delay, speed, colour, spin, s) in _bits) {
      final life = ((t.value - delay) / 0.65 * speed).clamp(0.0, 1.0);
      if (life <= 0 || life >= 1) continue;
      final y = -20 + life * (size.height + 40);
      final dx = math.sin(life * 9 + spin) * 18;
      p.color = colour.withValues(alpha: life < 0.85 ? 1 : (1 - life) / 0.15);
      canvas.save();
      canvas.translate(x * size.width + dx, y);
      canvas.rotate(life * spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: s * 1.6, height: s),
          const Radius.circular(1.5),
        ),
        p,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}

/// A row of glazed digits, the clue Glaze reveals.
class GlazeDigitsClue extends StatelessWidget {
  const GlazeDigitsClue({super.key, required this.digits});

  final List<int> digits;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final v in digits)
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
    );
  }
}

/// A small square grid with some cells shaded, the clue shape Kiln Path (and
/// later Pebbles) reveals to the keystone.
class ShadedGridClue extends StatelessWidget {
  const ShadedGridClue({
    super.key,
    required this.shaded,
    this.color = TesseraColors.terracotta,
  });

  /// Row-major mask over a square window.
  final List<bool> shaded;
  final Color color;

  @override
  Widget build(BuildContext context) {
    var n = 1;
    while (n * n < shaded.length) {
      n++;
    }
    final count = shaded.where((s) => s).length;
    return Semantics(
      label: '$count of ${shaded.length} keystone tiles shaded',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < n; r++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var c = 0; c < n; c++)
                  Container(
                    margin: const EdgeInsets.all(1.5),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: shaded[r * n + c]
                          ? color
                          : TesseraColors.shelfDark,
                      border: Border.all(
                        color: shaded[r * n + c]
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The shape of a seam, drawn as a gold line, the clue Seams reveals.
class SeamShapeClue extends StatelessWidget {
  const SeamShapeClue({super.key, required this.steps});

  /// Step directions: 0 up, 1 right, 2 down, 3 left.
  final List<int> steps;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'A seam shape of ${steps.length + 1} tiles',
      child: CustomPaint(
        size: const Size(120, 120),
        painter: _SeamShapePainter(steps),
      ),
    );
  }
}

class _SeamShapePainter extends CustomPainter {
  _SeamShapePainter(this.steps);

  final List<int> steps;

  @override
  void paint(Canvas canvas, Size size) {
    var x = 0, y = 0, minX = 0, maxX = 0, minY = 0, maxY = 0;
    final points = <(int, int)>[(0, 0)];
    for (final s in steps) {
      switch (s) {
        case 0:
          y--;
        case 1:
          x++;
        case 2:
          y++;
        default:
          x--;
      }
      points.add((x, y));
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
    final span = [maxX - minX, maxY - minY, 1].reduce((a, b) => a > b ? a : b);
    final cell = size.width / (span + 1);
    final ox = (size.width - (maxX - minX) * cell) / 2;
    final oy = (size.height - (maxY - minY) * cell) / 2;
    Offset at((int, int) p) =>
        Offset(ox + (p.$1 - minX) * cell, oy + (p.$2 - minY) * cell);
    final path = Path()..moveTo(at(points.first).dx, at(points.first).dy);
    for (final p in points.skip(1)) {
      path.lineTo(at(p).dx, at(p).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = TesseraColors.gold,
    );
    final dot = Paint()..color = TesseraColors.chalk;
    canvas.drawCircle(at(points.first), cell * 0.2, dot);
    canvas.drawCircle(at(points.last), cell * 0.2, dot);
  }

  @override
  bool shouldRepaint(_SeamShapePainter old) => old.steps != steps;
}
