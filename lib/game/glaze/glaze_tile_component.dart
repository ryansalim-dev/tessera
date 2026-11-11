import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight, FontFeature;

import '../../theme/tessera_colors.dart';
import 'glaze_game.dart';

/// One ceramic tile. Reads its state from the game each frame.
class GlazeTileComponent extends PositionComponent
    with TapCallbacks, HasGameReference<GlazeGame> {
  GlazeTileComponent(this.index) : super(anchor: Anchor.center);

  final int index;

  void press() => add(pressEffect());

  @override
  void onTapDown(TapDownEvent event) => game.selectTile(index);

  static final _fill = Paint();
  static final _stroke = Paint()..style = PaintingStyle.stroke;
  static final _shine = Paint()..color = const Color(0x33FFFFFF);

  bool _isPeerOfSelection() {
    final s = game.selected.value;
    if (s == null || s == index) return false;
    final p = game.board.puzzle;
    return p.row(s) == p.row(index) ||
        p.col(s) == p.col(index) ||
        p.box(s) == p.box(index);
  }

  @override
  void render(Canvas canvas) {
    final board = game.board;
    final value = board.valueAt(index);
    final given = board.isGiven(index);
    final selected = game.selected.value == index;
    final conflict = game.conflicts.contains(index);
    final radius = Radius.circular(size.x * 0.16);
    final rect = RRect.fromRectAndRadius(size.toRect(), radius);

    _fill.color = value == 0
        ? (_isPeerOfSelection()
              ? const Color(0xFFF1E7D8)
              : TesseraColors.clayLight)
        : TesseraColors.glaze(value);
    canvas.drawRRect(rect, _fill);

    if (value != 0) {
      // Glaze highlight along the top edge.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.x * 0.1,
            size.y * 0.08,
            size.x * 0.8,
            size.y * 0.22,
          ),
          radius,
        ),
        _shine,
      );
      final text = TextPaint(
        style: TextStyle(
          fontSize: size.y * 0.5,
          fontWeight: given ? FontWeight.w800 : FontWeight.w500,
          color: TesseraColors.onGlaze(value),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
      text.render(canvas, '$value', size / 2, anchor: Anchor.center);
    }

    if (given) {
      // Fired tiles get an inset rim so they read as fixed.
      _stroke
        ..color = TesseraColors.ink.withValues(alpha: 0.25)
        ..strokeWidth = 1.5;
      canvas.drawRRect(rect.deflate(3), _stroke);
    }
    if (conflict) {
      _stroke
        ..color = TesseraColors.terracotta
        ..strokeWidth = 3;
      canvas.drawRRect(rect.deflate(1.5), _stroke);
      canvas.drawCircle(
        Offset(size.x * 0.82, size.y * 0.18),
        size.x * 0.07,
        _fill..color = TesseraColors.terracotta,
      );
    }
    if (selected) {
      _stroke
        ..color = TesseraColors.gold
        ..strokeWidth = 3.5;
      canvas.drawRRect(rect.inflate(1), _stroke);
    }
  }
}
