import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/pack/country_profile.dart';
import 'package:terrimap_core/pack/pack_validator.dart';
import 'package:terrimap_core/pack/region_pack.dart';

String f(String id, String name) => File('packs/$id/$name').readAsStringSync();
CountryProfile profile(String id) => CountryProfile.parse(f(id, 'profile.json'));

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
  themeAndRegionTests();
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
    expect(de.traitOf('DE-XX').terrain, isNull); // 書かれていない地域は特性なし
    expect(de.traitOf('DE-XX').facilityBonus, isEmpty);
    expect(de.traitOf('DE-XX').enemyBias, isEmpty);
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

void themeAndRegionTests() {
  group('背景・施設・敵の見た目と、全地域の特性', () {
    for (final id in ['de', 'us']) {
      test('$id: 全地域に地形と背景があり、背景は定義済み・特性は国の個性を持つ', () {
        final p = CountryProfile.parse(f(id, 'profile.json'));
        final ids = (jsonDecode(f(id, 'regions.json'))['regions'] as List).map((r) => r['id'] as String).toList();
        expect(p.regions.keys.toSet(), ids.toSet()); // 全地域が書かれている(漏れ・余りなし)
        for (final r in ids) {
          final t = p.traitOf(r);
          expect(t.terrain, isNotNull, reason: '$r の terrain');
          expect(t.tags, isNotEmpty, reason: '$r の tags');
          expect(p.backdropOf(r), isNotNull, reason: '$r の backdrop');
        }
        // 背景は複数種類使われる(1種類だけで済ませていない)
        expect(ids.map((r) => p.traitOf(r).backdrop).toSet().length, greaterThan(3));
      });

      test('$id: 施設6種と敵4種の見た目と名前(日本語・英語)がそろっている', () {
        final p = CountryProfile.parse(f(id, 'profile.json'));
        expect(p.facilitySkins.keys.toSet(), CountryProfile.facilityTypes);
        expect(p.enemySkins.keys.toSet(), CountryProfile.enemyKinds);
        for (final s in [...p.facilitySkins.values, ...p.enemySkins.values]) {
          expect(s.name['ja'], isNotEmpty);
          expect(s.name['en'], isNotEmpty);
        }
      });
    }

    test('国が違えば、背景・施設・敵の見た目も違う', () {
      final de = CountryProfile.parse(f('de', 'profile.json'));
      final us = CountryProfile.parse(f('us', 'profile.json'));
      for (final k in CountryProfile.facilityTypes) {
        expect(de.facilitySkins[k]!.skin, isNot(us.facilitySkins[k]!.skin), reason: '施設 $k');
      }
      for (final k in CountryProfile.enemyKinds) {
        expect(de.enemySkins[k]!.skin, isNot(us.enemySkins[k]!.skin), reason: '敵 $k');
      }
      expect(de.backdrops.keys.toSet().intersection(us.backdrops.keys.toSet()), isEmpty);
      expect(de.facilitySkins['mine']!.nameIn('de'), 'Zeche');
      expect(us.facilitySkins['mine']!.nameIn('de'), 'Oil Derrick'); // 言語がなければ英語
    });

    test('州ごとの個性: 限定施設・敵の偏り・天候', () {
      final de = CountryProfile.parse(f('de', 'profile.json'));
      expect(de.traitOf('DE-BY').exclusiveFacility, 'brewery');
      expect(de.traitOf('DE-HH').enemyBias['armored'], 1.3);
      expect(de.backdropOf('DE-BY')!.note, contains('アルプス'));
      final us = CountryProfile.parse(f('us', 'profile.json'));
      expect(us.traitOf('US-OK').weatherEvent, 'tornado');
      expect(us.traitOf('US-FL').weatherEvent, 'hurricane');
      expect(us.traitOf('US-CA').weatherEvent, 'wildfire');
      expect(us.traitOf('US-AK').exclusiveFacility, 'pipeline');
    });

    Map<String, dynamic> base() => jsonDecode(f('de', 'profile.json')) as Map<String, dynamic>;
    List<String> with_(void Function(Map<String, dynamic>) edit) {
      final m = base();
      edit(m);
      return validate('de', profile: jsonEncode(m));
    }

    test('敵の見た目違い: 全種類に2つ。基本の見た目とも重ならず、州・地方で出し分けられ、強さは変わらない', () {
      for (final id in ['de', 'us']) {
        final p = profile(id);
        final all = <String>{...p.enemySkins.values.map((s) => s.skin)};
        for (final kind in CountryProfile.enemyKinds) {
          final vs = p.enemyVariants[kind] ?? const <EnemyVariant>[];
          expect(vs.length, 2, reason: '$id $kind');
          for (final v in vs) {
            expect(all.add(v.skin), isTrue, reason: '${v.skin} が重複'); // 基本とも、ほかの見た目違いとも違う
            expect(v.nameIn('en'), isNotEmpty);
            expect(v.nameIn('xx'), v.nameIn('en')); // 言語がなければ英語
            expect(v.nameIn('ja'), isNot(v.nameIn('en')));
          }
          // 候補は、基本の見た目が先頭
          final regionId = p.regions.keys.first;
          expect(p.enemySkinIds(kind, regionId: regionId).first, p.enemySkins[kind]!.skin);
        }
      }
    });

    test('敵の見た目の候補: どこでも出る見た目と、地方で出る見た目。地方のない州は、どこでも出るものだけ', () {
      final de = profile('de');
      expect(de.groupOf('DE-BY'), 'south');
      expect(de.groupOf('DE-SH'), 'north');
      // armored: stone_giant は south・west、ice_golem は north・east
      expect(de.enemySkinIds('armored', regionId: 'DE-BY'), ['iron_golem', 'stone_giant']);
      expect(de.enemySkinIds('armored', regionId: 'DE-SH'), ['iron_golem', 'ice_golem']);
      // どこでも出る wichtel は、どの州にも入る
      expect(de.enemySkinIds('normal', regionId: 'DE-SH'), ['rust_sprite', 'wichtel']);
      expect(de.enemySkinIds('normal', regionId: 'DE-BY'), ['rust_sprite', 'kobold_miner', 'wichtel']);
      // 地方を直接渡せる(地方決戦)
      expect(de.enemySkinIds('speedy', groupId: 'north'), ['dash_gremlin', 'field_hare', 'rat_pack']);
      // 知らない州・種類は、基本だけ／空
      expect(de.enemySkinIds('armored', regionId: 'XX'), ['iron_golem']);
      expect(de.enemySkinIds('unknown'), isEmpty);
      // 変わらない: 強さ・能力は敵の種類で決まる(見た目違いは持たない)
      expect(de.enemyOf('armored').armor, 1);
    });

    test('敵の見た目違いの不正を検出する', () {
      List<String> v(void Function(Map<String, dynamic>) edit) => with_((m) {
            m['enemyVariants'] ??= <String, dynamic>{};
            edit(m);
          });
      Map<String, dynamic> first(Map<String, dynamic> m) => (((m['enemyVariants'] as Map)['normal'] as List).first as Map<String, dynamic>);
      expect(v((m) => first(m)['skin'] = '').any((e) => e.contains('enemyVariants.normal の skin が空')), isTrue);
      expect(v((m) => first(m)['skin'] = 'rust_sprite').any((e) => e.contains('重複')), isTrue); // 基本の見た目と同じ
      expect(v((m) => first(m)['name'] = {'ja': 'x'}).any((e) => e.contains('name に英語がない')), isTrue);
      expect(v((m) => (m['enemyVariants'] as Map)['dragon'] = []).any((e) => e.contains('未知の敵 dragon')), isTrue);
      expect(v((m) => first(m)['when'] = {'groups': ['moon']}).any((e) => e.contains('未知の地方 moon')), isTrue);
      expect(v((m) => first(m)['when'] = {'regions': ['DE-XX']}).any((e) => e.contains('未知の州 DE-XX')), isTrue);
      expect(v((m) => (m['enemyVariants'] as Map)['normal'] = 'x').any((e) => e.contains('配列でない')), isTrue);
    });

    test('不正な背景・見た目・天候・敵の偏りを検出する', () {
      expect(with_((m) => (((m['regions'] as Map)['DE-BY'] as Map))['backdrop'] = 'moon').any((e) => e.contains('theme.backdrops にない')), isTrue);
      expect(with_((m) => (((m['theme'] as Map)['backdrops'] as Map)['alps'] as Map)['palette'] = ['#fff', 'red']).any((e) => e.contains('palette')), isTrue);
      expect(with_((m) => ((m['facilities'] as Map)['farm'] as Map)['name'] = {'ja': '農場'}).any((e) => e.contains('英語がない')), isTrue);
      expect(with_((m) => ((m['enemySkins'] as Map)['normal'] as Map)['skin'] = '').any((e) => e.contains('skin が空')), isTrue);
      expect(with_((m) => (m['facilities'] as Map)['tower'] = {'skin': 'x', 'name': {'en': 'x'}}).any((e) => e.contains('未知の施設')), isTrue);
      expect(with_((m) => (((m['regions'] as Map)['DE-BY'] as Map))['weatherEvent'] = 'meteor').any((e) => e.contains('weatherEvent')), isTrue);
      expect(with_((m) => (((m['regions'] as Map)['DE-BY'] as Map))['enemyBias'] = {'normal': 5.0}).any((e) => e.contains('enemyBias')), isTrue);
      expect(with_((m) => (((m['regions'] as Map)['DE-BY'] as Map))['facilityBonus'] = {'tower': 1.2}).any((e) => e.contains('未知の施設')), isTrue);
    });
  });
}
