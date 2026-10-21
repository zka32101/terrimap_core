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

  test('演出: ボスの登場は、赤い縁取り・BOSSの表示・波紋・揺れが出る', () {
    final fx = BattleFx();
    final s = play(fx: false);
    final st = s.state;
    fx.consume(st, const [BattleEvent(BattleEventType.spawn, enemyId: 'none', isBoss: true)], s.engine.stage);
    expect(fx.items.any((i) => i.kind == FxKind.banner && i.text == 'BOSS'), isTrue);
    expect(fx.items.any((i) => i.kind == FxKind.baseFlash), isTrue);
    expect(fx.shake(st.time + 0.02) == Offset.zero, false);
    // ふつうの敵の登場では何も出ない
    final fx2 = BattleFx();
    fx2.consume(st, const [BattleEvent(BattleEventType.spawn, enemyId: 'none')], s.engine.stage);
    expect(fx2.items, isEmpty);
  });

  test('演出: コンボは、間をあけずに倒すと増え、3連続から表示。間があくと1に戻る', () {
    final fx = BattleFx();
    final s = play(fx: false);
    final st = s.state;
    BattleState at(double t) => BattleState(
        phase: st.phase, wave: st.wave, prepTimer: st.prepTimer, spawned: st.spawned, spawnAcc: st.spawnAcc, enemies: const [],
        facilities: st.facilities, coins: st.coins, baseHp: st.baseHp, score: st.score, mistakes: st.mistakes, time: t, tickCount: st.tickCount);
    const kill = [BattleEvent(BattleEventType.kill, value: 5)];
    fx.consume(at(10.0), kill, s.engine.stage);
    fx.consume(at(10.5), kill, s.engine.stage);
    expect(fx.combo, 2);
    expect(fx.items.where((i) => i.kind == FxKind.combo), isEmpty); // 2連続までは出さない
    fx.consume(at(11.0), kill, s.engine.stage);
    expect(fx.combo, 3);
    expect(fx.items.where((i) => i.kind == FxKind.combo).single.text, '×3');
    fx.consume(at(20.0), kill, s.engine.stage); // 間があいた
    expect(fx.combo, 1);
    fx.clear();
    expect(fx.combo, 0);
  });

  test('演出: 勝利は花火と表示、敗北は赤い縁取りと強い揺れ。波クリアの表示も出る', () {
    final s = play(fx: false);
    final st = s.state;
    final win = BattleFx()..consume(st, const [BattleEvent(BattleEventType.victory)], s.engine.stage);
    expect(win.items.where((i) => i.kind == FxKind.confetti).length, 6);
    expect(win.items.any((i) => i.kind == FxKind.banner && i.text == 'VICTORY!'), isTrue);
    final lose = BattleFx()..consume(st, const [BattleEvent(BattleEventType.defeat)], s.engine.stage);
    expect(lose.items.any((i) => i.kind == FxKind.baseFlash), isTrue);
    expect(lose.items.any((i) => i.kind == FxKind.banner && i.text == 'DEFEAT'), isTrue);
    expect(lose.shake(st.time + 0.02) == Offset.zero, false);
    final clear = BattleFx()..consume(st, const [BattleEvent(BattleEventType.waveClear, value: 4)], s.engine.stage);
    expect(clear.items.single.text, 'WAVE 4 CLEAR');
  });

  testWidgets('演出: ボス・コンボ・花火・敗北を全部描いてもエラーにならない', (t) async {
    final s = play();
    final st = s.state;
    final fx = s.fx
      ..consume(st, const [BattleEvent(BattleEventType.spawn, enemyId: 'x', isBoss: true), BattleEvent(BattleEventType.victory), BattleEvent(BattleEventType.defeat)], s.engine.stage);
    for (var i = 0; i < 5; i++) {
      fx.consume(st, const [BattleEvent(BattleEventType.kill, value: 3)], s.engine.stage);
    }
    await t.pumpWidget(MaterialApp(home: SizedBox(width: 400, height: 600, child: BattleView(stage: s.engine.stage, state: st, fx: fx))));
    expect(t.takeException(), isNull);
    expect(fx.items.any((i) => i.kind == FxKind.combo), isTrue);
  });
}
