import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/daily/quiz_invite.dart';
import 'package:terrimap_core/pack/region_pack.dart';
import 'package:terrimap_core/progress/quiz_history.dart';
import 'package:terrimap_core/progress/weekly_goal.dart';
import 'dart:io';

RegionPack de() {
  String r(String f) => File('packs/de/$f').readAsStringSync();
  return RegionPack.parse(packJson: r('pack.json'), regionsJson: r('regions.json'),
      geoJson: r('geo.geojson'), stringsJsonByLang: {'en': r('strings/en.json')});
}

void main() {
  test('QuizInvite: コードの往復と、同じコードから同じ問題', () {
    final pack = de();
    final inv = QuizInvite(packId: pack.packId, seed: 12345, count: 5).withScore(4);
    expect(inv.toCode(), 'TMQ1.${pack.packId}.12345.5.s4');
    final back = QuizInvite.parse('解ける？\n${inv.toCode()}\nどうぞ')!;
    expect([back.packId, back.seed, back.count, back.score], [pack.packId, 12345, 5, 4]);
    expect(back.isValidFor(pack), isTrue);
    final a = inv.questions(pack), b = back.questions(pack);
    expect(a.length, 5);
    expect([for (final q in a) '${q.type}${q.targetId}${q.correctId}'], [for (final q in b) '${q.type}${q.targetId}${q.correctId}']);
  });

  test('QuizInvite: 壊れたコード・範囲外は読まない', () {
    expect(QuizInvite.parse(null), isNull);
    expect(QuizInvite.parse('TMQ1.xx.1.2'), isNull); // 問題数が少なすぎる
    expect(QuizInvite.parse('TMQ1.xx.1.30'), isNull);
    expect(QuizInvite.parse('TMQ1.xx.99999999999.5'), isNull);
    expect(QuizInvite.parse('TMQ1.xx.1.5.s9'), isNull); // 点数が問題数より多い
    expect(QuizInvite.parse('TMI1.xx.normal.a.easy'), isNull);
  });

  test('QuizInvite: 別の国のコードは弾く', () {
    final pack = de();
    expect(QuizInvite(packId: 'other', seed: 1).isValidFor(pack), isFalse);
  });

  test('WeeklyGoal: 今週の出題数で進み具合が決まる', () {
    var h = const QuizHistory();
    for (var i = 0; i < 12; i++) {
      h = h.record('2026-10-19', correct: i.isEven);
    }
    h = h.record('2026-10-01', correct: true); // 今週より前は数えない
    final g = WeeklyGoal.of(h, '2026-10-19', target: 20);
    expect([g.answered, g.reached, g.ratio], [12, false, 0.6]);
    final done = WeeklyGoal.of(h, '2026-10-19', target: 10);
    expect([done.reached, done.shown, done.ratio], [true, 10, 1.0]);
    expect(WeeklyGoal.of(const QuizHistory(), '2026-10-19').answered, 0);
  });
}
