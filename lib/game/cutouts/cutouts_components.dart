import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../../theme/tessera_colors.dart';
import '../common/effects.dart';
import 'cutouts_game.dart';

final _clay = Paint()..color = TesseraColors.clayLight;
final _ghost = Paint()..color = TesseraColors.grout.withValues(alpha: 0.5);
final _edge = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.5
  ..color = TesseraColors.groutDark;
final _grid = Paint()
  ..strokeWidth = 0.75
  ..color = TesseraColors.grout;
final _hole = Paint()..color = TesseraColors.ink;
final _stamp = Paint()..color = TesseraColors.cobalt;
final _fold = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2
  ..strokeCap = StrokeCap.round
  ..color = TesseraColors.terracotta;

/// One frame of the folding story: the sheet before fold [index] (with the
/// fold line and an arrow), or, for the last frame, the folded sheet with
/// its stamps.
class SheetStageComponent extends PositionComponent
    with HasGameReference<CutoutsGame> {
  SheetStageComponent(this.index);

  final int index;

  @override
  void render(Canvas canvas) {
    final p = game.board.puzzle;
    final sheet = p.stages[index];
    final n = p.size;
    final cell = size.x / n;
    Rect cellRect(int x, int y) =>
        Rect.fromLTWH(x * cell, y * cell, cell, cell);

    // The full sheet, faint, so the folded part reads as folded.
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(4)),
      _ghost,
    );
    final visible = Rect.fromLTRB(
      sheet.x0 * cell,
      sheet.y0 * cell,
      sheet.x1 * cell,
      sheet.y1 * cell,
    );
    canvas.drawRect(visible, _clay);
    for (var x = sheet.x0 + 1; x < sheet.x1; x++) {
      canvas.drawLine(
        Offset(x * cell, visible.top),
        Offset(x * cell, visible.bottom),
        _grid,
      );
    }
    for (var y = sheet.y0 + 1; y < sheet.y1; y++) {
      canvas.drawLine(
        Offset(visible.left, y * cell),
        Offset(visible.right, y * cell),
        _grid,
      );
    }
    canvas.drawRect(visible, _edge);

    final isLast = index == p.folds.length;
    if (isLast) {
      for (final s in p.stamps) {
        final r = cellRect(s % n, s ~/ n);
        canvas.drawCircle(r.center, cell * 0.3, _stamp);
      }
      return;
    }

    // Fold line and arrow from the moving half to the staying half.
    final f = p.folds[index];
    final c = visible.center;
    final Offset from, to;
    if (f.isVertical) {
      canvas.drawLine(
        Offset(c.dx, visible.top - 4),
        Offset(c.dx, visible.bottom + 4),
        _fold,
      );
      final dx = visible.width / 4;
      final sign = f == Fold.leftOverRight ? 1 : -1;
      from = Offset(c.dx - sign * dx, c.dy);
      to = Offset(c.dx + sign * dx, c.dy);
    } else {
      canvas.drawLine(
        Offset(visible.left - 4, c.dy),
        Offset(visible.right + 4, c.dy),
        _fold,
      );
      final dy = visible.height / 4;
      final sign = f == Fold.topOverBottom ? 1 : -1;
      from = Offset(c.dx, c.dy - sign * dy);
      to = Offset(c.dx, c.dy + sign * dy);
    }
    _arrow(canvas, from, to, f.isVertical);
  }

  void _arrow(Canvas canvas, Offset from, Offset to, bool vertical) {
    final lift = (to - from).distance * 0.6;
    final mid = Offset.lerp(from, to, 0.5)!;
    final control = vertical
        ? Offset(mid.dx, mid.dy - lift)
        : Offset(mid.dx - lift, mid.dy);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
    canvas.drawPath(path, _fold);
    // Arrow head pointing along the curve's end tangent.
    final dir = to - control;
    final unit = dir / dir.distance;
    final side = Offset(-unit.dy, unit.dx);
    final head = 6.0;
    canvas.drawLine(to, to - unit * head + side * head * 0.6, _fold);
    canvas.drawLine(to, to - unit * head - side * head * 0.6, _fold);
  }
}

/// One unfolded candidate. Tap to pick it.
class OptionComponent extends PositionComponent
    with TapCallbacks, HasGameReference<CutoutsGame> {
  OptionComponent(this.index) : super(anchor: Anchor.center);

  final int index;

  void press() => add(pressEffect());

  @override
  void onTapDown(TapDownEvent event) => game.pick(index);

  static final _card = Paint()..color = TesseraColors.grout;
  static final _shadow = Paint()
    ..color = TesseraColors.ink.withValues(alpha: 0.12)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  static final _ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  static final _crack = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..color = TesseraColors.terracotta;

  @override
  void render(Canvas canvas) {
    final board = game.board;
    final p = board.puzzle;
    final out = board.ruledOut.contains(index);
    final picked = board.picked == index;
    final card = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(12),
    );
    canvas.drawRRect(card.shift(const Offset(0, 3)), _shadow);
    canvas.drawRRect(card, _card);

    const pad = 8.0;
    final n = p.size;
    final cell = (size.x - 2 * pad) / n;
    final sheet = Rect.fromLTWH(pad, pad, n * cell, n * cell);
    canvas.drawRect(sheet, _clay);
    for (var k = 1; k < n; k++) {
      canvas.drawLine(
        Offset(pad + k * cell, sheet.top),
        Offset(pad + k * cell, sheet.bottom),
        _grid,
      );
      canvas.drawLine(
        Offset(sheet.left, pad + k * cell),
        Offset(sheet.right, pad + k * cell),
        _grid,
      );
    }
    for (final h in p.options[index]) {
      canvas.drawCircle(
        Offset(pad + (h % n + 0.5) * cell, pad + (h ~/ n + 0.5) * cell),
        cell * 0.3,
        _hole,
      );
    }

    if (out) {
      // Faded and cracked: ruled out.
      canvas.drawRRect(
        card,
        Paint()..color = TesseraColors.clay.withValues(alpha: 0.6),
      );
      final path = Path()
        ..moveTo(size.x * 0.2, size.y * 0.15)
        ..lineTo(size.x * 0.45, size.y * 0.45)
        ..lineTo(size.x * 0.38, size.y * 0.55)
        ..lineTo(size.x * 0.8, size.y * 0.85);
      canvas.drawPath(path, _crack);
    }
    if (picked) {
      _ring.color = TesseraColors.gold;
      canvas.drawRRect(card.inflate(2), _ring);
    }
  }

  /// "Kiln firing" on the right answer, under 600 ms.
  void fire({void Function()? onComplete}) {
    add(
      ScaleEffect.to(
        Vector2.all(1.06),
        EffectController(duration: 0.15, reverseDuration: 0.2),
      ),
    );
    add(TimerComponent(period: 0.5, removeOnFinish: true, onTick: onComplete));
  }
}
