import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../../theme/tessera_colors.dart';
import 'pebbles_board_component.dart';

/// Flame game for one Pebbles board.
///
/// Rules live in `puzzle_core`'s [PebblesBoard]; this class only renders and
/// routes input. A tap cycles a tile through pebble, grout dot and empty.
class PebblesGame extends FlameGame {
  PebblesGame({required this.board, this.haptics = true});

  static const solvedOverlay = 'solved';

  final PebblesBoard board;
  final bool haptics;

  final pebbleCount = ValueNotifier<int>(0);
  final solved = ValueNotifier<bool>(false);
  final hintsUsed = ValueNotifier<int>(0);

  Set<int> _conflicts = const {};
  Set<int> get conflicts => _conflicts;

  late final PebblesBoardComponent boardComponent;

  @override
  Color backgroundColor() => TesseraColors.clay;

  @override
  Future<void> onLoad() async {
    boardComponent = PebblesBoardComponent();
    await add(boardComponent);
    _layout(size);
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

  void tapTile(int cell) {
    if (solved.value) return;
    board.cycle(cell);
    _changed(cell);
  }

  PebblesHint? useHint() {
    if (solved.value) return null;
    final hint = board.hint();
    if (hint == null) return null;
    board.apply(hint);
    hintsUsed.value++;
    _changed(hint.cell);
    return hint;
  }

  void restart() {
    board.reset();
    solved.value = false;
    overlays.remove(solvedOverlay);
    _refresh();
  }

  void _refresh() {
    _conflicts = board.conflicts();
    pebbleCount.value = board.pebbles.length;
  }

  void _changed(int cell) {
    _refresh();
    boardComponent.tileAt(cell).press();
    if (haptics) HapticFeedback.selectionClick();
    if (board.isSolved) {
      solved.value = true;
      if (haptics) HapticFeedback.mediumImpact();
      boardComponent.fire(onComplete: () => overlays.add(solvedOverlay));
    }
  }

  @override
  void onRemove() {
    pebbleCount.dispose();
    solved.dispose();
    hintsUsed.dispose();
    super.onRemove();
  }
}
