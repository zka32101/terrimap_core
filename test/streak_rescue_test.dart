import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/daily/daily_streak.dart';
import 'package:terrimap_core/daily/streak_rescue.dart';

void main() {
  final s = const DailyStreak().record('2026-10-17').record('2026-10-18'); // 昨日までの2日連続
  final morning = DateTime(2026, 10, 19, 9);

  test('昨日まで続いていて今日がまだなら、今日の21時に知らせる', () {
    expect(StreakRescue.plan(streak: s, today: '2026-10-19', nowLocal: morning), DateTime(2026, 10, 19, 21));
    expect(StreakRescue.plan(streak: s, today: '2026-10-19', nowLocal: morning, hour: 19), DateTime(2026, 10, 19, 19));
  });

  test('今日済み・連続が切れた・まだ始めていない・時刻を過ぎた、では知らせない', () {
    expect(StreakRescue.plan(streak: s.record('2026-10-19'), today: '2026-10-19', nowLocal: morning), isNull);
    expect(StreakRescue.plan(streak: s, today: '2026-10-21', nowLocal: DateTime(2026, 10, 21, 9)), isNull); // 2日空いた
    expect(StreakRescue.plan(streak: const DailyStreak(), today: '2026-10-19', nowLocal: morning), isNull);
    expect(StreakRescue.plan(streak: s, today: '2026-10-19', nowLocal: DateTime(2026, 10, 19, 22)), isNull);
  });
}
