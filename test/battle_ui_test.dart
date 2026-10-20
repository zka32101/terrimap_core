import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
import 'package:terrimap_core/battle/stage_generator.dart';
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
  BattleSession session({Difficulty d = Difficulty.normal, bool assist = false}) => BattleSession(
      BattleEngine(StageGenerator(de).generate('DE-BY', d), profile: de.profile, pack: de, quizAssist: assist));

  group('BattleSession', () {
    test('設置枠を選んで施設を置き、強化・撤去できる', () {
      final s = session();
      final slot = s.engine.stage.slots.first;
      expect(s.place(FacilityType.farm), false); // 未選択
      s.tapCell(slot);
      expect(s.selected, slot);
      expect(s.place(FacilityType.farm), true);
      expect(s.state.facilities[slot]!.type, FacilityType.farm);
      expect(s.selectedFacility, isNotNull);
      final coins = s.state.coins;
      expect(s.upgrade(), true);
      expect(s.state.coins, lessThan(coins));
      expect(s.remove(), true);
      expect(s.selected, isNull);
      expect(s.state.facilities, isEmpty);
    });
    test('同じマスをもう一度で選択解除。設置枠でないマスは選べない', () {
      final s = session();
      final slot = s.engine.stage.slots.first;
      s.tapCell(slot);
      s.tapCell(slot);
      expect(s.selected, isNull);
      final land = s.engine.stage.land.firstWhere((c) => !s.engine.stage.slots.contains(c));
      s.tapCell(land);
      expect(s.selected, isNull);
    });
    test('時間: 速度・一時停止・終了後は進まない、イベントが記録される', () {
      final s = session();
      s.startWave();
      expect(s.state.phase, BattlePhase.wave);
      s.tick(2);
      final t1 = s.state.time;
      s.setSpeed(2);
      s.tick(1);
      expect(s.state.time - t1, closeTo(2, 0.05));
      s.togglePause();
      s.tick(5);
      expect(s.state.time - t1, closeTo(2, 0.05));
      expect(s.log, isNotEmpty);
      s.togglePause();
      var n = 0;
      while (!s.isOver && n++ < 3000) {
        s.tick(1);
      }
      expect(s.isOver, true); // 防衛なしは敗北
      expect(s.won, false);
      final t = s.state.time;
      s.tick(10);
      expect(s.state.time, t);
    });
    test('スキル: クイズ連動のとき、正解してから選ぶ', () {
      final s = session(assist: true);
      expect(s.skillNeedsQuiz, true);
      expect(s.skillQuestion, isNotNull);
      final first = s.skillChoices.first;
      expect(s.chooseSkill(first), false);
      s.answerSkillQuiz(correct: true);
      expect(s.skillNeedsQuiz, false);
      expect(s.chooseSkill(first), true);
      expect(s.state.skill, first);
      final off = session();
      expect(off.skillNeedsQuiz, false);
      expect(off.chooseSkill(off.skillChoices.first), true);
    });
    test('hard の修理: クイズの結果で無料／有料（オフならコインで修理）', () {
      final s = session(d: Difficulty.hard, assist: true);
      final slot = s.engine.stage.slots.first;
      s.tapCell(slot);
      s.state = s.state.copyWith(coins: 500);
      s.place(FacilityType.farm);
      final f = s.selectedFacility!;
      s.state = s.state.copyWith(facilities: {slot: f.copyWith(hp: 1)});
      final coins = s.state.coins;
      expect(s.repair(correct: true), true);
      expect(s.state.coins, coins);
      expect(s.state.facilities[slot]!.hp, s.engine.maxHpOf(s.state.facilities[slot]!));
      // オフなら、正解でもコインを払う
      final off = session(d: Difficulty.hard);
      off.tapCell(slot);
      off.state = off.state.copyWith(coins: 500);
      off.place(FacilityType.farm);
      off.state = off.state.copyWith(facilities: {slot: off.selectedFacility!.copyWith(hp: 1)});
      final c0 = off.state.coins;
      expect(off.repair(correct: true), true);
      expect(off.state.coins, lessThan(c0));
    });
  });

  group('BattleView', () {
    testWidgets('盤面を描き、マスのタップが onCellTap に届く', (t) async {
      final s = session();
      GridPos? tapped;
      await t.pumpWidget(MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: BattleView(stage: s.engine.stage, state: s.state, onCellTap: (c) => tapped = c),
          ),
        ),
      ));
      final slot = s.engine.stage.slots.first;
      final box = t.getRect(find.byType(BattleView));
      final l = BattleView.layout(box.size, s.engine.stage.cols, s.engine.stage.rows);
      await t.tapAt(box.topLeft + Offset(l.dx + (slot.col + 0.5) * l.cell, l.dy + (slot.row + 0.5) * l.cell));
      expect(tapped, slot);
    });
    testWidgets('ピンチで拡大でき、拡大後もタップが同じマスに届く', (t) async {
      final s = session();
      GridPos? tapped;
      await t.pumpWidget(MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: BattleView(stage: s.engine.stage, state: s.state, onCellTap: (c) => tapped = c),
          ),
        ),
      ));
      final box = t.getRect(find.byType(BattleView));
      final c = box.center;
      final g1 = await t.startGesture(c - const Offset(20, 0), pointer: 1);
      final g2 = await t.startGesture(c + const Offset(20, 0), pointer: 2);
      await g1.moveBy(const Offset(-60, 0));
      await g2.moveBy(const Offset(60, 0));
      await g1.up();
      await g2.up();
      await t.pump();
      final m = t.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      expect(m.maxScale, 3);
      // 拡大後、中央のタップは盤面の中央のマスに届く
      await t.tapAt(c);
      final cols = s.engine.stage.cols, rows = s.engine.stage.rows;
      expect(tapped, isNotNull);
      expect((tapped!.col - cols / 2).abs(), lessThanOrEqualTo(1));
      expect((tapped!.row - rows / 2).abs(), lessThanOrEqualTo(1));
    });
    testWidgets('施設・敵・選択・射程があっても描ける', (t) async {
      final s = session(d: Difficulty.hard);
      final slot = s.engine.stage.slots.first;
      s.tapCell(slot);
      s.state = s.state.copyWith(coins: 999);
      s.place(FacilityType.castle);
      s.placeExclusive();
      s.startWave();
      s.tick(8);
      await t.pumpWidget(MaterialApp(
        home: SizedBox(
          width: 360,
          height: 500,
          child: BattleView(
            stage: s.engine.stage,
            state: s.state,
            selected: slot,
            selectedRange: 2,
            facilityMaxHp: s.engine.maxHpOf,
          ),
        ),
      ));
      expect(find.byType(BattleView), findsOneWidget);
    });
    test('cellAt: 盤面の外は null', () {
      expect(BattleView.cellAt(const Offset(-5, 10), const Size(100, 100), 10, 10), isNull);
      expect(BattleView.cellAt(const Offset(55, 5), const Size(100, 100), 10, 10), const GridPos(5, 0));
    });
  });
}
