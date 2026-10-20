import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/bot.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
import 'package:terrimap_core/battle/replay.dart';
import 'package:terrimap_core/battle/stage_generator.dart';
import 'package:terrimap_core/battle_ui/battle_view.dart';
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
  final de = load('de');
  BattleEngine engine({int rules = BattleEngine.currentRules}) =>
      BattleEngine(StageGenerator(de).generate('DE-BY', Difficulty.easy), profile: de.profile, pack: de, quizAssist: false, rules: rules);

  Facility at(FacilityType t, int c, int r, {String? exclusive}) => Facility(t, GridPos(c, r), exclusive: exclusive);
  Map<GridPos, Facility> map(List<Facility> fs) => {for (final f in fs) f.pos: f};

  test('組み合わせボーナス: 周囲8マスの、違う種類の施設の数で決まる（同じ種類・離れた施設・限定施設は数えない。最大3種類）', () {
    final e = engine();
    final farm = at(FacilityType.farm, 5, 5);
    expect(e.synergyTypes(map([farm]), farm), 0);
    expect(e.synergyTypes(map([farm, at(FacilityType.farm, 6, 5)]), farm), 0); // 同じ種類
    expect(e.synergyTypes(map([farm, at(FacilityType.mine, 7, 5)]), farm), 0); // 離れている
    expect(e.synergyTypes(map([farm, at(FacilityType.mine, 6, 6)]), farm), 1); // 斜めも隣
    expect(e.synergyTypes(map([farm, at(FacilityType.mine, 6, 5), at(FacilityType.mine, 4, 5)]), farm), 1); // 同じ種類は1つに数える
    expect(e.synergyTypes(map([farm, at(FacilityType.castle, 6, 5, exclusive: 'x')]), farm), 0); // 限定施設は数えない
    final many = map([farm, at(FacilityType.mine, 4, 4), at(FacilityType.castle, 5, 4), at(FacilityType.shrine, 6, 4), at(FacilityType.fishery, 6, 5)]);
    expect(e.synergyTypes(many, farm), BattleEngine.synergyMaxTypes);
    expect(e.synergyBonus(many, farm), closeTo(BattleEngine.synergyMaxTypes * BattleEngine.synergyPerType, 1e-9));
  });

  test('ルール1（古い記録）では、組み合わせボーナスは働かない', () {
    final e = engine(rules: 1);
    final farm = at(FacilityType.farm, 5, 5);
    expect(e.synergyBonus(map([farm, at(FacilityType.mine, 6, 5)]), farm), 0);
  });

  test('古い記録（版1・ルール1）は、そのまま読めて、旧ルールで再生できる。新しい記録は版2・ルールの版つき', () {
    final e = engine(rules: 1);
    final rec = ReplayRecorder(e);
    BattleBot(e, BotProfile.regular, recorder: rec).play();
    final r = rec.toReplay(packId: de.packId, kind: StageKind.normal, stageId: 'DE-BY', difficulty: Difficulty.easy);
    expect(r.rules, 1);
    // 旧形式（'r' なし・版1）に書き換えても、同じ結果で再生できる
    final legacy = r.toJson()..['v'] = 1..remove('r');
    final back = Replay.fromJson(jsonDecode(jsonEncode(legacy)) as Map<String, dynamic>);
    expect(back.rules, 1);
    expect(back.verify(de), true);

    final e2 = engine();
    final rec2 = ReplayRecorder(e2);
    BattleBot(e2, BotProfile.regular, recorder: rec2).play();
    final r2 = rec2.toReplay(packId: de.packId, kind: StageKind.normal, stageId: 'DE-BY', difficulty: Difficulty.easy);
    expect(r2.rules, BattleEngine.currentRules);
    final j = r2.toJson();
    expect(j['v'], Replay.version);
    expect(j['r'], BattleEngine.currentRules);
    expect(Replay.fromShareCode(r2.toShareCode())!.verify(de), true);
  });

  testWidgets('盤面: 組み合わせの表示（synergy: true）で、隣り合う施設があっても描ける', (t) async {
    final e = engine();
    var st = e.start();
    final slots = e.stage.slots;
    st = e.place(st, FacilityType.farm, slots[0])!;
    final next = slots.firstWhere((p) => (p.col - slots[0].col).abs() <= 1 && (p.row - slots[0].row).abs() <= 1 && p != slots[0], orElse: () => slots[1]);
    st = e.place(st, FacilityType.fishery, next) ?? st;
    for (final on in [true, false]) {
      await t.pumpWidget(MaterialApp(home: SizedBox(width: 360, height: 500, child: BattleView(stage: e.stage, state: st, synergy: on))));
      expect(find.byType(BattleView), findsOneWidget);
    }
  });
}
