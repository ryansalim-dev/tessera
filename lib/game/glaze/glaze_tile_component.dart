import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart'
    show TextStyle, FontWeight, FontFeature, Shadow;

import '../../theme/tessera_colors.dart';
import '../../theme/tessera_theme.dart';
import '../common/ceramic.dart';
import '../common/effects.dart';
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
    final bounds = size.toRect();

    if (value == 0) {
      // Unglazed bisque, lit warmer along the selected row, column and box.
      Ceramic.tile(
        canvas,
        bounds,
        _isPeerOfSelection() ? _peer : TesseraColors.bisque,
        gloss: 0,
        depth: 0.06,
        pressed: selected,
      );
    } else {
      Ceramic.tile(
        canvas,
        bounds,
        TesseraColors.glaze(value),
        depth: given ? 0.1 : 0.07,
      );
    }
    final face = Ceramic.faceOf(
      bounds,
      depth: value == 0 ? 0.06 : (given ? 0.1 : 0.07),
      pressed: value == 0 && selected,
    );
    final radius = Radius.circular(size.x * 0.18);
    final rect = RRect.fromRectAndRadius(face, radius);

    if (value != 0) {
      final text = TextPaint(
        style: TextStyle(
          fontFamily: TesseraFonts.body,
          fontSize: size.y * 0.5,
          fontWeight: given ? FontWeight.w800 : FontWeight.w700,
          color: TesseraColors.onGlaze(value),
          fontFeatures: const [FontFeature.tabularFigures()],
          shadows: const [
            Shadow(color: Color(0x40000000), offset: Offset(0, 1.5)),
          ],
        ),
      );
      text.render(
        canvas,
        '$value',
        Vector2(face.center.dx, face.center.dy),
        anchor: Anchor.center,
      );
    }

    if (given) {
      // Fired tiles carry a maker's dot so they read as fixed.
      canvas.drawCircle(
        Offset(face.left + face.width * 0.17, face.bottom - face.height * 0.17),
        size.x * 0.045,
        _fill..color = TesseraColors.ink.withValues(alpha: 0.35),
      );
    }
    if (conflict) {
      _stroke
        ..color = TesseraColors.terracotta
        ..strokeWidth = 3;
      canvas.drawRRect(rect.deflate(1.5), _stroke);
      canvas.drawCircle(
        Offset(face.left + face.width * 0.82, face.top + face.height * 0.18),
        size.x * 0.08,
        _fill..color = const Color(0xFFE5483B),
      );
    }
    if (selected) {
      _glow.color = TesseraColors.emberGlow.withValues(alpha: 0.55);
      canvas.drawRRect(rect.inflate(3), _glow);
      _stroke
        ..color = TesseraColors.emberGlow
        ..strokeWidth = 3;
      canvas.drawRRect(rect.inflate(1.5), _stroke);
    }
  }

  static final _peer = Color.lerp(
    TesseraColors.bisque,
    TesseraColors.emberGlow,
    0.28,
  )!;
  static final _glow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
}
