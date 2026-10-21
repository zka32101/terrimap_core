import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
  test('すべての州に紹介文がある(英語・日本語は必須、国の言語すべてに文がある)。ない言語は英語になる', () {
    for (final id in ['de', 'us']) {
      final pack = load(id);
      final langs = ['en', 'ja', if (id == 'de') 'de', 'fr', 'es', 'it', 'pt', 'nl', 'tr', 'ko', 'zh'];
      for (final r in pack.regions) {
        final t = pack.profile!.traitOf(r.id);
        for (final l in langs) {
          expect(t.blurbIn(l).trim(), isNotEmpty, reason: '$id ${r.id} $l');
        }
        expect(t.blurbIn('xx'), t.blurbIn('en')); // 未対応の言語は英語
        expect(t.blurbIn('en').length, lessThan(300), reason: '${r.id} 長すぎる');
      }
    }
  });
}
