import 'package:flutter/material.dart';
import '../pack/region_pack.dart';
import 'projection.dart';

/// 形当て用: 1地域だけの輪郭を枠いっぱいに描く(周囲の地域は描かない)。
class RegionSilhouette extends StatelessWidget {
  final RegionPack pack;
  final String regionId;
  final Color color;
  const RegionSilhouette({super.key, required this.pack, required this.regionId, this.color = const Color(0xFF37474F)});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _SilhouettePainter(pack, regionId, color),
        child: const SizedBox.expand(),
      );
}

class _SilhouettePainter extends CustomPainter {
  final RegionPack pack; final String id; final Color color;
  _SilhouettePainter(this.pack, this.id, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final region = pack.regions.firstWhere((r) => r.id == id);
    final MapProjection proj = pack.projectionType == 'planar'
        ? const Planar()
        : EquirectCos.fromRefLat(pack.refLat);
    final rings = [for (final poly in region.polygons) [for (final p in poly) proj.project(p[0], p[1])]];
    var minX = double.infinity, minY = double.infinity, maxX = -double.infinity, maxY = -double.infinity;
    for (final ring in rings) {
      for (final o in ring) {
        if (o.dx < minX) minX = o.dx;
        if (o.dx > maxX) maxX = o.dx;
        if (o.dy < minY) minY = o.dy;
        if (o.dy > maxY) maxY = o.dy;
      }
    }
    const pad = 8.0;
    final w = maxX - minX, h = maxY - minY;
    final s = ((size.width - 2 * pad) / w) < ((size.height - 2 * pad) / h)
        ? (size.width - 2 * pad) / w
        : (size.height - 2 * pad) / h;
    final ox = (size.width - w * s) / 2, oy = (size.height - h * s) / 2;
    final path = Path();
    for (final ring in rings) {
      path.addPolygon([for (final o in ring) Offset(ox + (o.dx - minX) * s, oy + (o.dy - minY) * s)], true);
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SilhouettePainter o) => o.id != id || o.color != color || o.pack != pack;
}
