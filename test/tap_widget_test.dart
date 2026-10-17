// 実際のジェスチャ(InteractiveViewer + GestureDetector)経由で、全地域がタップできることを確かめる。
// ここで確かめるのはズーム1倍の状態。都市州などの小さい地域は、ズーム(ピンチ)と最小タップ半径で補う。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/map/projection.dart';
import 'package:terrimap_core/map/region_geometry.dart';
import 'package:terrimap_core/map/region_map_view.dart';
import 'package:terrimap_core/pack/region_pack.dart';

RegionPack load(String id) {
  String r(String f) => File('packs/$id/$f').readAsStringSync();
  final langs = Directory('packs/$id/strings')
      .listSync()
      .map((e) => e.uri.pathSegments.last.replaceAll('.json', ''));
  return RegionPack.parse(
      packJson: r('pack.json'),
      regionsJson: r('regions.json'),
      geoJson: r('geo.geojson'),
      stringsJsonByLang: {for (final l in langs) l: r('strings/$l.json')});
}

void main() {
  const sizes = [Size(320, 480), Size(390, 600), Size(412, 700)];
  for (final id in ['de', 'us']) {
    for (final size in sizes) {
      testWidgets('$id ${size.width.toInt()}x${size.height.toInt()}: 全地域を実際にタップできる', (t) async {
        final pack = load(id);
        final tapped = <String>[];
        await t.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: RegionMapView(
                  pack: pack,
                  colorOf: (_) => Colors.grey,
                  onTap: tapped.add,
                ),
              ),
            ),
          ),
        ));
        await t.pump();

        final origin = t.getTopLeft(find.byType(RegionMapView));
        final proj = pack.projectionType == 'planar'
            ? const Planar() as MapProjection
            : EquirectCos.fromRefLat(pack.refLat);
        final geo = RegionGeometry(pack, proj, size);

        final wrong = <String, String?>{};
        for (final r in pack.regions) {
          tapped.clear();
          await t.tapAt(origin + geo.centroid[r.id]!);
          await t.pump();
          if (tapped.length != 1 || tapped.single != r.id) {
            wrong[r.id] = tapped.isEmpty ? null : tapped.join(',');
          }
        }
        expect(wrong, isEmpty);
      });
    }
  }

  test('最小タップ領域の目安: 描画サイズが小さい地域の一覧(ズーム1倍・390x600)', () {
    for (final id in ['de', 'us']) {
      final pack = load(id);
      final proj = pack.projectionType == 'planar'
          ? const Planar() as MapProjection
          : EquirectCos.fromRefLat(pack.refLat);
      final geo = RegionGeometry(pack, proj, const Size(390, 600));
      final small = <String, double>{};
      for (final r in pack.regions) {
        final b = geo.paths[r.id]!.getBounds();
        final side = b.width < b.height ? b.width : b.height;
        if (side < 24) small[r.id] = side; // 指で押すには小さい(目安24px)
      }
      // 失敗させず、一覧を出す(ズームか最小タップ半径18pxで補う対象)。
      // ignore: avoid_print
      print('$id: ${small.length}地域が短辺24px未満 -> ${small.entries.map((e) => '${e.key}=${e.value.toStringAsFixed(1)}px').join(', ')}');
      expect(small.length, lessThan(pack.regions.length));
    }
  });
}
