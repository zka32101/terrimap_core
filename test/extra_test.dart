import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/bot.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
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
  final packs = {'de': load('de'), 'us': load('us')};

  test('各国に3つのエクストラ。波は8〜10で段階的に増え、題材は伝説・伝記・歴史のどれか', () {
    for (final e in packs.entries) {
      final xs = e.value.profile!.extras;
      expect(xs.length, 3, reason: e.key);
      expect([for (final x in xs) x.waves], [8, 9, 10], reason: e.key);
      expect(xs.map((x) => x.id).toSet().length, 3);
      for (final x in xs) {
        expect(x.seasons.length, 4, reason: x.id); // 4季が巡る
        expect(x.seasons.toSet().length, 4, reason: x.id);
        expect(x.titleIn('en'), isNotEmpty);
        expect(x.factIn('en'), isNotEmpty); // 事実と伝承の注記
        expect(x.bossNameIn('en'), isNotEmpty);
        expect(x.titleIn('xx'), x.titleIn('en')); // 言語がなければ英語
      }
    }
  });

  group('エクストラの生成', () {
    for (final e in packs.entries) {
      for (final x in e.value.profile!.extras) {
        for (final d in Difficulty.values) {
          test('${e.key} ${x.id} ${d.name}', () {
            final st = StageGenerator(e.value).generate(x.id, d, kind: StageKind.extra);
            expect(st.kind, StageKind.extra);
            expect(st.extraId, x.id);
            expect(st.regionId, x.center);
            expect(st.id, '${x.id}:${d.name}:extra');
            expect(st.waves.length, x.waves);
            expect(st.waves.first.baseHp, (48 * difficultyParams[d]!.hpMultiplier * StageGenerator.extraHpScale).round());
            expect(st.waves.last.hasBoss, true);
            expect(st.weatherEvent, x.weatherEvent);
            expect(st.backdrop, x.backdrop);
            expect(st.bossSkill, x.bossSkill);
            expect(st.weatherBoost, 1);
            // 季節は波ごとに巡る
            expect(st.season.name, x.seasons.first);
            for (var w = 1; w <= x.waves; w++) {
              expect(st.seasonAt(w).name, x.seasons[(w - 1) % x.seasons.length]);
            }
            expect(st.memberIds, contains(x.center));
            expect(st.entrances, isNotEmpty);
            expect(st.slots.length, greaterThanOrEqualTo(6));
            expect(StageGenerator(e.value).generate(x.id, d, kind: StageKind.extra).toJsonString(), st.toJsonString());
          });
        }
      }
    }
  });

  group('エクストラのバトル', () {
    test('ボスのスキルは指定どおり。季節の効果が波ごとに変わる', () {
      final de = packs['de']!;
      final x = de.profile!.extras.first;
      final st = StageGenerator(de).generate(x.id, Difficulty.normal, kind: StageKind.extra);
      final e = BattleEngine(st, profile: de.profile, pack: de);
      expect(e.bossSkill, x.bossSkill);
      // 秋 → 冬: 冬は敵が10%遅い
      final w1 = st.waves[0], w2 = st.waves[1];
      expect(st.seasonAt(1).name, 'autumn');
      expect(st.seasonAt(2).name, 'winter');
      final s1 = e.makeEnemy(w1, 0).speed / e.lengthFactor(st.paths[w1.entranceIndices[0]].length) / 1.2;
      final s2 = e.makeEnemy(w2, 0).speed / e.lengthFactor(st.paths[w2.entranceIndices[0]].length) / 1.2;
      expect(s2 / s1, closeTo(0.9, 1e-9));
    });
    test('天候が標準より1回多い', () {
      final us = packs['us']!;
      final x = us.profile!.extras.first; // blizzard・winter から始まる
      final st = StageGenerator(us).generate(x.id, Difficulty.normal, kind: StageKind.extra);
      final e = BattleEngine(st, profile: us.profile, pack: us);
      final base = Weather.schedule(seed: st.seed, wave: 1, type: st.weatherEvent, season: st.seasonAt(1), difficulty: st.difficulty).length;
      final withExtra = Weather.schedule(
              seed: st.seed, wave: 1, type: st.weatherEvent, season: st.seasonAt(1), difficulty: st.difficulty,
              extra: e.signature.weatherExtra + st.weatherBoost)
          .length;
      expect(withExtra, base + 2); // 米国の目玉(+1)とエクストラ(+1)
    });
    test('全エクストラ×3難易度で、ボットが最後まで遊べる。バランスの目安: hard は normal 以上に勝ちにくい', () {
      final wins = {for (final d in Difficulty.values) d: 0};
      var n = 0;
      for (final p in packs.values) {
        for (final x in p.profile!.extras) {
          n++;
          for (final d in Difficulty.values) {
            final st = StageGenerator(p).generate(x.id, d, kind: StageKind.extra);
            final r = BattleBot(BattleEngine(st, profile: p.profile, pack: p), BotProfile.expert).play(maxSeconds: 900);
            expect(r.wave, greaterThan(0), reason: '${x.id} ${d.name}');
            if (r.won) wins[d] = wins[d]! + 1;
          }
        }
      }
      expect(wins[Difficulty.hard]!, lessThanOrEqualTo(wins[Difficulty.normal]!), reason: '$wins / $n');
      // ignore: avoid_print
      print('extra expert wins: $wins of $n');
    });
  });
}
