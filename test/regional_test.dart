import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/bot.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
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
  final packs = {'de': load('de'), 'us': load('us')};

  test('地方は、全地域を1回ずつ含む（重ならず、もれなし）', () {
    for (final e in packs.entries) {
      final all = [for (final g in e.value.profile!.groups.values) ...g.regions];
      expect(all.toSet().length, all.length, reason: e.key);
      expect(all.toSet(), {for (final r in e.value.regions) r.id}, reason: e.key);
    }
  });

  group('地方決戦の生成', () {
    for (final e in packs.entries) {
      for (final g in e.value.profile!.groups.values) {
        for (final d in Difficulty.values) {
          test('${e.key} ${g.id} ${d.name}', () {
            final st = StageGenerator(e.value).generate(g.id, d, kind: StageKind.regional);
            expect(st.kind, StageKind.regional);
            expect(st.groupId, g.id);
            expect(st.regionId, g.center);
            expect(st.id, '${g.id}:${d.name}:regional');
            // 盤面にある州は、地方の州の一部で、中心の州を含む
            expect(st.memberIds, contains(g.center));
            expect(g.regions.toSet().containsAll(st.memberIds), true);
            // 波: easy 6・normal 7・hard 8。最初の波の敵のHPは1.2倍
            expect(st.waves.length, 7 + (d == Difficulty.easy ? -1 : d == Difficulty.hard ? 1 : 0));
            expect(st.waves.first.baseHp, (48 * difficultyParams[d]!.hpMultiplier * 1.2).round());
            expect(st.waves.last.hasBoss, true);
            // 盤面・進路・設置枠
            expect(st.land.contains(st.base), true);
            expect(st.entrances, isNotEmpty);
            expect(st.paths.length, st.entrances.length);
            for (final p in st.paths) {
              expect(p.first, st.entrances[st.paths.indexOf(p)].cell);
              expect(p.last, st.base);
              for (var i = 0; i + 1 < p.length; i++) {
                expect(p[i].manhattan(p[i + 1]), 1);
              }
              expect(p.every(st.land.contains), true);
            }
            expect(st.slots.length, greaterThanOrEqualTo(6));
            expect(st.slots.every(st.land.contains), true);
            expect(st.cols, lessThanOrEqualTo(StageGenerator.regionalGridMax));
            expect(st.rows, lessThanOrEqualTo(StageGenerator.regionalGridMax));
            // 限定施設は、盤面にある州のもの
            expect(st.exclusiveFacilities.length, lessThanOrEqualTo(st.memberIds.length));
            // 決定的
            final again = StageGenerator(e.value).generate(g.id, d, kind: StageKind.regional);
            expect(again.toJsonString(), st.toJsonString());
          });
        }
      }
    }
  });

  test('地方決戦は州ごとのステージより広い', () {
    for (final e in packs.entries) {
      final gen = StageGenerator(e.value);
      for (final g in e.value.profile!.groups.values) {
        final big = gen.generate(g.id, Difficulty.normal, kind: StageKind.regional);
        final one = gen.generate(g.center, Difficulty.normal);
        expect(big.land.length, greaterThan(one.land.length), reason: '${e.key} ${g.id}');
      }
    }
  });

  test('未知の地方は例外。エクストラは M7b まで未実装', () {
    final gen = StageGenerator(packs['de']!);
    expect(() => gen.generate('nope', Difficulty.normal, kind: StageKind.regional), throwsArgumentError);
    expect(() => gen.generate('DE-BY', Difficulty.normal, kind: StageKind.extra), throwsUnimplementedError);
  });

  group('地方決戦のバトル', () {
    test('限定施設を複数置け、同じものは1つだけ', () {
      final de = packs['de']!;
      final st = StageGenerator(de).generate('west', Difficulty.normal, kind: StageKind.regional);
      final e = BattleEngine(st, profile: de.profile, pack: de);
      expect(e.exclusiveIds.length, greaterThanOrEqualTo(2));
      var s = e.start().copyWith(coins: 5000);
      final ids = e.exclusiveIds;
      s = e.placeExclusive(s, st.slots[0])!;
      s = e.placeExclusive(s, st.slots[1], id: ids[1])!;
      expect(s.facilities.values.where((f) => f.exclusive != null).length, 2);
      expect(e.placeExclusive(s, st.slots[2], id: ids[0]), isNull); // 同じものは置けない
      expect(e.exclusiveLeft(s).length, ids.length - 2);
    });
    test('クイズの問題は、地方の州と隣の州から出る', () {
      final de = packs['de']!;
      final st = StageGenerator(de).generate('south', Difficulty.normal, kind: StageKind.regional);
      final e = BattleEngine(st, profile: de.profile, pack: de);
      final pool = {...st.memberIds, for (final r in de.regions.where((r) => st.memberIds.contains(r.id))) ...r.neighbors};
      var s = e.start();
      for (var w = 0; w < 8; w++) {
        s = s.copyWith(wave: w);
        expect(pool.contains(e.assistQuestion(s)!.targetId), true);
      }
    });
    test('全地方×3難易度で、ボットが最後まで遊べる。バランスの目安: easy は多く勝て、normal は勝てることも負けることもあり、hard は難しい', () {
      final wins = {for (final d in Difficulty.values) d: 0};
      var groups = 0;
      for (final p in packs.values) {
        for (final g in p.profile!.groups.values) {
          groups++;
          for (final d in Difficulty.values) {
            final st = StageGenerator(p).generate(g.id, d, kind: StageKind.regional);
            final e = BattleEngine(st, profile: p.profile, pack: p);
            final r = BattleBot(e, BotProfile.regular).play(maxSeconds: 900);
            expect(r.wave, greaterThan(0), reason: '${g.id} ${d.name}');
            if (r.won) wins[d] = wins[d]! + 1;
          }
        }
      }
      expect(wins[Difficulty.easy]!, greaterThanOrEqualTo(groups * 0.6), reason: 'easy $wins');
      expect(wins[Difficulty.normal]!, greaterThanOrEqualTo(groups * 0.2), reason: 'normal $wins');
      expect(wins[Difficulty.hard]!, lessThanOrEqualTo(wins[Difficulty.normal]!), reason: 'hard $wins');
    });
  });
}
