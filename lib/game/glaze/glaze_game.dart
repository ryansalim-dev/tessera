import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../../theme/tessera_colors.dart';
import 'glaze_board_component.dart';

/// Flame game for one Glaze board.
///
/// Rules live in `puzzle_core`'s [GlazeBoard]; this class only renders and
/// routes input. Flutter widgets talk to it through the notifiers below and
/// the public actions ([selectTile], [placeGlaze], [erase], [useHint]).
class GlazeGame extends FlameGame {
  GlazeGame({required this.board, this.haptics = true});

  static const solvedOverlay = 'solved';

  final GlazeBoard board;
  final bool haptics;

  final selected = ValueNotifier<int?>(null);
  final solved = ValueNotifier<bool>(false);
  final hintsUsed = ValueNotifier<int>(0);

  Set<int> _conflicts = const {};
  Set<int> get conflicts => _conflicts;

  late final GlazeBoardComponent boardComponent;

  @override
  Color backgroundColor() => TesseraColors.clay;

  @override
  Future<void> onLoad() async {
    boardComponent = GlazeBoardComponent();
    await add(boardComponent);
    _layout(size);
    _refresh();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _layout(size);
  }

  void _layout(Vector2 size) {
    final side = (size.x < size.y ? size.x : size.y) - 16;
    boardComponent
      ..size = Vector2.all(side)
      ..position = size / 2;
  }

  void selectTile(int index) {
    if (solved.value) return;
    selected.value = index;
    _tap();
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

  GlazeHint? useHint() {
    if (solved.value) return null;
    final hint = board.hint();
    if (hint == null) return null;
    board.place(hint.index, hint.value);
    hintsUsed.value++;
    selected.value = hint.index;
    _changed(hint.index);
    return hint;
  }

  void restart() {
    board.reset();
    selected.value = null;
    solved.value = false;
    overlays.remove(solvedOverlay);
    _refresh();
  }

  void _changed(int index) {
    _refresh();
    boardComponent.tileAt(index).press();
    _tap();
    if (board.isSolved) {
      solved.value = true;
      selected.value = null;
      if (haptics) HapticFeedback.mediumImpact();
      boardComponent.fire(onComplete: () => overlays.add(solvedOverlay));
    }
  }

  void _refresh() => _conflicts = board.conflicts();

  void _tap() {
    if (haptics) HapticFeedback.selectionClick();
  }

  @override
  void onRemove() {
    selected.dispose();
    solved.dispose();
    hintsUsed.dispose();
    super.onRemove();
  }
}

/// Short "press in" used when a tile changes.
Effect pressEffect() => ScaleEffect.to(
  Vector2.all(0.9),
  EffectController(duration: 0.06, reverseDuration: 0.1),
);
