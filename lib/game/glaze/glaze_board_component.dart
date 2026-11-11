import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../common/ceramic.dart';
import 'glaze_game.dart';
import 'glaze_tile_component.dart';

/// The grouted board: a grout slab with one [GlazeTileComponent] per cell.
class GlazeBoardComponent extends PositionComponent
    with HasGameReference<GlazeGame> {
  GlazeBoardComponent() : super(anchor: Anchor.center);

  static const _tileGap = 4.0;
  static const _boxGap = 8.0;

  final List<GlazeTileComponent> _tiles = [];

  GlazeTileComponent tileAt(int index) => _tiles[index];

  @override
  Future<void> onLoad() async {
    final n = game.board.size;
    for (var i = 0; i < n * n; i++) {
      _tiles.add(GlazeTileComponent(i));
    }
    await addAll(_tiles);
    _layoutTiles();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _layoutTiles();
  }

  @override
  set size(Vector2 value) {
    super.size = value;
    if (isLoaded) _layoutTiles();
  }

  void _layoutTiles() {
    final layout = game.board.puzzle.layout;
    final n = layout.size;
    final boxesAcross = n ~/ layout.boxCols;
    final boxesDown = n ~/ layout.boxRows;
    final gapsX = (n + 1) * _tileGap + (boxesAcross - 1) * _boxGap;
    final gapsY = (n + 1) * _tileGap + (boxesDown - 1) * _boxGap;
    final tile = math.max(
      0.0,
      math.min((size.x - gapsX) / n, (size.y - gapsY) / n),
    );
    for (var i = 0; i < _tiles.length; i++) {
      final r = i ~/ n, c = i % n;
      final x =
          _tileGap + c * (tile + _tileGap) + (c ~/ layout.boxCols) * _boxGap;
      final y =
          _tileGap + r * (tile + _tileGap) + (r ~/ layout.boxRows) * _boxGap;
      _tiles[i]
        ..size = Vector2.all(tile)
        ..position = Vector2(x + tile / 2, y + tile / 2);
    }
  }

  @override
  void render(Canvas canvas) => Ceramic.plate(canvas, size.toRect());

  /// "Kiln firing": a quick ripple across the tiles on solve, under 600 ms.
  void fire({void Function()? onComplete}) {
    final n = game.board.size;
    const step = 0.03;
    for (var i = 0; i < _tiles.length; i++) {
      final r = i ~/ n, c = i % n;
      _tiles[i].add(
        ScaleEffect.to(
          Vector2.all(1.08),
          EffectController(
            duration: 0.08,
            reverseDuration: 0.1,
            startDelay: (r + c) * step,
          ),
        ),
      );
    }
    final total = (2 * n - 2) * step + 0.2;
    add(
      TimerComponent(period: total, removeOnFinish: true, onTick: onComplete),
    );
  }
}
