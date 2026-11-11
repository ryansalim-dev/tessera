import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight, FontFeature;

import '../../theme/tessera_colors.dart';
import '../../theme/tessera_theme.dart';
import 'kiln_path_board_component.dart';
import 'kiln_path_game.dart';

/// The firing line and the checkpoints: a thick terracotta stroke through
/// the centres of the cells on the line, numbered studs on top of it, and a
/// glowing ember at the head.
class KilnPathLineComponent extends PositionComponent
    with HasGameReference<KilnPathGame>, ParentIsA<KilnPathBoardComponent> {
  static final _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = TesseraColors.terracotta;
  static final _fill = Paint();
  static final _lineGlow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = TesseraColors.ember.withValues(alpha: 0.45)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final _ring = Paint()
    ..style = PaintingStyle.stroke
    ..color = TesseraColors.gold;
  static final _glow = Paint()
    ..color = TesseraColors.gold.withValues(alpha: 0.4)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  @override
  void render(Canvas canvas) {
    final board = game.board;
    final tile = parent.tileSize;
    if (tile <= 0) return;

    final path = board.path;
    if (path.length > 1) {
      _line.strokeWidth = tile * 0.26;
      final p = Path();
      for (var i = 0; i < path.length; i++) {
        final c = parent.centreOf(path[i]);
        i == 0 ? p.moveTo(c.x, c.y) : p.lineTo(c.x, c.y);
      }
      _lineGlow.strokeWidth = tile * 0.42;
      canvas.drawPath(p, _lineGlow);
      _line
        ..color = TesseraColors.terracotta
        ..strokeWidth = tile * 0.26;
      canvas.drawPath(p, _line);
      _line
        ..color = TesseraColors.emberGlow
        ..strokeWidth = tile * 0.08;
      canvas.drawPath(p.shift(Offset(0, -tile * 0.04)), _line);
    }

    if (!game.solved.value) {
      final head = parent.centreOf(board.head).toOffset();
      canvas.drawCircle(head, tile * 0.3, _glow);
    }

    final next = board.nextCheckpoint;
    final r = tile * 0.3;
    final text = TextPaint(
      style: TextStyle(
        fontFamily: TesseraFonts.body,
        fontSize: r * 1.05,
        fontWeight: FontWeight.w800,
        color: TesseraColors.clayLight,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    for (var cell = 0; cell < board.puzzle.cellCount; cell++) {
      final cp = board.checkpointAt(cell);
      if (cp == 0) continue;
      final c = parent.centreOf(cell);
      _fill.color = board.contains(cell)
          ? TesseraColors.cobalt
          : TesseraColors.ink;
      canvas.drawCircle(c.toOffset(), r, _fill);
      if (cp == next && !game.solved.value) {
        _ring.strokeWidth = 3;
        canvas.drawCircle(c.toOffset(), r + 3, _ring);
      }
      text.render(canvas, '$cp', c, anchor: Anchor.center);
    }

    if (!game.solved.value && board.checkpointAt(board.head) == 0) {
      _fill.color = TesseraColors.gold;
      canvas.drawCircle(
        parent.centreOf(board.head).toOffset(),
        tile * 0.1,
        _fill,
      );
    }
  }
}
