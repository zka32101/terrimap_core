import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_progress.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
import 'package:terrimap_core/pack/region_pack.dart';
import 'package:terrimap_core/story/story.dart';

RegionPack load(String id) {
  String r(String f) => File('packs/$id/$f').readAsStringSync();
  final langs = Directory('packs/$id/strings').listSync().map((e) => e.uri.pathSegments.last.replaceAll('.json', ''));
  return RegionPack.parse(
      packJson: r('pack.json'), regionsJson: r('regions.json'), geoJson: r('geo.geojson'),
      stringsJsonByLang: {for (final l in langs) l: r('strings/$l.json')},
      profileJson: r('profile.json'));
}

void main() {
  final de = load('de');
  Story story() => Story.parse(File('packs/de/story.json').readAsStringSync());

  test('ドイツの物語: 読めて、データに問題がない', () {
    final s = story();
    expect(s.chapters, isNotEmpty);
    expect(s.validate(de), isEmpty);
    final c = s.forStage(StageKind.extra, 'de_loreley')!;
    expect(c.title.of('ja'), 'ラインの歌');
    expect(c.title.of('fr'), 'Le chant du Rhin');
    expect(c.title.of('xx'), 'The Song on the Rhine'); // 訳がない言語は英語
    expect(c.outro.any((l) => l.speaker == Speaker.note), true); // 伝説の章には、実在と伝説の注記
  });

  test('ドイツの物語: グリム・ニーベルンゲンの章があり、伝説の章には注記がある', () {
    final s = story();
    expect(s.chapters.map((c) => c.stageId), ['de_loreley', 'de_grimm', 'de_nibelung']);
    for (final c in s.chapters) {
      expect(c.outro.any((l) => l.speaker == Speaker.note), true, reason: c.id);
      expect(c.title.of('de'), isNot(c.title.of('en')), reason: c.id); // ドイツ語がある
    }
  });

  test('米国の物語: 3章が読めて、データに問題がない。伝説・創作のボスには注記がある', () {
    final us = load('us');
    final s = Story.parse(File('packs/us/story.json').readAsStringSync());
    expect(s.chapters.map((c) => c.stageId), ['us_bunyan', 'us_wright', 'us_moon']);
    expect(s.validate(us), isEmpty);
    for (final c in s.chapters) {
      expect(c.outro.any((l) => l.speaker == Speaker.note), true, reason: c.id); // 創作のボスも、実在と創作を分けて書く
      expect(c.title.of('ja'), isNot(c.title.of('en')));
    }
  });

  test('物語: 全言語の訳がそろっている（DE は 11 言語、US は de を除く 10 言語）', () {
    for (final (pack, langs) in [
      ('de', ['en', 'de', 'ja', 'fr', 'es', 'it', 'pt', 'nl', 'tr', 'ko', 'zh']),
      ('us', ['en', 'ja', 'fr', 'es', 'it', 'pt', 'nl', 'tr', 'ko', 'zh']),
    ]) {
      final s = Story.parse(File('packs/$pack/story.json').readAsStringSync());
      for (final c in s.chapters) {
        for (final t in [c.title, for (final l in [...c.intro, ...c.beforeBoss, ...c.outro]) l.text]) {
          for (final lang in langs) {
            expect(t.languages, contains(lang), reason: '$pack ${c.id} $lang');
          }
        }
      }
    }
  });

  test('検査: 未知のステージ・伝説の注記なし・前提の章の順番・重複・英語なしを見つける', () {
    LocalizedText t(String en) => LocalizedText({'en': en});
    final line = DialogueLine(Speaker.narrator, t('x'));
    final bad = Story([
      StoryChapter(id: 'a', kind: StageKind.extra, stageId: 'nope', title: t('A')),
      StoryChapter(id: 'a', kind: StageKind.normal, stageId: 'DE-BY', title: t('B'), requires: 'zzz'),
      StoryChapter(id: 'c', kind: StageKind.extra, stageId: 'de_loreley', title: t('C'), outro: [line]), // 伝説なのに note がない
      StoryChapter(id: 'd', kind: StageKind.regional, stageId: 'south', title: const LocalizedText({}), intro: [DialogueLine(Speaker.boss, const LocalizedText({'de': 'nur deutsch'}))]),
    ]);
    final errs = bad.validate(de).join('\n');
    expect(errs, contains('未知のエクストラ nope'));
    expect(errs, contains('章の id が重複'));
    expect(errs, contains('前提の章 zzz'));
    expect(errs, contains('伝説の章には'));
    expect(errs, contains('題名の英語がない'));
    expect(errs, contains('英語のない文'));
  });

  test('進み具合: クリアで章が終わり、前提の章を終えると次が読める。保存はしない（記録から計算）', () {
    LocalizedText t(String en) => LocalizedText({'en': en});
    final s = Story([
      StoryChapter(id: 'one', kind: StageKind.normal, stageId: 'DE-BY', title: t('1')),
      StoryChapter(id: 'two', kind: StageKind.extra, stageId: 'de_loreley', requires: 'one', title: t('2')),
    ]);
    final bp = BattleProgress();
    var p = StoryProgress(s, bp);
    expect(p.unlocked(s.chapters[0]), true);
    expect(p.unlocked(s.chapters[1]), false);
    expect(p.next!.id, 'one');
    expect(p.completedCount, 0);
    bp.recordClear(StageKind.normal, 'DE-BY', Difficulty.easy);
    p = StoryProgress(s, bp);
    expect(p.completed(s.chapters[0]), true);
    expect(p.unlocked(s.chapters[1]), true);
    expect(p.next!.id, 'two');
    bp.recordClear(StageKind.extra, 'de_loreley', Difficulty.hard);
    p = StoryProgress(s, bp);
    expect([p.completedCount, p.next], [2, null]);
  });

  test('読み込み: 壊れた章・知らない語り手は読み飛ばす', () {
    final s = Story.parse('{"chapters":[{"id":"ok","kind":"normal","stageId":"DE-BY","title":{"en":"x"},"intro":[{"speaker":"ghost","text":{"en":"a"}},{"speaker":"narrator","text":{"en":"b"}}]},{"id":"bad","kind":"weird","stageId":"x"},5]}');
    expect(s.chapters.length, 1);
    expect(s.chapters.first.intro.length, 1);
  });
}
