import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/review.dart';
import 'package:terrimap_core/battle/stage_generator.dart';
import 'package:terrimap_core/battle_ui/battle_view.dart';
import 'package:terrimap_core/pack/region_pack.dart';
import 'package:terrimap_core/progress/region_progress.dart';

RegionPack load(String id) {
  String r(String f) => File('packs/$id/$f').readAsStringSync();
  final langs = Directory('packs/$id/strings').listSync().map((e) => e.uri.pathSegments.last.replaceAll('.json', ''));
  return RegionPack.parse(
      packJson: r('pack.json'), regionsJson: r('regions.json'), geoJson: r('geo.geojson'),
      stringsJsonByLang: {for (final l in langs) l: r('strings/$l.json')},
      profileJson: r('profile.json'), factsJson: r('facts.json'));
}

void main() {
  final de = load('de');

  test('復習の重み: 間違えた州>未習得>習得済み', () {
    final w = battleReviewWeights(const RegionProgress({'a': RegionState.missed, 'b': RegionState.unseen, 'c': RegionState.mastered}));
    expect(w['a']! > w['b']! && w['b']! > w['c']!, true);
  });

  test('復習: 重みを渡すと、間違えた州が出やすくなる。問題は決定的で、重みなしの出題は変わらない', () {
    final stage = StageGenerator(de).generate('DE-BY', Difficulty.normal);
    final plain = BattleEngine(stage, profile: de.profile, pack: de);
    final ids = {stage.regionId, ...de.regions.firstWhere((r) => r.id == stage.regionId).neighbors};
    final weak = ids.first;
    final weights = {for (final id in ids) id: id == weak ? 200.0 : 0.05};
    final review = BattleEngine(stage, profile: de.profile, pack: de, reviewWeights: weights);
    var hits = 0, plainHits = 0;
    for (var wave = 0; wave < 40; wave++) {
      final s = plain.start().copyWith(wave: wave);
      if (review.assistQuestion(s)!.targetId == weak) hits++;
      if (plain.assistQuestion(s)!.targetId == weak) plainHits++;
      expect(review.assistQuestion(s)!.targetId, review.assistQuestion(s)!.targetId); // 決定的
    }
    expect(hits, greaterThan(plainHits));
    expect(hits, greaterThan(30));
  });

  testWidgets('全ての天候を重ねても描ける（地震はゆれる）', (t) async {
    final stage = StageGenerator(de).generate('DE-BY', Difficulty.normal);
    final e = BattleEngine(stage, profile: de.profile, pack: de, quizAssist: false);
    final s = e.start().copyWith(time: 12.3);
    for (final w in [null, 'hurricane', 'tornado', 'blizzard', 'heatwave', 'wildfire', 'flood', 'earthquake', 'storm', 'unknown']) {
      await t.pumpWidget(MaterialApp(home: SizedBox(width: 360, height: 500, child: BattleView(stage: stage, state: s, weather: w))));
      expect(t.takeException(), isNull, reason: '$w');
    }
  });
}
