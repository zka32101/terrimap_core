import 'quiz_history.dart';

/// 今週の学習目標（解いた問題数）。履歴から毎回計算するので、保存するのは目標の数だけ。
class WeeklyGoal {
  static const choices = [20, 50, 100];
  static const defaultTarget = 50;

  final int target;
  final int answered; // 今週（今日を含む直近7日）に解いた問題数
  const WeeklyGoal(this.target, this.answered);

  factory WeeklyGoal.of(QuizHistory history, String today, {int target = defaultTarget}) {
    final w = history.weekly(today, weeks: 1).first;
    return WeeklyGoal(target, w.total);
  }

  bool get reached => target > 0 && answered >= target;
  int get shown => answered > target ? target : answered;
  double get ratio => target <= 0 ? 0 : (answered / target).clamp(0.0, 1.0);
}
