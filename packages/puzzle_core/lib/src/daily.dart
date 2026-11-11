import 'difficulty.dart';
import 'puzzle_kind.dart';
import 'seeded_random.dart';

/// The calendar day a daily set belongs to. Always a plain date, so every
/// player gets the same set regardless of time of day.
class PuzzleDay {
  PuzzleDay(int year, int month, int day)
      : date = DateTime.utc(year, month, day);

  factory PuzzleDay.fromLocal(DateTime local) =>
      PuzzleDay(local.year, local.month, local.day);

  final DateTime date;

  /// `yyyy-mm-dd`.
  String get key => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Base seed for the whole day.
  int get seed => fnv1a32('tessera:$key');

  /// Seed for one puzzle in the day, so changing one type's generator never
  /// reshuffles the others.
  int seedFor(PuzzleKind kind) => fnv1a32('tessera:$key:${kind.name}');

  /// Monday is gentle, the week ramps up, Sunday is fierce.
  Difficulty get difficulty => switch (date.weekday) {
        DateTime.monday || DateTime.tuesday => Difficulty.gentle,
        DateTime.wednesday || DateTime.thursday => Difficulty.steady,
        DateTime.friday || DateTime.saturday => Difficulty.tricky,
        _ => Difficulty.fierce,
      };

  @override
  bool operator ==(Object other) => other is PuzzleDay && other.date == date;

  @override
  int get hashCode => date.hashCode;

  @override
  String toString() => 'PuzzleDay($key)';
}

/// The four puzzles in a day's tray, chosen deterministically from all types.
class DailyTray {
  DailyTray._(this.day, this.kinds);

  factory DailyTray.forDay(PuzzleDay day) {
    final kinds = List.of(PuzzleKind.values);
    SeededRandom(day.seed).shuffle(kinds);
    return DailyTray._(day, List.unmodifiable(kinds.take(trayLength)));
  }

  static const trayLength = 4;

  final PuzzleDay day;
  final List<PuzzleKind> kinds;
}
