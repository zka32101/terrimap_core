import '../pack/region_pack.dart';
import '../quiz/quiz_engine.dart';

/// 友だちへのクイズ挑戦状。同じ問題（シード）と、自分の点数を短い文字列にして送る。サーバーは使わない。
/// 形: `TMQ1.<packId>.<シード>.<問題数>` ＋ 点数があれば `.s4`。同じコードからは、同じ問題が同じ順で作られる。
class QuizInvite {
  static const minCount = 3, maxCount = 20, defaultCount = 5;
  static const _types = [QuestionType.nameFromMap, QuestionType.capitalFromName];

  final String packId;
  final int seed;
  final int count;
  final int? score; // 送り主の正解数（なければ null）
  const QuizInvite({required this.packId, required this.seed, this.count = defaultCount, this.score});

  QuizInvite withScore(int s) => QuizInvite(packId: packId, seed: seed, count: count, score: s.clamp(0, count));

  String toCode() => 'TMQ1.$packId.$seed.$count${score == null ? '' : '.s$score'}';

  static final _re = RegExp(r'TMQ1\.([a-z0-9_]+)\.(\d{1,10})\.(\d{1,2})(?:\.s(\d{1,2}))?(?![A-Za-z0-9_\-])');

  /// 貼られた文章のどこかにあるコードを読む。なければ null。範囲外の値のコードも null。
  static QuizInvite? parse(String? text) {
    if (text == null) return null;
    final m = _re.firstMatch(text);
    if (m == null) return null;
    final seed = int.parse(m.group(2)!);
    final count = int.parse(m.group(3)!);
    final score = m.group(4) == null ? null : int.parse(m.group(4)!);
    if (seed > 0x7fffffff || count < minCount || count > maxCount) return null;
    if (score != null && score > count) return null;
    return QuizInvite(packId: m.group(1)!, seed: seed, count: count, score: score);
  }

  bool isValidFor(RegionPack pack) => pack.packId == packId;

  List<Question> questions(RegionPack pack) => QuizEngine(pack, seed: seed).generate(count: count, types: _types);

  /// 送る文面。[headline] は「解けるかな？」のような一文。
  String shareText({required String headline, String result = ''}) => [headline, if (result.isNotEmpty) result, toCode()].join('\n');
}
