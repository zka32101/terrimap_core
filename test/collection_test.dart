import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_progress.dart';
import 'package:terrimap_core/battle/collection.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
import 'package:terrimap_core/pack/pack_facts.dart';

void main() {
  for (final c in ['de', 'us']) {
    test('$c: 州をクリアするとその州の名所が集まる。未クリアは集まらない', () {
      final facts = PackFacts.parse(File('packs/$c/facts.json').readAsStringSync());
      final region = facts.usable.first.regionId;
      final p = BattleProgress();
      final none = Collection(facts, p);
      expect(none.total, facts.usable.length);
      expect(none.unlockedCount, 0);
      p.recordClear(StageKind.normal, region, Difficulty.easy);
      final col = Collection(facts, p);
      expect(col.unlockedCount, facts.inRegion(region).length);
      expect(col.unlockedIds, {for (final l in facts.inRegion(region)) l.id});
      expect(col.landmarksOf(region).length, col.unlockedCount);
      // どの難易度でもよい・エクストラや地方決戦のクリアは数えない
      final q = BattleProgress()..recordClear(StageKind.extra, region, Difficulty.hard)..recordClear(StageKind.regional, region, Difficulty.hard);
      expect(Collection(facts, q).unlockedCount, 0);
    });
  }

  test('名所のデータがなければ空', () {
    final col = Collection(null, BattleProgress());
    expect(col.total, 0);
    expect(col.unlockedCount, 0);
    expect(col.cards, isEmpty);
    expect(col.landmarksOf('X'), isEmpty);
  });
}
