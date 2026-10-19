import 'daily_streak.dart';

/// 連続記録が途切れそうな日の夕方の通知（ストリーク救済）。
/// 今日のチャレンジがまだで、連続日数が1以上なら、今日の [hour] 時に知らせる。
/// 時刻が過ぎている・連続が切れている・今日すでに済ませていれば null。
class StreakRescue {
  static const defaultHour = 21;

  /// [today] はチャレンジと同じ yyyy-MM-dd、[nowLocal] は端末の現在時刻。
  /// 返す時刻は端末の日付の [hour]:00（日付の食い違いは、通知を出す側で今日として扱う）。
  static DateTime? plan({required DailyStreak streak, required String today, required DateTime nowLocal, int hour = defaultHour}) {
    if (streak.currentOn(today) <= 0 || streak.doneOn(today)) return null;
    final at = DateTime(nowLocal.year, nowLocal.month, nowLocal.day, hour);
    return at.isAfter(nowLocal) ? at : null;
  }
}
