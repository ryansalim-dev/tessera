import 'dart:ui';

import 'package:flame/components.dart';

import '../../theme/tessera_colors.dart';
import '../common/ceramic.dart';
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

  /// Fired clay: terracotta washed over the bisque.
  static final _fired = Color.lerp(
    TesseraColors.bisque,
    TesseraColors.ember,
    0.45,
  )!;

  @override
  void render(Canvas canvas) {
    final fired = game.board.contains(index);
    Ceramic.tile(
      canvas,
      size.toRect(),
      fired ? _fired : TesseraColors.bisque,
      gloss: fired ? 0.6 : 0,
      depth: 0.07,
      pressed: fired,
    );
  }
}
