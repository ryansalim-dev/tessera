import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../../theme/tessera_colors.dart';
import 'shards_components.dart';

/// Flame game for one Shards plate.
///
/// The broken plate sits on top and the shards wait in a tray below. Drag
/// a shard onto the plate to set it; tap a shard to turn it; drag a set
/// shard off the plate to lift it. Rules live in `puzzle_core`'s
/// [ShardsBoard].
class ShardsGame extends FlameGame {
  ShardsGame({required this.board, this.haptics = true});

  static const solvedOverlay = 'solved';

  final ShardsBoard board;
  final bool haptics;

  final placed = ValueNotifier<int>(0);
  final solved = ValueNotifier<bool>(false);
  final hintsUsed = ValueNotifier<int>(0);

  late final PlateComponent plate;
  final List<ShardComponent> shards = [];

  /// Plate cell size in pixels.
  double cell = 0;

  /// Tray shards are drawn at this fraction of plate size, chosen so the
  /// whole tray fits under the plate.
  double trayScale = 0.55;

  final List<Vector2> _slotCentres = [];

  @override
  Color backgroundColor() => TesseraColors.clay;

  @override
  Future<void> onLoad() async {
    plate = PlateComponent();
    await add(plate);
    for (var i = 0; i < board.shardCount; i++) {
      shards.add(ShardComponent(i));
    }
    await addAll(shards);
    _layout(size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _layout(size);
  }

  static const _gap = 12.0;

  void _layout(Vector2 size) {
    final n = board.puzzle.size;
    final count = board.shardCount;
    final extent = board.puzzle.shards
        .map((s) => math.max(s.rows, s.cols))
        .reduce(math.max);

    // Shrink the plate until a tray at a readable scale fits beneath it.
    var side = math.max(0.0, math.min(size.x - 2 * _gap, size.y * 0.6));
    var perRow = 1;
    var slot = 0.0;
    while (true) {
      cell = side / n;
      final trayH = size.y - side - 3 * _gap;
      // Largest tray scale (up to 0.6) whose slots fit the tray area.
      trayScale = 0.6;
      while (trayScale > 0.3) {
        slot = extent * cell * trayScale + _gap;
        perRow = math.max(1, (size.x / slot).floor());
        if ((count / perRow).ceil() * slot <= trayH) break;
        trayScale -= 0.02;
      }
      if (trayScale > 0.3 || side < 120) break;
      side *= 0.9;
    }

    plate
      ..size = Vector2.all(side)
      ..position = Vector2((size.x - side) / 2, _gap);
    final top = plate.position.y + side + 2 * _gap;
    final rowW = math.min(perRow, count) * slot;
    _slotCentres
      ..clear()
      ..addAll([
        for (var i = 0; i < count; i++)
          Vector2(
            (size.x - rowW) / 2 + (i % perRow + 0.5) * slot,
            top + (i ~/ perRow + 0.5) * slot,
          ),
      ]);
    for (final s in shards) {
      s.snap();
    }
  }

  Vector2 slotCentre(int shard) => _slotCentres[shard];

  /// Plate-space top-left of a cell.
  Vector2 cellTopLeft(int row, int col) =>
      plate.position + Vector2(col * cell, row * cell);

  /// Tries to set [shard] with its top-left at the nearest plate cell to
  /// [topLeft] (game coordinates). Lifts it back to the tray otherwise.
  bool drop(int shard, Vector2 topLeft) {
    if (solved.value) return false;
    final local = (topLeft - plate.position) / cell;
    final placement = ShardPlacement(
      board.turnsOf(shard),
      local.y.round(),
      local.x.round(),
    );
    board.lift(shard);
    final ok = board.place(shard, placement);
    _changed(shard, set: ok);
    return ok;
  }

  void turn(int shard) {
    if (solved.value) return;
    board.turn(shard);
    _changed(shard, set: board.isPlaced(shard));
  }

  ShardsHint? useHint() {
    if (solved.value) return null;
    final hint = board.hint();
    if (hint == null) return null;
    board.apply(hint);
    hintsUsed.value++;
    _changed(hint.shard, set: true);
    return hint;
  }

  void restart() {
    board.reset();
    solved.value = false;
    overlays.remove(solvedOverlay);
    placed.value = 0;
    for (final s in shards) {
      s.snap();
    }
  }

  void _changed(int shard, {required bool set}) {
    placed.value = board.placedCount;
    for (final s in shards) {
      s.snap();
    }
    shards[shard].press();
    if (haptics) {
      set ? HapticFeedback.lightImpact() : HapticFeedback.selectionClick();
    }
    if (board.isSolved) {
      solved.value = true;
      if (haptics) HapticFeedback.mediumImpact();
      plate.fire(onComplete: () => overlays.add(solvedOverlay));
    }
  }

  @override
  void onRemove() {
    placed.dispose();
    solved.dispose();
    hintsUsed.dispose();
    super.onRemove();
  }
}
