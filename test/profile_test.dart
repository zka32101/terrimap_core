import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/pack/country_profile.dart';
import 'package:terrimap_core/pack/pack_validator.dart';
import 'package:terrimap_core/pack/region_pack.dart';

String f(String id, String name) => File('packs/$id/$name').readAsStringSync();

List<String> validate(String id, {String? profile}) {
  final langs = (jsonDecode(f(id, 'pack.json'))['languages'] as List).cast<String>();
  return PackValidator.validate(
    packJson: f(id, 'pack.json'),
    regionsJson: f(id, 'regions.json'),
    geoJson: f(id, 'geo.geojson'),
    stringsJsonByLang: {for (final l in langs) l: f(id, 'strings/$l.json')},
    profileJson: profile ?? f(id, 'profile.json'),
  );
}

void main() {
  enemyAndActionTests();
  for (final id in ['de', 'us']) {
    test('$id: 同梱のprofileは検証を通る', () => expect(validate(id), isEmpty));
  }

  test('国ごとに戦い方が違う: ドイツは装甲型、米国は足の速い敵が多く進路が長い', () {
    final de = CountryProfile.parse(f('de', 'profile.json'));
    final us = CountryProfile.parse(f('us', 'profile.json'));
    expect(de.style, isNot(us.style));
    expect(de.enemyMix['armored']!, greaterThan(us.enemyMix['armored']!));
    expect(us.enemyMix['speedy']!, greaterThan(de.enemyMix['speedy']!));
    expect(de.signatureId, isNot(us.signatureId));
    expect(us.pathLength, 'long');
  });

  test('地域の特性を引ける。書かれていない地域は特性なし', () {
    final de = CountryProfile.parse(f('de', 'profile.json'));
    expect(de.traitOf('DE-BY').facilityBonus['factory'], 1.2);
    expect(de.traitOf('DE-HH').tags, contains('port'));
    expect(de.traitOf('DE-TH').terrain, isNull);
    expect(de.traitOf('DE-TH').facilityBonus, isEmpty);
    final us = CountryProfile.parse(f('us', 'profile.json'));
    expect(us.traitOf('US-FL').weatherEvent, 'hurricane');
  });

  test('RegionPack.parse に渡すと pack.profile から読める(なければnull)', () {
    RegionPack load(String id, {bool withProfile = true}) => RegionPack.parse(
          packJson: f(id, 'pack.json'),
          regionsJson: f(id, 'regions.json'),
          geoJson: f(id, 'geo.geojson'),
          stringsJsonByLang: {'en': f(id, 'strings/en.json')},
          profileJson: withProfile ? f(id, 'profile.json') : null,
        );
    expect(load('de').profile!.style, 'engineered');
    expect(load('de', withProfile: false).profile, isNull);
  });

  group('検証が不正を検出する', () {
    Map<String, dynamic> base() => jsonDecode(f('de', 'profile.json')) as Map<String, dynamic>;
    List<String> with_(void Function(Map<String, dynamic>) edit) {
      final m = base();
      edit(m);
      return validate('de', profile: jsonEncode(m));
    }

    test('敵の割合の合計が1でない', () {
      expect(with_((m) => (m['enemyMix'] as Map)['normal'] = 0.9).any((e) => e.contains('合計が1')), isTrue);
    });
    test('未知の敵・未知の地域・不正な地形', () {
      expect(with_((m) => (m['enemyMix'] as Map)['dragon'] = 0.0).any((e) => e.contains('未知の敵')), isTrue);
      expect(with_((m) => (m['regions'] as Map)['DE-XX'] = {}).any((e) => e.contains('未知の地域')), isTrue);
      expect(with_((m) => ((m['regions'] as Map)['DE-BY'] as Map)['terrain'] = 'lava').any((e) => e.contains('terrain')), isTrue);
    });
    test('経済の倍率・施設ボーナスが範囲外', () {
      expect(with_((m) => (m['economy'] as Map)['income'] = 5.0).any((e) => e.contains('economy.income')), isTrue);
      expect(
          with_((m) => (((m['regions'] as Map)['DE-BY'] as Map)['facilityBonus'] as Map)['factory'] = 3.0)
              .any((e) => e.contains('facilityBonus')),
          isTrue);
    });
    test('pathLength が不正', () {
      expect(with_((m) => m['pathLength'] = 'huge').any((e) => e.contains('pathLength')), isTrue);
    });
  });
}

void enemyAndActionTests() {
  group('敵の特性・攻撃アクション', () {
    test('国ごとに敵の性能と施設の撃ち方が違う', () {
      final de = CountryProfile.parse(f('de', 'profile.json'));
      final us = CountryProfile.parse(f('us', 'profile.json'));
      expect(de.enemyOf('armored').hp, greaterThan(us.enemyOf('armored').hp));
      expect(de.enemyOf('armored').ability, 'shield');
      expect(us.enemyOf('speedy').ability, 'swarm');
      expect(us.enemyOf('speedy').speed, greaterThan(de.enemyOf('speedy').speed));
      expect(us.enemyOf('armored').action, 'ranged_disable');
      expect(de.actionOf('factory')!.action, 'pierce');
      expect(us.actionOf('factory')!.action, 'splash');
      expect(de.actionOf('shrine'), isNull); // 書かれていない施設は標準
    });

    test('書かれていない敵は標準(倍率1.0・能力と行動なし)', () {
      final de = CountryProfile.parse(f('de', 'profile.json'));
      final t = de.enemyOf('normal');
      expect([t.hp, t.speed, t.baseDamage, t.armor, t.ability, t.action], [1.0, 1.0, 1.0, 0, 'none', 'none']);
    });

    Map<String, dynamic> base() => jsonDecode(f('de', 'profile.json')) as Map<String, dynamic>;
    List<String> with_(void Function(Map<String, dynamic>) edit) {
      final m = base();
      edit(m);
      return validate('de', profile: jsonEncode(m));
    }

    test('不正な敵・能力・行動・施設・倍率を検出する', () {
      expect(with_((m) => (m['enemies'] as Map)['dragon'] = {}).any((e) => e.contains('未知の敵')), isTrue);
      expect(with_((m) => ((m['enemies'] as Map)['armored'] as Map)['ability'] = 'fly_away').any((e) => e.contains('ability')), isTrue);
      expect(with_((m) => ((m['enemies'] as Map)['armored'] as Map)['action'] = 'nuke').any((e) => e.contains('action')), isTrue);
      expect(with_((m) => ((m['enemies'] as Map)['armored'] as Map)['hp'] = 9.0).any((e) => e.contains('enemies.armored.hp')), isTrue);
      expect(with_((m) => ((m['enemies'] as Map)['armored'] as Map)['armor'] = 7).any((e) => e.contains('armor')), isTrue);
      expect(with_((m) => (m['attackActions'] as Map)['tower'] = {'action': 'single'}).any((e) => e.contains('未知の施設')), isTrue);
      expect(with_((m) => ((m['attackActions'] as Map)['factory'] as Map)['action'] = 'laser').any((e) => e.contains('factory.action')), isTrue);
      expect(with_((m) => ((m['attackActions'] as Map)['factory'] as Map)['damage'] = 0.1).any((e) => e.contains('factory.damage')), isTrue);
    });
  });
}
