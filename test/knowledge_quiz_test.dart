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

    test('$c: 深い知識のデータは検査を通り、すべての州に題材がある。種類は決まった4つ', () {
      final f = pack.facts!;
      expect(f.validate(ids), isEmpty);
      expect(f.knowledgeRegionIds, ids, reason: '題材のない州がある');
      for (final k in f.knowledge) {
        expect(KnowledgeItem.kinds, contains(k.kind), reason: k.id);
        expect(k.nameIn('xx'), k.name['en']); // 言語がなければ英語
        expect(k.nameIn('ja'), isNot(k.name['en']), reason: '${k.id} の日本語名がない');
      }
    });

    test('$c: 深い知識の問題 — 正解は題材のある州、選択肢は4つで重複なし。題材の id が付く。同じ seed で同じ出題', () {
      final qs = QuizEngine(pack, seed: 5).generate(count: 400, types: const [QuestionType.knowledgeOf]);
      var asked = 0;
      for (final q in qs) {
        expect(q.type, QuestionType.knowledgeOf); // 全州に題材があるので、地図の問題にならない
        asked++;
        final item = pack.facts!.knowledge.firstWhere((k) => k.id == q.subjectId);
        expect(item.regionId, q.correctId);
        expect(q.choiceIds.length, 4);
        expect(q.choiceIds.toSet().length, 4);
        expect(q.choiceIds, contains(q.correctId));
      }
      expect(asked, qs.length);
      final again = QuizEngine(pack, seed: 5).generate(count: 400, types: const [QuestionType.knowledgeOf]);
      expect([for (final q in again) '${q.subjectId}:${q.choiceIds}'], [for (final q in qs) '${q.subjectId}:${q.choiceIds}']);
    });

    test('$c: 同じ州の題材が複数あるときは、どれも出題される', () {
      final multi = {for (final r in ids) r: pack.facts!.knowledgeIn(r)}..removeWhere((_, v) => v.length < 2);
      expect(multi, isNotEmpty);
      final seen = <String>{};
      for (final q in QuizEngine(pack, seed: 3).generate(count: 1500, types: const [QuestionType.knowledgeOf])) {
        seen.add(q.subjectId!);
      }
      for (final items in multi.values) {
        for (final it in items) {
          expect(seen, contains(it.id));
        }
      }
    });
  }

  test('題材のデータがなければ、地図から州名の問題になる', () {
    final pack = load('de', facts: false);
    final qs = QuizEngine(pack, seed: 1).generate(count: 30, types: const [QuestionType.knowledgeOf]);
    expect(qs.every((q) => q.type == QuestionType.nameFromMap && q.subjectId == null), true);
  });

  test('検査: 知識の id の重複・未知の州・不正な種類・英語の名前なしを見つける', () {
    final f = PackFacts.parse('{"v":1,"landmarks":[],"knowledge":['
        '{"id":"a","region":"X","kind":"food","name":{"en":"A"}},'
        '{"id":"a","region":"Y","kind":"weird","name":{"de":"B"}}]}');
    final errs = f.validate({'X'});
    expect(errs.any((e) => e.contains('重複')), true);
    expect(errs.any((e) => e.contains('未知の地域')), true);
    expect(errs.any((e) => e.contains('kind')), true);
    expect(errs.any((e) => e.contains('英語')), true);
  });
}
