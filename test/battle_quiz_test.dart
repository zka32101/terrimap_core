import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/stage_generator.dart';
import 'package:terrimap_core/pack/region_pack.dart';

RegionPack load(String id) {
  String r(String f) => File('packs/$id/$f').readAsStringSync();
  final langs = Directory('packs/$id/strings').listSync().map((e) => e.uri.pathSegments.last.replaceAll('.json', ''));
  return RegionPack.parse(
      packJson: r('pack.json'), regionsJson: r('regions.json'), geoJson: r('geo.geojson'),
      stringsJsonByLang: {for (final l in langs) l: r('strings/$l.json')},
      profileJson: r('profile.json'));
}

void main() {
  quizBuffTests();
  final de = load('de');
  BattleEngine eng(Difficulty d, {bool assist = true, bool withPack = true}) =>
      BattleEngine(StageGenerator(de).generate('DE-BY', d), profile: de.profile, pack: withPack ? de : null, quizAssist: assist);

  group('スキル選択のクイズ', () {
    test('問題は州と隣の州から出て、決定的', () {
      final e = eng(Difficulty.normal);
      final s = e.start();
      final q = e.assistQuestion(s)!;
      final pool = {'DE-BY', ...de.regions.firstWhere((r) => r.id == 'DE-BY').neighbors};
      expect(pool.contains(q.targetId), true);
      expect(q.choiceIds.contains(q.correctId), true);
      final q2 = e.assistQuestion(s)!;
      expect(q2.type, q.type);
      expect(q2.targetId, q.targetId);
      expect(q2.choiceIds, q.choiceIds);
      // 波が進むと別の問題になりうる（少なくとも例外なく出る）
      expect(e.assistQuestion(s.copyWith(wave: 3)), isNotNull);
    });
    test('正解: クイズ前は選べず、正解後は3つから選べる', () {
      final e = eng(Difficulty.normal);
      final s0 = e.start();
      final c = e.skillChoices(s0);
      expect(e.chooseSkill(s0, c.first), isNull); // 答える前は選べない
      final s1 = e.resolveSkillQuiz(s0, correct: true);
      expect(s1.skillUnlocked, true);
      expect(e.chooseSkill(s1, c[1])!.skill, c[1]);
    });
    test('不正解: 3つのうち1つが自動で決まる（何ももらえない、にはならない）', () {
      final e = eng(Difficulty.normal);
      final s0 = e.start();
      final c = e.skillChoices(s0);
      final s1 = e.resolveSkillQuiz(s0, correct: false);
      expect(c.contains(s1.skill), true);
      expect(e.resolveSkillQuiz(s0, correct: false).skill, s1.skill); // 決定的
      expect(e.skillChoices(s1), isEmpty);
    });
    test('オフ: 問題は出ず、そのまま3つから選べる', () {
      for (final e in [eng(Difficulty.normal, assist: false), eng(Difficulty.normal, withPack: false)]) {
        final s0 = e.start();
        expect(e.assistEnabled, false);
        expect(e.assistQuestion(s0), isNull);
        expect(e.resolveSkillQuiz(s0, correct: false).skill, isNull);
        final c = e.skillChoices(s0);
        expect(e.chooseSkill(s0, c.first)!.skill, c.first);
      }
    });
    test('次の波ではまたクイズが必要（解放は波ごと）', () {
      final e = eng(Difficulty.easy);
      var s = e.resolveSkillQuiz(e.start(), correct: true);
      s = e.chooseSkill(s, e.skillChoices(s).first)!;
      expect(s.skillUnlocked, true);
      // 波が終わるときに clearSkill される（copyWith(clearSkill)）
      final cleared = s.copyWith(clearSkill: true);
      expect(cleared.skillUnlocked, false);
      expect(cleared.skill, isNull);
    });
  });

  group('修理のクイズ（hard）', () {
    final hard = eng(Difficulty.hard);
    final pos = hard.stage.slots.first;
    BattleState damaged(BattleEngine e) {
      final f0 = Facility(FacilityType.farm, pos, invested: 100);
      final f = f0.copyWith(hp: e.maxHpOf(f0) ~/ 2);
      return e.start().copyWith(coins: 100, facilities: {pos: f});
    }

    test('正解は無料、不正解はコインを払う', () {
      final s = damaged(hard);
      final cost = hard.repairCostOf(s.facilities[pos]!)!;
      final ok = hard.repairByQuiz(s, pos, correct: true)!;
      expect(ok.coins, 100);
      expect(ok.facilities[pos]!.hp, hard.maxHpOf(ok.facilities[pos]!));
      final ng = hard.repairByQuiz(s, pos, correct: false)!;
      expect(ng.coins, 100 - cost);
      expect(ng.facilities[pos]!.hp, hard.maxHpOf(ng.facilities[pos]!));
    });
    test('不正解でコインが足りなければ null。満タンも null', () {
      final s = damaged(hard).copyWith(coins: 0);
      expect(hard.repairByQuiz(s, pos, correct: false), isNull);
      expect(hard.repairByQuiz(s, pos, correct: true), isNotNull); // 正解なら無料
      final full = hard.repairByQuiz(damaged(hard), pos, correct: true)!;
      expect(hard.repairByQuiz(full, pos, correct: true), isNull);
    });
    test('オフ: 正解扱いでもコインを払う', () {
      final off = eng(Difficulty.hard, assist: false);
      final s = damaged(off);
      final cost = off.repairCostOf(s.facilities[pos]!)!;
      expect(off.repairByQuiz(s, pos, correct: true)!.coins, 100 - cost);
    });
    test('修理の問題は位置で変わりうるが、決定的', () {
      final s = damaged(hard);
      final a = hard.assistQuestion(s, forRepair: pos)!, b = hard.assistQuestion(s, forRepair: pos)!;
      expect(a.targetId, b.targetId);
    });
  });

  test('制限時間: hard だけ10秒', () {
    expect(eng(Difficulty.hard).assistTimeLimit, 10);
    expect(eng(Difficulty.normal).assistTimeLimit, isNull);
    expect(eng(Difficulty.easy).assistTimeLimit, isNull);
  });
}

void quizBuffTests() {
  final de = load('de');
  final e = BattleEngine(StageGenerator(de).generate('DE-BY', Difficulty.normal), profile: de.profile, pack: de, quizAssist: true);
  group('クイズ正解の一時バフ', () {
    test('正解で攻撃バフ、連続で段数増、不正解では付かず、時間で切れる', () {
      final s0 = e.start();
      expect(BattleEngine.quizBuffBonus(s0), 0);
      expect(BattleEngine.quizBuffBonus(e.resolveSkillQuiz(s0, correct: false)), 0);
      final s1 = e.resolveSkillQuiz(s0, correct: true);
      expect(BattleEngine.quizBuffBonus(s1), closeTo(0.2, 1e-9));
      final s2 = e.resolveSkillQuiz(s1, correct: true);
      expect(BattleEngine.quizBuffBonus(s2), closeTo(0.3, 1e-9));
      expect(BattleEngine.quizBuffBonus(s2.copyWith(time: s2.time + 11)), 0);
    });
  });
}
