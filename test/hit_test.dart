import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/map/projection.dart';
import 'package:terrimap_core/map/region_geometry.dart';
import 'package:terrimap_core/pack/region_pack.dart';

RegionPack load(String id) {
  String r(String f) => File('packs/$id/$f').readAsStringSync();
  final langs = (Directory('packs/$id/strings').listSync())
      .map((e) => e.uri.pathSegments.last.replaceAll('.json', ''));
  return RegionPack.parse(
      packJson: r('pack.json'), regionsJson: r('regions.json'), geoJson: r('geo.geojson'),
      stringsJsonByLang: {for (final l in langs) l: r('strings/$l.json')});
}

void main() {
  const size = Size(390, 600); // 一般的なスマホ幅
  for (final id in ['de', 'us']) {
    test('$id: 全地域が重心タップ(ズーム1倍・半径18px)で自分自身に当たる', () {
      final pack = load(id);
      final proj = pack.projectionType == 'planar'
          ? const Planar() as MapProjection
          : EquirectCos.fromRefLat(pack.refLat);
      final geo = RegionGeometry(pack, proj, size);
      final miss = <String, String?>{};
      for (final r in pack.regions) {
        final hit = geo.hit(geo.centroid[r.id]!, 18);
        if (hit != r.id) miss[r.id] = hit;
      }
      expect(miss, isEmpty);
    });
  }
}
