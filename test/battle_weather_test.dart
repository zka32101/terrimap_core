import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
import 'package:terrimap_core/battle/stage.dart';
import 'package:terrimap_core/battle/stage_generator.dart';
import 'package:terrimap_core/battle/weather.dart';
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
  Stage by(Difficulty d) => StageGenerator(de).generate('DE-BY', d); // blizzard・winter

  group('予定', () {
    test('決定的で、難易度で回数が増え、持続は6〜12秒', () {
      final a = Weather.schedule(seed: 7, wave: 2, type: 'blizzard', season: Season.winter, difficulty: Difficulty.hard);
      final b = Weather.schedule(seed: 7, wave: 2, type: 'blizzard', season: Season.winter, difficulty: Difficulty.hard);
      expect([for (final s in a) (s.start, s.duration)], [for (final s in b) (s.start, s.duration)]);
      expect(a.length, 2);
      expect(Weather.schedule(seed: 7, wave: 2, type: 'blizzard', season: Season.winter, difficulty: Difficulty.normal).length, 1);
      for (final s in a) {
        expect(s.duration, inInclusiveRange(6, 12));
        expect(s.start, greaterThanOrEqualTo(Weather.firstStart));
      }
      expect(a[1].start, greaterThan(a[0].end - 1)); // 重ならない（間隔14秒 > 持続12秒）
    });
    test('天候がない・季節に合わない場合は空', () {
      expect(Weather.schedule(seed: 1, wave: 1, type: null, season: Season.winter, difficulty: Difficulty.normal), isEmpty);
      expect(Weather.schedule(seed: 1, wave: 1, type: 'blizzard', season: Season.summer, difficulty: Difficulty.normal), isEmpty);
      expect(Weather.schedule(seed: 1, wave: 1, type: 'heatwave', season: Season.winter, difficulty: Difficulty.normal), isEmpty);
      expect(Weather.fits('heatwave', Season.summer), true);
    });
    test('8種すべてに効果の表がある', () {
      expect(Weather.effects.keys.toSet(), Weather.types);
    });
  });

  group('進行', () {
    final stage = by(Difficulty.normal);
    final engine = BattleEngine(stage, profile: de.profile);
    final slot = Weather.schedule(seed: stage.seed, wave: 1, type: 'blizzard', season: stage.season, difficulty: stage.difficulty).first;

    BattleState wave1() => engine.startWave(engine.start()).state;

    test('予告→開始→終了の順にイベントが出る', () {
      final r = engine.advance(wave1(), slot.end + 1);
      final w = [for (final e in r.events) if (e.type.name.startsWith('weather')) e.type];
      expect(w.take(3), [BattleEventType.weatherWarning, BattleEventType.weatherStart, BattleEventType.weatherEnd]);
      expect(r.events.firstWhere((e) => e.type == BattleEventType.weatherStart).detail, 'blizzard');
    });
    test('weatherBlock があると1回防ぎ、回数が減る', () {
      final s = wave1().copyWith(weatherBlocks: 1);
      final r = engine.advance(s, slot.end + 1);
      expect(r.events.any((e) => e.type == BattleEventType.weatherBlocked), true);
      expect(r.events.any((e) => e.type == BattleEventType.weatherStart), false);
      expect(r.events.any((e) => e.type == BattleEventType.weatherEnd), false);
      expect(r.state.weatherBlocks, 0);
    });
    test('blizzard 中は敵が遅い（−25%）', () {
      Enemy mover() => Enemy(id: 'm', kind: 'normal', pathIndex: 0, hp: 99999, maxHp: 99999, speed: 1, progress: 0, isBoss: false, armor: 0, breachDamage: 1);
      BattleState at(double rel) => wave1().copyWith(enemies: [mover()], time: rel, waveStart: 0, spawned: stage.waves.first.enemyCount);
      double moved(double rel) => engine.tick(at(rel), 0.5).state.enemies.first.progress;
      final inside = slot.start + 1, outside = slot.end + 1;
      expect(moved(inside) / moved(outside), closeTo(0.75, 1e-9));
    });
  });

  group('季節', () {
    test('winter: 敵が全体に10%遅い', () {
      final st = by(Difficulty.normal);
      expect(st.season, Season.winter);
      final e = BattleEngine(st, profile: de.profile);
      final summer = st.withSeason(Season.summer);
      final es = BattleEngine(summer, profile: de.profile);
      final w = st.waves.first;
      expect(e.makeEnemy(w, 0).speed / es.makeEnemy(w, 0).speed, closeTo(0.9, 1e-9));
    });
    test('autumn: 撃破コイン+10%、summer: 足速型+5%・漁業が+10%威力', () {
      expect(Weather.seasons[Season.autumn]!.coin, 1.1);
      expect(Weather.seasons[Season.summer]!.speedySpeed, 1.05);
      final st = by(Difficulty.normal);
      final base = BattleEngine(st.withSeason(Season.autumn), profile: de.profile).facilityStats(Facility(FacilityType.fishery, const GridPos(0, 0))).damage;
      final summer = BattleEngine(st.withSeason(Season.summer), profile: de.profile).facilityStats(Facility(FacilityType.fishery, const GridPos(0, 0))).damage;
      expect(summer, (base * 1.1).round());
    });
  });

  test('全地域×3難易度で、天候があっても最後まで動く（ドイツ・米国の全天候）', () {
    final types = <String>{};
    for (final pack in [de, us]) {
      for (final r in pack.regions) {
        for (final d in Difficulty.values) {
          final stage = StageGenerator(pack).generate(r.id, d);
          final e = BattleEngine(stage, profile: pack.profile);
          final res = e.runToEnd(e.start(), maxSeconds: 1200);
          expect(res.state.phase == BattlePhase.defeat || res.state.isOver, true, reason: '${r.id} ${d.name}');
          for (final ev in res.events) {
            if (ev.type == BattleEventType.weatherStart) types.add(ev.detail!);
          }
        }
      }
    }
    expect(types.length, greaterThanOrEqualTo(4));
  });
}
