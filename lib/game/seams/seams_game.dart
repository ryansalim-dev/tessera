import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter/foundation.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../../theme/tessera_colors.dart';
import '../../juice/juice.dart';
import '../common/effects.dart';
import 'seams_board_component.dart';

/// Flame game for one Seams plate.
///
/// Rules live in `puzzle_core`'s [SeamsBoard]; this class only renders and
/// routes input. The player drags a gold seam out of a shard to its partner.
class SeamsGame extends FlameGame {
  SeamsGame({required this.board, this.haptics = true});

  static const solvedOverlay = 'solved';

  final SeamsBoard board;
  final bool haptics;

  final joined = ValueNotifier<int>(0);
  final solved = ValueNotifier<bool>(false);
  final hintsUsed = ValueNotifier<int>(0);

  late final SeamsBoardComponent boardComponent;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    boardComponent = SeamsBoardComponent();
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

  /// Starts a seam at [cell]. Returns false if there is nothing to draw from.
  bool begin(int cell) {
    if (solved.value) return false;
    final ok = board.begin(cell);
    if (ok) _changed(cell);
    return ok;
  }

  /// Draws the active seam toward [cell], stepping through any tiles in a
  /// straight line so quick swipes along a row work.
  bool extend(int cell) {
    final p = board.active;
    if (solved.value || p == null) return false;
    final seam = board.seam(p);
    if (seam.isEmpty) return false;
    var changed = false;
    if (seam.contains(cell)) {
      changed = board.extend(cell);
    } else {
      for (final c in _straightRun(seam.last, cell)) {
        if (!board.extend(c)) break;
        changed = true;
      }
    }
    if (changed) _changed(cell);
    return changed;
  }

  void end() => board.end();

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

  SeamsHint? useHint() {
    if (solved.value) return null;
    final hint = board.hint();
    if (hint == null) return null;
    board.apply(hint);
    hintsUsed.value++;
    _changed(board.puzzle.seams[hint.pair - 1].last);
    return hint;
  }

  void restart() {
    board.reset();
    solved.value = false;
    overlays.remove(solvedOverlay);
    joined.value = 0;
  }

  void _changed(int cell) {
    final before = joined.value;
    joined.value = board.joinedCount;
    final tile = boardComponent.tileAt(cell)..press();
    if (board.isSolved) {
      board.end();
      solved.value = true;
      if (haptics) Juice.solve();
      boardComponent.fire(onComplete: () => overlays.add(solvedOverlay));
      celebrate(this, size / 2, boardComponent.size.x / 2);
      return;
    }
    if (joined.value > before) {
      if (haptics) Juice.place(step: joined.value * 2);
      boardComponent.add(
        chipPuff(tile.position, TesseraColors.gold, size: tile.size.x),
      );
    } else if (haptics) {
      Juice.tap();
    }
  }

  @override
  void onRemove() {
    joined.dispose();
    solved.dispose();
    hintsUsed.dispose();
    super.onRemove();
  }
}
