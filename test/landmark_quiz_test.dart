import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/pack/pack_facts.dart';
import 'package:terrimap_core/pack/region_pack.dart';
import 'package:terrimap_core/quiz/quiz_engine.dart';

RegionPack load(String id, {bool facts = true}) {
  String r(String f) => File('packs/$id/$f').readAsStringSync();
  return RegionPack.parse(
      packJson: r('pack.json'),
      regionsJson: r('regions.json'),
      geoJson: r('geo.geojson'),
      stringsJsonByLang: {'en': r('strings/en.json')},
      factsJson: facts ? r('facts.json') : null);
}

void main() {
  for (final c in ['de', 'us']) {
    final pack = load(c);
    final ids = {for (final r in pack.regions) r.id};

    test('$c: facts.json は検査を通り、名所の州は実在する。英語の名前がある', () {
      final f = pack.facts!;
      expect(f.validate(ids), isEmpty);
      expect(f.landmarks.length, greaterThan(15));
      for (final l in f.landmarks) {
        expect(l.name['en'], isNotEmpty);
        expect(l.nameIn('xx'), l.name['en']); // 言語がなければ英語
      }
    });

    test('$c: 名所の問題 — 正解は名所のある州、選択肢は4つで重複なし。題材（名所）の id が付く', () {
      final qs = QuizEngine(pack, seed: 5).generate(count: 400, types: const [QuestionType.landmarkOf]);
      var asked = 0;
      for (final q in qs) {
        if (q.type != QuestionType.landmarkOf) {
          expect(q.type, QuestionType.nameFromMap); // 名所のない州は地図からの問題
          expect(pack.facts!.inRegion(q.targetId), isEmpty);
          continue;
        }
        asked++;
        final lm = pack.facts!.landmarks.firstWhere((l) => l.id == q.subjectId);
        expect(lm.regionId, q.correctId);
        expect(q.targetId, q.correctId);
        expect(q.choiceIds.length, 4);
        expect(q.choiceIds.toSet().length, 4);
        expect(q.choiceIds, contains(q.correctId));
      }
      expect(asked, greaterThan(100));
    });
  }

  test('名所のデータがない pack では、名所の問題は出ず、地図からの問題になる', () {
    final pack = load('de', facts: false);
    expect(pack.facts, isNull);
    final qs = QuizEngine(pack, seed: 1).generate(count: 30, types: const [QuestionType.landmarkOf]);
    expect(qs.every((q) => q.type == QuestionType.nameFromMap && q.subjectId == null), true);
  });

  test('use が false の名所は問題に使われない。検査は不正なデータを見つける', () {
    const json = '{"v":1,"landmarks":['
        '{"id":"a","region":"DE-BY","name":{"en":"A"},"use":false},'
        '{"id":"b","region":"DE-BY","name":{"en":"B"}}]}';
    final f = PackFacts.parse(json);
    expect(f.inRegion('DE-BY').map((l) => l.id), ['b']);
    final bad = PackFacts.parse('{"v":1,"landmarks":['
        '{"id":"a","region":"XX","name":{"en":"A"}},'
        '{"id":"a","region":"DE-BY","name":{"de":"A"}},'
        '{"id":"c","region":"DE-BY","name":{"en":"C"},"check":"maybe"}]}');
    final errs = bad.validate({'DE-BY'});
    expect(errs.length, 4); // 未知の地域・id重複・英語の名前なし・check不正
    expect(() => PackFacts.parse('{"v":2,"landmarks":[]}'), throwsFormatException);
  });

  test('同じ seed なら同じ問題（名所の問題を含めて）', () {
    final pack = load('us');
    List<String> run() => [
          for (final q in QuizEngine(pack, seed: 9).generate(count: 60, types: const [QuestionType.landmarkOf, QuestionType.neighborOf]))
            '${q.type.name}:${q.targetId}:${q.subjectId}:${q.choiceIds.join(',')}'
        ];
    expect(run(), run());
  });
}
