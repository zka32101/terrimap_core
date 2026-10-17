import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/pack/pack_validator.dart';
import 'package:terrimap_core/pack/region_pack.dart';

RegionPack load(String id) {
  String r(String f) => File('packs/$id/$f').readAsStringSync();
  final langs = Directory('packs/$id/strings').listSync().map((e) => e.uri.pathSegments.last.replaceAll('.json', ''));
  return RegionPack.parse(
      packJson: r('pack.json'), regionsJson: r('regions.json'), geoJson: r('geo.geojson'),
      stringsJsonByLang: {for (final l in langs) l: r('strings/$l.json')});
}

bool inRing(double x, double y, List<List<double>> ring) {
  var inside = false;
  for (var i = 0; i < ring.length - 1; i++) {
    final a = ring[i], b = ring[i + 1];
    if ((a[1] > y) != (b[1] > y) && x < a[0] + (y - a[1]) / (b[1] - a[1]) * (b[0] - a[0])) inside = !inside;
  }
  return inside;
}

Map<String, Set<String>> nbOf(RegionPack p) => {for (final r in p.regions) r.id: r.neighbors.toSet()};

void main() {
  for (final id in ['de', 'us']) {
    final pack = load(id);
    test('$id: 全地域に州都の位置があり、州の形の内側にある', () {
      for (final r in pack.regions) {
        expect(r.capitalPos, isNotNull, reason: r.id);
        expect(r.polygons.any((poly) => inRing(r.capitalPos![0], r.capitalPos![1], poly)), isTrue, reason: '${r.id} の州都が形の外');
      }
    });
    test('$id: 隣接は対称で、自分自身を含まず、実在する地域だけ', () {
      final nb = nbOf(pack);
      nb.forEach((a, set) {
        expect(set.contains(a), isFalse, reason: a);
        for (final b in set) {
          expect(nb.containsKey(b), isTrue, reason: '$a→$b は未知');
          expect(nb[b]!.contains(a), isTrue, reason: '$a→$b だけ');
        }
      });
    });
  }

  test('ドイツ: 隣接の実例', () {
    final nb = nbOf(load('de'));
    expect(nb['DE-BE'], {'DE-BB'}); // ベルリンはブランデンブルクに囲まれる(飛び地。ポリゴンに穴が無くても検出する)
    expect(nb['DE-SL'], {'DE-RP'});
    expect(nb['DE-HB'], {'DE-NI'});
    expect(nb['DE-HH'], {'DE-NI', 'DE-SH'});
    expect(nb['DE-BY'], {'DE-BW', 'DE-HE', 'DE-SN', 'DE-TH'});
    expect(nb['DE-NI']!.length, 9);
  });

  test('米国: 隣接の実例', () {
    final nb = nbOf(load('us'));
    expect(nb['US-AK'], isEmpty);
    expect(nb['US-HI'], isEmpty);
    expect(nb['US-ME'], {'US-NH'});
    expect(nb['US-DC'], {'US-MD', 'US-VA'});
    expect(nb['US-TN']!.length, 8);
    expect(nb['US-MO']!.length, 8);
    expect(nb['US-AZ']!.contains('US-CO'), isFalse); // フォー・コーナーズは点で接するだけ(隣としない)
    expect(nb['US-UT']!.contains('US-NM'), isFalse);
    expect(nb['US-WY']!.contains('US-CO'), isTrue);
    expect(nb['US-OR']!.contains('US-NV'), isTrue);
    expect(nb['US-OK']!.contains('US-CO'), isTrue); // 短い境界(パンハンドル)
  });

  test('米国: 湖の上の境界も隣として扱う(ミシガン-ミネソタ・イリノイ)', () {
    final nb = nbOf(load('us'));
    expect(nb['US-MI'], {'US-IL', 'US-IN', 'US-MN', 'US-OH', 'US-WI'});
  });

  group('検証が誤りを検出する', () {
    Map<String, String> files(String id) {
      String r(String f) => File('packs/$id/$f').readAsStringSync();
      return {'pack': r('pack.json'), 'regions': r('regions.json'), 'geo': r('geo.geojson'), 'en': r('strings/en.json')};
    }

    List<String> run(Map<String, String> f, void Function(List regs) edit) {
      final regs = jsonDecode(f['regions']!)['regions'] as List;
      edit(regs);
      return PackValidator.validate(
          packJson: f['pack']!, regionsJson: jsonEncode({'regions': regs}), geoJson: f['geo']!,
          stringsJsonByLang: {'en': f['en']!});
    }

    Map reg(List regs, String id) => regs.firstWhere((r) => r['id'] == id) as Map;

    test('州都の位置が形の外', () {
      final err = run(files('de'), (regs) => reg(regs, 'DE-BY')['capitalPos'] = {'x': 0.0, 'y': 0.0});
      expect(err.any((e) => e.contains('DE-BY') && e.contains('形の外')), isTrue);
    });
    test('隣接が非対称', () {
      final err = run(files('de'), (regs) => (reg(regs, 'DE-SL')['neighbors'] as List).add('DE-BY'));
      expect(err.any((e) => e.contains('非対称')), isTrue);
    });
    test('隣接に自分自身・未知の地域・重複', () {
      final err = run(files('de'), (regs) {
        (reg(regs, 'DE-SL')['neighbors'] as List).addAll(['DE-SL', 'XX-ZZ', 'DE-RP']);
      });
      expect(err.any((e) => e.contains('自分自身')), isTrue);
      expect(err.any((e) => e.contains('未知の地域')), isTrue);
      expect(err.any((e) => e.contains('重複')), isTrue);
    });
    test('一部の地域だけ capitalPos があるのは不可', () {
      final err = run(files('us'), (regs) => reg(regs, 'US-AK').remove('capitalPos'));
      expect(err.any((e) => e.contains('capitalPos') && e.contains('全地域')), isTrue);
    });
    test('どちらも無い旧形式は通る', () {
      final err = run(files('us'), (regs) {
        for (final r in regs) {
          (r as Map).remove('capitalPos');
          r.remove('neighbors');
        }
      });
      expect(err, isEmpty);
    });
  });
}
