import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_progress.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
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

  test('クリアを記録し、難易度ごとに確かめられる', () {
    final p = BattleProgress();
    expect(p.isCleared(StageKind.normal, 'DE-BY'), false);
    p.recordClear(StageKind.normal, 'DE-BY', Difficulty.normal);
    expect(p.isCleared(StageKind.normal, 'DE-BY'), true);
    expect(p.isCleared(StageKind.normal, 'DE-BY', difficulty: Difficulty.normal), true);
    expect(p.isCleared(StageKind.normal, 'DE-BY', difficulty: Difficulty.hard), false);
    expect(p.isCleared(StageKind.regional, 'DE-BY'), false); // 種別が違う
  });

  test('地方決戦の解放: 地方の州の過半数（半分ちょうどでは足りない）', () {
    final south = de.profile!.groups['south']!; // 2州
    final p = BattleProgress();
    expect(p.regionalUnlocked(south), false);
    p.recordClear(StageKind.normal, 'DE-BY', Difficulty.easy);
    expect(p.regionalUnlocked(south), false); // 1/2 は過半数でない
    p.recordClear(StageKind.normal, 'DE-BW', Difficulty.easy);
    expect(p.regionalUnlocked(south), true);
    final north = de.profile!.groups['north']!; // 5州: 3州で解放
    for (final r in north.regions.take(2)) {
      p.recordClear(StageKind.normal, r, Difficulty.normal);
    }
    expect(p.regionalUnlocked(north), false);
    p.recordClear(StageKind.normal, north.regions[2], Difficulty.hard);
    expect(p.regionalUnlocked(north), true);
    expect(p.regionalProgress(north), 3);
  });

  test('エクストラの解放: 全州を hard でクリア', () {
    final p = BattleProgress();
    for (final r in de.regions) {
      p.recordClear(StageKind.normal, r.id, Difficulty.normal);
    }
    expect(p.extraUnlocked(de), false); // normal では足りない
    for (final r in de.regions.skip(1)) {
      p.recordClear(StageKind.normal, r.id, Difficulty.hard);
    }
    expect(p.extraUnlocked(de), false); // 1州たりない
    p.recordClear(StageKind.normal, de.regions.first.id, Difficulty.hard);
    expect(p.extraUnlocked(de), true);
    expect(p.extraUnlocked(us), false); // 国ごと（米国の州は別）
  });

  test('保存と復元（壊れた文字列は空の記録）', () {
    final p = BattleProgress()
      ..recordClear(StageKind.normal, 'DE-BY', Difficulty.hard)
      ..recordClear(StageKind.regional, 'south', Difficulty.normal)
      ..recordClear(StageKind.extra, 'de_loreley', Difficulty.hard);
    final q = BattleProgress.fromJsonString(p.toJsonString());
    expect(q.isCleared(StageKind.normal, 'DE-BY', difficulty: Difficulty.hard), true);
    expect(q.isCleared(StageKind.regional, 'south', difficulty: Difficulty.normal), true);
    expect(q.isCleared(StageKind.extra, 'de_loreley'), true);
    expect(q.isCleared(StageKind.extra, 'de_grimm'), false);
    expect(BattleProgress.fromJsonString(null).clearedStates(['DE-BY']), 0);
    expect(BattleProgress.fromJsonString('{{{').clearedStates(['DE-BY']), 0);
    expect(BattleProgress.fromJsonString('{"cleared":{"normal:X":["bogus","easy"]}}').isCleared(StageKind.normal, 'X', difficulty: Difficulty.easy), true);
  });
}
