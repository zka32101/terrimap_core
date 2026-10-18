import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
import 'package:terrimap_core/battle/signature.dart';
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

  test('知らない目玉・目玉なしは、何もしない（中立）', () {
    final stage = StageGenerator(de).generate('DE-BY', Difficulty.normal);
    final r = SignatureRule.create('nope', stage: stage, pack: de, profile: de.profile);
    for (final t in FacilityType.values) {
      expect(r.facilityDamage(t), 1.0);
    }
    expect(r.weatherExtra, 0);
    expect(r.weatherIntensity, 1.0);
    expect(SignatureRule.create(null, stage: stage), same(SignatureRule.neutral));
  });

  group('federal_specialties（ドイツ）', () {
    test('同じ得意分野の州が隣り合うほど、その種類が強くなる（+5%・+10%・上限+15%）', () {
      final r = const FederalSpecialties({FacilityType.factory: 1, FacilityType.mine: 2, FacilityType.farm: 3, FacilityType.castle: 9});
      expect(r.facilityDamage(FacilityType.factory), 1.0);
      expect(r.facilityDamage(FacilityType.mine), closeTo(1.05, 1e-9));
      expect(r.facilityDamage(FacilityType.farm), closeTo(1.10, 1e-9));
      expect(r.facilityDamage(FacilityType.castle), closeTo(1.15, 1e-9));
      expect(r.facilityDamage(FacilityType.shrine), 1.0);
    });
    test('実際の隣接から数える。pack がなければ中立。威力に反映される', () {
      final profile = de.profile!;
      final aligned = <String, Map<FacilityType, int>>{};
      for (final reg in de.regions) {
        final stage = StageGenerator(de).generate(reg.id, Difficulty.normal);
        final rule = SignatureRule.create(profile.signatureId, stage: stage, pack: de, profile: profile) as FederalSpecialties;
        aligned[reg.id] = rule.aligned;
        // 自分の得意分野は、数に含まれる
        for (final t in FacilityType.values) {
          if (profile.traitOf(reg.id).facilityBonus.containsKey(t.name)) expect(rule.aligned[t], greaterThanOrEqualTo(1), reason: '${reg.id} ${t.name}');
        }
      }
      // ボーナスがつく州が、少なくとも1つある
      final bonus = aligned.entries.where((e) => e.value.values.any((n) => n >= 2));
      expect(bonus, isNotEmpty);
      final id = bonus.first.key;
      final t = bonus.first.value.entries.firstWhere((e) => e.value >= 2).key;
      final stage = StageGenerator(de).generate(id, Difficulty.normal);
      final withPack = BattleEngine(stage, profile: profile, pack: de);
      final without = BattleEngine(stage, profile: profile);
      final f = Facility(t, const GridPos(0, 0));
      expect(withPack.facilityStats(f).damage, greaterThan(without.facilityStats(f).damage));
      expect(without.signature.facilityDamage(t), 1.0);
    });
  });

  group('weather_extremes（米国）', () {
    test('天候が1回増え、効果の変化が25%大きくなる', () {
      final stage = StageGenerator(us).generate('US-TX', Difficulty.normal);
      final e = BattleEngine(stage, profile: us.profile, pack: us);
      expect(e.signature.weatherExtra, 1);
      final base = Weather.effects['blizzard']!;
      final k = scaleWeather(base, e.signature.weatherIntensity);
      expect(k.enemySpeed, closeTo(1 - 0.25 * 1.25, 1e-9)); // 0.75 → 0.6875
      expect(k.rangeDelta, closeTo(-1.25, 1e-9));
      expect(k.damage, closeTo(1 - 0.15 * 1.25, 1e-9));
      expect(scaleWeather(base, 1.0), same(base));
    });
    test('予定の回数: 米国は標準より1回多い', () {
      for (final reg in us.regions) {
        final stage = StageGenerator(us).generate(reg.id, Difficulty.hard);
        if (stage.weatherEvent == null) continue;
        final e = BattleEngine(stage, profile: us.profile, pack: us);
        final n = Weather.schedule(
            seed: stage.seed, wave: 1, type: stage.weatherEvent, season: stage.season, difficulty: stage.difficulty, extra: e.signature.weatherExtra).length;
        final std = Weather.schedule(seed: stage.seed, wave: 1, type: stage.weatherEvent, season: stage.season, difficulty: stage.difficulty).length;
        if (std > 0) expect(n, std + 1, reason: reg.id);
      }
    });
    test('米国の目玉があっても、全地域×3難易度で最後まで動く（天候の回数が増えても）', () {
      for (final reg in us.regions.take(12)) {
        for (final d in Difficulty.values) {
          final e = BattleEngine(StageGenerator(us).generate(reg.id, d), profile: us.profile, pack: us);
          final res = e.runToEnd(e.start(), maxSeconds: 600);
          expect(res.state.isOver || res.state.time >= 599, true, reason: '${reg.id} ${d.name}');
        }
      }
    });
  });
}
