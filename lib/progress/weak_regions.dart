/// 苦手な州（よく間違える州）。
class WeakRegion {
  final String id;
  final int misses;
  final bool mastered; // 一度でも正解して習得済みか
  const WeakRegion(this.id, this.misses, this.mastered);
}

class WeakRegions {
  /// 間違えた回数の多い順。まだ習得していない州を先に、習得済みはそのあと。同数は id 順。
  /// [regionIds] に含まれない id と、間違えていない州は出さない。
  static List<WeakRegion> rank(Map<String, int> misses, Set<String> mastered, Iterable<String> regionIds, {int limit = 5}) {
    final ids = regionIds.toSet();
    final list = [
      for (final e in misses.entries)
        if (e.value > 0 && ids.contains(e.key)) WeakRegion(e.key, e.value, mastered.contains(e.key)),
    ]..sort((a, b) {
        if (a.mastered != b.mastered) return a.mastered ? 1 : -1;
        final c = b.misses.compareTo(a.misses);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    return list.take(limit).toList();
  }
}
