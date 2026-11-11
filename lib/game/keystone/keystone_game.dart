import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart'
    show TextStyle, FontWeight, FontFeature, Shadow;
import 'package:puzzle_core/puzzle_core.dart';

import '../../theme/tessera_colors.dart';
import '../../juice/juice.dart';
import '../../theme/tessera_theme.dart';
import '../common/ceramic.dart';
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
  final _plate = _KeystonePlate();

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < KeystonePuzzle.cellCount; i++) {
      tiles.add(KeystoneTileComponent(i));
    }
    await add(_plate);
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
    _plate
      ..position = origin
      ..size = Vector2.all(side);
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
    if (haptics) Juice.tap();
  }

  void placeGlaze(int value) {
    final i = selected.value;
    if (i == null || solved.value || !board.place(i, value)) return;
    _changed(i, placed: true);
  }

  void erase() {
    final i = selected.value;
    if (i == null || solved.value || !board.clear(i)) return;
    _changed(i, erased: true);
  }

  void useHint() {
    if (solved.value) return;
    final h = board.hint();
    if (h == null) return;
    board.place(h.$1, h.$2);
    hintsUsed.value++;
    selected.value = h.$1;
    _changed(h.$1, placed: true);
  }

  void restart() {
    board.reset();
    selected.value = null;
    solved.value = false;
    overlays.remove(solvedOverlay);
    _conflicts = board.conflicts();
  }

  void _changed(int index, {bool placed = false, bool erased = false}) {
    _conflicts = board.conflicts();
    final tile = tiles[index]..add(pressEffect());
    if (board.isSolved) {
      solved.value = true;
      selected.value = null;
      if (haptics) Juice.keystone();
      _assemble();
      celebrate(this, _plate.center, _plate.size.x * 0.6);
      return;
    }
    if (placed && _conflicts.contains(index)) {
      if (haptics) Juice.error();
      tile.add(shakeEffect());
    } else if (placed) {
      if (haptics) Juice.place();
      add(
        chipPuff(
          tile.position,
          TesseraColors.glaze(board.valueAt(index)),
          size: tile.size.x,
        ),
      );
    } else if (erased && haptics) {
      Juice.erase();
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

  static final _stroke = Paint()..style = PaintingStyle.stroke;

  @override
  void render(Canvas canvas) {
    final board = game.board;
    final value = board.valueAt(index);
    final selected = game.selected.value == index;
    final pressed = value == 0 && selected;
    if (value == 0) {
      Ceramic.tile(
        canvas,
        size.toRect(),
        TesseraColors.bisque,
        gloss: 0,
        depth: 0.06,
        pressed: pressed,
      );
    } else {
      Ceramic.tile(canvas, size.toRect(), TesseraColors.glaze(value));
    }
    final face = Ceramic.faceOf(
      size.toRect(),
      depth: value == 0 ? 0.06 : 0.08,
      pressed: pressed,
    );
    final radius = Radius.circular(size.x * 0.18);
    final rect = RRect.fromRectAndRadius(face, radius);

    if (value != 0) {
      TextPaint(
        style: TextStyle(
          fontFamily: TesseraFonts.body,
          shadows: const [
            Shadow(color: Color(0x40000000), offset: Offset(0, 1.5)),
          ],
          fontSize: size.y * 0.48,
          fontWeight: board.isGiven(index) ? FontWeight.w800 : FontWeight.w500,
          color: TesseraColors.onGlaze(value),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ).render(
        canvas,
        '$value',
        Vector2(face.center.dx, face.center.dy),
        anchor: Anchor.center,
      );
    }

    if (board.isGiven(index)) {
      final source = board.puzzle.sourceOf(index);
      final lent = board.givens.lent.contains(index);
      _stroke
        ..strokeWidth = 4
        ..color = source != null && !lent
            ? game.rims[source] ?? TesseraColors.ink
            : TesseraColors.chalk.withValues(alpha: 0.7);
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
    if (selected) {
      _stroke
        ..color = TesseraColors.emberGlow
        ..strokeWidth = 3.5;
      canvas.drawRRect(rect.inflate(1.5), _stroke);
    }
  }
}

/// The kiln shelf under the keystone grid.
class _KeystonePlate extends PositionComponent {
  _KeystonePlate() : super(priority: -1);

  @override
  void render(Canvas canvas) {
    if (size.x <= 0) return;
    Ceramic.plate(canvas, size.toRect());
  }
}
