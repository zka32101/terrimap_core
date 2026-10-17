import 'dart:math' as math;
import '../pack/region_pack.dart';
import 'rng.dart';

enum QuestionType {
  locateOnMap,
  nameFromMap,
  capitalFromName,
  nameFromCapital,
  /// 形当て: 対象地域だけの輪郭を見せて、名称を4択で答える。
  silhouette,
}

class Question {
  final QuestionType type;
  final String targetId;
  final List<String> choiceIds; // 4択(locateOnMapは空: 地図タップで回答)
  final String correctId;
  const Question(this.type, this.targetId, this.choiceIds, this.correctId);
  bool isCorrect(String answerId) => answerId == correctId;
}

class QuizEngine {
  final RegionPack pack;
  final Rng _rng;
  QuizEngine(this.pack, {required int seed}) : _rng = Rng(seed);

  /// 出題。[pool]で出題対象を絞る(例: 解放済みの地域のみ)。選択肢は全地域から選ぶ。
  /// [weights]を渡すと、重いほど先に出る(復習モード。[reviewWeights]で作る)。
  /// 省略時は従来どおり一様なシャッフル(同seedの出題は変わらない)。
  List<Question> generate({
    required int count,
    required List<QuestionType> types,
    Set<String>? pool,
    Map<String, double>? weights,
  }) {
    final all = pack.regions.map((r) => r.id).toList()..sort(); // 順序をpack非依存に固定
    final base = pool == null ? all : all.where(pool.contains).toList();
    final targets = weights == null ? _rng.shuffled(base) : _weightedOrder(base, weights);
    final out = <Question>[];
    for (var i = 0; i < count && targets.isNotEmpty; i++) {
      final t = targets[i % targets.length];
      final type = types[_rng.nextInt(types.length)];
      if (type == QuestionType.locateOnMap) {
        out.add(Question(type, t, const [], t));
        continue;
      }
      final distract = _rng.shuffled(all.where((x) => x != t)).take(3);
      out.add(Question(type, t, _rng.shuffled([t, ...distract]), t));
    }
    return out;
  }

  /// 重み付きで重複なしの並びを作る(Efraimidis-Spirakis: キー=-ln(u)/w の昇順)。
  List<String> _weightedOrder(List<String> ids, Map<String, double> weights) {
    final keyed = <(double, String)>[
      for (final id in ids) (-math.log(_rng.nextDouble()) / math.max(weights[id] ?? 1.0, 1e-6), id),
    ];
    keyed.sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
    return [for (final k in keyed) k.$2];
  }
}

/// 復習モードの重み。未習得でミスが多い地域ほど重く、習得済みは軽い(間隔を空けて出る)。
/// [mastered]/[misses]は ProgressStore の値をそのまま渡す。
Map<String, double> reviewWeights(Iterable<String> regionIds,
    {required Set<String> mastered, required Map<String, int> misses}) {
  return {
    for (final id in regionIds)
      id: () {
        final m = misses[id] ?? 0;
        return mastered.contains(id) ? 0.25 + 0.25 * math.min(m, 3) : 1.0 + 2.0 * math.min(m, 4);
      }(),
  };
}
