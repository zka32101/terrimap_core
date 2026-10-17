import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/pack/region_pack.dart';
import 'package:terrimap_core/quiz/quiz_engine.dart';
import 'package:terrimap_core/quiz/rng.dart';
import 'package:terrimap_core/daily/daily_challenge.dart';
import 'package:terrimap_core/quiz/difficulty.dart';

RegionPack de() {
  String r(String f) => File('packs/de/$f').readAsStringSync();
  return RegionPack.parse(packJson: r('pack.json'), regionsJson: r('regions.json'),
      geoJson: r('geo.geojson'), stringsJsonByLang: {'en': r('strings/en.json')});
}

void main() {
  silhouetteTests();
  reviewTests();
  difficultyTests();
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

RegionPack us() {
  String r(String f) => File('packs/us/$f').readAsStringSync();
  return RegionPack.parse(packJson: r('pack.json'), regionsJson: r('regions.json'),
      geoJson: r('geo.geojson'), stringsJsonByLang: {'en': r('strings/en.json')});
}

void difficultyTests() {
  for (final (name, pack, big, small) in [
    ('de', de(), 'DE-BY', ['DE-HB', 'DE-HH', 'DE-BE']),
    ('us', us(), 'US-TX', ['US-DC', 'US-RI', 'US-DE']),
  ]) {
    test('難易度 $name: 3分割は重ならず全地域を覆う', () {
      final e = regionsForDifficulty(pack, Difficulty.easy);
      final n = regionsForDifficulty(pack, Difficulty.normal);
      final h = regionsForDifficulty(pack, Difficulty.hard);
      expect(e.intersection(n), isEmpty);
      expect(n.intersection(h), isEmpty);
      expect(e.intersection(h), isEmpty);
      expect({...e, ...n, ...h}, pack.regions.map((r) => r.id).toSet());
      expect([e.length, n.length, h.length].every((x) => x > 0), isTrue);
    });
    test('難易度 $name: 大きい地域はeasy・小さい地域はhard', () {
      expect(regionsForDifficulty(pack, Difficulty.easy), contains(big));
      expect(regionsForDifficulty(pack, Difficulty.hard), containsAll(small));
    });
  }
  test('難易度: poolに渡すと対象の形だけ出る（選択肢は全地域）', () {
    final pool = regionsForDifficulty(de(), Difficulty.hard);
    final qs = QuizEngine(de(), seed: 2).generate(count: 12, types: [QuestionType.silhouette], pool: pool);
    expect(qs.every((q) => pool.contains(q.targetId)), isTrue);
    expect(qs.every((q) => q.choiceIds.length == 4), isTrue);
  });
}

void reviewTests() {
  test('復習: weights省略時は従来と同じ出題', () {
    final a = QuizEngine(de(), seed: 3).generate(count: 8, types: QuestionType.values);
    final b = QuizEngine(de(), seed: 3).generate(count: 8, types: QuestionType.values, weights: null);
    expect([for (final q in a) q.targetId], [for (final q in b) q.targetId]);
  });
  test('復習: 重み付きでも同seedで同じ・重複なし', () {
    final ids = de().regions.map((r) => r.id);
    final w = reviewWeights(ids, mastered: {'DE-BY'}, misses: {'DE-HH': 3});
    final a = QuizEngine(de(), seed: 5).generate(count: 16, types: [QuestionType.nameFromMap], weights: w);
    final b = QuizEngine(de(), seed: 5).generate(count: 16, types: [QuestionType.nameFromMap], weights: w);
    expect([for (final q in a) q.targetId], [for (final q in b) q.targetId]);
    expect({for (final q in a) q.targetId}.length, 16);
  });
  test('復習: ミスの多い地域が先頭に出やすく、習得済みは出にくい', () {
    final ids = de().regions.map((r) => r.id).toList();
    final w = reviewWeights(ids, mastered: {'DE-BY'}, misses: {'DE-HH': 4});
    var hhFirst = 0, byFirst = 0;
    for (var seed = 0; seed < 300; seed++) {
      final f = QuizEngine(de(), seed: seed).generate(count: 1, types: [QuestionType.nameFromMap], weights: w).first.targetId;
      if (f == 'DE-HH') hhFirst++;
      if (f == 'DE-BY') byFirst++;
    }
    expect(hhFirst, greaterThan(300 * 0.25)); // 一様なら約6%
    expect(byFirst, lessThan(300 * 0.03)); // 一様なら約6%
  });
  test('reviewWeights: 値の範囲', () {
    final w = reviewWeights(['a', 'b', 'c', 'd'], mastered: {'b', 'c'}, misses: {'a': 9, 'c': 1});
    expect(w, {'a': 9.0, 'b': 0.25, 'c': 0.5, 'd': 1.0});
  });
}

void silhouetteTests() {
  test('形当て: 4択は重複なしで正解を含み、対象=正解', () {
    final qs = QuizEngine(de(), seed: 3).generate(count: 20, types: [QuestionType.silhouette]);
    expect(qs, hasLength(20));
    for (final q in qs) {
      expect(q.type, QuestionType.silhouette);
      expect(q.choiceIds.toSet().length, 4);
      expect(q.choiceIds, contains(q.correctId));
      expect(q.correctId, q.targetId);
    }
  });
}
