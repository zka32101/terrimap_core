import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/bot.dart';
import 'package:terrimap_core/battle/endless.dart';
import 'package:terrimap_core/battle/grid.dart';
import 'package:terrimap_core/battle/stage_generator.dart';
import 'package:terrimap_core/pack/region_pack.dart';
import 'package:terrimap_core/story/story.dart';

RegionPack load(String id) {
  String r(String f) => File('packs/$id/$f').readAsStringSync();
  final langs = Directory('packs/$id/strings')
      .listSync()
      .map((e) => e.uri.pathSegments.last.replaceAll('.json', ''));
  return RegionPack.parse(
      packJson: r('pack.json'),
      regionsJson: r('regions.json'),
      geoJson: r('geo.geojson'),
      stringsJsonByLang: {for (final l in langs) l: r('strings/$l.json')},
      profileJson: r('profile.json'));
}

StageGenerator g2(RegionPack p, int rules) => StageGenerator(p, rules: rules);

void main() {
  test('エンドレスのステージ: 30波で10波ごとにボス、同じ州なら毎回同じ、通常の盤面とは別', () {
    for (final id in ['de', 'us']) {
      final pack = load(id);
      final g = StageGenerator(pack);
      final region = pack.regions.first.id;
      final a = g.endless(region), b = g.endless(region);
      expect(a.toJsonString(), b.toJsonString());
      expect(a.waves.length, StageGenerator.endlessWaves);
      expect(a.kind, StageKind.normal);
      expect(a.waves.where((w) => w.hasBoss).map((w) => w.number),
          [30]); // 版4: ボスは最終波だけ
      expect(a.waves.where((w) => w.miniBoss).map((w) => w.number),
          [10, 20]); // 10波ごとにミニボス
      expect(
          g2(pack, 3)
              .endless(region)
              .waves
              .where((w) => w.hasBoss)
              .map((w) => w.number),
          [10, 20, 30]); // 版3は10波ごとにボス
      expect(a.waves.last.baseHp, greaterThan(a.waves.first.baseHp * 10));
      expect(a.seed, isNot(g.generate(region, a.difficulty).seed));
    }
  });

  test('自己ベスト: 波数が主で、同じ波数ならスコア。更新したときだけ入れ替わる', () {
    var b = const EndlessBoard.empty();
    expect(b.best, isNull);
    expect(b.improved(const EndlessResult('x', 0, 500)),
        isFalse); // 1波も守れなければ記録しない
    const r1 = EndlessResult('x', 5, 100);
    expect(b.improved(r1), isTrue);
    b = b.add(r1);
    expect(b.improved(const EndlessResult('x', 4, 99999)), isFalse);
    expect(b.improved(const EndlessResult('x', 5, 101)), isTrue);
    expect(b.add(const EndlessResult('x', 4, 99999)).bestOf('x')!.waves, 5);
    b = b
        .add(const EndlessResult('y', 9, 1))
        .add(const EndlessResult('x', 6, 1));
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
    final casual = BattleBot(
            BattleEngine(st, profile: pack.profile, pack: pack),
            BotProfile.casual)
        .play(maxSeconds: 3000);
    final expert = BattleBot(
            BattleEngine(st, profile: pack.profile, pack: pack),
            BotProfile.expert)
        .play(maxSeconds: 3000);
    expect(casual.wave, greaterThan(1));
    expect(expert.wave, greaterThan(1));
    expect(casual.won || expert.won, isFalse); // 30波は、ボットには届かない腕試し
  });

  test('今日の州: 日付で決まり、毎回同じ。絞り込んだ州の中から選ぶ', () {
    final pack = load('us');
    final a = EndlessDaily.regionFor(pack, '2026-10-21');
    expect(EndlessDaily.regionFor(pack, '2026-10-21'), a);
    expect(
        {
          for (var d = 1; d <= 28; d++)
            EndlessDaily.regionFor(
                pack, '2026-10-${d.toString().padLeft(2, '0')}')
        }.length,
        greaterThan(5)); // 日替わりで散る
    const free = {'US-CA', 'US-TX'};
    for (var d = 1; d <= 28; d++) {
      expect(
          free,
          contains(EndlessDaily.regionFor(
              pack, '2026-11-${d.toString().padLeft(2, '0')}',
              allowedIds: free)));
    }
    expect(() => EndlessDaily.regionFor(pack, '2026-10-21', allowedIds: {}),
        throwsArgumentError);
  });

  test('続きの章: 各国に3つ(10・20・30波)。守った波数で読める章が増え、新しく読める章だけ取り出せる', () {
    for (final id in ['de', 'us']) {
      final pack = load(id);
      final story =
          Story.parse(File('packs/$id/story.json').readAsStringSync());
      expect(story.validate(pack), isEmpty, reason: id);
      expect([for (final e in story.epilogues) e.waves], [10, 20, 30],
          reason: id);
      for (final e in story.epilogues) {
        expect(e.title.of('ja'), isNotEmpty);
        expect(e.lines.any((l) => l.speaker == Speaker.hero), isTrue,
            reason: e.id);
        for (final lang in [
          'en',
          'ja',
          'de',
          'fr',
          'es',
          'it',
          'pt',
          'nl',
          'tr',
          'ko',
          'zh'
        ]) {
          expect(e.lines.every((l) => l.text.of(lang).isNotEmpty), isTrue,
              reason: '${e.id} $lang');
        }
      }
      expect(story.unlockedEpilogues(9), isEmpty);
      expect(story.unlockedEpilogues(20).map((e) => e.waves), [10, 20]);
      expect(story.newlyUnlocked(8, 22).map((e) => e.waves), [10, 20]);
      expect(story.newlyUnlocked(20, 20), isEmpty);
    }
  });
}
