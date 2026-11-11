import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';

import '../common/ceramic.dart';
import 'kiln_path_game.dart';
import 'kiln_path_line_component.dart';
import 'kiln_path_tile_component.dart';

/// The grouted board: a grout slab, one [KilnPathTileComponent] per cell and
/// the firing line drawn on top. Owns drag and tap input so a single gesture
/// can sweep across many tiles.
class KilnPathBoardComponent extends PositionComponent
    with HasGameReference<KilnPathGame>, DragCallbacks, TapCallbacks {
  KilnPathBoardComponent() : super(anchor: Anchor.center);

  static const _tileGap = 4.0;

  final List<KilnPathTileComponent> _tiles = [];
  late final KilnPathLineComponent _line;

  double _tile = 0;

  KilnPathTileComponent tileAt(int index) => _tiles[index];

  /// Centre of [cell] in this component's coordinates.
  Vector2 centreOf(int cell) => _tiles[cell].position;

  double get tileSize => _tile;

  @override
  Future<void> onLoad() async {
    final n = game.board.size;
    for (var i = 0; i < n * n; i++) {
      _tiles.add(KilnPathTileComponent(i));
    }
    await addAll(_tiles);
    _line = KilnPathLineComponent()..priority = 1;
    await add(_line);
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
    _line.size = size;
  }

  /// The cell under [local], or null when over grout or off the board.
  int? cellAt(Vector2 local) {
    final n = game.board.size;
    final pitch = _tile + _tileGap;
    if (pitch <= 0) return null;
    final c = ((local.x - _tileGap) / pitch).floor();
    final r = ((local.y - _tileGap) / pitch).floor();
    if (r < 0 || c < 0 || r >= n || c >= n) return null;
    return r * n + c;
  }

  int? _lastDragCell;

  void _input(Vector2 local) {
    final cell = cellAt(local);
    if (cell == null || cell == _lastDragCell) return;
    _lastDragCell = cell;
    game.moveTo(cell);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _lastDragCell = null;
    _input(event.localPosition);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _lastDragCell = null;
    _input(event.localPosition);
  }

  // Flutter's DragUpdateDetails.globalPosition is already the pointer's new
  // position, and Flame adds the delta again for its "end" position, so the
  // "start" position is the one under the finger. Converted from canvas
  // space so it still resolves when the finger leaves the board.
  @override
  void onDragUpdate(DragUpdateEvent event) =>
      _input(absoluteToLocal(event.canvasStartPosition));

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _lastDragCell = null;
  }

  @override
  void render(Canvas canvas) => Ceramic.plate(canvas, size.toRect());

  /// "Kiln firing": a ripple that follows the line from start to end, under
  /// 600 ms.
  void fire({void Function()? onComplete}) {
    final path = game.board.path;
    final step = 0.4 / path.length;
    for (var i = 0; i < path.length; i++) {
      _tiles[path[i]].add(
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
    add(TimerComponent(period: 0.6, removeOnFinish: true, onTick: onComplete));
  }
}
