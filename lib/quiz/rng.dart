/// 端末・OS非依存の決定的乱数(mulberry32)。dart:math Randomは実装依存のため使わない。
class Rng {
  int _s;
  Rng(int seed) : _s = seed & 0xFFFFFFFF;
  int _next() {
    _s = (_s + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _s;
    t = ((t ^ (t >> 15)) * (t | 1)) & 0xFFFFFFFF;
    t = (t ^ ((t ^ (t >> 7)) * (t | 61))) & 0xFFFFFFFF;
    return (t ^ (t >> 14)) & 0xFFFFFFFF;
  }
  /// 0 <= n < max
  int nextInt(int max) => _next() % max;
  List<T> shuffled<T>(Iterable<T> src) {
    final l = src.toList();
    for (var i = l.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final t = l[i]; l[i] = l[j]; l[j] = t;
    }
    return l;
  }
}

/// FNV-1a 32bit。日付+packIdからシード生成用。
int fnv1a(String s) {
  var h = 0x811C9DC5;
  for (final c in s.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}
