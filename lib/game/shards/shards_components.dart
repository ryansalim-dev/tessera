import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../../theme/tessera_colors.dart';
import 'shards_game.dart';

/// The broken plate: clay where the plate is, nothing where it chipped.
class PlateComponent extends PositionComponent
    with HasGameReference<ShardsGame> {
  static final _grout = Paint()..color = TesseraColors.grout;
  static final _clay = Paint()..color = TesseraColors.clayLight;
  static final _shadow = Paint()
    ..color = TesseraColors.ink.withValues(alpha: 0.12)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  @override
  void render(Canvas canvas) {
    final p = game.board.puzzle;
    final n = p.size;
    final cell = game.cell;
    final outline = Path();
    for (var i = 0; i < p.cellCount; i++) {
      if (!p.plate[i]) continue;
      outline.addRect(
        Rect.fromLTWH((i % n) * cell, (i ~/ n) * cell, cell, cell),
      );
    }
    canvas.drawPath(outline.shift(const Offset(0, 3)), _shadow);
    canvas.drawPath(outline, _grout);
    for (var i = 0; i < p.cellCount; i++) {
      if (!p.plate[i]) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            (i % n) * cell + 2,
            (i ~/ n) * cell + 2,
            cell - 4,
            cell - 4,
          ),
          Radius.circular(cell * 0.12),
        ),
        _clay,
      );
    }
  }

  /// "Kiln firing": every set shard pulses, under 600 ms.
  void fire({void Function()? onComplete}) {
    for (final s in game.shards) {
      s.add(
        ScaleEffect.to(
          Vector2.all(1.04),
          EffectController(duration: 0.12, reverseDuration: 0.15),
        ),
      );
    }
    add(TimerComponent(period: 0.5, removeOnFinish: true, onTick: onComplete));
  }
}

/// One shard. Drag it onto the plate, tap it to turn it.
class ShardComponent extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameReference<ShardsGame> {
  ShardComponent(this.index);

  final int index;

  bool _dragging = false;

  ShardShape get shape =>
      game.board.puzzle.shards[index].rotated(game.board.turnsOf(index));

  /// Moves to the plate (if set) or its tray slot, at the right scale.
  void snap() {
    final s = shape;
    final cell = game.cell;
    size = Vector2(s.cols * cell, s.rows * cell);
    final p = game.board.placementOf(index);
    if (p != null) {
      scale = Vector2.all(1);
      position = game.cellTopLeft(p.row, p.col);
      priority = 1;
    } else {
      scale = Vector2.all(game.trayScale);
      position = game.slotCentre(index) - size * game.trayScale / 2;
      priority = 2;
    }
  }

  void press() => add(
    ScaleEffect.by(
      Vector2.all(0.94),
      EffectController(duration: 0.06, reverseDuration: 0.1),
    ),
  );

  @override
  bool containsLocalPoint(Vector2 point) {
    final cell = game.cell;
    if (cell <= 0) return false;
    final r = (point.y / cell).floor(), c = (point.x / cell).floor();
    // A little forgiveness in the tray, where shards are drawn small.
    if (!game.board.isPlaced(index)) {
      return point.x >= 0 &&
          point.y >= 0 &&
          point.x <= size.x &&
          point.y <= size.y;
    }
    return shape.contains(r, c);
  }

  @override
  void onTapUp(TapUpEvent event) => game.turn(index);

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (game.solved.value) return;
    _dragging = true;
    // Grow to plate size around the finger so the drop preview is honest.
    final grab = event.localPosition;
    final before = absolutePositionOf(grab);
    scale = Vector2.all(1);
    position += before - absolutePositionOf(grab);
    priority = 10;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_dragging) position += event.canvasDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_dragging) return;
    _dragging = false;
    game.drop(index, position.clone());
  }

  static final _fill = Paint();
  static final _gold = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = TesseraColors.gold;
  static final _shine = Paint()..color = const Color(0x33FFFFFF);
  static final _shadow = Paint()
    ..color = TesseraColors.ink.withValues(alpha: 0.18)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  @override
  void render(Canvas canvas) {
    final cell = game.cell;
    if (cell <= 0) return;
    final s = shape;
    final path = Path();
    for (final (r, c) in s.cells) {
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(c * cell + 1.5, r * cell + 1.5, cell - 3, cell - 3),
          Radius.circular(cell * 0.12),
        ),
      );
    }
    if (_dragging) canvas.drawPath(path.shift(const Offset(0, 6)), _shadow);
    _fill.color = TesseraColors.glaze(index + 1);
    canvas.drawPath(path, _fill);
    for (final (r, c) in s.cells) {
      canvas.drawRect(
        Rect.fromLTWH(c * cell + 4, r * cell + 4, cell - 8, cell * 0.2),
        _shine,
      );
    }
    // Kintsugi edge: gold along every outer edge of the shard.
    for (final (r, c) in s.cells) {
      final x = c * cell, y = r * cell;
      if (!s.contains(r - 1, c)) {
        canvas.drawLine(Offset(x, y), Offset(x + cell, y), _gold);
      }
      if (!s.contains(r + 1, c)) {
        canvas.drawLine(Offset(x, y + cell), Offset(x + cell, y + cell), _gold);
      }
      if (!s.contains(r, c - 1)) {
        canvas.drawLine(Offset(x, y), Offset(x, y + cell), _gold);
      }
      if (!s.contains(r, c + 1)) {
        canvas.drawLine(Offset(x + cell, y), Offset(x + cell, y + cell), _gold);
      }
    }
  }
}
