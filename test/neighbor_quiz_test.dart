import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/pack/region_pack.dart';
import 'package:terrimap_core/quiz/quiz_engine.dart';

RegionPack load(String id) {
  String r(String f) => File('packs/$id/$f').readAsStringSync();
  return RegionPack.parse(
      packJson: r('pack.json'), regionsJson: r('regions.json'), geoJson: r('geo.geojson'), stringsJsonByLang: {'en': r('strings/en.json')});
}

void main() {
  for (final c in ['de', 'us']) {
    final pack = load(c);
    final nb = {for (final r in pack.regions) r.id: r.neighbors.toSet()};

    test('$c: 隣接の問題は、正解が隣、誤答は隣でない。選択肢は4つで重複なし', () {
      final qs = QuizEngine(pack, seed: 7).generate(count: 600, types: const [QuestionType.neighborOf]);
      var asked = 0;
      for (final q in qs) {
        if (q.type != QuestionType.neighborOf) {
          expect(q.type, QuestionType.nameFromMap); // 隣のない地域は地図からの問題になる
          expect(nb[q.targetId], isEmpty);
          continue;
        }
        asked++;
        expect(q.choiceIds.length, 4);
        expect(q.choiceIds.toSet().length, 4);
        expect(nb[q.targetId]!.contains(q.correctId), true, reason: '${q.targetId} → ${q.correctId}');
        expect(q.choiceIds, contains(q.correctId));
        for (final id in q.choiceIds) {
          expect(id, isNot(q.targetId));
          if (id != q.correctId) expect(nb[q.targetId]!.contains(id), false, reason: '${q.targetId}: 誤答 $id は隣');
        }
      }
      expect(asked, greaterThan(500));
    });

    test('$c: 同じ seed なら同じ問題', () {
      List<String> run() => [
            for (final q in QuizEngine(pack, seed: 3).generate(count: 50, types: QuestionType.values)) '${q.type.name}:${q.targetId}:${q.correctId}:${q.choiceIds.join(',')}'
          ];
      expect(run(), run());
    });
  }

  test('us: 角で接するだけの州（アリゾナとコロラド）は、誤答に出ない', () {
    final pack = load('us');
    final qs = QuizEngine(pack, seed: 11).generate(count: 3000, types: const [QuestionType.neighborOf], pool: {'US-AZ'});
    expect(qs.where((q) => q.type == QuestionType.neighborOf), isNotEmpty);
    for (final q in qs.where((q) => q.type == QuestionType.neighborOf)) {
      expect(q.choiceIds, isNot(contains('US-CO')));
    }
  });

  test('us: 隣のない州（アラスカ・ハワイ）は、地図からの州名の問題になる', () {
    final pack = load('us');
    final qs = QuizEngine(pack, seed: 1).generate(count: 20, types: const [QuestionType.neighborOf], pool: {'US-HI'});
    expect(qs, isNotEmpty);
    for (final q in qs) {
      expect(q.type, QuestionType.nameFromMap);
      expect(q.correctId, 'US-HI');
    }
  });
}
