import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../theme/tessera_colors.dart';

/// A small painted vignette of each puzzle type for its home tile, drawn on
/// top of the type's glaze.
class PuzzleArt extends StatelessWidget {
  const PuzzleArt({super.key, required this.kind});

  final PuzzleKind kind;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ArtPainter(kind), size: Size.infinite);
}

class _ArtPainter extends CustomPainter {
  _ArtPainter(this.kind);

  final PuzzleKind kind;

  static const _cream = Color(0xFFFFF6EA);
  static const _shadow = Color(0x55000000);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    switch (kind) {
      case PuzzleKind.glaze:
        _glaze(canvas, s);
      case PuzzleKind.kilnPath:
        _kilnPath(canvas, s);
      case PuzzleKind.pebbles:
        _pebbles(canvas, s);
      case PuzzleKind.seams:
        _seams(canvas, s);
      case PuzzleKind.cutouts:
        _cutouts(canvas, s);
      case PuzzleKind.shards:
        _shards(canvas, s);
    }
    canvas.restore();
  }

  void _tile(Canvas canvas, Rect r, Color c, {double radius = 0.2}) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(r.width * radius));
    canvas.drawRRect(
      rr.shift(Offset(0, r.width * 0.1)),
      Paint()..color = Color.lerp(c, Colors.black, 0.4)!,
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(c, Colors.white, 0.2)!, c],
        ).createShader(r),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          r.left + r.width * 0.12,
          r.top + r.height * 0.1,
          r.width * 0.45,
          r.height * 0.14,
        ),
        Radius.circular(r.width * 0.1),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  void _glaze(Canvas canvas, double s) {
    final g = TesseraColors.glazes;
    final colours = [
      g[1],
      _cream,
      g[2],
      _cream,
      g[3],
      g[4],
      g[0],
      g[5],
      _cream,
    ];
    final t = s * 0.24, gap = s * 0.05;
    final o = (s - 3 * t - 2 * gap) / 2;
    for (var i = 0; i < 9; i++) {
      _tile(
        canvas,
        Rect.fromLTWH(
          o + (i % 3) * (t + gap),
          o + (i ~/ 3) * (t + gap) - s * 0.02,
          t,
          t,
        ),
        colours[i],
      );
    }
  }

  void _kilnPath(Canvas canvas, double s) {
    final pts = [
      Offset(s * 0.2, s * 0.25),
      Offset(s * 0.8, s * 0.25),
      Offset(s * 0.8, s * 0.5),
      Offset(s * 0.2, s * 0.5),
      Offset(s * 0.2, s * 0.75),
      Offset(s * 0.75, s * 0.75),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.13
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _shadow,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _cream,
    );
    for (final (i, p) in [(0, pts[0]), (1, pts[2]), (2, pts[5])]) {
      canvas.drawCircle(p, s * 0.09, Paint()..color = TesseraColors.ink);
      _label(canvas, '${i + 1}', p, s * 0.11, _cream);
    }
    canvas.drawCircle(
      pts[5],
      s * 0.16,
      Paint()
        ..color = TesseraColors.emberGlow.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _pebbles(Canvas canvas, double s) {
    final cell = s * 0.2;
    final o = (s - 4 * cell) / 2;
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.35);
    for (var k = 0; k <= 4; k++) {
      canvas.drawLine(
        Offset(o + k * cell, o),
        Offset(o + k * cell, o + 4 * cell),
        grid,
      );
      canvas.drawLine(
        Offset(o, o + k * cell),
        Offset(o + 4 * cell, o + k * cell),
        grid,
      );
    }
    for (final (c, r) in [(1, 0), (3, 1), (0, 2), (2, 3)]) {
      final centre = Offset(o + (c + 0.5) * cell, o + (r + 0.5) * cell);
      final stone = Rect.fromCenter(
        center: centre,
        width: cell * 0.72,
        height: cell * 0.58,
      );
      canvas.drawOval(
        stone.shift(Offset(0, cell * 0.08)),
        Paint()..color = _shadow,
      );
      canvas.drawOval(stone, Paint()..color = _cream);
      canvas.drawOval(
        Rect.fromLTWH(
          stone.left + stone.width * 0.18,
          stone.top + stone.height * 0.15,
          stone.width * 0.35,
          stone.height * 0.25,
        ),
        Paint()..color = Colors.white,
      );
    }
  }

  void _seams(Canvas canvas, double s) {
    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFFFE1A0);
    final a = Path()
      ..moveTo(s * 0.22, s * 0.25)
      ..lineTo(s * 0.22, s * 0.72)
      ..lineTo(s * 0.5, s * 0.72);
    final b = Path()
      ..moveTo(s * 0.45, s * 0.28)
      ..lineTo(s * 0.78, s * 0.28)
      ..lineTo(s * 0.78, s * 0.75);
    for (final p in [a, b]) {
      canvas.drawPath(p.shift(Offset(0, s * 0.03)), gold..color = _shadow);
      canvas.drawPath(p, gold..color = const Color(0xFFFFE1A0));
    }
    final t = s * 0.2;
    for (final (o, c) in [
      (Offset(s * 0.22, s * 0.25), TesseraColors.cobalt),
      (Offset(s * 0.5, s * 0.72), TesseraColors.cobalt),
      (Offset(s * 0.45, s * 0.28), TesseraColors.terracotta),
      (Offset(s * 0.78, s * 0.75), TesseraColors.terracotta),
    ]) {
      canvas.save();
      canvas.translate(o.dx, o.dy);
      canvas.rotate(0.25);
      _tile(
        canvas,
        Rect.fromCenter(center: Offset.zero, width: t, height: t),
        c,
      );
      canvas.restore();
    }
  }

  void _cutouts(Canvas canvas, double s) {
    final sheet = Rect.fromLTWH(s * 0.18, s * 0.2, s * 0.64, s * 0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        sheet.shift(Offset(0, s * 0.04)),
        const Radius.circular(4),
      ),
      Paint()..color = _shadow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sheet, const Radius.circular(4)),
      Paint()..color = _cream,
    );
    // The folded flap.
    final flap = Path()
      ..moveTo(sheet.center.dx, sheet.top)
      ..lineTo(sheet.right, sheet.top)
      ..lineTo(sheet.right - s * 0.06, sheet.bottom - s * 0.04)
      ..lineTo(sheet.center.dx, sheet.bottom)
      ..close();
    canvas.drawPath(flap, Paint()..color = const Color(0xFFE6D6BF));
    canvas.drawLine(
      Offset(sheet.center.dx, sheet.top - s * 0.04),
      Offset(sheet.center.dx, sheet.bottom + s * 0.04),
      Paint()
        ..strokeWidth = 2.5
        ..color = TesseraColors.ember,
    );
    for (final p in [
      Offset(s * 0.32, s * 0.36),
      Offset(s * 0.68, s * 0.36),
      Offset(s * 0.4, s * 0.62),
      Offset(s * 0.6, s * 0.62),
    ]) {
      canvas.drawCircle(p, s * 0.055, Paint()..color = TesseraColors.ink);
    }
  }

  void _shards(Canvas canvas, double s) {
    final c = s * 0.2;
    void piece(List<(int, int)> cells, Offset o, Color colour, double turn) {
      canvas.save();
      canvas.translate(o.dx, o.dy);
      canvas.rotate(turn);
      for (final (x, y) in cells) {
        _tile(
          canvas,
          Rect.fromLTWH(x * c, y * c, c - 1.5, c - 1.5),
          colour,
          radius: 0.12,
        );
      }
      canvas.restore();
    }

    piece(
      [(0, 0), (0, 1), (0, 2), (1, 2)],
      Offset(s * 0.1, s * 0.12),
      TesseraColors.gold,
      -0.12,
    );
    piece(
      [(0, 0), (1, 0), (2, 0), (1, 1)],
      Offset(s * 0.42, s * 0.14),
      _cream,
      0.1,
    );
    piece(
      [(0, 0), (1, 0), (1, 1)],
      Offset(s * 0.48, s * 0.52),
      TesseraColors.celadon,
      -0.05,
    );
  }

  void _label(Canvas canvas, String text, Offset c, double size, Color colour) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: size,
          color: colour,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_ArtPainter old) => old.kind != kind;
}
