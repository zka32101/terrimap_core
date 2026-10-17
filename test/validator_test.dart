import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/pack/pack_validator.dart';

Map<String, String> files(String id) {
  String r(String f) => File('packs/$id/$f').readAsStringSync();
  final pack = jsonDecode(r('pack.json')) as Map<String, dynamic>;
  return {
    'pack': r('pack.json'),
    'regions': r('regions.json'),
    'geo': r('geo.geojson'),
    for (final l in pack['languages']) 'lang:$l': r('strings/$l.json'),
  };
}

List<String> run(Map<String, String> f, {String? pack, String? regions, String? geo, Map<String, String>? strings}) =>
    PackValidator.validate(
      packJson: pack ?? f['pack']!,
      regionsJson: regions ?? f['regions']!,
      geoJson: geo ?? f['geo']!,
      stringsJsonByLang: strings ??
          {for (final e in f.entries) if (e.key.startsWith('lang:')) e.key.substring(5): e.value},
    );

void main() {
  for (final id in ['de', 'us']) {
    test('$id: 同梱packは検証を通る', () => expect(run(files(id)), isEmpty));
  }

  test('翻訳の欠落を検出する', () {
    final f = files('de');
    final s = jsonDecode(f['lang:en']!) as Map<String, dynamic>;
    (s['regions'] as Map).remove('DE-BY');
    final err = run(f, strings: {'en': jsonEncode(s)});
    expect(err.any((e) => e.contains('地域名の欠落') && e.contains('DE-BY')), isTrue);
  });

  test('宣言した言語のファイルが無いと検出する', () {
    final f = files('de');
    final pack = jsonDecode(f['pack']!) as Map<String, dynamic>;
    (pack['languages'] as List).add('fr');
    final err = run(f, pack: jsonEncode(pack));
    expect(err.any((e) => e.contains('strings/fr.json')), isTrue);
  });

  test('regionsとgeoのid不一致を検出する', () {
    final f = files('de');
    final reg = jsonDecode(f['regions']!) as Map<String, dynamic>;
    (reg['regions'] as List).removeLast();
    final err = run(f, regions: jsonEncode(reg));
    expect(err.any((e) => e.contains('id不一致')), isTrue);
  });

  test('attribution/licenseが空だと検出する', () {
    final f = files('de');
    final pack = jsonDecode(f['pack']!) as Map<String, dynamic>;
    pack['attribution'] = '';
    pack['license'] = {'name': ''};
    final err = run(f, pack: jsonEncode(pack));
    expect(err, containsAll(['pack.json: attribution が空', 'license.name が空']));
  });

  test('閉じていないリングを検出する', () {
    final f = files('de');
    final geo = jsonDecode(f['geo']!) as Map<String, dynamic>;
    final ring = (geo['features'][0]['geometry']['coordinates'][0][0] as List);
    ring.removeLast();
    final err = run(f, geo: jsonEncode(geo));
    expect(err.any((e) => e.contains('リング不正')), isTrue);
  });
}
