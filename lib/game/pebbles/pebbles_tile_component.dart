import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../../theme/tessera_colors.dart';
import '../common/ceramic.dart';
import '../common/effects.dart';
import 'pebbles_game.dart';

/// One tile, tinted by its grout region. Shows a pebble, a grout dot, or
/// nothing.
class PebblesTileComponent extends PositionComponent
    with TapCallbacks, HasGameReference<PebblesGame> {
  PebblesTileComponent(this.index) : super(anchor: Anchor.center);

  final int index;

  void press() => add(pressEffect());

  @override
  void onTapDown(TapDownEvent event) => game.tapTile(index);

  static final _fill = Paint();
  static final _stroke = Paint()..style = PaintingStyle.stroke;
  static final _shine = Paint()..color = const Color(0x55FFFFFF);

  @override
  void render(Canvas canvas) {
    final face = Ceramic.faceOf(size.toRect(), depth: 0.06);
    final radius = Radius.circular(size.x * 0.14);
    final rect = RRect.fromRectAndRadius(face, radius);
    Ceramic.tile(
      canvas,
      size.toRect(),
      game.boardComponent.tintAt(index),
      radius: 0.14,
      depth: 0.06,
      gloss: 0.4,
    );

    final centre = face.center;
    switch (game.board.markAt(index)) {
      case PebbleMark.empty:
        break;
      case PebbleMark.dot:
        _fill.color = TesseraColors.groutDark;
        canvas.drawCircle(centre, size.x * 0.08, _fill);
      case PebbleMark.pebble:
        final conflict = game.conflicts.contains(index);
        final stone = Rect.fromCenter(
          center: centre.translate(0, size.y * 0.02),
          width: size.x * 0.62,
          height: size.y * 0.5,
        );
        _fill.color = TesseraColors.ink.withValues(alpha: 0.18);
        canvas.drawOval(stone.shift(Offset(0, size.y * 0.05)), _fill);
        _fill.color = conflict ? TesseraColors.terracotta : TesseraColors.ink;
        canvas.drawOval(stone, _fill);
        canvas.drawOval(
          Rect.fromLTWH(
            stone.left + stone.width * 0.2,
            stone.top + stone.height * 0.14,
            stone.width * 0.35,
            stone.height * 0.25,
          ),
          _shine,
        );
        if (conflict) {
          _stroke
            ..color = TesseraColors.terracotta
            ..strokeWidth = 3;
          canvas.drawRRect(rect.deflate(1.5), _stroke);
        }
    }
  }
}
