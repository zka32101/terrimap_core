/// 進捗の保存先インターフェース。実装(Hive等)はアプリ側。regionsは「正解済み」を塗る用。
abstract class ProgressStore {
  Future<Set<String>> mastered(String packId);
  Future<void> markMastered(String packId, String regionId);
  Future<void> recordMiss(String packId, String regionId);
  Future<Map<String, int>> misses(String packId);
}

class InMemoryProgressStore implements ProgressStore {
  final _m = <String, Set<String>>{};
  final _x = <String, Map<String, int>>{};
  @override
  Future<Set<String>> mastered(String p) async => {...?_m[p]};
  @override
  Future<void> markMastered(String p, String r) async => (_m[p] ??= {}).add(r);
  @override
  Future<void> recordMiss(String p, String r) async {
    final m = _x[p] ??= {};
    m[r] = (m[r] ?? 0) + 1;
  }
  @override
  Future<Map<String, int>> misses(String p) async => {...?_x[p]};
}

/// 称号: 習得率から決める(閾値は仮)。
String titleFor(int mastered, int total) {
  final r = total == 0 ? 0 : mastered / total;
  if (r >= 1) return 'master';
  if (r >= 0.75) return 'expert';
  if (r >= 0.4) return 'explorer';
  return 'beginner';
}
