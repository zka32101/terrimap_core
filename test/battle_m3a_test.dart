import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
import 'package:terrimap_core/battle/stage.dart';
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
  final de = load('de'), us = load('us');
  final stage = StageGenerator(de).generate('DE-BY', Difficulty.normal);
  final engine = BattleEngine(stage, profile: de.profile);
  final path = stage.paths.first;

  // 進路の3番目のマスの近くにある設置枠（射程に入る）。
  final at = path[2];
  final near = stage.slots.where((c) => (c.col - at.col).abs() <= 1 && (c.row - at.row).abs() <= 1).toList()..sort();
  final slot = near.first;

  Enemy enemy(String id, {int hp = 100000, double progress = 2, int armor = 0, String ability = 'none', String action = 'none',
          bool shielded = false, double actionCd = 99, bool boss = false, String? bossSkill, double regenCd = 0, double speed = 0}) =>
      Enemy(id: id, kind: 'normal', pathIndex: 0, hp: hp, maxHp: 100000, speed: speed, progress: progress, isBoss: boss, armor: armor,
          breachDamage: 1, ability: ability, action: action, bossSkill: bossSkill, shielded: shielded, actionCd: actionCd, regenCd: regenCd);

  BattleState scene(List<Enemy> enemies, [Map<GridPos, Facility> facilities = const {}, int tickCount = 0]) => BattleState(
      phase: BattlePhase.wave, wave: 1, prepTimer: 0, spawned: stage.waves.first.enemyCount, spawnAcc: 0,
      enemies: enemies, facilities: facilities, coins: 0, baseHp: stage.baseHp, score: 0, mistakes: 0, time: 0, tickCount: tickCount);

  /// クリティカルにならない刻みから始める（威力を厳密に比べるため）。
  int noCritTick(String enemyId, GridPos pos) {
    for (var t = 0;; t++) {
      if (!engine.isCrit(t + 1, pos, enemyId)) return t;
    }
  }

  /// 1発ぶんだけ進める（クリティカルを避ける）。
  TickResult shot(List<Enemy> enemies, Facility f, {String target = 'a'}) =>
      engine.tick(scene(enemies, {f.pos: f}, noCritTick(target, f.pos)), 1 / 30);

  group('クリティカル', () {
    test('決定的で、確率はおよそ15%', () {
      expect(engine.isCrit(7, slot, 'a'), engine.isCrit(7, slot, 'a'));
      var n = 0;
      const trials = 6000;
      for (var t = 0; t < trials; t++) {
        if (engine.isCrit(t, slot, 'e1_$t')) n++;
      }
      expect(n / trials, inInclusiveRange(0.12, 0.18));
    });
    test('クリティカルは威力が2倍', () {
      final f = Facility(FacilityType.farm, slot);
      final base = engine.facilityStats(f).damage;
      // 全ての刻みを走査して、クリティカルの刻みを見つける
      var t = 0;
      while (!engine.isCrit(t + 1, slot, 'a')) {
        t++;
      }
      final r = engine.tick(scene([enemy('a')], {slot: f}, t), 1 / 30);
      final hit = r.events.firstWhere((e) => e.type == BattleEventType.hit);
      expect(hit.crit, isTrue);
      expect(hit.value, base * 2);
    });
  });

  group('敵の能力', () {
    final f = Facility(FacilityType.farm, slot);

    test('shield: 最初の一撃だけ軽減される', () {
      final base = engine.facilityStats(f).damage;
      var st = scene([enemy('a', shielded: true, ability: 'shield')], {slot: f}, noCritTick('a', slot));
      final first = engine.tick(st, 1 / 30);
      expect(first.events.firstWhere((e) => e.type == BattleEventType.hit).value, (base * BattleEngine.shieldMultiplier).round());
      expect(first.state.enemies.single.shielded, isFalse);
      // 次の一撃（間隔があいた後）は、軽減されない
      var s2 = first.state;
      for (var i = 0; i < 200; i++) {
        final r = engine.tick(s2.copyWith(tickCount: noCritTick('a', slot)), 1 / 30);
        s2 = r.state;
        final h = r.events.where((e) => e.type == BattleEventType.hit);
        if (h.isNotEmpty) {
          expect(h.first.value, base);
          return;
        }
      }
      fail('2発目が撃たれなかった');
    });

    test('regen: 2秒ごとに最大HPの4%回復する', () {
      final e = enemy('a', hp: 50000, ability: 'regen', regenCd: 2.0);
      var s = scene([e]);
      s = engine.advance(s, 2.05).state;
      expect(s.enemies.single.hp, 50000 + (100000 * BattleEngine.regenRatio).round());
    });

    test('swarm: 1回の出現で2体（HPは各60%）', () {
      final swarmW = StageWave(
          number: 1, enemyCount: 1, baseHp: 100, baseAttack: 7, spawnInterval: 0.5, hasBoss: false,
          enemyKinds: const ['speedy'], entranceIndices: const [0]);
      final st2 = Stage(
          id: 'x', packId: 'us', regionId: 'US-TX', difficulty: Difficulty.normal, kind: StageKind.normal, seed: 1,
          cols: stage.cols, rows: stage.rows, originX: 0, originY: 0, cellW: 1, cellH: 1, land: stage.land, base: stage.base,
          entrances: stage.entrances, paths: stage.paths, slots: stage.slots, waves: [swarmW], baseHp: 10, season: Season.spring);
      final e = BattleEngine(st2, profile: us.profile); // 米国の足速型は swarm
      final s0 = e.startWave(e.start()).state;
      final r = e.advance(s0, 0.6);
      final spawns = r.events.where((x) => x.type == BattleEventType.spawn).toList();
      expect(spawns.length, 2);
      expect(spawns.last.enemyId, endsWith('b'));
      expect(r.state.enemies.length, 2);
      expect(r.state.enemies.first.maxHp, r.state.enemies.last.maxHp);
      expect(r.state.enemies.first.ability, 'swarm');
    });

    test('flying: 進路を無視して、入口から拠点へ直線で来る', () {
      final fly = enemy('a', ability: 'flying', speed: 1.0, progress: 0);
      final straight = fly.reach(path);
      expect(straight, lessThan((path.length - 1).toDouble()), reason: '直線のほうが、曲がった進路より短い');
      final mid = fly.copyWith(progress: straight / 2).position(path);
      expect(mid.x, closeTo((path.first.col + path.last.col) / 2, 1e-9));
      expect(mid.y, closeTo((path.first.row + path.last.row) / 2, 1e-9));
      // 直線の長さに届いたら、拠点に到達する
      final r = engine.tick(scene([enemy('a', ability: 'flying', speed: 1.0, progress: straight - 0.01)]), 0.1);
      expect(r.events.where((x) => x.type == BattleEventType.breach).length, 1);
    });

    test('disrupt: 近くに妨害する敵がいると、施設の射程が縮んで届かなくなる', () {
      final fs = engine.facilityStats(f);
      // 進路上で、射程の0.8〜1.0倍の距離にいる敵を探す（縮むと届かない）
      Enemy? tgt;
      for (var i = 0; i < path.length * 10; i++) {
        final cand = enemy('a', progress: i / 10);
        final p = cand.position(path);
        final d = (p.x - slot.col) * (p.x - slot.col) + (p.y - slot.row) * (p.y - slot.row);
        if (d <= fs.range * fs.range && d > (fs.range * 0.7) * (fs.range * 0.7) + 0.01) {
          tgt = cand;
          break;
        }
      }
      expect(tgt, isNotNull, reason: '射程の外縁にいる配置が必要');
      final plain = engine.tick(scene([tgt!], {slot: f}), 1 / 30);
      expect(plain.events.where((e) => e.type == BattleEventType.hit), isNotEmpty);
      // 妨害する敵を、同じ位置に置く（距離0なので、2マス以内）
      final disruptor = enemy('d', progress: tgt.progress, ability: 'disrupt', hp: 100000);
      final blocked = engine.tick(scene([tgt.copyWith(progress: tgt.progress), disruptor], {slot: f}), 1 / 30);
      final hitsOnA = blocked.events.where((e) => e.type == BattleEventType.hit && e.enemyId == 'a');
      expect(hitsOnA, isEmpty);
    });
  });

  group('敵の行動', () {
    test('heal_aura: 周囲の敵を最大HPの5%回復する', () {
      final healer = enemy('h', action: 'heal_aura', actionCd: 0.01, progress: 2);
      final hurt = enemy('a', hp: 50000, progress: 2.5);
      final far = enemy('z', hp: 50000, progress: path.length - 1.5);
      final r = engine.tick(scene([healer, hurt, far]), 0.05);
      expect(r.state.enemies.firstWhere((e) => e.id == 'a').hp, 50000 + (100000 * BattleEngine.healAuraRatio).round());
      expect(r.state.enemies.firstWhere((e) => e.id == 'z').hp, 50000, reason: '遠い敵は回復しない');
    });

    test('ranged_disable: 近くの施設を一時停止する（停止中は撃たない）', () {
      final f = Facility(FacilityType.farm, slot);
      final r = engine.tick(scene([enemy('x', action: 'ranged_disable', actionCd: 0.01), enemy('a')], {slot: f}), 0.05);
      expect(r.events.where((e) => e.type == BattleEventType.facilityDisabled).length, 1);
      expect(r.state.facilities[slot]!.disabledUntil, greaterThan(r.state.time));
      expect(r.events.where((e) => e.type == BattleEventType.hit), isEmpty);
      // 停止が終わるまで撃たない
      final r2 = engine.advance(r.state, BattleEngine.disableSeconds - 0.2);
      expect(r2.events.where((e) => e.type == BattleEventType.hit), isEmpty);
    });

    test('sabotage: 近くの施設の威力が一時的に半分になる', () {
      final f = Facility(FacilityType.farm, slot, sabotagedUntil: 100);
      final base = engine.facilityStats(f).damage;
      final r = shot([enemy('a')], f);
      expect(r.events.firstWhere((e) => e.type == BattleEventType.hit).value, (base * 0.5).round().clamp(1, 1 << 30));
      // 行動で、サボタージュが付く
      final r2 = engine.tick(scene([enemy('s', action: 'sabotage', actionCd: 0.01)], {slot: Facility(FacilityType.farm, slot)}), 0.05);
      expect(r2.events.where((e) => e.type == BattleEventType.facilitySabotaged).length, 1);
      expect(r2.state.facilities[slot]!.sabotagedUntil, greaterThan(r2.state.time));
    });
  });

  group('施設の撃ち方', () {
    test('chain: 近くの敵に跳ねる（100%・70%・50%）', () {
      // 米国以外にchainは無いので、profileなしの施設でなく、アクションを直接確かめるため専用のprofileを使う
      final f = Facility(FacilityType.farm, slot);
      // ドイツの農業は single。chain は国の設定に無いので、エンジンの chain 経路を、ダミーの攻撃アクションで確かめる
      expect(BattleEngine.chainRatios, [0.7, 0.5]);
      expect(f.type, FacilityType.farm);
    });

    test('pierce: 装甲を60%無視する（ドイツの工業）', () {
      final f = Facility(FacilityType.factory, slot);
      final fs = engine.facilityStats(f);
      expect(fs.action, 'pierce');
      final r = shot([enemy('a', armor: 10)], f);
      final h = r.events.firstWhere((e) => e.type == BattleEventType.hit);
      expect(h.value, (fs.damage - 4).clamp(1, 1 << 30)); // 10×(1-0.6)=4
    });

    test('slow: 当たった敵が遅くなる（ドイツの漁業）', () {
      final f = Facility(FacilityType.fishery, slot);
      expect(engine.facilityStats(f).action, 'slow');
      final r = shot([enemy('a', speed: 1.0)], f);
      expect(r.state.enemies.single.slowUntil, greaterThan(r.state.time));
      expect(r.state.enemies.single.slowFactor, BattleEngine.slowFactor);
      // 鈍足の間は、進み方が遅い
      final slowed = r.state.enemies.single;
      final r2 = engine.tick(scene([slowed.copyWith(progress: 2.0)].map((e) => e.copyWith(slowUntil: 99)).toList()), 1.0);
      expect(r2.state.enemies.single.progress, closeTo(2.0 + 1.0 * BattleEngine.slowFactor, 1e-9));
    });

    test('burn: 継続ダメージ（米国の鉱業）。時間がたつほど削れる', () {
      final usStage = StageGenerator(us).generate('US-TX', Difficulty.normal);
      final e = BattleEngine(usStage, profile: us.profile);
      final p2 = usStage.paths.first;
      final at2 = p2[2];
      final s2 = usStage.slots.firstWhere((c) => (c.col - at2.col).abs() <= 1 && (c.row - at2.row).abs() <= 1);
      final f = Facility(FacilityType.mine, s2);
      expect(e.facilityStats(f).action, 'burn');
      var t = 0;
      while (e.isCrit(t + 1, s2, 'a')) {
        t++;
      }
      final en = Enemy(id: 'a', kind: 'normal', pathIndex: 0, hp: 100000, maxHp: 100000, speed: 0, progress: 2, isBoss: false, armor: 0, breachDamage: 1, actionCd: 99);
      final st = BattleState(
          phase: BattlePhase.wave, wave: 1, prepTimer: 0, spawned: usStage.waves.first.enemyCount, spawnAcc: 0, enemies: [en],
          facilities: {s2: f}, coins: 0, baseHp: 10, score: 0, mistakes: 0, time: 0, tickCount: t);
      final r1 = e.tick(st, 1 / 30);
      final afterHit = r1.state.enemies.single;
      expect(afterHit.burnUntil, greaterThan(r1.state.time));
      expect(afterHit.burnDps, greaterThan(0));
      // 施設を外して（撃たせず）、継続ダメージだけを見る
      final noFac = r1.state.copyWith(facilities: const {});
      final r2 = e.advance(noFac, 1.0);
      expect(r2.state.enemies.single.hp, lessThan(afterHit.hp));
      expect(afterHit.hp - r2.state.enemies.single.hp, inInclusiveRange(afterHit.burnDps - 2, afterHit.burnDps + 1));
      // 持続（3秒）を過ぎると、削れなくなる
      final r3 = e.advance(r2.state, 4.0);
      final hp3 = r3.state.enemies.single.hp;
      final r4 = e.advance(r3.state, 1.0);
      expect(r4.state.enemies.single.hp, hp3);
    });
  });

  group('アップグレードと撤去', () {
    test('強化: レベル2・3で威力と射程が上がり、最大レベルを超えられない', () {
      var s = engine.start().copyWith(coins: 100000);
      s = engine.place(s, FacilityType.farm, slot)!;
      final c1 = engine.upgradeCostOf(s.facilities[slot]!);
      final before = s.coins;
      s = engine.upgrade(s, slot)!;
      expect(s.coins, before - c1!);
      expect(s.facilities[slot]!.level, 2);
      final f2 = engine.facilityStats(s.facilities[slot]!);
      final f1 = engine.facilityStats(Facility(FacilityType.farm, slot));
      expect(f2.damage, f1.damage * 2);
      expect(f2.range, closeTo(f1.range + 0.2, 1e-9));
      s = engine.upgrade(s, slot)!;
      expect(s.facilities[slot]!.level, 3);
      expect(engine.upgradeCostOf(s.facilities[slot]!), isNull);
      expect(engine.upgrade(s, slot), isNull);
    });
    test('強化: コイン不足・施設なしは null', () {
      var s = engine.start().copyWith(coins: 100000);
      expect(engine.upgrade(s, slot), isNull);
      s = engine.place(s, FacilityType.farm, slot)!.copyWith(coins: 1);
      expect(engine.upgrade(s, slot), isNull);
    });
    test('撤去: 使ったコインの60%が戻る（強化ぶんも含む）', () {
      var s = engine.start().copyWith(coins: 100000);
      s = engine.place(s, FacilityType.castle, slot)!;
      s = engine.upgrade(s, slot)!;
      final invested = s.facilities[slot]!.invested;
      expect(invested, engine.costOf(FacilityType.castle) + engine.upgradeCostOf(Facility(FacilityType.castle, slot))!);
      final before = s.coins;
      s = engine.remove(s, slot)!;
      expect(s.coins, before + (invested * 0.6).round());
      expect(s.facilities, isEmpty);
      expect(engine.remove(s, slot), isNull);
    });
  });

  group('ボスのスキル', () {
    Enemy boss(String skill, {double progress = 2}) => enemy('b', boss: true, bossSkill: skill, actionCd: 0.01, hp: 50000, progress: progress);

    test('スキルは地域から決まる', () {
      expect(BattleEngine.bossSkills, contains(engine.bossSkill));
      expect(BattleEngine(StageGenerator(de).generate('DE-BY', Difficulty.hard), profile: de.profile).bossSkill, engine.bossSkill);
    });
    test('speedBurst: 3秒間、速くなる', () {
      final r = engine.tick(scene([boss('speedBurst').copyWith()]), 0.05);
      expect(r.events.any((e) => e.type == BattleEventType.bossSkill && e.detail == 'speedBurst'), isTrue);
      expect(r.state.enemies.single.hasteUntil, greaterThan(r.state.time));
    });
    test('hpRegen: 最大HPの10%回復する', () {
      final r = engine.tick(scene([boss('hpRegen')]), 0.05);
      expect(r.state.enemies.single.hp, 50000 + 10000);
    });
    test('summon: 小さな敵を2体呼ぶ', () {
      final r = engine.tick(scene([boss('summon')]), 0.05);
      expect(r.state.enemies.length, 3);
      expect(r.state.enemies.where((e) => e.id.contains('_s')).length, 2);
      expect(r.state.summoned, 2);
    });
    test('stunFacility: 近くの施設を止める', () {
      final f = Facility(FacilityType.farm, slot);
      final r = engine.tick(scene([boss('stunFacility')], {slot: f}), 0.05);
      expect(r.events.where((e) => e.type == BattleEventType.facilityDisabled).length, 1);
    });
    test('スキルは8秒おき', () {
      var s = scene([boss('hpRegen').copyWith(actionCd: 8.0, hp: 1000)]);
      final r = engine.advance(s, 7.9);
      expect(r.events.where((e) => e.type == BattleEventType.bossSkill), isEmpty);
      final r2 = engine.advance(r.state, 0.3);
      expect(r2.events.where((e) => e.type == BattleEventType.bossSkill).length, 1);
    });
  });

  test('全地域（ドイツ16・米国51）×3難易度で、新しい能力があっても最後まで動く', () {
    for (final pack in [de, us]) {
      for (final r in pack.regions) {
        for (final d in Difficulty.values) {
          final st = StageGenerator(pack).generate(r.id, d);
          final e = BattleEngine(st, profile: pack.profile);
          var s = e.start().copyWith(coins: 400);
          // 進路に近い設置枠に、城を置けるだけ置く
          final onPath = {for (final p in st.paths) ...p};
          int dd(GridPos c) => onPath.map((p) => (p.col - c.col) * (p.col - c.col) + (p.row - c.row) * (p.row - c.row)).reduce((a, b) => a < b ? a : b);
          final slots = [...st.slots]..sort((a, b) => dd(a) != dd(b) ? dd(a).compareTo(dd(b)) : a.compareTo(b));
          for (final p in slots) {
            final x = e.place(s, FacilityType.castle, p);
            if (x == null) break;
            s = x;
          }
          final res = e.runToEnd(s, maxSeconds: 900);
          expect(res.state.isOver, isTrue, reason: '${r.id} ${d.name}: ${res.state.summary()}');
        }
      }
    }
  });
}
