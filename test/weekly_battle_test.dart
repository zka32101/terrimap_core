import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
import 'package:terrimap_core/battle/invite.dart';
import 'package:terrimap_core/battle/weekly_battle.dart';
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
  test('週の名前: ISO 週。月曜はじまり・年をまたぐ週', () {
    expect(WeeklyBattle.weekOf('2026-10-19'), '2026-W43'); // 月曜
    expect(WeeklyBattle.weekOf('2026-10-25'), '2026-W43'); // 日曜
    expect(WeeklyBattle.weekOf('2026-10-26'), '2026-W44');
    expect(WeeklyBattle.weekOf('2026-01-01'), '2026-W01');
    expect(WeeklyBattle.weekOf('2021-01-03'), '2020-W53'); // 前年の最終週に入る
    expect(WeeklyBattle.weekOf('2024-12-30'), '2025-W01'); // 翌年の第1週に入る
  });

  test('残り日数: 月曜=7、日曜=1', () {
    expect(WeeklyBattle.daysLeft('2026-10-19'), 7);
    expect(WeeklyBattle.daysLeft('2026-10-22'), 4);
    expect(WeeklyBattle.daysLeft('2026-10-25'), 1);
  });

  for (final c in ['de', 'us']) {
    test('$c: 同じ週は同じ条件で、週が変わると変わりうる。招待コードとして有効', () {
      final pack = load(c);
      final a = WeeklyBattle.forDate(pack, '2026-10-19');
      final b = WeeklyBattle.forDate(pack, '2026-10-25'); // 同じ週の日曜
      expect((a.kind, a.stageId, a.difficulty), (b.kind, b.stageId, b.difficulty));
      expect(a.week, '2026-W43');
      final seen = {for (var w = 0; w < 30; w++) WeeklyBattle.forDate(pack, DateTime.utc(2026, 1, 5).add(Duration(days: 7 * w)).toIso8601String().substring(0, 10)).stageId};
      expect(seen.length, greaterThan(1)); // 毎週同じではない
      for (var w = 0; w < 30; w++) {
        final day = DateTime.utc(2026, 1, 5).add(Duration(days: 7 * w)).toIso8601String().substring(0, 10);
        final x = WeeklyBattle.forDate(pack, day);
        expect(x.difficulty == Difficulty.hard || x.difficulty == Difficulty.normal, isTrue);
        expect(x.invite(pack.packId).isValidFor(pack), isTrue, reason: '$day ${x.stageId}');
        expect(x.kind, pack.profile!.groups.isNotEmpty ? StageKind.regional : StageKind.normal);
      }
    });
  }

  test('招待コード: 結果つきで往復できる', () {
    final pack = load('de');
    final w = WeeklyBattle.forDate(pack, '2026-10-20');
    final code = w.invite(pack.packId, won: true, baseHp: 12).toCode();
    final back = Invite.parse('今週のチャレンジ $code よろしく')!;
    expect((back.kind, back.stageId, back.difficulty, back.won, back.baseHp), (w.kind, w.stageId, w.difficulty, true, 12));
  });

  test('結果の保存: 今週だけ「挑戦済み」。壊れたデータは未挑戦', () {
    final r = WeeklyRecord('2026-W43', true, 9);
    final back = WeeklyRecord.fromJson(r.toJson())!;
    expect((back.week, back.won, back.baseHp), ('2026-W43', true, 9));
    expect(back.doneIn('2026-W43'), isTrue);
    expect(back.doneIn('2026-W44'), isFalse);
    expect(WeeklyRecord.fromJson(null), isNull);
    expect(WeeklyRecord.fromJson('{broken'), isNull);
    expect(WeeklyRecord.fromJson('{"week":1}'), isNull);
  });
}
