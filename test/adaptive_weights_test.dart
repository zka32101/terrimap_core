import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/review.dart';
import 'package:terrimap_core/progress/region_progress.dart';
import 'package:terrimap_core/quiz/quiz_engine.dart';
import 'package:terrimap_core/pack/region_pack.dart';
import 'dart:io';

void main() {
  test('苦手の重み: 間違いが多いほど重く（上限あり）、未出題は標準、習得済みは軽い', () {
    final p = RegionProgress({
      'a': RegionState.missed,
      'b': RegionState.missed,
      'c': RegionState.missed,
      'd': RegionState.unseen,
      'e': RegionState.mastered,
    });
    final w = adaptiveQuizWeights(p, {'a': 1, 'b': 3, 'c': 99, 'e': 4});
    expect(w['a'], 2.5);
    expect(w['b'], 3.5);
    expect(w['c'], 4.5); // 5回で頭打ち
    expect(w['d'], 1.5);
    expect(w['e'], 0.4); // 習得済みは、ミスの記録があっても軽い
    expect(w['b']! > w['a']!, true);
  });

  test('出題への効果: 苦手な州が、そうでない州より多く出る（同じ種で再現できる）', () {
    String r(String f) => File('packs/de/$f').readAsStringSync();
    final pack = RegionPack.parse(
        packJson: r('pack.json'), regionsJson: r('regions.json'), geoJson: r('geo.geojson'), stringsJsonByLang: {'en': r('strings/en.json')});
    final ids = pack.regions.map((x) => x.id).toList()..sort();
    final weak = ids.first;
    final progress = RegionProgress({for (final id in ids) id: id == weak ? RegionState.missed : RegionState.mastered});
    final w = adaptiveQuizWeights(progress, {weak: 5});
    var weakFirst = 0;
    for (var seed = 1; seed <= 200; seed++) {
      final qs = QuizEngine(pack, seed: seed).generate(count: 1, types: const [QuestionType.nameFromMap], weights: w);
      if (qs.first.targetId == weak) weakFirst++;
    }
    expect(weakFirst, greaterThan(200 ~/ ids.length * 3)); // 一様なら約 200/16 回。その3倍以上
  });
}
