import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/stage_generator.dart';
import 'package:terrimap_core/battle_ui/battle_fx.dart';
import 'package:terrimap_core/battle_ui/battle_session.dart';
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
  BattleSession play({bool fx = true}) {
    final s = BattleSession(BattleEngine(StageGenerator(de).generate('DE-BY', Difficulty.normal), profile: de.profile, pack: de));
    s.fx.enabled = fx;
    // 施設をいくつか置いて波を始める
    for (final slot in s.engine.stage.slots.take(4)) {
      s.tapCell(slot);
      s.place(FacilityType.castle);
    }
    s.startWave();
    return s;
  }

  test('演出: 戦うと、弾・火花・ダメージ数字・撃破の爆発・波の表示ができ、時間がたつと消える', () {
    final s = play();
    final seen = <FxKind>{};
    for (var i = 0; i < 1500 && !s.isOver; i++) {
      s.tick(0.1);
      seen.addAll(s.fx.items.map((e) => e.kind));
    }
    expect(seen, containsAll([FxKind.banner, FxKind.shot, FxKind.spark, FxKind.damage, FxKind.burst]));
    expect(s.fx.items.length, lessThanOrEqualTo(BattleFx.maxItems));
    // 終わってしばらくすると、残りは古いものとして捨てられる（新しいイベントが来たときに掃除される）
    s.fx.consume(s.state, const [], s.engine.stage);
    expect(s.fx.items.every((i) => s.state.time - i.t0 <= i.life + 0.05), true);
  });

  test('演出: 画面の揺れは、拠点が突破された・ボスなどの直後だけあり、時間とともに止まる', () {
    final fx = BattleFx();
    final s = play(fx: false);
    final st = s.state;
    expect(fx.shake(st.time), Offset.zero);
    fx.consume(st, const [BattleEvent(BattleEventType.breach, value: 1)], s.engine.stage);
    expect(fx.shake(st.time + 0.02) == Offset.zero, false);
    expect(fx.shake(st.time + 1.0), Offset.zero);
  });

  test('演出: オフなら何も作らず、揺れもない', () {
    final s = play(fx: false);
    for (var i = 0; i < 300; i++) {
      s.tick(0.1);
    }
    expect(s.fx.items, isEmpty);
    expect(s.fx.shake(s.state.time), Offset.zero);
  });

  testWidgets('演出つきの盤面を描いてもエラーにならない（画像なし）', (t) async {
    final s = play();
    for (var i = 0; i < 200; i++) {
      s.tick(0.1);
    }
    await t.pumpWidget(MaterialApp(
      home: SizedBox(width: 400, height: 600, child: BattleView(stage: s.engine.stage, state: s.state, fx: s.fx)),
    ));
    expect(t.takeException(), isNull);
  });
}
