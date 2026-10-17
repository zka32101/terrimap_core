import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/map/projection.dart';
import 'package:terrimap_core/map/region_geometry.dart';
import 'package:terrimap_core/map/region_map_view.dart';
import 'package:terrimap_core/pack/region_pack.dart';

RegionPack us() {
  String r(String f) => File('packs/us/$f').readAsStringSync();
  return RegionPack.parse(
      packJson: r('pack.json'), regionsJson: r('regions.json'),
      geoJson: r('geo.geojson'), stringsJsonByLang: {'en': r('strings/en.json')});
}

Future<TransformationController> pump(WidgetTester t, {required bool controls, List<String>? tapped}) async {
  await t.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 390, height: 600,
        child: RegionMapView(pack: us(), colorOf: (_) => Colors.grey, showZoomControls: controls,
            onTap: tapped?.add),
      ),
    ),
  ));
  return t.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!;
}

void main() {
  testWidgets('既定ではズームボタンは出ない', (t) async {
    await pump(t, controls: false);
    expect(find.byKey(const Key('zoom_in')), findsNothing);
  });

  testWidgets('ボタンで拡大・縮小・元に戻す(1〜12倍の範囲)', (t) async {
    final tc = await pump(t, controls: true);
    expect(tc.value.getMaxScaleOnAxis(), closeTo(1, 1e-9));
    await t.tap(find.byKey(const Key('zoom_in')));
    expect(tc.value.getMaxScaleOnAxis(), closeTo(2, 1e-9));
    await t.tap(find.byKey(const Key('zoom_in')));
    expect(tc.value.getMaxScaleOnAxis(), closeTo(4, 1e-9));
    for (var i = 0; i < 6; i++) {
      await t.tap(find.byKey(const Key('zoom_in')));
    }
    expect(tc.value.getMaxScaleOnAxis(), closeTo(12, 1e-9)); // 上限
    await t.tap(find.byKey(const Key('zoom_out')));
    expect(tc.value.getMaxScaleOnAxis(), closeTo(6, 1e-9));
    await t.tap(find.byKey(const Key('zoom_reset')));
    expect(tc.value.getMaxScaleOnAxis(), closeTo(1, 1e-9));
    await t.tap(find.byKey(const Key('zoom_out'))); // 下限(1倍より小さくならない)
    expect(tc.value.getMaxScaleOnAxis(), closeTo(1, 1e-9));
  });

  testWidgets('拡大後も、画面上の位置どおりに地図のタップが効く', (t) async {
    final tapped = <String>[];
    final tc = await pump(t, controls: true, tapped: tapped);
    // 地図の中心にいちばん近い代表点の州(拡大しても画面内に残る)
    final geo = RegionGeometry(us(), const Planar(), const Size(390, 600));
    final center = geo.paths.values.map((p) => p.getBounds()).reduce((a, b) => a.expandToInclude(b)).center;
    final id = (geo.centroid.keys.toList()
          ..sort((a, b) => (geo.centroid[a]! - center).distance.compareTo((geo.centroid[b]! - center).distance)))
        .first;
    await t.tap(find.byKey(const Key('zoom_in')));
    await t.tap(find.byKey(const Key('zoom_in')));
    expect(tc.value.getMaxScaleOnAxis(), closeTo(4, 1e-9));
    final onScreen = MatrixUtils.transformPoint(tc.value, geo.centroid[id]!);
    final origin = t.getTopLeft(find.byType(RegionMapView));
    await t.tapAt(origin + onScreen);
    expect(tapped, [id]);
  });
}
