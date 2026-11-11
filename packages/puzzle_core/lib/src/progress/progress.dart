import '../daily.dart';
import '../puzzle_kind.dart';

/// What the player finished on one day: tray puzzles (with the hints each
/// took) and the keystone.
class DayRecord {
  const DayRecord({this.solved = const {}, this.keystone});

  /// Tray puzzles solved that day, mapped to the hints used.
  final Map<PuzzleKind, int> solved;

  /// The keystone result, or null if it was not set that day.
  final KeystoneResult? keystone;

  /// A day counts toward the streak once any daily puzzle is fired.
  bool get counts => solved.isNotEmpty || keystone != null;

  DayRecord withSolved(PuzzleKind kind, int hints) => solved.containsKey(kind)
      ? this
      : DayRecord(solved: {...solved, kind: hints}, keystone: keystone);

  /// Keeps the better result if the keystone is set more than once.
  DayRecord withKeystone(KeystoneResult result) {
    final old = keystone;
    if (old != null && (old.gold || !result.gold)) return this;
    return DayRecord(solved: solved, keystone: result);
  }

  Map<String, Object?> toJson() => {
        'solved': {for (final e in solved.entries) e.key.name: e.value},
        if (keystone != null) 'keystone': keystone!.toJson(),
      };

  factory DayRecord.fromJson(Map<String, Object?> json) {
    final solved = <PuzzleKind, int>{};
    final raw = json['solved'];
    if (raw is Map) {
      for (final e in raw.entries) {
        // Skip types a later build removed or renamed.
        final kind = _kindByName[e.key];
        if (kind != null && e.value is int) solved[kind] = e.value as int;
      }
    }
    final k = json['keystone'];
    return DayRecord(
      solved: solved,
      keystone: k is Map ? KeystoneResult.fromJson(k.cast()) : null,
    );
  }

  static final _kindByName = {for (final k in PuzzleKind.values) k.name: k};
}

class KeystoneResult {
  const KeystoneResult({required this.gold, required this.hints});

  /// Set with every clue collected and no hints.
  final bool gold;
  final int hints;

  Map<String, Object?> toJson() => {'gold': gold, 'hints': hints};

  factory KeystoneResult.fromJson(Map<String, Object?> json) => KeystoneResult(
        gold: json['gold'] == true,
        hints: json['hints'] is int ? json['hints'] as int : 0,
      );
}

/// Every day's record, keyed by [PuzzleDay.key], plus streak maths.
///
/// Immutable: each change returns a new log, which the app then saves.
class ProgressLog {
  ProgressLog([Map<String, DayRecord> days = const {}])
      : days = Map.unmodifiable(days);

  /// Bump when the stored shape changes incompatibly.
  static const version = 1;

  final Map<String, DayRecord> days;

  DayRecord dayOf(PuzzleDay day) => days[day.key] ?? const DayRecord();

  ProgressLog recordSolve(PuzzleDay day, PuzzleKind kind, int hints) =>
      _with(day, dayOf(day).withSolved(kind, hints));

  ProgressLog recordKeystone(PuzzleDay day, KeystoneResult result) =>
      _with(day, dayOf(day).withKeystone(result));

  ProgressLog _with(PuzzleDay day, DayRecord record) =>
      ProgressLog({...days, day.key: record});

  bool counts(PuzzleDay day) => days[day.key]?.counts ?? false;

  /// Consecutive counted days ending today. If today is not done yet the
  /// streak is still alive and ends yesterday instead.
  int currentStreak(PuzzleDay today) {
    var d = counts(today) ? today : _shift(today, -1);
    var n = 0;
    while (counts(d)) {
      n++;
      d = _shift(d, -1);
    }
    return n;
  }

  /// The longest run of counted days ever.
  int bestStreak() {
    final dates = [
      for (final e in days.entries)
        if (e.value.counts) DateTime.parse(e.key),
    ]..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final d in dates) {
      run = prev != null && d.difference(prev).inDays == 1 ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }

  /// The seven days ending [today], oldest first, for the week strip.
  List<(PuzzleDay, DayRecord)> week(PuzzleDay today) => [
        for (var i = 6; i >= 0; i--)
          (_shift(today, -i), dayOf(_shift(today, -i))),
      ];

  static PuzzleDay _shift(PuzzleDay day, int days) {
    // UTC dates, so adding days never trips over daylight saving.
    final d = day.date.add(Duration(days: days));
    return PuzzleDay(d.year, d.month, d.day);
  }

  Map<String, Object?> toJson() => {
        'version': version,
        'days': {for (final e in days.entries) e.key: e.value.toJson()},
      };

  /// Reads a saved log. Anything unreadable gives an empty log rather than a
  /// crash on launch.
  factory ProgressLog.fromJson(Object? json) {
    if (json is! Map || json['version'] != version) return ProgressLog();
    final raw = json['days'];
    if (raw is! Map) return ProgressLog();
    final days = <String, DayRecord>{};
    for (final e in raw.entries) {
      if (e.key is String &&
          e.value is Map &&
          DateTime.tryParse(e.key as String) != null) {
        days[e.key as String] =
            DayRecord.fromJson((e.value as Map).cast<String, Object?>());
      }
    }
    return ProgressLog(days);
  }
}
