import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
import 'package:terrimap_core/battle/stage_generator.dart';
import 'package:terrimap_core/battle/stage.dart';
import 'package:terrimap_core/pack/country_profile.dart';
import 'package:terrimap_core/pack/region_pack.dart';

RegionPack load(String id) {
  String r(String f) => File('packs/$id/$f').readAsStringSync();
  final langs = Directory('packs/$id/strings')
      .listSync()
      .map((e) => e.uri.pathSegments.last.replaceAll('.json', ''));
  return RegionPack.parse(
      packJson: r('pack.json'),
      regionsJson: r('regions.json'),
      geoJson: r('geo.geojson'),
      stringsJsonByLang: {for (final l in langs) l: r('strings/$l.json')},
      profileJson: r('profile.json'));
}

Set<String> kindsOf(RegionPack pack, int rules) {
  final g = StageGenerator(pack, rules: rules);
  return {
    for (final r in pack.regions)
      for (final d in Difficulty.values)
        for (final w in g.generate(r.id, d).waves) ...w.enemyKinds,
  };
}

void main() {
  test('ルール版2のステージは、新しい敵を含まず、版3では新しい敵が出る（古い記録のステージを変えない）', () {
    for (final id in ['de', 'us']) {
      final pack = load(id);
      expect(
          kindsOf(pack, 2).difference(CountryProfile.baseEnemyKinds), isEmpty,
          reason: id);
      expect(kindsOf(pack, 3).intersection(CountryProfile.newEnemyKinds),
          CountryProfile.newEnemyKinds,
          reason: id);
    }
  });

  test('版2と版3で、4種類の敵だけの波は、版2のステージと同じ並び（乱数の使い方が変わらない）', () {
    final pack = load('de');
    final a =
        StageGenerator(pack, rules: 2).generate('DE-BY', Difficulty.normal);
    final b =
        StageGenerator(pack, rules: 3).generate('DE-BY', Difficulty.normal);
    // 新しい敵が出始める前の波（1〜4波）は同じ
    for (var i = 0; i < 4; i++) {
      expect(b.waves[i].enemyKinds, a.waves[i].enemyKinds);
    }
  });

  test('新しい敵: 飛ぶ敵は直進、妨害の敵は妨害、群れの敵は群れ。能力が国のデータから付く', () {
    for (final id in ['de', 'us']) {
      final pack = load(id);
      final st = StageGenerator(pack)
          .generate(pack.regions.first.id, Difficulty.normal);
      final engine = BattleEngine(st, profile: pack.profile, pack: pack);
      StageWave w(String k) => StageWave(
          number: 1,
          enemyCount: 1,
          baseHp: 100,
          baseAttack: 7,
          spawnInterval: 1,
          hasBoss: false,
          enemyKinds: [k],
          entranceIndices: const [0]);
      expect(engine.makeEnemy(w('flyer'), 0).flying, isTrue, reason: id);
      expect(engine.makeEnemy(w('saboteur'), 0).action,
          pack.profile!.enemyOf('saboteur').action,
          reason: id);
      expect(pack.profile!.enemyOf('saboteur').action, isNot('none'),
          reason: id);
      expect(engine.makeEnemy(w('swarmer'), 0).ability, 'swarm', reason: id);
    }
  });

  test('分裂の敵: 倒すと2体に分かれ、分かれた敵はもう分かれない。波は分かれた敵を倒すまで終わらない', () {
    final pack = load('us');
    final st =
        StageGenerator(pack).generate(pack.regions.first.id, Difficulty.normal);
    final engine = BattleEngine(st, profile: pack.profile, pack: pack);
    final w = st.waves.first;
    final parent = engine.makeEnemy(
        StageWave(
            number: 1,
            enemyCount: 1,
            baseHp: 100,
            baseAttack: 7,
            spawnInterval: 1,
            hasBoss: false,
            enemyKinds: const ['splitter'],
            entranceIndices: const [0]),
        0);
    var s = engine.startWave(engine.start()).state;
    s = s.copyWith(enemies: [
      parent.copyWith(hp: 5, progress: 1.0, burnUntil: 1000, burnDps: 500)
    ], spawned: w.enemyCount);
    final r = engine.tick(s, BattleEngine.step);
    final kids = r.state.enemies;
    expect(kids.length, BattleEngine.splitCount);
    expect(
        kids.every((e) =>
            e.kind == 'splitter' &&
            e.id.contains('_p') &&
            e.maxHp < parent.maxHp),
        isTrue);
    expect(r.state.phase, BattlePhase.wave); // 子が残っているので波は終わらない
    // 子を倒しても、さらには分かれない
    final k = [
      for (final e in kids) e.copyWith(hp: 1, burnUntil: 1000, burnDps: 500)
    ];
    final r2 = engine.tick(r.state.copyWith(enemies: k), BattleEngine.step);
    expect(r2.state.enemies.where((e) => e.kind == 'splitter').length,
        lessThan(kids.length + 1));
    expect(r2.state.enemies.every((e) => !e.id.contains('_p') || e.hp > 0),
        isTrue);
    expect(r2.state.enemies.length, 0);
  });

  test('見た目違いごとの特性: 版3は見た目違いの特性が効き、版2は基本のまま。選び方は見た目と同じ', () {
    final pack = load('de');
    final prof = pack.profile!;
    final base = prof.enemyOf('armored');
    final st = StageGenerator(pack).generate('DE-BY', Difficulty.normal);
    final e3 = BattleEngine(st, profile: prof, pack: pack);
    final e2 = BattleEngine(st, profile: prof, pack: pack, rules: 2);
    final seen = <String>{};
    for (var i = 0; i < 60; i++) {
      final w = StageWave(
          number: 1,
          enemyCount: 60,
          baseHp: 100,
          baseAttack: 7,
          spawnInterval: 1,
          hasBoss: false,
          enemyKinds: List.filled(60, 'armored'),
          entranceIndices: const [0]);
      final v = prof.variantFor('armored', 'e1_$i',
          regionId: st.regionId, groupId: st.groupId);
      final a = e3.makeEnemy(w, i), b = e2.makeEnemy(w, i);
      expect(b.maxHp, (100 * 2.0 * base.hp).round(), reason: '版2は基本の特性');
      if (v == null) {
        expect(a.maxHp, b.maxHp);
      } else {
        seen.add(v.skin);
        final t = v.trait!;
        expect(a.maxHp, (100 * 2.0 * base.hp * t.hp).round(), reason: v.skin);
        expect(a.armor, 8 + base.armor + t.armor, reason: v.skin);
        if (t.ability != 'none') expect(a.ability, t.ability, reason: v.skin);
      }
    }
    expect(seen, isNotEmpty);
  });

  test('新しい敵は国ごとに違う: 能力・倍率・出る割合が、ドイツとアメリカで同じでない', () {
    final de = load('de').profile!, us = load('us').profile!;
    for (final k in CountryProfile.newEnemyKinds) {
      final a = de.enemyOf(k), b = us.enemyOf(k);
      final same = a.hp == b.hp &&
          a.speed == b.speed &&
          a.baseDamage == b.baseDamage &&
          a.armor == b.armor &&
          a.ability == b.ability &&
          a.action == b.action;
      expect(same, isFalse, reason: k);
      expect(de.enemyMixV3[k], isNot(us.enemyMixV3[k]), reason: k);
    }
    expect(de.enemyOf('saboteur').action, isNot(us.enemyOf('saboteur').action));
  });

  test('hard だけの敵: 版4の hard にだけ出る。版3以前・easy・normal には出ない', () {
    for (final id in ['de', 'us']) {
      final pack = load(id);
      Set<String> kindsAt(int rules, Difficulty d) => {
            for (final r in pack.regions)
              for (final w
                  in StageGenerator(pack, rules: rules).generate(r.id, d).waves)
                ...w.enemyKinds,
          };
      expect(
          kindsAt(4, Difficulty.hard)
              .intersection(CountryProfile.hardEnemyKinds),
          CountryProfile.hardEnemyKinds,
          reason: id);
      expect(
          kindsAt(4, Difficulty.normal)
              .intersection(CountryProfile.hardEnemyKinds),
          isEmpty,
          reason: id);
      expect(
          kindsAt(4, Difficulty.easy)
              .intersection(CountryProfile.hardEnemyKinds),
          isEmpty,
          reason: id);
      expect(
          kindsAt(3, Difficulty.hard)
              .intersection(CountryProfile.hardEnemyKinds),
          isEmpty,
          reason: id);
    }
  });

  test('ミニボス: 地方決戦・エクストラの中盤に1体、通常の州ステージにはいない。ボスより軽く、スキルを使う', () {
    for (final id in ['de', 'us']) {
      final pack = load(id);
      final prof = pack.profile!;
      final g = StageGenerator(pack);
      expect(
          g
              .generate(pack.regions.first.id, Difficulty.hard)
              .waves
              .any((w) => w.miniBoss),
          isFalse,
          reason: id);
      for (final grp in prof.groups.keys) {
        final st = g.generate(grp, Difficulty.normal, kind: StageKind.regional);
        final minis = st.waves.where((w) => w.miniBoss).toList();
        expect(minis.length, 1, reason: '$id $grp');
        expect(minis.single.hasBoss, isFalse);
        final engine = BattleEngine(st, profile: prof, pack: pack);
        final w = minis.single;
        final e = engine.makeEnemy(w, w.enemyCount - 1);
        final boss =
            engine.makeEnemy(st.waves.last, st.waves.last.enemyCount - 1);
        expect(e.isMini, isTrue);
        expect(e.isBoss, isFalse);
        expect(e.bossSkill, prof.miniBossFor(st.regionId, groupId: grp)!.skill);
        expect(e.maxHp, (w.baseHp * BattleEngine.miniHp).round());
        expect(e.maxHp / w.baseHp, lessThan(boss.maxHp / st.waves.last.baseHp));
        // 版3では出ない
        expect(
            BattleEngine(st, profile: prof, pack: pack, rules: 3)
                .makeEnemy(w, w.enemyCount - 1)
                .isMini,
            isFalse);
      }
      // 版3以前のステージには、ミニボスの印がない
      expect(
          StageGenerator(pack, rules: 3)
              .generate(prof.groups.keys.first, Difficulty.normal,
                  kind: StageKind.regional)
              .waves
              .any((w) => w.miniBoss),
          isFalse);
    }
  });
}
