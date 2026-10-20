import 'dart:ui';
import '../pack/region_pack.dart';
import 'projection.dart';

/// 投影・フィット・タップ判定だけを担う描画非依存の幾何。Widgetなしでテストできる。
class RegionGeometry {
  final Map<String, Path> paths = {};
  final Map<String, double> area = {};
  final Map<String, Offset> centroid = {};
  RegionGeometry(RegionPack pack, MapProjection proj, Size size) {
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
    // 縦に合わせて拡大した地図(ドイツなど縦長)は、左右の余りを半分ずつにして、画面の真ん中に置く。
    final offX = ((size.width - 2 * pad - (maxX - minX) * s) / 2).clamp(0, double.infinity);
    Offset tf(Offset o) => Offset(pad + offX + (o.dx - minX) * s, pad + (o.dy - minY) * s);
    raw.forEach((id, rings) {
      final path = Path(); var total = 0.0;
      final anchors = <Offset>[]; var bestArea = -1.0; Offset best = Offset.zero;
      for (final ring in rings) {
        final pts = ring.map(tf).toList();
        path.addPolygon(pts, true);
        final a = _ringArea(pts);
        total += a;
        final anchor = _interiorPoint(pts);
        anchors.add(anchor);
        if (a > bestArea) { bestArea = a; best = anchor; }
      }
      paths[id] = path; area[id] = total; centroid[id] = best; this.anchors[id] = anchors;
      _rings[id] = [for (final ring in rings) ring.map(tf).toList()];
    });
    // 飛び地を囲む地域(例: ブランデンブルクとベルリン)は、代表点が内側の小地域に入りうる。
    // その場合は走査線上で「自分自身に当たる点」を探し直す。
    for (final id in paths.keys) {
      if (hit(centroid[id]!, 0) == id) continue;
      final found = _findOwnPoint(id);
      if (found != null) centroid[id] = found;
    }
  }

  final Map<String, List<List<Offset>>> _rings = {};

  Offset? _findOwnPoint(String id) {
    final b = paths[id]!.getBounds();
    for (var k = 1; k < 40; k++) {
      final y = b.top + b.height * k / 40;
      final xs = <double>[];
      for (final pts in _rings[id]!) {
        for (var i = 0; i < pts.length - 1; i++) {
          final p = pts[i], q = pts[i + 1];
          if ((p.dy > y) != (q.dy > y)) xs.add(p.dx + (y - p.dy) / (q.dy - p.dy) * (q.dx - p.dx));
        }
      }
      xs.sort();
      for (var i = 0; i + 1 < xs.length; i += 2) {
        final c = Offset((xs[i] + xs[i + 1]) / 2, y);
        if (hit(c, 0) == id) return c;
      }
    }
    return null;
  }

  /// 各ポリゴンの内部代表点。重心フォールバック(極小地域のタップ補助)に使う。
  final Map<String, List<Offset>> anchors = {};

  static double _ringArea(List<Offset> pts) {
    var sum = 0.0;
    for (var i = 0; i < pts.length - 1; i++) {
      sum += pts[i].dx * pts[i + 1].dy - pts[i + 1].dx * pts[i].dy;
    }
    return sum.abs() / 2;
  }

  /// 面積重心。凹形・飛び地で外に出る場合は、重心の高さで水平に走査し最も長い内側区間の中点を返す。
  static Offset _interiorPoint(List<Offset> pts) {
    var a2 = 0.0, cx = 0.0, cy = 0.0;
    for (var i = 0; i < pts.length - 1; i++) {
      final c = pts[i].dx * pts[i + 1].dy - pts[i + 1].dx * pts[i].dy;
      a2 += c; cx += (pts[i].dx + pts[i + 1].dx) * c; cy += (pts[i].dy + pts[i + 1].dy) * c;
    }
    if (a2.abs() < 1e-9) return pts.first;
    final g = Offset(cx / (3 * a2), cy / (3 * a2));
    if (_inside(pts, g)) return g;
    final xs = <double>[];
    for (var i = 0; i < pts.length - 1; i++) {
      final p = pts[i], q = pts[i + 1];
      if ((p.dy > g.dy) != (q.dy > g.dy)) {
        xs.add(p.dx + (g.dy - p.dy) / (q.dy - p.dy) * (q.dx - p.dx));
      }
    }
    xs.sort();
    var bestW = -1.0; var bx = pts.first.dx;
    for (var i = 0; i + 1 < xs.length; i += 2) {
      if (xs[i + 1] - xs[i] > bestW) { bestW = xs[i + 1] - xs[i]; bx = (xs[i] + xs[i + 1]) / 2; }
    }
    return Offset(bx, g.dy);
  }

  static bool _inside(List<Offset> pts, Offset q) {
    var in_ = false;
    for (var i = 0, j = pts.length - 1; i < pts.length; j = i++) {
      final p = pts[i], r = pts[j];
      if ((p.dy > q.dy) != (r.dy > q.dy) &&
          q.dx < (r.dx - p.dx) * (q.dy - p.dy) / (r.dy - p.dy) + p.dx) {
        in_ = !in_;
      }
    }
    return in_;
  }

  /// 1) 点を含む地域のうち最小面積 2) なければ半径内で最も近い重心
  String? hit(Offset p, double radius) {
    String? best;
    paths.forEach((id, path) {
      if (path.contains(p) && (best == null || area[id]! < area[best]!)) best = id;
    });
    if (best != null) return best;
    double bd = radius;
    anchors.forEach((id, list) {
      for (final c in list) {
        final d = (c - p).distance;
        if (d <= bd) { bd = d; best = id; }
      }
    });
    return best;
  }
}
