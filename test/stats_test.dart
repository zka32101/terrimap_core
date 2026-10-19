import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_progress.dart';
import 'package:terrimap_core/battle/collection.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
import 'package:terrimap_core/battle/stats.dart';
import 'package:terrimap_core/daily/daily_streak.dart';
import 'package:terrimap_core/pack/pack_facts.dart';
import 'package:terrimap_core/progress/region_progress.dart';

void main() {
  final facts = PackFacts.parse(File('packs/de/facts.json').readAsStringSync());
  final ids = [for (final l in facts.usable) l.regionId].toSet().toList()..sort();

  Stats make(BattleProgress p, {RegionProgress? rp, DailyStreak streak = const DailyStreak(), String today = '2026-10-19'}) => Stats.compute(
        regionIds: ids,
        regions: rp ?? RegionProgress({for (final r in ids) r: RegionState.unseen}),
        battle: p,
        collection: Collection(facts, p),
        streak: streak,
        today: today,
        regionalTotal: 3,
        extraTotal: 2,
      );

  test('空のデータでは、すべて0（総数だけが出る）', () {
    final s = make(BattleProgress());
    expect((s.quizMastered, s.quizMissed, s.quizUnseen), (0, 0, ids.length));
    expect(s.quizTotal, ids.length);
    expect(s.totalStates, ids.length);
    expect(s.statesClearedAny, 0);
    expect(s.statesCleared.values.every((v) => v == 0), isTrue);
    expect((s.regionalCleared, s.regionalTotal, s.extraCleared, s.extraTotal), (0, 3, 0, 2));
    expect((s.streakCurrent, s.streakBest), (0, 0));
    expect((s.cardsUnlocked, s.achievementsUnlocked), (0, 0));
    expect(s.cardsTotal, greaterThan(0));
    expect(s.achievementsTotal, greaterThan(0));
  });

  test('クイズ: 習得・間違い・未学習が数えられる', () {
    final rp = RegionProgress({ids[0]: RegionState.mastered, ids[1]: RegionState.missed, for (final r in ids.skip(2)) r: RegionState.unseen});
    final s = make(BattleProgress(), rp: rp);
    expect((s.quizMastered, s.quizMissed, s.quizUnseen), (1, 1, ids.length - 2));
  });

  test('バトル: 難易度ごと・どの難易度でも・地方決戦・エクストラ', () {
    final p = BattleProgress()
      ..recordClear(StageKind.normal, ids[0], Difficulty.easy)
      ..recordClear(StageKind.normal, ids[0], Difficulty.hard)
      ..recordClear(StageKind.normal, ids[1], Difficulty.normal)
      ..recordClear(StageKind.regional, 'g', Difficulty.easy)
      ..recordClear(StageKind.extra, 'x', Difficulty.hard);
    final s = make(p);
    expect(s.statesCleared[Difficulty.easy], 1);
    expect(s.statesCleared[Difficulty.normal], 1);
    expect(s.statesCleared[Difficulty.hard], 1);
    expect(s.statesClearedAny, 2); // 2州（同じ州の別難易度は1つと数える）
    expect((s.regionalCleared, s.extraCleared), (1, 1));
    expect(s.cardsUnlocked, greaterThan(0)); // 州をクリアすると図鑑が増える
  });

  test('連続日数: 今の連続は昨日までなら続き、2日空くと0。最長は残る', () {
    final st = const DailyStreak().record('2026-10-16').record('2026-10-17').record('2026-10-18');
    expect(make(BattleProgress(), streak: st, today: '2026-10-18').streakCurrent, 3);
    expect(make(BattleProgress(), streak: st, today: '2026-10-19').streakCurrent, 3); // 昨日までやっていれば継続中
    final late = make(BattleProgress(), streak: st, today: '2026-10-21');
    expect(late.streakCurrent, 0);
    expect(late.streakBest, 3);
  });

  test('実績の数が、実績の一覧と一致する', () {
    final p = BattleProgress()..recordClear(StageKind.normal, ids[0], Difficulty.easy);
    final s = make(p, streak: const DailyStreak().record('2026-10-19'));
    expect(s.achievementsUnlocked, greaterThan(0));
    expect(s.achievementsUnlocked, lessThanOrEqualTo(s.achievementsTotal));
  });
}
