import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter/foundation.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../../juice/juice.dart';
import '../common/effects.dart';
import 'kiln_path_board_component.dart';

/// Flame game for one Kiln Path board.
///
/// Rules live in `puzzle_core`'s [KilnPathBoard]; this class only renders and
/// routes input. The player drags the firing line out of checkpoint 1; going
/// back over the line cuts it. Flutter widgets talk to it through the
/// notifiers below and the public actions ([moveTo], [undo], [useHint],
/// [restart]).
class KilnPathGame extends FlameGame {
  KilnPathGame({required this.board, this.haptics = true});

  static const solvedOverlay = 'solved';

  final KilnPathBoard board;
  final bool haptics;

  /// Cells on the line, for the progress label.
  final lineLength = ValueNotifier<int>(1);
  final solved = ValueNotifier<bool>(false);
  final hintsUsed = ValueNotifier<int>(0);

  late final KilnPathBoardComponent boardComponent;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    boardComponent = KilnPathBoardComponent();
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

  /// Moves the head toward [cell]. A cell in a straight, clear line from the
  /// head is reached step by step, so a quick swipe along a row works; a cell
  /// already on the line cuts it back there.
  bool moveTo(int cell) {
    if (solved.value) return false;
    final before = board.length;
    if (board.contains(cell)) {
      board.moveTo(cell);
    } else {
      for (final c in _straightRun(board.head, cell)) {
        if (!board.moveTo(c)) break;
      }
    }
    if (board.length == before) return false;
    _changed();
    return true;
  }

  /// Cells from just after [from] to [to] when they share a row or column.
  List<int> _straightRun(int from, int to) {
    final n = board.size;
    final fr = from ~/ n, fc = from % n, tr = to ~/ n, tc = to % n;
    if (fr != tr && fc != tc) return [to];
    final dr = (tr - fr).sign, dc = (tc - fc).sign;
    final run = <int>[];
    var r = fr, c = fc;
    while (r != tr || c != tc) {
      r += dr;
      c += dc;
      run.add(r * n + c);
    }
    return run;
  }

  bool undo() {
    if (solved.value || !board.undo()) return false;
    _changed();
    return true;
  }

  KilnPathHint? useHint() {
    if (solved.value) return null;
    final hint = board.hint();
    if (hint == null) return null;
    board.apply(hint);
    hintsUsed.value++;
    _changed();
    return hint;
  }

  void restart() {
    board.reset();
    solved.value = false;
    overlays.remove(solvedOverlay);
    lineLength.value = board.length;
  }

  void _changed() {
    final grew = board.length > lineLength.value;
    lineLength.value = board.length;
    boardComponent.tileAt(board.head).press();
    if (board.isSolved) {
      solved.value = true;
      if (haptics) Juice.solve();
      boardComponent.fire(onComplete: () => overlays.add(solvedOverlay));
      celebrate(this, size / 2, boardComponent.size.x / 2);
      return;
    }
    if (!haptics) return;
    if (grew) {
      Juice.place(step: board.length);
    } else {
      Juice.erase();
    }
  }

  @override
  void onRemove() {
    lineLength.dispose();
    solved.dispose();
    hintsUsed.dispose();
    super.onRemove();
  }
}
