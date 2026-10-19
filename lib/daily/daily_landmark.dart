import '../pack/pack_facts.dart';

/// 今日の名所。日付（DailyChallenge と同じ UTC の yyyy-MM-dd）から、問題に使う名所を1つ選ぶ。
/// 同じ日・同じデータなら、どの端末でも同じ名所になる。名所がなければ null。
class DailyLandmark {
  static Landmark? pick(PackFacts? facts, String date) {
    final list = facts?.usable ?? const <Landmark>[];
    if (list.isEmpty) return null;
    var h = 0x811C9DC5; // FNV-1a
    for (final c in date.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0x7FFFFFFF;
    }
    return list[h % list.length];
  }
}
