import 'dart:ui';

import 'package:flame/components.dart';

import '../../theme/tessera_colors.dart';
import '../common/effects.dart';
import 'kiln_path_game.dart';

/// One clay tile. Tiles the line has passed through take on a warm, fired
/// tint. Checkpoints and the line itself are drawn by the line component so
/// they sit above every tile.
class KilnPathTileComponent extends PositionComponent
    with HasGameReference<KilnPathGame> {
  KilnPathTileComponent(this.index) : super(anchor: Anchor.center);

  final int index;

  void press() => add(pressEffect());

  static final _fill = Paint();

  /// Fired clay: terracotta washed over the light clay.
  static final _fired = Color.lerp(
    TesseraColors.clayLight,
    TesseraColors.terracotta,
    0.22,
  )!;

  @override
  void render(Canvas canvas) {
    _fill.color = game.board.contains(index) ? _fired : TesseraColors.clayLight;
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), Radius.circular(size.x * 0.16)),
      _fill,
    );
  }
}
