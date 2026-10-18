import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
import 'package:terrimap_core/battle/invite.dart';
import 'package:terrimap_core/battle/replay.dart';
import 'package:terrimap_core/battle/stage_generator.dart';
import 'package:terrimap_core/pack/region_pack.dart';

RegionPack load(String id) {
  String r(String f) => File('packs/$id/$f').readAsStringSync();
  final langs = Directory('packs/$id/strings').listSync().map((e) => e.uri.pathSegments.last.replaceAll('.json', ''));
  return RegionPack.parse(
      packJson: r('pack.json'), regionsJson: r('regions.json'), geoJson: r('geo.geojson'),
      stringsJsonByLang: {for (final l in langs) l: r('strings/$l.json')},
      profileJson: r('profile.json'), factsJson: r('facts.json'));
}

void main() {
  final de = load('de');

  test('コードは短く、書き出して読み直すと同じ。結果つき・なし、どちらも', () {
    const a = Invite(packId: 'de', kind: StageKind.normal, stageId: 'DE-BY', difficulty: Difficulty.hard);
    expect(a.toCode(), 'TMI1.de.normal.DE-BY.hard');
    final b = Invite.parse(a.toCode())!;
    expect((b.packId, b.kind, b.stageId, b.difficulty, b.hasResult), ('de', StageKind.normal, 'DE-BY', Difficulty.hard, false));
    const c = Invite(packId: 'de', kind: StageKind.extra, stageId: 'de_loreley', difficulty: Difficulty.normal, won: true, baseHp: 12);
    expect(c.toCode(), 'TMI1.de.extra.de_loreley.normal.w12');
    final d = Invite.parse(c.toCode())!;
    expect((d.kind, d.won, d.baseHp), (StageKind.extra, true, 12));
    expect(Invite.parse('TMI1.us.regional.west.easy.l0')!.won, false);
  });

  test('メッセージの中に埋もれていても読める。壊れたものは null', () {
    final t = const Invite(packId: 'de', kind: StageKind.normal, stageId: 'DE-BE', difficulty: Difficulty.easy, won: false, baseHp: 3)
        .shareText(headline: 'Terrimap: Can you beat Berlin (Easy)?', result: 'My result: ❌ ♥3');
    expect(t.split('\n').length, 3);
    final p = Invite.parse('友だちから届いた!\n$t\nよろしく')!;
    expect((p.stageId, p.difficulty, p.won, p.baseHp), ('DE-BE', Difficulty.easy, false, 3));
    for (final bad in [null, '', 'hello', 'TMI1.de.normal.DE-BY', 'TMI1.de.normal.DE-BY.extreme', 'TMI2.de.normal.DE-BY.easy', 'TMI1.de.cheat.DE-BY.easy']) {
      expect(Invite.parse(bad), isNull, reason: '$bad');
    }
  });

  test('この国のデータにあるステージだけ有効（別の国・存在しない id は無効）', () {
    expect(Invite.parse('TMI1.de.normal.DE-BY.easy')!.isValidFor(de), true);
    expect(Invite.parse('TMI1.us.normal.DE-BY.easy')!.isValidFor(de), false);
    expect(Invite.parse('TMI1.de.normal.XX-ZZ.easy')!.isValidFor(de), false);
    final g = de.profile!.groups.keys.first, x = de.profile!.extras.first.id;
    expect(Invite.parse('TMI1.de.regional.$g.hard')!.isValidFor(de), true);
    expect(Invite.parse('TMI1.de.extra.$x.hard')!.isValidFor(de), true);
    expect(Invite.parse('TMI1.de.regional.nowhere.hard')!.isValidFor(de), false);
  });

  test('招待から、同じ条件のステージが作られる（リプレイと同じ id・難易度）', () {
    final stage = StageGenerator(de).generate('DE-BY', Difficulty.normal);
    final rec = ReplayRecorder(BattleEngine(stage, profile: de.profile, pack: de, quizAssist: false));
    final r = rec.toReplay(packId: de.packId, kind: StageKind.normal, stageId: 'DE-BY', difficulty: Difficulty.normal);
    final inv = Invite.fromReplay(r);
    expect((inv.stageId, inv.difficulty, inv.kind, inv.packId), ('DE-BY', Difficulty.normal, StageKind.normal, de.packId));
    final again = StageGenerator(de).generate(inv.stageId, inv.difficulty, kind: inv.kind);
    expect(again.seed, stage.seed);
  });
}
