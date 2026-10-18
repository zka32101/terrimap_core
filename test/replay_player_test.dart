import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/bot.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
import 'package:terrimap_core/battle/replay.dart';
import 'package:terrimap_core/battle/stage_generator.dart';
import 'package:terrimap_core/battle_ui/replay_player.dart';
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
  BattleEngine engineOf(String id, Difficulty d) => BattleEngine(StageGenerator(de).generate(id, d), profile: de.profile, pack: de);

  Replay record(String id, Difficulty d, BotProfile bp) {
    final e = engineOf(id, d);
    final rec = ReplayRecorder(e);
    BattleBot(e, bp, recorder: rec).play();
    return rec.toReplay(packId: de.packId, kind: StageKind.normal, stageId: id, difficulty: d);
  }

  test('最後まで再生すると、記録された結果と同じになる（一気に飛ばしても、フレームで進めても）', () {
    final r = record('DE-BY', Difficulty.normal, BotProfile.regular);
    final skip = ReplayPlayer(engineOf('DE-BY', Difficulty.normal), r)..skipToEnd();
    expect(skip.isOver, true);
    expect(skip.matchesRecorded, true);
    expect([skip.state.baseHp, skip.state.wave, skip.state.score], [r.result.baseHp, r.result.wave, r.result.score]);

    final frames = ReplayPlayer(engineOf('DE-BY', Difficulty.normal), r)..setSpeed(4);
    var n = 0;
    while (!frames.isOver && n++ < 200000) {
      frames.tick(0.016 + (n % 3) * 0.011); // ばらつくフレーム
    }
    expect(frames.matchesRecorded, true);
    expect(frames.state.summary(), skip.state.summary());
  });

  test('一時停止・速度・やり直し', () {
    final r = record('DE-BY', Difficulty.easy, BotProfile.expert);
    final p = ReplayPlayer(engineOf('DE-BY', Difficulty.easy), r);
    p.togglePause();
    p.tick(5);
    expect(p.state.tickCount, 0); // 止まっている
    p.togglePause();
    p.tick(1);
    final t1 = p.state.tickCount;
    expect(t1, inInclusiveRange(29, 31));
    p.setSpeed(2);
    p.tick(1);
    expect(p.state.tickCount - t1, inInclusiveRange(59, 61));
    expect(p.progress, inInclusiveRange(0.0, 1.0));
    p.skipToEnd();
    expect(p.progress, 1.0);
    p.restart();
    expect(p.state.tickCount, 0);
    expect(p.isOver, false);
    p.skipToEnd();
    expect(p.matchesRecorded, true);
  });

  test('施設の操作が記録どおりの刻みで起きる（最初の操作の直後に施設が置かれている）', () {
    final r = record('DE-BY', Difficulty.normal, BotProfile.regular);
    final first = r.ops.firstWhere((o) => o.kind == ReplayOp.place);
    final p = ReplayPlayer(engineOf('DE-BY', Difficulty.normal), r);
    expect(p.state.facilities.length, first.tick == 0 ? greaterThan(0) : 0);
    while (p.state.tickCount <= first.tick) {
      p.tick(1 / 30);
    }
    expect(p.state.facilities, isNotEmpty);
  });

  test('改ざんされた記録は、止まって corrupt になる', () {
    final r = record('DE-BY', Difficulty.normal, BotProfile.regular);
    final bad = Replay(
        packId: r.packId, kind: r.kind, stageId: r.stageId, difficulty: r.difficulty, quizAssist: r.quizAssist,
        ops: [const ReplayOp(0, ReplayOp.place, pos: GridPos(-1, -1), arg: 'farm')], result: r.result);
    final p = ReplayPlayer(engineOf('DE-BY', Difficulty.normal), bad);
    expect(p.corrupt, true);
    p.tick(10);
    expect(p.state.tickCount, 0);
    expect(p.finished, true);
    expect(p.matchesRecorded, false);
  });

  test('イベントのログがたまる（最大 maxLog 件）', () {
    final r = record('DE-BY', Difficulty.normal, BotProfile.regular);
    final p = ReplayPlayer(engineOf('DE-BY', Difficulty.normal), r)..skipToEnd();
    expect(p.log, isNotEmpty);
    expect(p.log.length, lessThanOrEqualTo(ReplayPlayer.maxLog));
  });
}
