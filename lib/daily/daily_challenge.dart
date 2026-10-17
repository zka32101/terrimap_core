import '../pack/region_pack.dart';
import '../quiz/quiz_engine.dart';
import '../quiz/rng.dart';

class DailyChallenge {
  static const questionCount = 5;
  /// 日付(yyyy-MM-dd, 端末ローカルでなくUTC基準を推奨)+packIdで全員同一の問題。
  static List<Question> forDate(RegionPack pack, String yyyyMmDd) {
    final seed = fnv1a('$yyyyMmDd|${pack.packId}');
    return QuizEngine(pack, seed: seed).generate(
      count: questionCount,
      types: const [QuestionType.nameFromMap, QuestionType.capitalFromName],
    );
  }

  /// 絵文字共有テキスト。results[i]=true で🟩。
  static String shareText(String appName, String yyyyMmDd, List<bool> results) {
    final score = results.where((e) => e).length;
    final row = results.map((e) => e ? '🟩' : '🟥').join();
    return '$appName $yyyyMmDd $score/${results.length}\n$row';
  }
}
