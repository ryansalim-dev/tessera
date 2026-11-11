/// A small, fully deterministic PRNG (xorshift32).
///
/// `dart:math`'s `Random(seed)` is not guaranteed to produce the same sequence
/// across SDK versions or platforms. Daily puzzles must be identical for every
/// player worldwide, so generation only ever uses this class.
class SeededRandom {
  SeededRandom(int seed) : _state = _mix(seed);

  int _state;

  static const _mask = 0xFFFFFFFF;

  static int _mix(int seed) {
    final s = seed & _mask;
    return s == 0 ? 0x9E3779B9 : s;
  }

  /// Next unsigned 32-bit value.
  int nextUint32() {
    var x = _state;
    x ^= (x << 13) & _mask;
    x ^= x >> 17;
    x ^= (x << 5) & _mask;
    _state = x & _mask;
    return _state;
  }

  /// Uniform-enough integer in `[0, max)`.
  int nextInt(int max) {
    assert(max > 0);
    return nextUint32() % max;
  }

  /// In-place Fisher-Yates shuffle.
  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}

/// 32-bit FNV-1a hash of [input]. Used to derive stable seeds from strings.
int fnv1a32(String input) {
  var hash = 0x811C9DC5;
  for (final unit in input.codeUnits) {
    hash ^= unit & 0xFF;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
    hash ^= unit >> 8;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}
