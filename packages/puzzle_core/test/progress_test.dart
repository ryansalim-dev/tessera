import 'dart:convert';

import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  final nov11 = PuzzleDay(2026, 11, 11);
  PuzzleDay nov(int d) => PuzzleDay(2026, 11, d);

  ProgressLog played(Iterable<int> novDays) {
    var log = ProgressLog();
    for (final d in novDays) {
      log = log.recordSolve(nov(d), PuzzleKind.glaze, 0);
    }
    return log;
  }

  test('empty log has no streak', () {
    expect(ProgressLog().currentStreak(nov11), 0);
    expect(ProgressLog().bestStreak(), 0);
  });

  test('streak counts consecutive days ending today', () {
    expect(played([9, 10, 11]).currentStreak(nov11), 3);
  });

  test('streak stays alive until today is over', () {
    expect(played([9, 10]).currentStreak(nov11), 2);
  });

  test('a missed day breaks the streak', () {
    expect(played([7, 8, 10, 11]).currentStreak(nov11), 2);
    expect(played([7, 8, 9]).currentStreak(nov11), 0);
  });

  test('best streak is the longest run, across month ends', () {
    var log = played([1, 2, 3, 4, 8, 9]);
    log = log
        .recordSolve(PuzzleDay(2026, 10, 30), PuzzleKind.seams, 1)
        .recordSolve(PuzzleDay(2026, 10, 31), PuzzleKind.seams, 1);
    expect(log.bestStreak(), 6);
  });

  test('keystone alone keeps the streak', () {
    final log = ProgressLog()
        .recordKeystone(nov11, const KeystoneResult(gold: false, hints: 2));
    expect(log.currentStreak(nov11), 1);
  });

  test('first solve of a kind is kept', () {
    final log = ProgressLog()
        .recordSolve(nov11, PuzzleKind.glaze, 0)
        .recordSolve(nov11, PuzzleKind.glaze, 3);
    expect(log.dayOf(nov11).solved[PuzzleKind.glaze], 0);
  });

  test('a gold keystone is never downgraded', () {
    final log = ProgressLog()
        .recordKeystone(nov11, const KeystoneResult(gold: false, hints: 1))
        .recordKeystone(nov11, const KeystoneResult(gold: true, hints: 0))
        .recordKeystone(nov11, const KeystoneResult(gold: false, hints: 4));
    expect(log.dayOf(nov11).keystone!.gold, isTrue);
  });

  test('week strip is the last seven days, oldest first', () {
    final week = played([5, 11]).week(nov11);
    expect(
        week.map((e) => e.$1.key), [for (var d = 5; d <= 11; d++) nov(d).key]);
    expect(week.map((e) => e.$2.counts),
        [true, false, false, false, false, false, true]);
  });

  test('round-trips through JSON', () {
    final log = played([10, 11])
        .recordSolve(nov11, PuzzleKind.shards, 2)
        .recordKeystone(nov11, const KeystoneResult(gold: true, hints: 0));
    final back = ProgressLog.fromJson(jsonDecode(jsonEncode(log.toJson())));
    expect(back.currentStreak(nov11), 2);
    expect(
        back.dayOf(nov11).solved, {PuzzleKind.glaze: 0, PuzzleKind.shards: 2});
    expect(back.dayOf(nov11).keystone!.gold, isTrue);
  });

  test('bad or unknown saved data gives an empty log', () {
    expect(ProgressLog.fromJson(null).days, isEmpty);
    expect(ProgressLog.fromJson('nope').days, isEmpty);
    expect(ProgressLog.fromJson({'version': 99, 'days': {}}).days, isEmpty);
    final log = ProgressLog.fromJson({
      'version': ProgressLog.version,
      'days': {
        'not-a-date': {'solved': {}},
        '2026-11-11': {
          'solved': {'glaze': 0, 'retiredType': 1},
        },
      },
    });
    expect(log.days.keys, ['2026-11-11']);
    expect(log.dayOf(nov11).solved, {PuzzleKind.glaze: 0});
  });
}
