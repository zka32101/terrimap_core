import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/achievements.dart';
import 'package:terrimap_core/battle/battle_progress.dart';
import 'package:terrimap_core/battle/collection.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
import 'package:terrimap_core/pack/pack_facts.dart';
import 'package:terrimap_core/progress/region_progress.dart';

void main() {
  final facts = PackFacts.parse(File('packs/de/facts.json').readAsStringSync());
  final ids = [for (final l in facts.usable) l.regionId].toSet().toList();

  Achievements make(BattleProgress p, {int streak = 0, RegionProgress? rp}) =>
      Achievements(regionIds: ids, progress: p, collection: Collection(facts, p), bestStreak: streak, regions: rp);
  Achievement of(Achievements a, String id) => a.all.firstWhere((x) => x.id == id);

  test('空のデータでは、すべて未達成', () {
    final a = make(BattleProgress());
    expect(a.unlockedCount, 0);
    expect(a.all.every((x) => !x.unlocked && x.shown == 0), isTrue);
  });

  test('クリアの境界: あと1で未達成、ちょうどで達成', () {
    final p = BattleProgress();
    for (final r in ids.take(ids.length - 1)) {
      p.recordClear(StageKind.normal, r, Difficulty.easy);
    }
    var a = make(p);
    expect(of(a, 'firstClear').unlocked, isTrue);
    expect(of(a, 'allClear').unlocked, isFalse);
    expect(of(a, 'allClear').value, ids.length - 1);
    expect(of(a, 'allNormal').unlocked, isFalse);
    p.recordClear(StageKind.normal, ids.last, Difficulty.easy);
    a = make(p);
    expect(of(a, 'allClear').unlocked, isTrue);
    expect(of(a, 'allEasy').unlocked, isTrue);
    expect(of(a, 'allHard').unlocked, isFalse);
  });

  test('連続日数は最長で判定。目標を超えても表示は目標まで', () {
    final p = BattleProgress();
    expect(of(make(p, streak: 2), 'streak3').unlocked, isFalse);
    expect(of(make(p, streak: 3), 'streak3').unlocked, isTrue);
    expect(of(make(p, streak: 7), 'streak30').unlocked, isFalse);
    final a = of(make(p, streak: 50), 'streak30');
    expect(a.unlocked, isTrue);
    expect(a.shown, 30);
    expect(a.ratio, 1.0);
  });

  test('図鑑・ボス・地方決戦・全州マスター', () {
    final p = BattleProgress()
      ..recordClear(StageKind.extra, 'x', Difficulty.hard)
      ..recordClear(StageKind.regional, 'g', Difficulty.easy);
    final rp = RegionProgress({for (final r in ids) r: RegionState.mastered});
    final a = make(p, rp: rp);
    expect(of(a, 'boss').unlocked, isTrue);
    expect(of(a, 'regional').unlocked, isTrue);
    expect(of(a, 'mastered').unlocked, isTrue);
    expect(of(a, 'cards10').unlocked, isFalse);
    for (final r in ids) {
      p.recordClear(StageKind.normal, r, Difficulty.easy);
    }
    final b = make(p);
    expect(of(b, 'cardsAll').unlocked, isTrue);
    expect(of(b, 'cards10').unlocked, isTrue);
    expect(of(b, 'mastered').unlocked, isFalse);
  });

  test('データ削除（空の記録）に戻すと、すべて未達成', () {
    final p = BattleProgress()..recordClear(StageKind.normal, ids.first, Difficulty.hard);
    expect(make(p, streak: 9).unlockedCount, greaterThan(0));
    expect(make(BattleProgress()).unlockedCount, 0);
  });

  test('i18n: すべての実績に名前と説明がある', () {
    final en = File('i18n/battle.en.json').readAsStringSync();
    for (final a in make(BattleProgress()).all) {
      expect(en.contains('"ach.${a.id}"'), isTrue, reason: a.id);
      expect(en.contains('"ach.${a.id}.desc"'), isTrue, reason: a.id);
    }
  });
}
