import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/exclusive.dart';
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
  Stage gen(RegionPack p, String r, Difficulty d) => StageGenerator(p).generate(r, d);
  final hardStage = gen(de, 'DE-BY', Difficulty.hard);
  final hard = BattleEngine(hardStage, profile: de.profile);
  final normal = BattleEngine(gen(de, 'DE-BY', Difficulty.normal), profile: de.profile);
  final path = hardStage.paths.first;
  final slots = hardStage.slots.where((c) => (c.col - path[2].col).abs() <= 1 && (c.row - path[2].row).abs() <= 1).toList()..sort();

  BattleState scene(BattleEngine e, List<Enemy> es, Map<GridPos, Facility> fs) => BattleState(
      phase: BattlePhase.wave, wave: 1, prepTimer: 0, spawned: e.stage.waves.first.enemyCount, spawnAcc: 0, enemies: es,
      facilities: fs, coins: 0, baseHp: e.stage.baseHp, score: 0, mistakes: 0, time: 0);

  Enemy walker(String id, {String kind = 'normal', double progress = 2, bool boss = false, String action = 'none'}) => Enemy(
      id: id, kind: kind, pathIndex: 0, hp: 1000000, maxHp: 1000000, speed: 1, progress: progress, isBoss: boss, armor: 0,
      breachDamage: 1, action: action);

  group('耐久（hard）', () {
    test('hard だけ耐久がある。城は多く、限定施設は2倍', () {
      final s = hard.place(hard.start().copyWith(coins: 9999), FacilityType.farm, slots.first)!;
      final f = s.facilities[slots.first]!;
      expect(f.hp, hard.maxHpOf(f));
      expect(f.hp, (hardStage.waves.first.baseHp * 1.5).round());
      expect(hard.maxHpOf(Facility(FacilityType.castle, slots.first)), greaterThan(hard.maxHpOf(f)));
      expect(normal.maxHpOf(Facility(FacilityType.farm, slots.first)), 0);
    });
    test('敵が射程に入ると足を止めて施設を攻撃する（easy/normal は壊れない）', () {
      final f = Facility(FacilityType.farm, slots.first).copyWith(hp: hard.maxHpOf(Facility(FacilityType.farm, slots.first)), invested: 100);
      final e = walker('a', progress: 2);
      final r = hard.tick(scene(hard, [e], {f.pos: f}), 1 / 30);
      expect(r.events.any((x) => x.type == BattleEventType.facilityDamaged), true);
      expect(r.state.enemies.first.progress, 2); // 動かない
      expect(r.state.facilities[f.pos]!.hp, lessThan(f.hp));
      // normal では攻撃しない
      final g = Facility(FacilityType.farm, slots.first, hp: 0);
      final n = normal.tick(scene(normal, [e], {g.pos: g}), 1 / 30);
      expect(n.events.any((x) => x.type == BattleEventType.facilityDamaged), false);
      expect(n.state.enemies.first.progress, greaterThan(2));
    });
    test('足速型は走り抜け、装甲型は2倍、ボスは範囲攻撃', () {
      Facility fac(GridPos p) => Facility(FacilityType.farm, p, hp: 100000, invested: 100);
      final f = fac(slots.first);
      expect(hard.tick(scene(hard, [walker('a', kind: 'speedy')], {f.pos: f}), 1 / 30).events.any((x) => x.type == BattleEventType.facilityDamaged), false);
      int dmg(Enemy e) => hard.tick(scene(hard, [e], {f.pos: f}), 1 / 30).events.firstWhere((x) => x.type == BattleEventType.facilityDamaged).value!;
      expect(dmg(walker('b', kind: 'armored')), closeTo(dmg(walker('c')) * 2, 1));
      final near = slots.where((c) => c != slots.first && (c.col - slots.first.col).abs() <= 1 && (c.row - slots.first.row).abs() <= 1).toList();
      if (near.isNotEmpty) {
        final r = hard.tick(scene(hard, [walker('boss', boss: true)], {f.pos: f, near.first: fac(near.first)}), 1 / 30);
        expect(r.events.where((x) => x.type == BattleEventType.facilityDamaged).length, 2);
      }
    });
    test('壊れた施設は消えて、使ったコインの半分が戻る', () {
      final f = Facility(FacilityType.farm, slots.first, hp: 1, invested: 100);
      final r = hard.tick(scene(hard, [walker('a')], {f.pos: f}), 1 / 30);
      expect(r.state.facilities, isEmpty);
      expect(r.events.any((x) => x.type == BattleEventType.facilityDestroyed), true);
      expect(r.state.coins, 50);
    });
    test('城が近くにあると、受ける被害が7割になる', () {
      final others = slots.where((c) => c != slots.first && (c.col - slots.first.col).abs() <= 1 && (c.row - slots.first.row).abs() <= 1).toList();
      if (others.isEmpty) return;
      final farm = Facility(FacilityType.farm, slots.first, hp: 100000, invested: 100);
      final castle = Facility(FacilityType.castle, others.first, hp: 100000, invested: 100);
      int dmg(Map<GridPos, Facility> fs) => hard.tick(scene(hard, [walker('a')], fs), 1 / 30).events.firstWhere((x) => x.type == BattleEventType.facilityDamaged && x.facilityPos == farm.pos).value!;
      final plain = dmg({farm.pos: farm});
      expect(dmg({farm.pos: farm, castle.pos: castle}), (plain * 0.7).round());
    });
    test('修理: 不足ぶんに応じたコイン。満タンは null。修理スキルは全回復', () {
      final max = hard.maxHpOf(Facility(FacilityType.farm, slots.first));
      final f = Facility(FacilityType.farm, slots.first, hp: max ~/ 2, invested: 100);
      final cost = ((max - max ~/ 2) / max * 100 * 0.5).ceil();
      expect(hard.repairCostOf(f), cost);
      var s = scene(hard, [], {f.pos: f}).copyWith(coins: cost - 1);
      expect(hard.repair(s, f.pos), isNull);
      s = s.copyWith(coins: cost);
      final r = hard.repair(s, f.pos)!;
      expect(r.coins, 0);
      expect(r.facilities[f.pos]!.hp, max);
      expect(hard.repairCostOf(r.facilities[f.pos]!), isNull);
      expect(normal.repairCostOf(Facility(FacilityType.farm, slots.first)), isNull);
    });
    test('神社は周囲の施設を回復する（hard）', () {
      final others = slots.where((c) => c != slots.first && (c.col - slots.first.col).abs() <= 1 && (c.row - slots.first.row).abs() <= 1).toList();
      if (others.isEmpty) return;
      final shrine = Facility(FacilityType.shrine, others.first, hp: 100000, invested: 100);
      final farm = Facility(FacilityType.farm, slots.first, hp: 10, invested: 100);
      final s = scene(hard, [], {shrine.pos: shrine, farm.pos: farm}).copyWith(time: 1.99, spawned: 0);
      final r = hard.tick(s, 0.02);
      expect(r.state.facilities[farm.pos]!.hp, greaterThan(10));
    });
  });

  group('限定施設', () {
    test('全ての限定施設の id に原型がある', () {
      for (final p in [de, us]) {
        for (final r in p.regions) {
          final id = p.profile!.traitOf(r.id).exclusiveFacility;
          if (id != null) expect(exclusiveKinds.containsKey(id), true, reason: '${r.id} $id');
        }
      }
      expect(exclusiveKinds.values.toSet(), ExclusiveKind.values.toSet());
    });
    test('1ステージに1つ。地域に限定施設がなければ置けない', () {
      final s0 = normal.start().copyWith(coins: 9999);
      final s1 = normal.placeExclusive(s0, slots.first)!;
      expect(s1.facilities[slots.first]!.exclusive, 'brewery');
      expect(s1.coins, 9999 - normal.exclusiveCostOf()!);
      expect(normal.placeExclusive(s1, slots[1]), isNull);
      expect(normal.upgrade(s1, slots.first), isNull);
      expect(normal.remove(s1, slots.first)!.coins, greaterThan(s1.coins));
      // コイン不足
      expect(normal.placeExclusive(normal.start().copyWith(coins: 1), slots.first), isNull);
      // 限定施設のない地域
      final none = de.regions.map((r) => r.id).firstWhere((id) => de.profile!.traitOf(id).exclusiveFacility == null, orElse: () => '');
      if (none.isNotEmpty) {
        final e = BattleEngine(gen(de, none, Difficulty.normal), profile: de.profile);
        expect(e.exclusiveCostOf(), isNull);
        expect(e.placeExclusive(e.start().copyWith(coins: 9999), e.stage.slots.first), isNull);
      }
    });
    test('brewery: 1秒ごとに範囲の敵へ継続ダメージ', () {
      final f = Facility(FacilityType.castle, slots.first, exclusive: 'brewery', invested: 150);
      final e = walker('a', progress: 2);
      final s = scene(normal, [e], {f.pos: f}).copyWith(time: 0.99);
      final r = normal.tick(s, 0.02);
      expect(r.state.enemies.first.hp, lessThan(e.hp));
    });
    test('port: 近くの敵が遅くなる', () {
      final f = Facility(FacilityType.castle, slots.first, exclusive: 'seaport', invested: 120);
      double moved(Map<GridPos, Facility> fs) => normal.tick(scene(normal, [walker('a')], fs), 1.0).state.enemies.first.progress - 2;
      expect(moved({f.pos: f}) / moved({}), closeTo(0.7, 1e-9));
    });
    test('resource: 撃破コイン +15%', () {
      final f = Facility(FacilityType.castle, slots.first, exclusive: 'stock_exchange', invested: 140);
      final weak = Enemy(id: 'k', kind: 'normal', pathIndex: 0, hp: 1, maxHp: 1, speed: 0, progress: 2, isBoss: false, armor: 0, breachDamage: 1);
      final farm = Facility(FacilityType.farm, slots[1]);
      int coins(Map<GridPos, Facility> fs) => normal.tick(scene(normal, [weak], fs), 1 / 30).state.coins;
      // 別の施設で撃破させる（farm の射程に入る位置で比較）
      final fs = {farm.pos: farm};
      final base = coins(fs);
      if (base > 0) expect(coins({...fs, f.pos: f}), greaterThan(base));
    });
    test('core: 周囲の施設の威力が上がる', () {
      final core = Facility(FacilityType.castle, slots[0], exclusive: 'automotive_works', invested: 160);
      final near = slots.where((c) => c != slots[0] && (c.col - slots[0].col).abs() <= 1 && (c.row - slots[0].row).abs() <= 1).toList();
      if (near.isEmpty) return;
      final farm = Facility(FacilityType.farm, near.first);
      int hit(Map<GridPos, Facility> fs) {
        for (var t = 0;; t++) {
          if (normal.isCrit(t + 1, farm.pos, 'a')) continue;
          final r = normal.tick(scene(normal, [walker('a')], fs).copyWith(tickCount: t), 1 / 30);
          return r.events.firstWhere((x) => x.type == BattleEventType.hit).value!;
        }
      }
      expect(hit({farm.pos: farm, core.pos: core}), greaterThan(hit({farm.pos: farm})));
    });
    test('space: 長射程の貫通で撃つ', () {
      final e = BattleEngine(gen(us, 'US-TX', Difficulty.normal), profile: us.profile);
      final f = Facility(FacilityType.castle, e.stage.slots.first, exclusive: 'space_center', invested: 200);
      final fs = e.facilityStats(f);
      expect(fs.action, 'pierce');
      expect(fs.range, greaterThan(4));
    });
    test('symbol: 拠点HPが10秒ごとに1回復する', () {
      final e = BattleEngine(gen(de, 'DE-BE', Difficulty.normal), profile: de.profile);
      expect(de.profile!.traitOf('DE-BE').exclusiveFacility, 'parliament');
      final f = Facility(FacilityType.castle, e.stage.slots.first, exclusive: 'parliament', invested: 180);
      final s = BattleState(
          phase: BattlePhase.wave, wave: 1, prepTimer: 0, spawned: e.stage.waves.first.enemyCount, spawnAcc: 0, enemies: const [],
          facilities: {f.pos: f}, coins: 0, baseHp: e.stage.baseHp - 3, score: 0, mistakes: 0, time: 9.99);
      final r = e.tick(s, 0.02);
      expect(r.events.any((x) => x.type == BattleEventType.baseHeal), true);
      expect(r.state.baseHp, e.stage.baseHp - 2);
    });
  });

  test('全地域×hard で、限定施設・耐久があっても最後まで動く', () {
    for (final pack in [de, us]) {
      for (final r in pack.regions) {
        final stage = StageGenerator(pack).generate(r.id, Difficulty.hard);
        final e = BattleEngine(stage, profile: pack.profile);
        var s = e.start().copyWith(coins: 600);
        s = e.placeExclusive(s, stage.slots.first) ?? s;
        for (final p in stage.slots.skip(1).take(4)) {
          s = e.place(s, FacilityType.castle, p) ?? s;
        }
        final res = e.runToEnd(s, maxSeconds: 1200);
        expect(res.state.isOver || res.state.time >= 1199, true, reason: '${r.id} ${res.state.summary()}');
      }
    }
  });
}
