import 'dart:convert';

/// 1週間ぶんのクイズの結果。
class WeekSummary {
  final String start; // その週（7日間）の最初の日 yyyy-MM-dd
  final int correct, total;
  const WeekSummary(this.start, this.correct, this.total);

  /// 正答率（%）。出題がなければ null。
  int? get accuracyPercent => total == 0 ? null : (correct * 100 / total).round();
}

/// クイズの日ごとの結果（学習の進み具合のグラフ用）。不変で、[record] は新しいインスタンスを返す。
/// 日付は DailyChallenge と同じ UTC の yyyy-MM-dd。古い日は [keepDays] 日を超えたら捨てる。
class QuizHistory {
  static const keepDays = 84; // 12週間
  final Map<String, List<int>> _days; // 日付 -> [正解数, 出題数]
  const QuizHistory._(this._days);
  const QuizHistory() : _days = const {};

  static DateTime _d(String s) {
    final p = s.split('-').map(int.parse).toList();
    return DateTime.utc(p[0], p[1], p[2]);
  }

  static String _s(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int get totalAnswers => _days.values.fold(0, (a, v) => a + v[1]);

  QuizHistory record(String date, {required bool correct}) {
    final next = {for (final e in _days.entries) e.key: [...e.value]};
    final v = next[date] ??= [0, 0];
    v[1]++;
    if (correct) v[0]++;
    final cutoff = _s(_d(date).subtract(const Duration(days: keepDays - 1)));
    next.removeWhere((k, _) => k.compareTo(cutoff) < 0);
    return QuizHistory._(next);
  }

  /// [today] で終わる直近 [weeks] 週の、週ごとの結果（古い週から）。最後の週は [today] を含む7日間。
  List<WeekSummary> weekly(String today, {int weeks = 8}) {
    final end = _d(today);
    final out = <WeekSummary>[];
    for (var w = weeks - 1; w >= 0; w--) {
      final last = end.subtract(Duration(days: 7 * w));
      final first = last.subtract(const Duration(days: 6));
      var c = 0, t = 0;
      for (var i = 0; i < 7; i++) {
        final v = _days[_s(first.add(Duration(days: i)))];
        if (v != null) {
          c += v[0];
          t += v[1];
        }
      }
      out.add(WeekSummary(_s(first), c, t));
    }
    return out;
  }

  String toJsonString() => jsonEncode(_days);

  factory QuizHistory.fromJsonString(String? s) {
    if (s == null) return const QuizHistory();
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return QuizHistory._({
        for (final e in m.entries) e.key: [for (final n in e.value as List) n as int],
      });
    } catch (_) {
      return const QuizHistory();
    }
  }
}
