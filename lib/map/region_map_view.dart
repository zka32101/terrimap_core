import 'package:flutter/material.dart';
import '../pack/region_pack.dart';
import 'projection.dart';

typedef RegionColor = Color Function(String regionId);

/// タイル不要・オフラインの自前描画マップ。タップ判定は Path.contains。
/// 重なり/極小地域は「面積の小さい方を優先」し、最小タップ半径で補助する。
class RegionMapView extends StatefulWidget {
  final RegionPack pack;
  final RegionColor colorOf;
  final ValueChanged<String>? onTap;
  final double minTapRadius; // 論理px
  const RegionMapView({
    super.key, required this.pack, required this.colorOf,
    this.onTap, this.minTapRadius = 18,
  });
  @override
  State<RegionMapView> createState() => _State();
}

class _State extends State<RegionMapView> {
  final _tc = TransformationController();
  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final MapProjection proj = widget.pack.projectionType == 'planar'
        ? const Planar()
        : EquirectCos.fromRefLat(widget.pack.refLat);
    return LayoutBuilder(builder: (_, c) {
      final geo = _Geo(widget.pack, proj, c.biggest);
      return InteractiveViewer(
        transformationController: _tc, maxScale: 12, minScale: 1,
        child: GestureDetector(
          onTapUp: (d) {
            final scale = _tc.value.getMaxScaleOnAxis();
            final id = geo.hit(d.localPosition, widget.minTapRadius / scale);
            if (id != null) widget.onTap?.call(id);
          },
          child: CustomPaint(size: c.biggest, painter: _Painter(geo, widget.colorOf)),
        ),
      );
    });
  }
}

class _Geo {
  final Map<String, Path> paths = {};
  final Map<String, double> area = {};
  final Map<String, Offset> centroid = {};
  _Geo(RegionPack pack, MapProjection proj, Size size) {
    var minX = double.infinity, minY = double.infinity, maxX = -double.infinity, maxY = -double.infinity;
    final raw = <String, List<List<Offset>>>{};
    for (final r in pack.regions) {
      raw[r.id] = [for (final poly in r.polygons) [for (final p in poly) proj.project(p[0], p[1])]];
      for (final ring in raw[r.id]!) { for (final o in ring) {
        if (o.dx < minX) minX = o.dx; if (o.dx > maxX) maxX = o.dx;
        if (o.dy < minY) minY = o.dy; if (o.dy > maxY) maxY = o.dy;
      } }
    }
    const pad = 8.0;
    final s = ((size.width - 2 * pad) / (maxX - minX)).clamp(0, double.infinity) <
            ((size.height - 2 * pad) / (maxY - minY))
        ? (size.width - 2 * pad) / (maxX - minX)
        : (size.height - 2 * pad) / (maxY - minY);
    Offset tf(Offset o) => Offset(pad + (o.dx - minX) * s, pad + (o.dy - minY) * s);
    raw.forEach((id, rings) {
      final path = Path(); var a = 0.0; var cx = 0.0, cy = 0.0, n = 0;
      for (final ring in rings) {
        final pts = ring.map(tf).toList();
        path.addPolygon(pts, true);
        var sum = 0.0;
        for (var i = 0; i < pts.length - 1; i++) {
          sum += pts[i].dx * pts[i + 1].dy - pts[i + 1].dx * pts[i].dy;
        }
        a += sum.abs() / 2;
        for (final p in pts) { cx += p.dx; cy += p.dy; n++; }
      }
      paths[id] = path; area[id] = a; centroid[id] = Offset(cx / n, cy / n);
    });
  }

  /// 1) 点を含む地域のうち最小面積 2) なければ半径内で最も近い重心
  String? hit(Offset p, double radius) {
    String? best;
    paths.forEach((id, path) {
      if (path.contains(p) && (best == null || area[id]! < area[best]!)) best = id;
    });
    if (best != null) return best;
    double bd = radius;
    centroid.forEach((id, c) {
      final d = (c - p).distance;
      if (d <= bd) { bd = d; best = id; }
    });
    return best;
  }
}

class _Painter extends CustomPainter {
  final _Geo geo; final RegionColor colorOf;
  _Painter(this.geo, this.colorOf);
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..style = PaintingStyle.fill;
    final line = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.6..color = const Color(0xFF455A64);
    // 大きい地域から先に描く(小さい地域が下に隠れないように)
    final order = geo.paths.keys.toList()..sort((a, b) => geo.area[b]!.compareTo(geo.area[a]!));
    for (final id in order) {
      final path = geo.paths[id]!;
      canvas.drawPath(path, fill..color = colorOf(id));
      canvas.drawPath(path, line);
    }
  }
  @override
  bool shouldRepaint(_Painter o) => true;
}
