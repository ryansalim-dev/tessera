import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight, FontFeature;

import '../../theme/tessera_colors.dart';
import '../../theme/tessera_theme.dart';
import '../common/ceramic.dart';
import '../common/effects.dart';
import 'seams_game.dart';

/// The plate: tiles, the seams and the shards. Owns drag and tap input so
/// one gesture can sweep across many tiles.
class SeamsBoardComponent extends PositionComponent
    with HasGameReference<SeamsGame>, DragCallbacks, TapCallbacks {
  SeamsBoardComponent() : super(anchor: Anchor.center);

  static const _tileGap = 3.0;

  final List<SeamsTileComponent> _tiles = [];
  double _tile = 0;

  SeamsTileComponent tileAt(int index) => _tiles[index];
  Vector2 centreOf(int cell) => _tiles[cell].position;
  double get tileSize => _tile;

  @override
  Future<void> onLoad() async {
    final n = game.board.size;
    for (var i = 0; i < n * n; i++) {
      _tiles.add(SeamsTileComponent(i));
    }
    await addAll(_tiles);
    await add(_SeamsOverlay()..priority = 1);
    _layoutTiles();
  }

  @override
  set size(Vector2 value) {
    super.size = value;
    if (isLoaded) _layoutTiles();
  }

  void _layoutTiles() {
    final n = game.board.size;
    final gaps = (n + 1) * _tileGap;
    _tile = math.max(0.0, math.min((size.x - gaps) / n, (size.y - gaps) / n));
    for (var i = 0; i < _tiles.length; i++) {
      final r = i ~/ n, c = i % n;
      _tiles[i]
        ..size = Vector2.all(_tile)
        ..position = Vector2(
          _tileGap + c * (_tile + _tileGap) + _tile / 2,
          _tileGap + r * (_tile + _tileGap) + _tile / 2,
        );
    }
  }

  int? cellAt(Vector2 local) {
    final n = game.board.size;
    final pitch = _tile + _tileGap;
    if (pitch <= 0) return null;
    final c = ((local.x - _tileGap) / pitch).floor();
    final r = ((local.y - _tileGap) / pitch).floor();
    if (r < 0 || c < 0 || r >= n || c >= n) return null;
    return r * n + c;
  }

  int? _lastCell;

  @override
  void onTapDown(TapDownEvent event) {
    final cell = cellAt(event.localPosition);
    if (cell != null) game.begin(cell);
  }

  @override
  void onTapUp(TapUpEvent event) => game.end();

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final cell = cellAt(event.localPosition);
    _lastCell = cell;
    if (cell != null && game.board.active == null) game.begin(cell);
  }

  // See KilnPathBoardComponent: the "start" position is under the finger.
  @override
  void onDragUpdate(DragUpdateEvent event) {
    final cell = cellAt(absoluteToLocal(event.canvasStartPosition));
    if (cell == null || cell == _lastCell) return;
    _lastCell = cell;
    game.extend(cell);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _lastCell = null;
    game.end();
  }

  @override
  void render(Canvas canvas) => Ceramic.plate(canvas, size.toRect());

  /// "Kiln firing": each seam ripples from shard to shard, under 600 ms.
  void fire({void Function()? onComplete}) {
    final p = game.board.puzzle;
    for (var pair = 1; pair <= p.pairCount; pair++) {
      final seam = game.board.seam(pair);
      final step = 0.4 / seam.length;
      for (var i = 0; i < seam.length; i++) {
        _tiles[seam[i]].add(
          ScaleEffect.to(
            Vector2.all(1.08),
            EffectController(
              duration: 0.08,
              reverseDuration: 0.1,
              startDelay: i * step,
            ),
          ),
        );
      }
    }
    add(TimerComponent(period: 0.6, removeOnFinish: true, onTick: onComplete));
  }
}

/// One clay tile, washed with the colour of the seam that covers it.
class SeamsTileComponent extends PositionComponent
    with HasGameReference<SeamsGame> {
  SeamsTileComponent(this.index) : super(anchor: Anchor.center);

  final int index;

  void press() => add(pressEffect());

  @override
  void render(Canvas canvas) {
    final board = game.board;
    final shard = board.puzzle.endpoints[index] != 0;
    final owner = shard ? 0 : board.ownerAt(index);
    Ceramic.tile(
      canvas,
      size.toRect(),
      owner == 0
          ? TesseraColors.bisque
          : Color.lerp(TesseraColors.bisque, TesseraColors.glaze(owner), 0.3)!,
      gloss: 0,
      depth: 0.06,
      pressed: owner != 0,
    );
  }
}

/// Seams and shards, drawn above every tile. A seam is a gold kintsugi line
/// with its pair's glaze running through the middle; shards are glazed
/// chips carrying the pair number, so colour is never the only cue.
class _SeamsOverlay extends Component
    with HasGameReference<SeamsGame>, ParentIsA<SeamsBoardComponent> {
  static final _gold = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = TesseraColors.gold;
  static final _core = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final _goldGlow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = TesseraColors.gold.withValues(alpha: 0.5)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final _ring = Paint()
    ..style = PaintingStyle.stroke
    ..color = TesseraColors.gold;

  @override
  void render(Canvas canvas) {
    final board = game.board;
    final p = board.puzzle;
    final tile = parent.tileSize;
    if (tile <= 0) return;

    for (var pair = 1; pair <= p.pairCount; pair++) {
      final seam = board.seam(pair);
      if (seam.length < 2) continue;
      final path = Path();
      for (var i = 0; i < seam.length; i++) {
        final c = parent.centreOf(seam[i]);
        i == 0 ? path.moveTo(c.x, c.y) : path.lineTo(c.x, c.y);
      }
      _goldGlow.strokeWidth = tile * 0.4;
      canvas.drawPath(path, _goldGlow);
      _gold.strokeWidth = tile * 0.26;
      canvas.drawPath(path, _gold);
      _core
        ..strokeWidth = tile * 0.12
        ..color = TesseraColors.glaze(pair);
      canvas.drawPath(path, _core);
    }

    final r = tile * 0.34;
    for (var cell = 0; cell < p.cellCount; cell++) {
      final pair = p.endpoints[cell];
      if (pair == 0) continue;
      final c = parent.centreOf(cell).toOffset();
      // A chipped shard: a rounded square turned a little.
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(0.25);
      Ceramic.tile(
        canvas,
        Rect.fromCenter(center: Offset.zero, width: 2 * r, height: 2 * r),
        TesseraColors.glaze(pair),
        radius: 0.3,
        depth: 0.12,
      );
      if (board.isJoined(pair)) {
        _ring.strokeWidth = 2.5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: 2 * r + 4,
              height: 2 * r + 4,
            ),
            Radius.circular(r * 0.4),
          ),
          _ring,
        );
      }
      canvas.restore();
      TextPaint(
        style: TextStyle(
          fontFamily: TesseraFonts.body,
          fontSize: r * 1.0,
          fontWeight: FontWeight.w800,
          color: TesseraColors.onGlaze(pair),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ).render(canvas, '$pair', Vector2(c.dx, c.dy), anchor: Anchor.center);
    }
  }
}
