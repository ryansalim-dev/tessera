import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../../theme/tessera_colors.dart';
import 'cutouts_components.dart';

/// Flame game for one Cutouts puzzle.
///
/// Shows the folding story across the top (each fold, then the stamps on
/// the folded sheet) and the four unfolded candidates below. Rules live in
/// `puzzle_core`'s [CutoutsBoard].
class CutoutsGame extends FlameGame {
  CutoutsGame({required this.board, this.haptics = true});

  static const solvedOverlay = 'solved';

  final CutoutsBoard board;
  final bool haptics;

  final solved = ValueNotifier<bool>(false);
  final hintsUsed = ValueNotifier<int>(0);
  final mistakes = ValueNotifier<int>(0);

  final List<SheetStageComponent> stages = [];
  final List<OptionComponent> options = [];

  @override
  Color backgroundColor() => TesseraColors.clay;

  @override
  Future<void> onLoad() async {
    final p = board.puzzle;
    for (var i = 0; i <= p.folds.length; i++) {
      stages.add(SheetStageComponent(i));
    }
    for (var i = 0; i < p.options.length; i++) {
      options.add(OptionComponent(i));
    }
    await addAll([...stages, ...options]);
    _layout(size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _layout(size);
  }

  static const _gap = 12.0;

  void _layout(Vector2 size) {
    final n = stages.length;
    final stage = math.max(
      0.0,
      math.min((size.x - (n + 1) * _gap) / n, size.y * 0.24),
    );
    final stripW = n * stage + (n - 1) * _gap;
    for (var i = 0; i < n; i++) {
      stages[i]
        ..size = Vector2.all(stage)
        ..position = Vector2((size.x - stripW) / 2 + i * (stage + _gap), _gap);
    }
    final top = stage + 3 * _gap;
    final option = math.max(
      0.0,
      math.min((size.x - 3 * _gap) / 2, (size.y - top - 2 * _gap) / 2),
    );
    final gridW = 2 * option + _gap;
    for (var i = 0; i < options.length; i++) {
      options[i]
        ..size = Vector2.all(option)
        ..position = Vector2(
          (size.x - gridW) / 2 + (i % 2) * (option + _gap) + option / 2,
          top + (i ~/ 2) * (option + _gap) + option / 2,
        );
    }
  }

  /// Picks [option]. Returns true if it was the real result.
  bool pick(int option) {
    if (solved.value || board.ruledOut.contains(option)) return false;
    final right = board.pick(option);
    options[option].press();
    mistakes.value = board.mistakes;
    if (right) {
      solved.value = true;
      if (haptics) HapticFeedback.mediumImpact();
      options[option].fire(onComplete: () => overlays.add(solvedOverlay));
    } else if (haptics) {
      HapticFeedback.heavyImpact();
    }
    return right;
  }

  int? useHint() {
    if (solved.value) return null;
    final h = board.hint();
    if (h == null) return null;
    board.apply(h);
    hintsUsed.value++;
    options[h].press();
    if (haptics) HapticFeedback.selectionClick();
    return h;
  }

  void restart() {
    board.reset();
    solved.value = false;
    mistakes.value = 0;
    overlays.remove(solvedOverlay);
  }

  @override
  void onRemove() {
    solved.dispose();
    hintsUsed.dispose();
    mistakes.dispose();
    super.onRemove();
  }
}
