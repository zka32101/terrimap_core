import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/bot.dart';
import 'package:terrimap_core/battle/daily_battle.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
import 'package:terrimap_core/battle/replay.dart';
import 'package:terrimap_core/battle/stage_generator.dart';
import 'package:terrimap_core/battle_ui/battle_session.dart';
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

  BattleEngine engineOf(RegionPack p, String id, Difficulty d, {StageKind kind = StageKind.normal, bool assist = true}) =>
      BattleEngine(StageGenerator(p).generate(id, d, kind: kind), profile: p.profile, pack: p, quizAssist: assist);

  Replay botReplay(RegionPack p, String id, Difficulty d, BotProfile bp, {StageKind kind = StageKind.normal, bool assist = true}) {
    final e = engineOf(p, id, d, kind: kind, assist: assist);
    final rec = ReplayRecorder(e);
    BattleBot(e, bp, recorder: rec).play();
    return rec.toReplay(packId: p.packId, kind: kind, stageId: id, difficulty: d);
  }

  test('ボットの対戦を記録して再生すると、保存された結果と一致する（全難易度・通常/地方/エクストラ・クイズ連動の有無）', () {
    for (final d in Difficulty.values) {
      final r = botReplay(de, 'DE-BY', d, BotProfile.regular);
      expect(r.ops, isNotEmpty);
      expect(r.verify(de), true, reason: 'DE-BY $d');
    }
    expect(botReplay(us, 'US-CA', Difficulty.normal, BotProfile.expert, assist: false).verify(us), true);
    final g = de.profile!.groups.keys.first;
    expect(botReplay(de, g, Difficulty.normal, BotProfile.expert, kind: StageKind.regional).verify(de), true);
    final x = de.profile!.extras.first.id;
    expect(botReplay(de, x, Difficulty.easy, BotProfile.expert, kind: StageKind.extra).verify(de), true);
  });

  test('結果の中身: 勝ち負け・波・拠点HP・波ごとの被害', () {
    final r = botReplay(de, 'DE-BY', Difficulty.easy, BotProfile.expert);
    expect(r.result.won, true);
    expect(r.result.breaches.length, r.result.wave);
    expect(r.result.baseHp, greaterThan(0));
    final lost = botReplay(de, 'DE-BY', Difficulty.hard, BotProfile.casual);
    if (!lost.result.won) expect(lost.result.breaches.last, greaterThan(0));
  });

  test('画面の操作役（BattleSession）で遊んだ記録は、フレームの刻み方によらず、遊んだ結果と同じ結果で再生できる', () {
    List<ReplayOp> play(List<double> frames) {
      final s = BattleSession(engineOf(de, 'DE-BY', Difficulty.easy, assist: false));
      final slots = s.engine.stage.slots;
      var i = 0;
      void act() {
        // 一定の刻み数ごとに、操作する
        if (s.state.tickCount % 40 == 0 && i < slots.length && !s.isOver) {
          s.selected = slots[i];
          if (s.place(i % 2 == 0 ? FacilityType.farm : FacilityType.factory)) i++;
        }
        if (s.state.tickCount % 90 == 0 && s.inPrep && s.state.wave < s.engine.stage.waves.length) s.startWave();
      }

      var t = 0;
      while (!s.isOver && t < 200000) {
        act();
        s.tick(frames[t % frames.length]);
        t++;
      }
      final rep = s.recorder.toReplay(packId: de.packId, kind: StageKind.normal, stageId: 'DE-BY', difficulty: Difficulty.easy);
      expect(rep.verify(de), true);
      // 画面で遊んだ最後の状態と、再生の結果が一致する
      expect([rep.result.baseHp, rep.result.wave, rep.result.score], [s.state.baseHp, s.state.wave, s.state.score]);
      return rep.ops;
    }

    // 60fps相当と、ばらつくフレームで、記録が（刻みの上で）同じ結果に再生できる
    // （操作のタイミングはフレームごとに違ってよい。それぞれの記録が、遊んだ結果と一致して再生できればよい）
    expect(play([1 / 60]), isNotEmpty);
    expect(play([0.016, 0.031, 0.007, 0.05]), isNotEmpty);
  });

  test('保存→読み込みで同じ。共有の文字列も往復できる。壊れた文字列は null', () {
    final r = botReplay(de, 'DE-BY', Difficulty.normal, BotProfile.regular);
    final back = Replay.tryParse(r.toJsonString())!;
    expect(back.verify(de), true);
    expect(back.result, r.result);
    final code = r.toShareCode();
    expect(code, matches(RegExp(r'^[A-Za-z0-9_\-=]+$')));
    expect(Replay.fromShareCode(code)!.verify(de), true);
    expect(Replay.tryParse('{not json'), isNull);
    expect(Replay.tryParse(null), isNull);
    expect(Replay.fromShareCode('!!!'), isNull);
  });

  test('改ざんは見つかる: 結果を書き換える／操作を消す／別の pack で再生', () {
    final r = botReplay(de, 'DE-BY', Difficulty.normal, BotProfile.regular);
    final fake = r.withResult(ReplayResult(!r.result.won, r.result.wave, r.result.baseHp + 1, r.result.score, r.result.breaches));
    expect(fake.verify(de), false);
    final fewer = Replay(
        packId: r.packId, kind: r.kind, stageId: r.stageId, difficulty: r.difficulty, quizAssist: r.quizAssist, ops: r.ops.skip(r.ops.length ~/ 2).toList(), result: r.result);
    expect(fewer.verify(de), false);
    expect(() => r.buildEngine(us), throwsArgumentError);
    // 置けない場所への操作
    final bad = Replay(
        packId: r.packId, kind: r.kind, stageId: r.stageId, difficulty: r.difficulty, quizAssist: r.quizAssist,
        ops: [const ReplayOp(0, ReplayOp.place, pos: GridPos(-1, -1), arg: 'farm')], result: r.result);
    expect(bad.verify(de), false);
  });

  group('デイリーのバトル', () {
    test('同じ日付と pack なら同じ条件。日付が変わると変わる', () {
      final a = DailyBattle.forDate(de, '2026-10-18'), b = DailyBattle.forDate(de, '2026-10-18');
      expect([a.stageId, a.difficulty, a.kind], [b.stageId, b.difficulty, b.kind]);
      final days = {for (var d = 1; d <= 28; d++) DailyBattle.forDate(de, '2026-10-${d.toString().padLeft(2, '0')}').stageId};
      expect(days.length, greaterThan(5));
      expect(DailyBattle.forDate(us, '2026-10-18').stageId, startsWith('US-'));
    });

    test('難易度の割合はおおよそ easy 3 : normal 5 : hard 2。選べる州を絞れる', () {
      final c = {for (final d in Difficulty.values) d: 0};
      for (var i = 0; i < 600; i++) {
        final day = DateTime.utc(2026, 1, 1).add(Duration(days: i));
        final b = DailyBattle.forDate(us, day.toIso8601String().substring(0, 10));
        c[b.difficulty] = c[b.difficulty]! + 1;
      }
      expect(c[Difficulty.normal]!, greaterThan(c[Difficulty.easy]!));
      expect(c[Difficulty.easy]!, greaterThan(c[Difficulty.hard]!));
      final only = {'DE-BY', 'DE-NW'};
      for (var d = 1; d <= 20; d++) {
        expect(only, contains(DailyBattle.forDate(de, '2026-11-${d.toString().padLeft(2, '0')}', allowedIds: only).stageId));
      }
      expect(() => DailyBattle.forDate(de, '2026-11-01', allowedIds: {}), throwsArgumentError);
    });

    test('今日のバトルを遊んで記録→再生→共有テキスト（波ごとの🟩🟥と拠点HP）', () {
      final day = DailyBattle.forDate(de, '2026-10-18');
      final e = engineOf(de, day.stageId, day.difficulty);
      final rec = ReplayRecorder(e);
      BattleBot(e, BotProfile.regular, recorder: rec).play();
      final r = rec.toReplay(packId: de.packId, kind: day.kind, stageId: day.stageId, difficulty: day.difficulty);
      expect(r.verify(de), true);
      final text = day.shareText('Terrimap', r.result, totalWaves: e.stage.waves.length, maxBaseHp: e.stage.baseHp);
      final lines = text.split('\n');
      expect(lines.first, startsWith('Terrimap 2026-10-18 ${day.difficulty.name}'));
      expect(lines.first, contains('♥'));
      expect(lines[1].runes.length, e.stage.waves.length);
      expect(RegExp(r'^[🟩🟥⬛]+$').hasMatch(lines[1]), true);
    });
  });
}
