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
  /// 拡大・縮小・元に戻すボタンを右下に出す(ピンチ操作に気づきにくい人・極小地域向け)。
  final bool showZoomControls;
  /// 拡大・移動の状態を外から読む/操作するためのコントローラ(省略時は内部で持つ)。
  final TransformationController? controller;
  const RegionMapView({
    super.key, required this.pack, required this.colorOf,
    this.onTap, this.minTapRadius = 18, this.showZoomControls = false, this.controller,
  });
  @override
  State<RegionMapView> createState() => _State();
}

class _State extends State<RegionMapView> {
  static const _minScale = 1.0, _maxScale = 12.0;
  final _ownTc = TransformationController();
  TransformationController get _tc => widget.controller ?? _ownTc;

  Offset _focus = Offset.zero; // 地図の中身の中心(地図は上寄せで描かれるため、画面中央ではなくこちらを基準に拡大する)

  /// 地図の中心を基準に倍率を[factor]倍する(1〜12倍の範囲に収める)。
  void _zoomBy(double factor) {
    final cur = _tc.value.getMaxScaleOnAxis();
    final next = (cur * factor).clamp(_minScale, _maxScale);
    if (next == cur) return;
    final f = next / cur;
    final c = _focus;
    _tc.value = Matrix4.translationValues(c.dx, c.dy, 0) *
        Matrix4.diagonal3Values(f, f, f) *
        Matrix4.translationValues(-c.dx, -c.dy, 0) *
        _tc.value;
    if (next == _minScale) _tc.value = Matrix4.identity();
  }

  Widget _zoomControls() => Positioned(
        right: 8,
        bottom: 8,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final (key, icon, tip, act) in <(String, IconData, String, VoidCallback)>[
            ('zoom_in', Icons.add, 'Zoom in', () => _zoomBy(2)),
            ('zoom_out', Icons.remove, 'Zoom out', () => _zoomBy(0.5)),
            ('zoom_reset', Icons.fit_screen, 'Reset zoom', () => _tc.value = Matrix4.identity()),
          ])
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Material(
                color: Colors.white.withValues(alpha: 0.9),
                shape: const CircleBorder(side: BorderSide(color: Color(0xFFB0BEC5))),
                child: IconButton(
                  key: Key(key),
                  icon: Icon(icon),
                  tooltip: tip,
                  visualDensity: VisualDensity.compact,
                  onPressed: act,
                ),
              ),
            ),
        ]),
      );

  @override
  void dispose() { _ownTc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final MapProjection proj = widget.pack.projectionType == 'planar'
        ? const Planar()
        : EquirectCos.fromRefLat(widget.pack.refLat);
    return LayoutBuilder(builder: (_, c) {
      final geo = RegionGeometry(widget.pack, proj, c.biggest);
      _focus = geo.paths.values.map((p) => p.getBounds()).reduce((a, b) => a.expandToInclude(b)).center;
      final viewer = InteractiveViewer(
        transformationController: _tc, maxScale: _maxScale, minScale: _minScale,
        child: GestureDetector(
          onTapUp: (d) {
            final scale = _tc.value.getMaxScaleOnAxis();
            final id = geo.hit(d.localPosition, widget.minTapRadius / scale);
            if (id != null) widget.onTap?.call(id);
          },
          child: CustomPaint(size: c.biggest, painter: _Painter(geo, widget.colorOf, _tc)),
        ),
      );
      if (!widget.showZoomControls) return viewer;
      return Stack(children: [Positioned.fill(child: viewer), _zoomControls()]);
    });
  }
}

class _Painter extends CustomPainter {
  final RegionGeometry geo; final RegionColor colorOf; final TransformationController tc;
  _Painter(this.geo, this.colorOf, this.tc) : super(repaint: tc);
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..style = PaintingStyle.fill;
    // 境界線は拡大しても細いまま(拡大率で割る)
    final scale = tc.value.getMaxScaleOnAxis();
    final line = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.6 / scale..color = const Color(0xFF455A64);
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
