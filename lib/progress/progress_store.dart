import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the player's [ProgressLog] and writes it to the device after every
/// change, so solves and streaks survive closing the app.
class ProgressStore extends ChangeNotifier {
  ProgressStore._(this._log, this._write);

  /// An unsaved store, for tests and previews.
  ProgressStore.memory([ProgressLog? log])
    : _log = log ?? ProgressLog(),
      _write = null;

  /// Loads the saved log from the device.
  static Future<ProgressStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    var log = ProgressLog();
    final saved = prefs.getString(_key);
    if (saved != null) {
      try {
        log = ProgressLog.fromJson(jsonDecode(saved));
      } on FormatException {
        // Corrupt save: start fresh rather than fail to launch.
      }
    }
    return ProgressStore._(log, (s) => prefs.setString(_key, s));
  }

  static const _key = 'tessera.progress';

  ProgressLog _log;
  final Future<bool> Function(String)? _write;

  ProgressLog get log => _log;

  void recordSolve(PuzzleDay day, PuzzleKind kind, int hints) =>
      _update(_log.recordSolve(day, kind, hints));

  void recordKeystone(PuzzleDay day, KeystoneResult result) =>
      _update(_log.recordKeystone(day, result));

  void _update(ProgressLog next) {
    _log = next;
    notifyListeners();
    _write?.call(jsonEncode(next.toJson()));
  }
}
