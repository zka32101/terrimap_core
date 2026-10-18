import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/i18n/ui_strings.dart';

void main() {
  final en = File('i18n/battle.en.json').readAsStringSync();

  test('引数を置き換え、ないキーはキーそのまま、言語がなければ英語', () {
    final s = UiStrings.parse({'en': en}, lang: 'fr');
    expect(s.lang, 'en'); // フランス語がないので英語になる
    expect(s.t('hud.wave', {'n': 2, 'total': 5}), 'Wave 2/5');
    expect(s.t('no.such.key'), 'no.such.key');
    expect(s.has('hud.wave'), true);
    expect(s.has('no.such.key'), false);
  });

  test('その言語にないキーは英語で埋める', () {
    final s = UiStrings.parse({'en': en, 'xx': jsonEncode({'hud.base': 'BASE'})}, lang: 'xx');
    expect(s.lang, 'xx');
    expect(s.t('hud.base'), 'BASE');
    expect(s.t('hud.coins'), 'Coins');
  });

  test('placeholders: {} の名前を拾う', () {
    expect(UiStrings.placeholders('Wave {n}/{total}'), {'n', 'total'});
    expect(UiStrings.placeholders('none'), isEmpty);
  });

  test('すべての言語ファイルが、英語とキー・{}が一致する', () {
    final base = (jsonDecode(en) as Map<String, dynamic>).cast<String, String>();
    final files = Directory('i18n').listSync().whereType<File>().where((f) => RegExp(r'battle\.\w+\.json$').hasMatch(f.path));
    expect(files, isNotEmpty);
    for (final f in files) {
      final t = (jsonDecode(f.readAsStringSync()) as Map<String, dynamic>).cast<String, String>();
      for (final e in t.entries) {
        expect(base.containsKey(e.key), true, reason: '${f.path}: 英語にないキー ${e.key}');
        expect(UiStrings.placeholders(e.value), UiStrings.placeholders(base[e.key]!), reason: '${f.path}: ${e.key}');
        expect(e.value.trim(), isNotEmpty, reason: '${f.path}: ${e.key} が空');
      }
    }
  });

  test('英語の文言: すべて空でなく、施設・敵・スキル・天候・季節の名前がそろっている', () {
    final base = (jsonDecode(en) as Map<String, dynamic>).cast<String, String>();
    for (final v in base.values) {
      expect(v.trim(), isNotEmpty);
    }
    for (final k in [
      for (final f in ['farm', 'fishery', 'factory', 'mine', 'castle', 'shrine']) 'facility.$f',
      for (final e in ['normal', 'speedy', 'armored', 'healer', 'boss']) 'enemy.$e',
      for (final w in ['hurricane', 'tornado', 'blizzard', 'heatwave', 'wildfire', 'flood', 'earthquake', 'storm']) 'weather.$w',
      for (final x in ['spring', 'summer', 'autumn', 'winter']) 'season.$x',
      for (final k in ['waveAtkBonus', 'waveRangeBonus', 'waveCoinBonus', 'waveAtkSpeedBonus', 'slow', 'weatherBlock', 'repair']) 'skill.$k',
      for (final b in ['speedBurst', 'hpRegen', 'summon', 'stunFacility']) 'boss.$b',
      for (final x in ['core', 'port', 'resource', 'brewery', 'symbol', 'space']) 'exclusive.$x',
      for (final d in ['easy', 'normal', 'hard']) 'difficulty.$d',
    ]) {
      expect(base.containsKey(k), true, reason: k);
    }
  });

  test('国のプロファイルにある限定施設は、すべて名前の文言(exclusive.name.<id>)がある', () {
    final base = (jsonDecode(en) as Map<String, dynamic>);
    for (final c in ['de', 'us']) {
      final regions = (jsonDecode(File('packs/$c/profile.json').readAsStringSync()) as Map<String, dynamic>)['regions'] as Map<String, dynamic>;
      for (final r in regions.values) {
        final id = (r as Map<String, dynamic>)['exclusiveFacility'] as String?;
        if (id != null) expect(base.containsKey('exclusive.name.$id'), true, reason: '$c: $id');
      }
    }
  });
}
