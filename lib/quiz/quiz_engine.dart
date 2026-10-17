import '../pack/region_pack.dart';
import 'rng.dart';

enum QuestionType { locateOnMap, nameFromMap, capitalFromName, nameFromCapital }

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
  List<Question> generate({
    required int count,
    required List<QuestionType> types,
    Set<String>? pool,
  }) {
    final all = pack.regions.map((r) => r.id).toList()..sort(); // 順序をpack非依存に固定
    final targets = _rng.shuffled(pool == null ? all : all.where(pool.contains).toList());
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
}
