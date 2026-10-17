import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/daily/daily_streak.dart';

void main() {
  test('連続して増える・同日は変わらない', () {
    var s = const DailyStreak();
    s = s.record('2026-10-17');
    expect((s.current, s.best), (1, 1));
    expect(s.record('2026-10-17').current, 1);
    s = s.record('2026-10-18').record('2026-10-19');
    expect((s.current, s.best, s.lastDate), (3, 3, '2026-10-19'));
  });
  test('月・年またぎも連続', () {
    final s = const DailyStreak().record('2026-12-31').record('2027-01-01');
    expect(s.current, 2);
    expect(const DailyStreak().record('2028-02-28').record('2028-02-29').record('2028-03-01').current, 3);
  });
  test('空いたら1に戻り、最長は残る', () {
    final s = const DailyStreak().record('2026-10-01').record('2026-10-02').record('2026-10-05');
    expect((s.current, s.best), (1, 2));
  });
  test('過去日付は無視', () {
    final s = const DailyStreak().record('2026-10-10').record('2026-10-05');
    expect((s.current, s.lastDate), (1, '2026-10-10'));
  });
  test('currentOn: 昨日まで継続中なら表示、2日空いたら0', () {
    final s = const DailyStreak().record('2026-10-16').record('2026-10-17');
    expect(s.currentOn('2026-10-17'), 2);
    expect(s.currentOn('2026-10-18'), 2);
    expect(s.currentOn('2026-10-19'), 0);
    expect(const DailyStreak().currentOn('2026-10-19'), 0);
    expect(s.doneOn('2026-10-17'), isTrue);
    expect(s.doneOn('2026-10-18'), isFalse);
  });
  test('JSON往復・欠けた項目は0', () {
    final s = const DailyStreak().record('2026-10-16').record('2026-10-17');
    final r = DailyStreak.fromJson(s.toJson());
    expect((r.current, r.best, r.lastDate), (2, 2, '2026-10-17'));
    expect(DailyStreak.fromJson('{}').current, 0);
  });
}
