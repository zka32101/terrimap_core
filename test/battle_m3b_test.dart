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

/// chain を撃つ施設を、テスト用に差し込む。
class ChainEngine extends BattleEngine {
  ChainEngine(super.stage, {super.profile});
  @override
  ({int damage, double range, double cooldown, String action}) facilityStats(Facility f, {int wave = 1}) =>
      (damage: 100, range: 3.0, cooldown: 1.0, action: 'chain');
}

void main() {
  final de = load('de');
  Stage st(Difficulty d) => StageGenerator(de).generate('DE-BY', d);
  final stage = st(Difficulty.normal);
  final engine = BattleEngine(stage, profile: de.profile);
  final path = stage.paths.first;
  final slot = stage.slots.where((c) => (c.col - path[2].col).abs() <= 1 && (c.row - path[2].row).abs() <= 1).toList()..sort();

  Enemy enemy(String id, double progress) => Enemy(
      id: id, kind: 'normal', pathIndex: 0, hp: 100000, maxHp: 100000, speed: 0, progress: progress, isBoss: false, armor: 0, breachDamage: 1);

  BattleState scene(List<Enemy> es, [Map<GridPos, Facility> fs = const {}, String? skill]) => BattleState(
      phase: BattlePhase.wave, wave: 1, prepTimer: 0, spawned: stage.waves.first.enemyCount, spawnAcc: 0, enemies: es,
      facilities: fs, coins: 0, baseHp: stage.baseHp, score: 0, mistakes: 0, time: 0, skill: skill);

  test('chain: 近い順に100%・70%・50%で当たる', () {
    final e = ChainEngine(stage, profile: de.profile);
    final f = Facility(FacilityType.farm, slot.first);
    for (var t = 0;; t++) {
      if (e.isCrit(t + 1, f.pos, 'd')) continue;
      final r = e.tick(scene([enemy('a', 1.5), enemy('b', 2.0), enemy('c', 2.5), enemy('d', 3.0)], {f.pos: f}).copyWith(tickCount: t), 1 / 30);
      final hits = {for (final h in r.events.where((x) => x.type == BattleEventType.hit)) h.enemyId!: h.value};
      // 拠点にいちばん近い d が本命で、近い順に c、b へ跳ねる。3回までなので a には当たらない
      expect(hits['d'], 100);
      expect(hits['c'], 70);
      expect(hits['b'], 50);
      expect(hits.containsKey('a'), false);
      break;
    }
  });

  group('スキル選択', () {
    final s0 = engine.start();
    test('候補は3つで、決定的。準備中だけ', () {
      final c = engine.skillChoices(s0);
      expect(c.length, 3);
      expect(c.toSet().length, 3);
      expect(engine.skillChoices(s0), c);
      expect(engine.skillChoices(scene([])), isEmpty);
    });
    test('候補にあるものだけ選べ、選ぶと候補は空になる', () {
      final c = engine.skillChoices(s0);
      expect(engine.chooseSkill(s0, 'nonexistent'), isNull);
      final s1 = engine.chooseSkill(s0, c.first)!;
      expect(s1.skill, c.first);
      expect(engine.skillChoices(s1), isEmpty);
      expect(engine.chooseSkill(s1, c.first), isNull);
    });
    test('repair は hard だけ。選ぶと停止・妨害が直る', () {
      final seen = <String>{};
      for (final d in Difficulty.values) {
        final e = BattleEngine(st(d), profile: de.profile);
        var s = e.start();
        for (var w = 0; w < 40; w++) {
          seen.addAll(e.skillChoices(s));
          s = s.copyWith(wave: s.wave + 1);
        }
        if (d != Difficulty.hard) expect(seen.contains('repair'), false);
      }
      final hard = BattleEngine(st(Difficulty.hard), profile: de.profile);
      var s = hard.start();
      while (!hard.skillChoices(s).contains('repair')) {
        s = s.copyWith(wave: s.wave + 1);
      }
      final f = Facility(FacilityType.farm, slot.first, disabledUntil: 99, sabotagedUntil: 99);
      final r = hard.chooseSkill(s.copyWith(facilities: {f.pos: f}), 'repair')!;
      expect(r.facilities[f.pos]!.disabledUntil, 0);
      expect(r.facilities[f.pos]!.sabotagedUntil, 0);
    });
    test('weatherBlock は無効化の回数を増やす', () {
      var s = engine.start();
      while (!engine.skillChoices(s).contains('weatherBlock')) {
        s = s.copyWith(wave: s.wave + 1);
      }
      expect(engine.chooseSkill(s, 'weatherBlock')!.weatherBlocks, 1);
    });
    test('効果: 威力+25%・射程+1・速度+15%・コイン+20%・鈍足', () {
      final f = Facility(FacilityType.farm, slot.first);
      int dmg(String? skill) {
        for (var t = 0;; t++) {
          if (engine.isCrit(t + 1, f.pos, 'd')) continue;
          final r = engine.tick(scene([enemy('a', 2)], {f.pos: f}, skill).copyWith(tickCount: t), 1 / 30);
          return r.events.firstWhere((x) => x.type == BattleEventType.hit).value!;
        }
      }
      expect(dmg('waveAtkBonus'), (dmg(null) * 1.25).round());
      // 射程: 設置枠から離れた敵に、通常は届かず、waveRangeBonus なら届く
      final range = engine.facilityStats(f).range;
      Enemy? far;
      for (var p = 0.0; p < path.length - 1; p += 0.25) {
        final q = Enemy.positionAt(false, p, path);
        final d = (q.x - f.pos.col) * (q.x - f.pos.col) + (q.y - f.pos.row) * (q.y - f.pos.row);
        if (d > (range + 0.1) * (range + 0.1) && d <= (range + 0.9) * (range + 0.9)) {
          far = enemy('a', p);
          break;
        }
      }
      if (far != null) {
        bool hit(String? sk) => engine.tick(scene([far!], {f.pos: f}, sk), 1 / 30).events.any((x) => x.type == BattleEventType.hit);
        expect(hit(null), false);
        expect(hit('waveRangeBonus'), true);
      }
      // 攻撃速度: 撃った後のクールダウンが短くなる
      double cd(String? sk) => engine.tick(scene([enemy('a', 2)], {f.pos: f}, sk), 1 / 30).state.facilities[f.pos]!.cooldown;
      expect(cd('waveAtkSpeedBonus'), closeTo(cd(null) / 1.15, 1e-9));
      // 鈍足: 敵の進みが20%減る
      Enemy mover() => Enemy(id: 'm', kind: 'normal', pathIndex: 0, hp: 9, maxHp: 9, speed: 1, progress: 1, isBoss: false, armor: 0, breachDamage: 1);
      double moved(String? sk) => engine.tick(scene([mover()], const {}, sk), 1.0).state.enemies.first.progress - 1;
      expect(moved('slow'), closeTo(moved(null) * 0.8, 1e-9));
      // コイン
      Enemy weak() => Enemy(id: 'k', kind: 'normal', pathIndex: 0, hp: 1, maxHp: 1, speed: 0, progress: 2, isBoss: false, armor: 0, breachDamage: 1);
      int coins(String? sk) => engine.tick(scene([weak()], {f.pos: f}, sk), 1 / 30).state.coins;
      expect(coins('waveCoinBonus'), greaterThan(coins(null)));
    });
    test('効果は次の波だけ（波が終わると外れる）', () {
      var s = engine.chooseSkill(engine.start(), engine.skillChoices(engine.start()).first)!;
      s = engine.startWave(s).state;
      expect(s.skill, isNotNull);
      final f = Facility(FacilityType.farm, slot.first);
      s = s.copyWith(facilities: {f.pos: f}, coins: 0);
      var cleared = false;
      for (var i = 0; i < 30 * 600 && !s.isOver && !cleared; i++) {
        final r = engine.tick(s, 1 / 30);
        s = r.state;
        cleared = r.events.any((e) => e.type == BattleEventType.waveClear);
      }
      if (cleared && !s.isOver) {
        expect(s.skill, isNull);
        expect(s.phase, BattlePhase.prep);
      }
    });
  });

  group('難易度の細部', () {
    test('波数・開始コイン・拠点HPが難易度で変わる', () {
      final e = st(Difficulty.easy), n = st(Difficulty.normal), h = st(Difficulty.hard);
      expect(e.waves.length, n.waves.length - 1);
      expect(h.waves.length, n.waves.length + 2);
      int c(Stage s) => BattleEngine(s, profile: de.profile).start().coins;
      expect(c(e), greaterThan(c(n)));
      expect(c(n), greaterThan(c(h)));
      expect(e.baseHp, n.baseHp + 8);
      expect(h.baseHp, n.baseHp - 2);
    });
    test('hard の敵のHPと速さは normal より大きい', () {
      final en = BattleEngine(st(Difficulty.normal), profile: de.profile), eh = BattleEngine(st(Difficulty.hard), profile: de.profile);
      final wn = en.stage.waves.first, wh = eh.stage.waves.first;
      expect(wh.baseHp, greaterThan(wn.baseHp));
      final i = [for (var k = 0; k < wn.enemyCount && k < wh.enemyCount; k++) k].firstWhere((k) => wn.enemyKinds[k] == wh.enemyKinds[k] && k < wn.enemyCount - 1);
      expect(eh.makeEnemy(wh, i).speed / en.makeEnemy(wn, i).speed, closeTo(difficultyParams[Difficulty.hard]!.speedMultiplier, 1e-9));
    });
    test('easy は到達の被害が常に1', () {
      final e = BattleEngine(st(Difficulty.easy), profile: de.profile);
      for (final w in e.stage.waves) {
        for (var i = 0; i < w.enemyCount; i++) {
          expect(e.makeEnemy(w, i).breachDamage, 1);
        }
      }
    });
  });
}
