import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight, FontFeature;
import 'package:flutter/services.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../../theme/tessera_colors.dart';
import '../common/effects.dart';

/// Flame game for the day's keystone: a 5x5 grid where every row and
/// column holds each glaze once. Tiles revealed by a tray puzzle carry that
/// puzzle's rim colour; tiles lent for an early start carry a dashed rim.
class KeystoneGame extends FlameGame {
  KeystoneGame({required this.board, required this.rims, this.haptics = true});

  static const solvedOverlay = 'solved';

  final KeystoneBoard board;

  /// Rim colour per tray puzzle, for the tiles it revealed.
  final Map<PuzzleKind, Color> rims;
  final bool haptics;

  final selected = ValueNotifier<int?>(null);
  final solved = ValueNotifier<bool>(false);
  final hintsUsed = ValueNotifier<int>(0);

  Set<int> _conflicts = const {};
  Set<int> get conflicts => _conflicts;

  final List<KeystoneTileComponent> tiles = [];

  @override
  Color backgroundColor() => TesseraColors.clay;

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < KeystonePuzzle.cellCount; i++) {
      tiles.add(KeystoneTileComponent(i));
    }
    await addAll(tiles);
    _layout(size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _layout(size);
  }

  static const _gap = 6.0;

  void _layout(Vector2 size) {
    const n = KeystonePuzzle.size;
    final side = math.max(0.0, math.min(size.x, size.y) - 16);
    final tile = math.max(0.0, (side - (n + 1) * _gap) / n);
    final origin = (size - Vector2.all(side)) / 2;
    for (var i = 0; i < tiles.length; i++) {
      tiles[i]
        ..size = Vector2.all(tile)
        ..position =
            origin +
            Vector2(
              _gap + (i % n) * (tile + _gap) + tile / 2,
              _gap + (i ~/ n) * (tile + _gap) + tile / 2,
            );
    }
  }

  void selectTile(int index) {
    if (solved.value) return;
    selected.value = index;
    if (haptics) HapticFeedback.selectionClick();
  }

  void placeGlaze(int value) {
    final i = selected.value;
    if (i == null || solved.value || !board.place(i, value)) return;
    _changed(i);
  }

  void erase() {
    final i = selected.value;
    if (i == null || solved.value || !board.clear(i)) return;
    _changed(i);
  }

  void useHint() {
    if (solved.value) return;
    final h = board.hint();
    if (h == null) return;
    board.place(h.$1, h.$2);
    hintsUsed.value++;
    selected.value = h.$1;
    _changed(h.$1);
  }

  void restart() {
    board.reset();
    selected.value = null;
    solved.value = false;
    overlays.remove(solvedOverlay);
    _conflicts = board.conflicts();
  }

  void _changed(int index) {
    _conflicts = board.conflicts();
    tiles[index].add(pressEffect());
    if (haptics) HapticFeedback.selectionClick();
    if (board.isSolved) {
      solved.value = true;
      selected.value = null;
      if (haptics) HapticFeedback.heavyImpact();
      _assemble();
    }
  }

  /// The mosaic "click" cascade: tiles settle in one after another, under
  /// 600 ms.
  void _assemble() {
    for (var i = 0; i < tiles.length; i++) {
      tiles[i].add(
        ScaleEffect.to(
          Vector2.all(1.1),
          EffectController(
            duration: 0.07,
            reverseDuration: 0.08,
            startDelay: i * 0.014,
          ),
        ),
      );
    }
    add(
      TimerComponent(
        period: 0.6,
        removeOnFinish: true,
        onTick: () => overlays.add(solvedOverlay),
      ),
    );
  }

  @override
  void onRemove() {
    selected.dispose();
    solved.dispose();
    hintsUsed.dispose();
    super.onRemove();
  }
}

class KeystoneTileComponent extends PositionComponent
    with TapCallbacks, HasGameReference<KeystoneGame> {
  KeystoneTileComponent(this.index) : super(anchor: Anchor.center);

  final int index;

  @override
  void onTapDown(TapDownEvent event) => game.selectTile(index);

  static final _fill = Paint();
  static final _stroke = Paint()..style = PaintingStyle.stroke;

  @override
  void render(Canvas canvas) {
    final board = game.board;
    final value = board.valueAt(index);
    final radius = Radius.circular(size.x * 0.16);
    final rect = RRect.fromRectAndRadius(size.toRect(), radius);

    _fill.color = value == 0
        ? TesseraColors.clayLight
        : TesseraColors.glaze(value);
    canvas.drawRRect(rect, _fill);

    if (value != 0) {
      TextPaint(
        style: TextStyle(
          fontSize: size.y * 0.48,
          fontWeight: board.isGiven(index) ? FontWeight.w800 : FontWeight.w500,
          color: TesseraColors.onGlaze(value),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ).render(canvas, '$value', size / 2, anchor: Anchor.center);
    }

    if (board.isGiven(index)) {
      final source = board.puzzle.sourceOf(index);
      final lent = board.givens.lent.contains(index);
      _stroke
        ..strokeWidth = 4
        ..color = source != null && !lent
            ? game.rims[source] ?? TesseraColors.ink
            : TesseraColors.ink.withValues(alpha: 0.35);
      if (lent) {
        // Dashed rim: a lent tile, not earned.
        final r = rect.deflate(3).outerRect;
        const dash = 6.0;
        for (var x = r.left; x < r.right; x += 2 * dash) {
          canvas.drawLine(
            Offset(x, r.top),
            Offset(math.min(x + dash, r.right), r.top),
            _stroke,
          );
          canvas.drawLine(
            Offset(x, r.bottom),
            Offset(math.min(x + dash, r.right), r.bottom),
            _stroke,
          );
        }
        for (var y = r.top; y < r.bottom; y += 2 * dash) {
          canvas.drawLine(
            Offset(r.left, y),
            Offset(r.left, math.min(y + dash, r.bottom)),
            _stroke,
          );
          canvas.drawLine(
            Offset(r.right, y),
            Offset(r.right, math.min(y + dash, r.bottom)),
            _stroke,
          );
        }
      } else {
        canvas.drawRRect(rect.deflate(3), _stroke);
      }
    }
    if (game.conflicts.contains(index)) {
      _stroke
        ..color = TesseraColors.terracotta
        ..strokeWidth = 3;
      canvas.drawRRect(rect.deflate(1.5), _stroke);
    }
    if (game.selected.value == index) {
      _stroke
        ..color = TesseraColors.gold
        ..strokeWidth = 3.5;
      canvas.drawRRect(rect.inflate(1), _stroke);
    }
  }
}
