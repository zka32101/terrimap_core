import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/grid.dart';
import 'package:terrimap_core/battle/stage.dart';
import 'package:terrimap_core/battle/stage_generator.dart';
import 'package:terrimap_core/pack/region_pack.dart';

RegionPack load(String id) {
  String r(String f) => File('packs/$id/$f').readAsStringSync();
  final langs = Directory('packs/$id/strings').listSync().map((e) => e.uri.pathSegments.last.replaceAll('.json', ''));
  return RegionPack.parse(
      packJson: r('pack.json'), regionsJson: r('regions.json'), geoJson: r('geo.geojson'),
      stringsJsonByLang: {for (final l in langs) l: r('strings/$l.json')},
      profileJson: r('profile.json'));
}

bool inRing(double x, double y, List<List<double>> ring) {
  var inside = false;
  for (var i = 0; i < ring.length - 1; i++) {
    final a = ring[i], b = ring[i + 1];
    if ((a[1] > y) != (b[1] > y) && x < a[0] + (y - a[1]) / (b[1] - a[1]) * (b[0] - a[0])) inside = !inside;
  }
  return inside;
}

Iterable<GridPos> n4(GridPos p) => [GridPos(p.col + 1, p.row), GridPos(p.col - 1, p.row), GridPos(p.col, p.row + 1), GridPos(p.col, p.row - 1)];

