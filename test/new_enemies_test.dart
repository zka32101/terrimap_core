import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/difficulty.dart';
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
      expect(engine.makeEnemy(w('saboteur'), 0).action, 'sabotage', reason: id);
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
}
