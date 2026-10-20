import 'dart:math' as math;
import '../pack/pack_facts.dart';
import '../pack/region_pack.dart';
import 'rng.dart';

enum QuestionType {
  locateOnMap,
  nameFromMap,
  capitalFromName,
  nameFromCapital,
  /// 形当て: 対象地域だけの輪郭を見せて、名称を4択で答える。
  silhouette,
  /// 隣接: 対象の地域と**接している**地域を4択で答える（正解は隣の地域のうち1つ。誤答は接していない地域）。
  /// 隣のない地域（飛び地の州など）は、この問題にならず、地図から州名の問題になる。
  neighborOf,
  /// 名所: 「この名所はどの州にある？」を4択で答える（名所は `packs/<国>/facts.json`）。名所のデータがない州は、地図から州名の問題になる。
  landmarkOf,

  /// 深い知識: 「この名物・特産品・企業・行事はどの州のもの？」を4択で答える（題材は `facts.json` の `knowledge`）。
  /// 題材のない州は、地図から州名の問題になる。
  knowledgeOf,
}

class Question {
  final QuestionType type;
  final String targetId;
  final List<String> choiceIds; // 4択(locateOnMapは空: 地図タップで回答)
  final String correctId;
  /// 問題の題材の id（名所の問題では名所の id。なければ null）。
  final String? subjectId;
  const Question(this.type, this.targetId, this.choiceIds, this.correctId, {this.subjectId});
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
      if (type == QuestionType.landmarkOf) {
        final marks = pack.facts?.inRegion(t) ?? const <Landmark>[];
        if (marks.isNotEmpty) {
          final ordered = [...marks]..sort((a, b) => a.id.compareTo(b.id));
          final lm = ordered[_rng.nextInt(ordered.length)];
          final distract = _rng.shuffled(all.where((x) => x != t)).take(3);
          out.add(Question(type, t, _rng.shuffled([t, ...distract]), t, subjectId: lm.id));
          continue;
        }
        final distract = _rng.shuffled(all.where((x) => x != t)).take(3);
        out.add(Question(QuestionType.nameFromMap, t, _rng.shuffled([t, ...distract]), t));
        continue;
      }
      if (type == QuestionType.knowledgeOf) {
        final items = pack.facts?.knowledgeIn(t) ?? const <KnowledgeItem>[];
        final distract = _rng.shuffled(all.where((x) => x != t)).take(3);
        if (items.isNotEmpty) {
          final ordered = [...items]..sort((a, b) => a.id.compareTo(b.id));
          final it = ordered[_rng.nextInt(ordered.length)];
          out.add(Question(type, t, _rng.shuffled([t, ...distract]), t, subjectId: it.id));
        } else {
          out.add(Question(QuestionType.nameFromMap, t, _rng.shuffled([t, ...distract]), t));
        }
        continue;
      }
      if (type == QuestionType.neighborOf) {
        final nb = _neighbors(t, all);
        if (nb.isNotEmpty) {
          final correct = nb[_rng.nextInt(nb.length)];
          out.add(Question(type, t, _rng.shuffled([correct, ..._farOnes(t, nb, all)]), correct));
          continue;
        }
        // 隣がない地域は、地図から州名の問題にする
        final distract = _rng.shuffled(all.where((x) => x != t)).take(3);
        out.add(Question(QuestionType.nameFromMap, t, _rng.shuffled([t, ...distract]), t));
        continue;
      }
      final distract = _rng.shuffled(all.where((x) => x != t)).take(3);
      out.add(Question(type, t, _rng.shuffled([t, ...distract]), t));
    }
    return out;
  }

  /// 地域 [id] の隣（packのデータにある地域だけ。並びは固定）。
  List<String> _neighbors(String id, List<String> all) {
    final set = all.toSet();
    final r = pack.regions.where((x) => x.id == id);
    return r.isEmpty ? const [] : ([for (final n in r.first.neighbors) if (set.contains(n)) n]..sort());
  }

  /// 隣接の問題の誤答 3 つ。隣ではなく、**隣と2つ以上共通の隣をもつ地域**（角で接するだけ・水域をはさむ等で紛らわしい地域）も避ける。
  /// 足りなければ、隣でない地域から補う。
  List<String> _farOnes(String t, List<String> nb, List<String> all) {
    final nbSet = nb.toSet();
    final mine = nbSet;
    bool confusing(String x) {
      final other = _neighbors(x, all).toSet();
      return other.intersection(mine).length >= 2;
    }
    final notNeighbor = all.where((x) => x != t && !nbSet.contains(x)).toList();
    final clear = notNeighbor.where((x) => !confusing(x)).toList();
    final pool = clear.length >= 3 ? clear : notNeighbor;
    return _rng.shuffled(pool).take(3).toList();
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
