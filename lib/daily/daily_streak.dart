import 'dart:convert';

/// 今日のチャレンジの連続記録。日付は DailyChallenge と同じ UTC の yyyy-MM-dd。
/// 保存先はアプリ側（[toJson] / [DailyStreak.fromJson]）。ProgressStoreの形式は変えない。
class DailyStreak {
  final int current;
  final int best;
  final String? lastDate;
  const DailyStreak({this.current = 0, this.best = 0, this.lastDate});

  static DateTime _d(String s) {
    final p = s.split('-').map(int.parse).toList();
    return DateTime.utc(p[0], p[1], p[2]);
  }

  static int _daysBetween(String from, String to) => _d(to).difference(_d(from)).inDays;

  /// [date] のチャレンジを完了した記録。同じ日の再記録・過去日付は変えない。
  DailyStreak record(String date) {
    final last = lastDate;
    if (last != null) {
      final gap = _daysBetween(last, date);
      if (gap <= 0) return this;
      final next = gap == 1 ? current + 1 : 1;
      return DailyStreak(current: next, best: next > best ? next : best, lastDate: date);
    }
    return DailyStreak(current: 1, best: best > 1 ? best : 1, lastDate: date);
  }

  /// 表示用の連続日数。昨日までやっていれば継続中、2日以上空いたら0。
  int currentOn(String today) {
    final last = lastDate;
    if (last == null) return 0;
    final gap = _daysBetween(last, today);
    return gap <= 1 ? current : 0;
  }

  bool doneOn(String date) => lastDate == date;

  String toJson() => jsonEncode({'current': current, 'best': best, 'lastDate': lastDate});

  factory DailyStreak.fromJson(String src) {
    final m = jsonDecode(src) as Map<String, dynamic>;
    return DailyStreak(
      current: (m['current'] as int?) ?? 0,
      best: (m['best'] as int?) ?? 0,
      lastDate: m['lastDate'] as String?,
    );
  }
}
