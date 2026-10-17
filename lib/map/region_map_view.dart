import 'package:flutter/material.dart';
import '../pack/region_pack.dart';
import 'projection.dart';
import 'region_geometry.dart';

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
      final geo = RegionGeometry(widget.pack, proj, c.biggest);
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

class _Painter extends CustomPainter {
  final RegionGeometry geo; final RegionColor colorOf;
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
