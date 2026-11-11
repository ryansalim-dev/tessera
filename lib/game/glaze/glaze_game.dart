import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter/foundation.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../../juice/juice.dart';
import '../../theme/tessera_colors.dart';
import '../common/effects.dart';
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
  Color backgroundColor() => const Color(0x00000000);

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
    _changed(i, placed: true);
  }

  void erase() {
    final i = selected.value;
    if (i == null || solved.value || !board.clear(i)) return;
    _changed(i, erased: true);
  }

  GlazeHint? useHint() {
    if (solved.value) return null;
    final hint = board.hint();
    if (hint == null) return null;
    board.place(hint.index, hint.value);
    hintsUsed.value++;
    selected.value = hint.index;
    _changed(hint.index, placed: true);
    return hint;
  }

  void restart() {
    board.reset();
    selected.value = null;
    solved.value = false;
    overlays.remove(solvedOverlay);
    _refresh();
  }

  void _changed(int index, {bool placed = false, bool erased = false}) {
    _refresh();
    final tile = boardComponent.tileAt(index);
    tile.press();
    if (board.isSolved) {
      solved.value = true;
      selected.value = null;
      if (haptics) Juice.solve();
      boardComponent.fire(onComplete: () => overlays.add(solvedOverlay));
      celebrate(this, size / 2, boardComponent.size.x / 2);
      return;
    }
    if (placed && conflicts.contains(index)) {
      if (haptics) Juice.error();
      boardComponent.add(shakeEffect());
    } else if (placed) {
      if (haptics) Juice.place();
      boardComponent.add(
        chipPuff(
          tile.position,
          TesseraColors.glaze(board.valueAt(index)),
          size: tile.size.x,
        ),
      );
    } else if (erased) {
      if (haptics) Juice.erase();
    }
  }

  void _refresh() => _conflicts = board.conflicts();

  void _tap() {
    if (haptics) Juice.tap();
  }

  @override
  void onRemove() {
    selected.dispose();
    solved.dispose();
    hintsUsed.dispose();
    super.onRemove();
  }
}
