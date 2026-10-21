import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/bot.dart';
import 'package:terrimap_core/battle/endless.dart';
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
  test('エンドレスのステージ: 30波で最後だけボス、同じ州なら毎回同じ、通常の盤面とは別', () {
    for (final id in ['de', 'us']) {
      final pack = load(id);
      final g = StageGenerator(pack);
      final region = pack.regions.first.id;
      final a = g.endless(region), b = g.endless(region);
      expect(a.toJsonString(), b.toJsonString());
      expect(a.waves.length, StageGenerator.endlessWaves);
      expect(a.kind, StageKind.normal);
      expect(a.waves.where((w) => w.hasBoss).map((w) => w.number), [StageGenerator.endlessWaves]);
      expect(a.waves.last.baseHp, greaterThan(a.waves.first.baseHp * 10));
      expect(a.seed, isNot(g.generate(region, a.difficulty).seed));
    }
  });

  test('自己ベスト: 波数が主で、同じ波数ならスコア。更新したときだけ入れ替わる', () {
    var b = const EndlessBoard.empty();
    expect(b.best, isNull);
    expect(b.improved(const EndlessResult('x', 0, 500)), isFalse); // 1波も守れなければ記録しない
    const r1 = EndlessResult('x', 5, 100);
    expect(b.improved(r1), isTrue);
    b = b.add(r1);
    expect(b.improved(const EndlessResult('x', 4, 99999)), isFalse);
    expect(b.improved(const EndlessResult('x', 5, 101)), isTrue);
    expect(b.add(const EndlessResult('x', 4, 99999)).bestOf('x')!.waves, 5);
    b = b.add(const EndlessResult('y', 9, 1)).add(const EndlessResult('x', 6, 1));
    expect(b.best!.regionId, 'y');
    expect([for (final r in b.ranked) r.regionId], ['y', 'x']);
  });

  test('保存と復元。壊れたデータは空', () {
    final b = const EndlessBoard.empty().add(const EndlessResult('x', 7, 1234));
    final c = EndlessBoard.fromJson(b.toJson());
    expect(c.bestOf('x')!.waves, 7);
    expect(c.bestOf('x')!.score, 1234);
    expect(EndlessBoard.fromJson('not json').best, isNull);
    expect(EndlessBoard.fromJson(null).best, isNull);
    expect(EndlessBoard.fromJson('{"x":[0,5],"y":"z"}').best, isNull);
  });

  test('ボットで通しで遊べる(エンドレスでも止まらず終わり、ボットは途中で力尽きる)', () {
    final pack = load('us');
    final st = StageGenerator(pack).endless(pack.regions.first.id);
    final casual = BattleBot(BattleEngine(st, profile: pack.profile, pack: pack), BotProfile.casual).play(maxSeconds: 3000);
    final expert = BattleBot(BattleEngine(st, profile: pack.profile, pack: pack), BotProfile.expert).play(maxSeconds: 3000);
    expect(casual.wave, greaterThan(1));
    expect(expert.wave, greaterThan(1));
    expect(casual.won || expert.won, isFalse); // 30波は、ボットには届かない腕試し
  });
}
