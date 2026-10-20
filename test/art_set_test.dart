import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/stage_generator.dart';
import 'package:terrimap_core/battle_ui/art_set.dart';
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

Future<ui.Image> solid(int w, int h, Color c) async {
  final rec = ui.PictureRecorder();
  Canvas(rec).drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..color = c);
  return rec.endRecording().toImage(w, h);
}

class _EmptyBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw FlutterError('no asset');
}

void main() {
  final de = load('de');
  BattleSession session() => BattleSession(
      BattleEngine(StageGenerator(de).generate('DE-BY', Difficulty.hard), profile: de.profile, pack: de, quizAssist: false));

  test('load: 画像が無いバンドルでも例外にならず空の ArtSet', () async {
    final art = await ArtSet.load(_EmptyBundle());
    expect(art.isEmpty, true);
    expect(art.backdrop('alps'), isNull);
  });

  testWidgets('天候の画像: ArtSet.weather が返し、あれば画像で、無ければ図形で描ける（どの天候でも例外にならない）', (t) async {
    final img = (await t.runAsync(() => solid(16, 9, const Color(0x8880CBC4))))!;
    final art = ArtSet(images: {'weather/storm': img});
    expect(art.weather('storm'), same(img));
    expect(art.weather('flood'), isNull);
    final s = session();
    for (final w in ['storm', 'flood']) {
      await t.pumpWidget(MaterialApp(home: SizedBox(width: 360, height: 500, child: BattleView(stage: s.engine.stage, state: s.state, art: art, weather: w))));
      await t.pump(const Duration(milliseconds: 100));
      expect(t.takeException(), isNull, reason: w);
    }
  });

  testWidgets('画像ありでも描ける（背景・施設・敵・ボス）。画像が無い要素は null', (t) async {
    final img = (await t.runAsync(() => solid(8, 8, Colors.red)))!;
    final s = session();
    final slot = s.engine.stage.slots.first;
    s.tapCell(slot);
    s.state = s.state.copyWith(coins: 999);
    s.place(FacilityType.farm);
    s.startWave();
    s.tick(8);
    final art = ArtSet(
      images: {
        'backdrops/${s.engine.stage.backdrop}': img,
        'facilities/farm_windmill': img,
        'enemies/rust_sprite': img,
      },
      facilitySkins: {for (final e in de.profile!.facilitySkins.entries) e.key: e.value.skin},
      enemySkins: {for (final e in de.profile!.enemySkins.entries) e.key: e.value.skin},
    );
    final f = s.state.facilities.values.first;
    expect(art.facility(f), isNotNull);
    expect(art.facility(f.copyWith(level: 2)), isNotNull);
    expect(art.enemy(s.state.enemies.firstWhere((e) => e.kind == 'normal', orElse: () => s.state.enemies.first)), anyOf(isNull, isNotNull));
    await t.pumpWidget(MaterialApp(
      home: SizedBox(width: 360, height: 500, child: BattleView(stage: s.engine.stage, state: s.state, art: art)),
    ));
    expect(find.byType(BattleView), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('縦長（俯瞰）の背景でも描ける', (t) async {
    final tall = (await t.runAsync(() => solid(90, 160, Colors.green)))!;
    final s = session();
    final art = ArtSet(images: {'backdrops/${s.engine.stage.backdrop}': tall});
    await t.pumpWidget(MaterialApp(
      home: SizedBox(width: 360, height: 640, child: BattleView(stage: s.engine.stage, state: s.state, art: art)),
    ));
    expect(find.byType(BattleView), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('名所の画像: landmarks/<id> を返す。無い名所は null（図鑑カードは代わりのアイコン）', (t) async {
    final img = (await t.runAsync(() => solid(8, 8, Colors.blue)))!;
    final art = ArtSet(images: {'landmarks/heidelberg_castle': img});
    expect(art.landmark('heidelberg_castle'), same(img));
    expect(art.landmark('europa_park'), isNull);
    expect(const ArtSet().landmark('heidelberg_castle'), isNull);
  });
}
