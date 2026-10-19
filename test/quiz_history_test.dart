import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/progress/quiz_history.dart';
import 'package:terrimap_core/progress/weak_regions.dart';

void main() {
  test('日ごとに数え、週ごとの正答率を出す（古い週から。最後の週は今日を含む7日間）', () {
    var h = const QuizHistory();
    h = h.record('2026-10-19', correct: true).record('2026-10-19', correct: false).record('2026-10-13', correct: true); // 今週
    h = h.record('2026-10-12', correct: true); // 先週（10/6〜10/12）
    final w = h.weekly('2026-10-19', weeks: 3);
    expect(w.length, 3);
    expect((w.last.start, w.last.correct, w.last.total, w.last.accuracyPercent), ('2026-10-13', 2, 3, 67));
    expect((w[1].start, w[1].correct, w[1].total, w[1].accuracyPercent), ('2026-10-06', 1, 1, 100));
    expect(w.first.total, 0);
    expect(w.first.accuracyPercent, isNull); // 出題のない週は null
    expect(h.totalAnswers, 4);
  });

  test('元のインスタンスは変わらない。保存・復元できる。壊れた保存は空として扱う', () {
    const h0 = QuizHistory();
    final h1 = h0.record('2026-10-19', correct: true);
    expect(h0.totalAnswers, 0);
    final back = QuizHistory.fromJsonString(h1.toJsonString());
    expect(back.totalAnswers, 1);
    expect(QuizHistory.fromJsonString('xxx').totalAnswers, 0);
    expect(QuizHistory.fromJsonString(null).totalAnswers, 0);
  });

  test('84日より古い日は捨てる', () {
    final h = const QuizHistory().record('2026-01-01', correct: true).record('2026-10-19', correct: true);
    expect(h.totalAnswers, 1);
  });

  test('苦手な州: 未習得を先に、間違いの多い順。間違えていない州と対象外の id は出さない', () {
    final r = WeakRegions.rank({'A': 3, 'B': 5, 'C': 1, 'D': 0, 'X': 9}, {'B'}, ['A', 'B', 'C', 'D'], limit: 5);
    expect([for (final e in r) e.id], ['A', 'C', 'B']); // B は習得済みなので後ろ
    expect(r.last.mastered, true);
    expect(WeakRegions.rank({'A': 3, 'C': 3}, {}, ['A', 'C']).map((e) => e.id).toList(), ['A', 'C']); // 同数は id 順
    expect(WeakRegions.rank({'A': 1, 'B': 2, 'C': 3}, {}, ['A', 'B', 'C'], limit: 2).length, 2);
  });
}
