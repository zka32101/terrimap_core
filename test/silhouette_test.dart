import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/map/region_silhouette.dart';
import 'package:terrimap_core/pack/region_pack.dart';

void main() {
  testWidgets('RegionSilhouette: 全州を描画しても例外が出ない', (t) async {
    String r(String f) => File('packs/de/$f').readAsStringSync();
    final pack = RegionPack.parse(packJson: r('pack.json'), regionsJson: r('regions.json'),
        geoJson: r('geo.geojson'), stringsJsonByLang: {'en': r('strings/en.json')});
    for (final region in pack.regions) {
      await t.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 200, height: 200, child: RegionSilhouette(pack: pack, regionId: region.id)),
      ));
      expect(tester_ok(t), isTrue);
    }
  });
}

bool tester_ok(WidgetTester t) => t.takeException() == null;
