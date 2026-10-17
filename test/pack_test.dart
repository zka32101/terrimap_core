import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/pack/region_pack.dart';

void main() {
  test('de pack parses: 16 regions, names present', () {
    String r(String f) => File('packs/de/$f').readAsStringSync();
    final pack = RegionPack.parse(
      packJson: r('pack.json'), regionsJson: r('regions.json'),
      geoJson: r('geo.geojson'), stringsJsonByLang: {'en': r('strings/en.json')});
    expect(pack.regions.length, 16);
    expect(pack.strings['en']!['regions']!['DE-BY'], 'Bavaria');
  });
}
