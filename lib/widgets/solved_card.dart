import 'package:flutter/material.dart';

import '../theme/tessera_colors.dart';

/// The "Fired!" card shown over a solved board, with the keystone clue the
/// puzzle reveals.
class SolvedCard extends StatelessWidget {
  const SolvedCard({super.key, required this.hintsUsed, required this.clue});

  final int hintsUsed;

  /// The keystone clue this puzzle reveals.
  final Widget clue;

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
              Text(
                'Fired!',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hintsUsed == 0
                    ? 'No hints. Gold glaze earned.'
                    : 'Solved with $hintsUsed hint${hintsUsed == 1 ? '' : 's'}.',
                style: text.bodyMedium?.copyWith(color: TesseraColors.inkSoft),
              ),
              const SizedBox(height: 16),
              Text('Keystone clue', style: text.labelLarge),
              const SizedBox(height: 6),
              clue,
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
                          : TesseraColors.clayLight,
                      border: Border.all(color: TesseraColors.grout),
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
    final dot = Paint()..color = TesseraColors.ink;
    canvas.drawCircle(at(points.first), cell * 0.2, dot);
    canvas.drawCircle(at(points.last), cell * 0.2, dot);
  }

  @override
  bool shouldRepaint(_SeamShapePainter old) => old.steps != steps;
}