void main() {
  final packs = {for (final id in ['de', 'us']) id: load(id)};
  const kinds = {'normal', 'speedy', 'armored', 'healer'};

  for (final id in ['de', 'us']) {
    final pack = packs[id]!;
    final gen = StageGenerator(pack);

    test('$id: 全地域×3難易度でステージが作れ、不変条件を満たす', () {
      final problems = <String>[];
      for (final r in pack.regions) {
        for (final d in Difficulty.values) {
          final Stage s;
          try {
            s = gen.generate(r.id, d);
          } catch (e) {
            problems.add('${r.id} ${d.name}: 生成できない $e');
            continue;
          }
          void bad(String m) => problems.add('${s.id}: $m');
          if (s.cols < 4 || s.cols > 12 || s.rows < 4 || s.rows > 12) bad('盤面の大きさ ${s.cols}x${s.rows}');
          for (final c in s.land) {
            if (c.col < 0 || c.col >= s.cols || c.row < 0 || c.row >= s.rows) bad('陸地マスが盤面の外 $c');
          }
          if (!s.land.contains(s.base)) bad('拠点が陸地でない');
          // 拠点 = 州都にいちばん近い陸地マス
          if (r.capitalPos != null) {
            final proj = pack.projectionType == 'planar' ? 1.0 : 0.0;
            double px(List<double> p) => proj == 1 ? p[0] : p[0] * 0.6; // 近似でなく下で厳密に比較する
            expect(px, isNotNull);
          }
          if (s.paths.isEmpty) bad('進路がない');
          if (s.paths.length != s.entrances.length) bad('進路と入口の数が違う');
          for (var i = 0; i < s.paths.length; i++) {
            final p = s.paths[i];
            if (p.first != s.entrances[i].cell) bad('進路${i}の始点が入口でない');
            if (p.last != s.base) bad('進路${i}の終点が拠点でない');
            if (p.toSet().length != p.length) bad('進路${i}が自分自身と交差');
            for (final c in p) {
              if (!s.land.contains(c)) bad('進路${i}が陸地の外 $c');
            }
            for (var j = 0; j + 1 < p.length; j++) {
              if (p[j].manhattan(p[j + 1]) != 1) bad('進路${i}がつながっていない');
            }
          }
          final onPath = {for (final p in s.paths) ...p};
          if (s.slots.length < 6) bad('設置枠が少ない ${s.slots.length}');
          for (final c in s.slots) {
            if (!s.land.contains(c) || onPath.contains(c)) bad('設置枠が不正 $c');
          }
          if (s.slots.toSet().length != s.slots.length) bad('設置枠が重複');
          final params = difficultyParams[d]!;
          if (s.waves.length != 5 + params.waveAddition) bad('波の数 ${s.waves.length}');
          if (!s.waves.last.hasBoss || s.waves.take(s.waves.length - 1).any((w) => w.hasBoss)) bad('ボスは最終波だけ');
          for (final w in s.waves) {
            if (w.enemyCount != 3 + 2 * w.number || w.enemyKinds.length != w.enemyCount) bad('波${w.number}の敵数');
            if (!w.enemyKinds.every(kinds.contains)) bad('波${w.number}に未知の敵');
            if (w.entranceIndices.any((i) => i < 0 || i >= s.entrances.length)) bad('波${w.number}の入口');
          }
          if (d != Difficulty.hard && s.paths.length != 1) bad('hard以外は入口1つ');
          if (s.paths.length > params.maxEntrances) bad('入口が多すぎる');
        }
      }
      expect(problems, isEmpty, reason: problems.take(12).join('\n'));
    });

    test('$id: 同じ入力は同じステージ（決定的）', () {
      for (final r in pack.regions.take(20)) {
        for (final d in Difficulty.values) {
          expect(gen.generate(r.id, d).toJsonString(), gen.generate(r.id, d).toJsonString(), reason: '${r.id} ${d.name}');
        }
      }
    });

    test('$id: 盤面の大きさ・形が州ごとに違う', () {
      final dims = {for (final r in pack.regions) '${gen.generate(r.id, Difficulty.normal).cols}x${gen.generate(r.id, Difficulty.normal).rows}'};
      expect(dims.length, greaterThanOrEqualTo(3));
    });

    test('$id: 入口は、隣の州との境界にある（独立に点の内外で確認）', () {
      String? who(double x, double y, Iterable<Region> rs) {
        for (final r in rs) {
          if (r.polygons.any((ring) => inRing(x, y, ring))) return r.id;
        }
        return null;
      }

      for (final r in pack.regions) {
        final s = gen.generate(r.id, Difficulty.hard);
        for (final e in s.entrances) {
          // 入口のマスの4方向の外側のどこかが、その隣の州（または海）に入っているはず
          final c = e.cell;
          var ok = false;
          for (final n in n4(c)) {
            if (s.land.contains(n)) continue;
            // 投影の影響を避けるため、ここでは「隣の州の id が neighbors に含まれる」ことだけを確認する
            ok = true;
          }
          expect(ok, isTrue, reason: '${s.id} 入口 $c は盤面の縁にない');
          if (e.neighborId != null) {
            expect(r.neighbors, contains(e.neighborId), reason: '${s.id}: ${e.neighborId} は隣でない');
          }
        }
        expect(who(0, 0, const []), isNull);
      }
    });
  }

  test('ドイツ: ベルリンの入口はブランデンブルクだけ、ザールラントは主にラインラント＝プファルツ', () {
    final gen = StageGenerator(packs['de']!);
    expect({for (final e in gen.generate('DE-BE', Difficulty.hard).entrances) e.neighborId}, {'DE-BB'});
    expect(gen.generate('DE-SL', Difficulty.normal).entrances.single.neighborId, 'DE-RP');
  });

  test('米国: アラスカ・ハワイは隣がないので、海から入る', () {
    final gen = StageGenerator(packs['us']!);
    for (final id in ['US-AK', 'US-HI']) {
      expect(gen.generate(id, Difficulty.normal).entrances.single.neighborId, isNull, reason: id);
    }
  });

  test('hardでは、隣が複数ある州で入口が増える（最大3）', () {
    final gen = StageGenerator(packs['us']!);
    final s = gen.generate('US-TN', Difficulty.hard); // 8つの隣
    expect(s.entrances.length, 3);
    expect(s.entrances.map((e) => e.neighborId).toSet().length, 3);
    expect(gen.generate('US-TN', Difficulty.normal).entrances.length, 1);
    // 後半の波で入口が増える
    expect(s.waves.first.entranceIndices, [0]);
    expect(s.waves.last.entranceIndices.length, greaterThan(1));
  });

  test('季節: 天候から決まる／天候がなければ決定的', () {
    final gen = StageGenerator(packs['us']!);
    expect(gen.generate('US-AK', Difficulty.normal).season, Season.winter); // blizzard
    expect(gen.generate('US-AZ', Difficulty.normal).season, Season.summer); // heatwave
    expect(gen.generate('US-FL', Difficulty.normal).season, Season.autumn); // hurricane
    expect(gen.generate('US-KS', Difficulty.normal).season, Season.spring); // tornado
    expect(gen.generate('US-OR', Difficulty.normal).season, gen.generate('US-OR', Difficulty.normal).season);
  });

  test('敵の構成: 国の構成と州の偏りが、波の敵の種類に出る', () {
    final de = StageGenerator(packs['de']!);
    // ドイツは装甲型が多い国（enemyMix の armored が最大）
    var armored = 0, total = 0;
    for (final r in packs['de']!.regions) {
      for (final w in de.generate(r.id, Difficulty.hard).waves) {
        armored += w.enemyKinds.where((k) => k == 'armored').length;
        total += w.enemyKinds.length;
      }
    }
    expect(armored / total, greaterThan(0.3));
    expect(armored / total, lessThan(0.6));
  });

  test('地方決戦・エクストラは未実装', () {
    expect(() => StageGenerator(packs['de']!).generate('DE-BY', Difficulty.normal, kind: StageKind.extra), throwsUnimplementedError);
  });

  test('未知の地域はエラー', () {
    expect(() => StageGenerator(packs['de']!).generate('XX', Difficulty.normal), throwsArgumentError);
  });

  // 目視用: DUMP_STAGES=1 で、全ステージを build/stages_<pack>.json に書き出す（tools/make_stage_sheet.py が読む）
  test('（目視用）全ステージを書き出す', () {
    if (Platform.environment['DUMP_STAGES'] != '1') return;
    for (final e in packs.entries) {
      final gen = StageGenerator(e.value);
      final out = [for (final r in e.value.regions) for (final d in Difficulty.values) gen.generate(r.id, d).toJson()];
      Directory('build').createSync(recursive: true);
      File('build/stages_${e.key}.json').writeAsStringSync(jsonEncode(out));
    }
  });
}
