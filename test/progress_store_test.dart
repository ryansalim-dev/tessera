import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tessera/progress/progress_store.dart';

void main() {
  final day = PuzzleDay(2026, 11, 11);

  test('solves and the keystone survive reopening the app', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await ProgressStore.open();
    first
      ..recordSolve(day, PuzzleKind.glaze, 0)
      ..recordKeystone(day, const KeystoneResult(gold: true, hints: 0));
    // Let the write finish.
    await Future<void>.delayed(Duration.zero);

    final second = await ProgressStore.open();
    expect(second.log.dayOf(day).solved, {PuzzleKind.glaze: 0});
    expect(second.log.dayOf(day).keystone!.gold, isTrue);
    expect(second.log.currentStreak(day), 1);
  });

  test('a corrupt save starts fresh instead of crashing', () async {
    SharedPreferences.setMockInitialValues({'tessera.progress': '{nope'});
    final store = await ProgressStore.open();
    expect(store.log.days, isEmpty);
  });
}
