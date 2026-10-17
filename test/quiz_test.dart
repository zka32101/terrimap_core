import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/pack/region_pack.dart';
import 'package:terrimap_core/quiz/quiz_engine.dart';
import 'package:terrimap_core/quiz/rng.dart';
import 'package:terrimap_core/daily/daily_challenge.dart';

RegionPack de() {
  String r(String f) => File('packs/de/$f').readAsStringSync();
  return RegionPack.parse(packJson: r('pack.json'), regionsJson: r('regions.json'),
      geoJson: r('geo.geojson'), stringsJsonByLang: {'en': r('strings/en.json')});
}

void main() {
  test('Rng: Pythonリファレンスと一致', () {
    final g = Rng(12345);
    expect([for (var i = 0; i < 5; i++) g.nextInt(1000)], [904, 523, 393, 292, 857]);
    expect(fnv1a('2026-10-17|jp'), 321860080);
  });
  test('同seedで同じ問題', () {
    final a = QuizEngine(de(), seed: 1).generate(count: 10, types: QuestionType.values);
    final b = QuizEngine(de(), seed: 1).generate(count: 10, types: QuestionType.values);
    expect([for (final q in a) '${q.type}${q.targetId}${q.choiceIds}'],
           [for (final q in b) '${q.type}${q.targetId}${q.choiceIds}']);
  });
  test('4択は重複なしで正解を含む', () {
    for (final q in QuizEngine(de(), seed: 7).generate(count: 30, types: [QuestionType.nameFromMap])) {
      expect(q.choiceIds.toSet().length, 4);
      expect(q.choiceIds, contains(q.correctId));
    }
  });
  test('デイリー共有テキスト', () {
    expect(DailyChallenge.shareText('X', '2026-10-17', [true, false, true, true, false]),
        'X 2026-10-17 3/5\n🟩🟥🟩🟩🟥');
  });
}
