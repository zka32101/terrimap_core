import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/map/projection.dart';
import 'package:terrimap_core/map/region_geometry.dart';
import 'package:terrimap_core/pack/region_pack.dart';

RegionPack load(String id) {
  String r(String f) => File('packs/$id/$f').readAsStringSync();
  return RegionPack.parse(packJson: r('pack.json'), regionsJson: r('regions.json'), geoJson: r('geo.geojson'), stringsJsonByLang: {'en': r('strings/en.json')});
}

void main() {
  Rect bounds(RegionGeometry g) => g.paths.values.map((p) => p.getBounds()).reduce((a, b) => a.expandToInclude(b));

  test('縦に合わせて拡大した地図(ドイツ)は、左右の余りが同じで、画面の真ん中に置かれる', () {
    final de = load('de');
    final proj = de.projectionType == 'planar' ? const Planar() : EquirectCos.fromRefLat(de.refLat);
    for (final size in const [Size(400, 400), Size(500, 300), Size(360, 640)]) {
      final b = bounds(RegionGeometry(de, proj, size));
      final left = b.left, right = size.width - b.right;
      if (b.height > size.height - 17) {
        // 縦いっぱい(横に余りがある)ときは、左右が等しい
        expect((left - right).abs(), lessThan(0.5), reason: '$size');
      } else {
        expect(left, closeTo(8, 0.5), reason: '$size'); // 横いっぱいのときは、これまでどおり
      }
    }
  });

  test('横に合わせて拡大した地図は、これまでどおり左端から(横の位置は変わらない)', () {
    final de = load('de');
    final proj = de.projectionType == 'planar' ? const Planar() : EquirectCos.fromRefLat(de.refLat);
    final b = bounds(RegionGeometry(de, proj, const Size(200, 2000)));
    expect(b.left, closeTo(8, 0.5));
    expect(b.right, closeTo(192, 0.5));
  });
}
