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

/// 進路にいちばん近い設置枠から順に、[n]個を選ぶ。
List<GridPos> bestSlots(Stage s, int n) {
  final onPath = {for (final p in s.paths) ...p};
  int d(GridPos c) => onPath.map((p) => (p.col - c.col) * (p.col - c.col) + (p.row - c.row) * (p.row - c.row)).reduce((a, b) => a < b ? a : b);
  final slots = [...s.slots]..sort((a, b) => d(a) != d(b) ? d(a).compareTo(d(b)) : a.compareTo(b));
  return slots.take(n).toList();
}

BattleState withCoins(BattleState s, int coins) => s.copyWith(coins: coins);

void main() {
  final de = load('de'), us = load('us');
  final stage = StageGenerator(de).generate('DE-BY', Difficulty.normal);
  final engine = BattleEngine(stage, profile: de.profile);

  test('開始: コイン・拠点HP・準備中。国の経済の倍率が掛かる', () {
    final s = engine.start();
    expect(s.phase, BattlePhase.prep);
    expect(s.wave, 0);
    expect(s.baseHp, stage.baseHp);
    expect(s.coins, (160 * de.profile!.startCoins).round());
    expect(engine.costOf(FacilityType.castle), (150 * de.profile!.facilityCost).round());
  });

  test('施設を置く: 置けない場合は null、置くとコインが減る', () {
    var s = withCoins(engine.start(), 1000);
    final pos = stage.slots.first;
    final placed = engine.place(s, FacilityType.farm, pos)!;
    expect(placed.coins, 1000 - engine.costOf(FacilityType.farm));
    expect(placed.facilities[pos]!.type, FacilityType.farm);
    expect(engine.place(placed, FacilityType.farm, pos), isNull, reason: 'すでに施設がある');
    final notSlot = stage.paths.first.first; // 進路上は設置枠でない
    expect(engine.place(s, FacilityType.farm, notSlot), isNull);
    expect(engine.place(s.copyWith(coins: 1), FacilityType.farm, pos), isNull, reason: 'コイン不足');
  });

  test('防衛なし: 拠点が壊れて敗北する（到達・敗北のイベント）', () {
    final r = engine.runToEnd(engine.start());
    expect(r.state.phase, BattlePhase.defeat);
    expect(r.state.baseHp, 0);
    expect(r.state.mistakes, greaterThan(0));
    expect(r.events.where((e) => e.type == BattleEventType.breach), isNotEmpty);
    expect(r.events.last.type, BattleEventType.defeat);
  });

  test('十分な防衛: 全ての波を守りきって勝利する', () {
    var s = withCoins(engine.start(), 100000);
    for (final p in bestSlots(stage, 14)) {
      s = engine.place(s, FacilityType.castle, p)!;
    }
    final r = engine.runToEnd(s);
    expect(r.state.phase, BattlePhase.victory, reason: r.state.summary());
    expect(r.state.baseHp, greaterThan(0));
    expect(r.events.where((e) => e.type == BattleEventType.waveClear).length, stage.waves.length);
    expect(r.events.where((e) => e.type == BattleEventType.waveStart).length, stage.waves.length);
    expect(r.events.last.type, BattleEventType.victory);
    expect(r.state.score, greaterThan(0));
    // 倒した敵の数 = 出した敵の数 + 到達した敵の数でなく、(撃破 + 到達) = 出現
    final spawn = r.events.where((e) => e.type == BattleEventType.spawn).length;
    final kill = r.events.where((e) => e.type == BattleEventType.kill).length;
    final breach = r.events.where((e) => e.type == BattleEventType.breach).length;
    expect(spawn, stage.waves.fold<int>(0, (a, w) => a + w.enemyCount));
    expect(kill + breach, spawn);
  });

  test('決定的: 同じステージ・同じ操作は、同じ結果・同じイベント', () {
    String run() {
      var s = withCoins(engine.start(), 600);
      for (final p in bestSlots(stage, 3)) {
        s = engine.place(s, FacilityType.farm, p) ?? s;
      }
      final r = engine.runToEnd(s);
      return '${r.state.summary()}|${r.events.join(',')}';
    }

    expect(run(), run());
  });

  test('同じ時間を、細かく進めても粗く進めても（刻みを揃えれば）同じ結果', () {
    var s = withCoins(engine.start(), 600);
    for (final p in bestSlots(stage, 3)) {
      s = engine.place(s, FacilityType.farm, p) ?? s;
    }
    final a = engine.advance(s, 20).state;
    var b = s;
    for (var i = 0; i < 20; i++) {
      b = engine.advance(b, 1).state;
    }
    expect(a.summary(), b.summary());
  });

  test('準備を飛ばして波を始める: waveStart が出て、波の状態になる', () {
    final r = engine.startWave(engine.start());
    expect(r.state.phase, BattlePhase.wave);
    expect(r.state.wave, 1);
    expect(r.events.single.type, BattleEventType.waveStart);
  });

  test('波が終わると準備に戻り、次の波の準備時間が始まる', () {
    var s = withCoins(engine.start(), 100000);
    for (final p in bestSlots(stage, 14)) {
      s = engine.place(s, FacilityType.castle, p)!;
    }
    s = engine.startWave(s).state;
    var cleared = false;
    for (var i = 0; i < 30 * 600 && !cleared; i++) {
      final r = engine.tick(s, BattleEngine.step);
      s = r.state;
      cleared = r.events.any((e) => e.type == BattleEventType.waveClear);
    }
    expect(cleared, isTrue);
    expect(s.phase, BattlePhase.prep);
    expect(s.wave, 1);
    expect(s.prepTimer, difficultyParams[Difficulty.normal]!.waveBreakSeconds);
    expect(s.enemies, isEmpty);
    // 準備時間が過ぎると、自動で次の波が始まる
    final r = engine.advance(s, s.prepTimer + 0.1);
    expect(r.state.phase, BattlePhase.wave);
    expect(r.state.wave, 2);
    expect(r.events.any((e) => e.type == BattleEventType.waveStart && e.value == 2), isTrue);
  });

  group('性能（国の特性・難易度の反映）', () {
    final w1 = stage.waves.first;

    test('敵: 装甲型は体力×2.0×国の倍率、装甲=8+国の加算。ボスは基礎HPの2.5倍', () {
      final armoredW = StageWave(
          number: 1, enemyCount: 3, baseHp: 100, baseAttack: 7, spawnInterval: 1, hasBoss: true,
          enemyKinds: const ['armored', 'normal', 'normal'], entranceIndices: const [0]);
      final t = de.profile!.enemyOf('armored');
      final a = engine.makeEnemy(armoredW, 0);
      expect(a.maxHp, (100 * 2.0 * t.hp).round());
      expect(a.armor, 8 + t.armor);
      expect(a.breachDamage, (2 * t.baseDamage).round()); // 装甲型は既存の規則で2
      final boss = engine.makeEnemy(armoredW, 2);
      expect(boss.isBoss, isTrue);
      expect(boss.maxHp, 250);
      expect(w1.enemyKinds.length, w1.enemyCount);
    });

    test('敵の速さ: 足速型は速い、難易度の倍率が掛かる', () {
      final w = StageWave(
          number: 1, enemyCount: 2, baseHp: 100, baseAttack: 7, spawnInterval: 1, hasBoss: false,
          enemyKinds: const ['normal', 'speedy'], entranceIndices: const [0]);
      final n = engine.makeEnemy(w, 0), s = engine.makeEnemy(w, 1);
      expect(s.speed / n.speed, closeTo(1.8 * de.profile!.enemyOf('speedy').speed / de.profile!.enemyOf('normal').speed, 1e-9));
      final hard = BattleEngine(StageGenerator(de).generate('DE-BY', Difficulty.hard), profile: de.profile);
      expect(hard.makeEnemy(w, 0).speed / n.speed, closeTo(1.15, 1e-9));
    });

    test('施設: 国の攻撃アクションの威力・間隔・撃ち方と、地域のボーナスが反映される', () {
      for (final t in FacilityType.values) {
        final f = Facility(t, const GridPos(0, 0));
        final fs = engine.facilityStats(f);
        final act = de.profile!.attackActions[t.name];
        final bonus = de.profile!.traitOf('DE-BY').facilityBonus[t.name] ?? 1.0;
        expect(fs.damage, (facilityBase[t]!.damage * (act?.damage ?? 1.0) * bonus).round().clamp(1, 1 << 30), reason: t.name);
        expect(fs.action, act?.action ?? 'single', reason: t.name);
        expect(fs.cooldown, closeTo((1 / facilityBase[t]!.attackSpeed) * (act?.cooldown ?? 1.0), 1e-9), reason: t.name);
      }
    });

    test('撃破の報酬: 12+3×波 に、難易度と国の収入の倍率', () {
      var s = withCoins(engine.start(), 100000);
      for (final p in bestSlots(stage, 14)) {
        s = engine.place(s, FacilityType.castle, p)!;
      }
      final r = engine.runToEnd(s);
      final first = r.events.firstWhere((e) => e.type == BattleEventType.kill && !e.isBoss);
      expect(first.value, (15 * 1.0 * de.profile!.income).round().clamp(1, 1 << 30));
    });
  });

  group('攻撃の細部', () {
    BattleState scene(List<Enemy> enemies, Map<GridPos, Facility> facilities) => BattleState(
        phase: BattlePhase.wave, wave: 1, prepTimer: 0, spawned: stage.waves.first.enemyCount, spawnAcc: 0,
        enemies: enemies, facilities: facilities, coins: 0, baseHp: stage.baseHp, score: 0, mistakes: 0, time: 0);

    Enemy enemy(String id, {String kind = 'normal', int hp = 1000, double progress = 2, int armor = 0}) => Enemy(
        id: id, kind: kind, pathIndex: 0, hp: hp, maxHp: hp, speed: 0, progress: progress, isBoss: false,
        armor: armor, breachDamage: 1);

    test('装甲はダメージから引かれる（最低1）', () {
      final path = stage.paths.first;
      final at = path[2];
      // 進路の3番目のマスのすぐ隣の設置枠を選ぶ
      final slot = stage.slots.firstWhere((c) => c.manhattan(at) == 1 || (c.col - at.col).abs() <= 1 && (c.row - at.row).abs() <= 1);
      final f = Facility(FacilityType.farm, slot);
      final expected = engine.facilityStats(f).damage;
      final r = engine.tick(scene([enemy('a', armor: 8)], {slot: f}), 1 / 30);
      final hit = r.events.firstWhere((e) => e.type == BattleEventType.hit);
      expect(hit.value, (expected - 8).clamp(1, 1 << 30));
      final strong = engine.tick(scene([enemy('a', armor: 0)], {slot: f}), 1 / 30);
      expect(strong.events.firstWhere((e) => e.type == BattleEventType.hit).value, expected);
    });

    test('範囲攻撃(splash): 近くの敵にも、割合のダメージ', () {
      final path = stage.paths.first;
      final at = path[2];
      final slot = stage.slots.firstWhere((c) => (c.col - at.col).abs() <= 1 && (c.row - at.row).abs() <= 1);
      // ドイツの城は splash
      final f = Facility(FacilityType.castle, slot);
      final fs = engine.facilityStats(f);
      expect(fs.action, 'splash');
      final r = engine.tick(scene([enemy('a', progress: 2), enemy('b', progress: 1.9)], {slot: f}), 1 / 30);
      final hits = r.events.where((e) => e.type == BattleEventType.hit).toList();
      expect(hits.length, 2);
      expect(hits.first.enemyId, 'a'); // 拠点に近い方を狙う
      expect(hits.first.value, fs.damage);
      expect(hits.last.value, (fs.damage * BattleEngine.splashRatio).round());
    });

    test('撃った後は、間隔があくまで撃たない', () {
      final path = stage.paths.first;
      final at = path[2];
      final slot = stage.slots.firstWhere((c) => (c.col - at.col).abs() <= 1 && (c.row - at.row).abs() <= 1);
      final f = Facility(FacilityType.farm, slot);
      var st = scene([enemy('a')], {slot: f});
      final cd = engine.facilityStats(f).cooldown;
      var shots = 0;
      for (var i = 0; i < (cd * 3 / BattleEngine.step).round(); i++) {
        final r = engine.tick(st, BattleEngine.step);
        shots += r.events.where((e) => e.type == BattleEventType.hit).length;
        st = r.state;
      }
      expect(shots, inInclusiveRange(3, 4)); // 3秒ぶんの間隔で、3〜4発
    });

    test('射程の外の敵は撃たない', () {
      final path = stage.paths.first;
      final start = path.first;
      final far = stage.slots.reduce((a, b) => a.manhattan(start) >= b.manhattan(start) ? a : b);
      final f = Facility(FacilityType.farm, far);
      final e = enemy('a', progress: 0);
      final p = e.position(path);
      final dist2 = (p.x - far.col) * (p.x - far.col) + (p.y - far.row) * (p.y - far.row);
      final range = engine.facilityStats(f).range;
      expect(dist2, greaterThan(range * range), reason: 'このテストは、射程の外に敵がいる配置が前提');
      final r = engine.tick(scene([e], {far: f}), 1 / 30);
      expect(r.events.where((x) => x.type == BattleEventType.hit), isEmpty);
    });
  });

  test('全地域（ドイツ16・米国51）で、バトルを始めて最後まで動かせる（例外なし。防衛なしは敗北）', () {
    for (final pack in [de, us]) {
      for (final r in pack.regions) {
        final st = StageGenerator(pack).generate(r.id, Difficulty.normal);
        final e = BattleEngine(st, profile: pack.profile);
        final res = e.runToEnd(e.start(), maxSeconds: 900);
        expect(res.state.phase, BattlePhase.defeat, reason: '${r.id}: ${res.state.summary()}');
      }
    }
  });
}
