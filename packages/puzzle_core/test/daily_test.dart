import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  test('day key and seed are stable', () {
    final day = PuzzleDay(2026, 11, 11);
    expect(day.key, '2026-11-11');
    expect(day.seed, PuzzleDay(2026, 11, 11).seed);
    expect(day.seed, isNot(PuzzleDay(2026, 11, 12).seed));
    // Pin one value so an accidental change to seeding is caught: changing it
    // would change every player's daily set.
    expect(day.seed, fnv1a32('tessera:2026-11-11'));
  });

  test('local time of day does not change the day', () {
    expect(PuzzleDay.fromLocal(DateTime(2026, 11, 11, 0, 1)),
        PuzzleDay.fromLocal(DateTime(2026, 11, 11, 23, 59)));
  });

  test('difficulty ramps through the week', () {
    // 2026-11-09 is a Monday.
    final week = [
      for (var d = 9; d <= 15; d++) PuzzleDay(2026, 11, d).difficulty
    ];
    expect(week.first, Difficulty.gentle);
    expect(week.last, Difficulty.fierce);
    for (var i = 1; i < week.length; i++) {
      expect(week[i].index, greaterThanOrEqualTo(week[i - 1].index));
    }
  });

  test('tray holds four distinct kinds and is deterministic', () {
    final day = PuzzleDay(2026, 11, 11);
    final tray = DailyTray.forDay(day);
    expect(tray.kinds, hasLength(DailyTray.trayLength));
    expect(tray.kinds.toSet(), hasLength(DailyTray.trayLength));
    expect(DailyTray.forDay(day).kinds, tray.kinds);
  });

  test('SeededRandom sequence is pinned', () {
    final rng = SeededRandom(1);
    expect([rng.nextUint32(), rng.nextUint32(), rng.nextUint32()],
        [270369, 67634689, 2647435461]);
  });
}
