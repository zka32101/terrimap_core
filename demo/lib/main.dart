// 地図だけを動かすデモ。Playwright から読めるよう、状態を document.title に出す。
// (Semantics を有効にすると、クリックがアクセシビリティ経由の操作になり、座標つきのタップが届かなくなるため使わない)
//   ?pack=de|us            表示するパック
//   ?probe=US-RI,US-TX     画面上の位置(代表点)を出したい地域
// title の形式: "tapped=<id|none>;scale=<n>;pos=<id>:<x>:<y>,..."(座標はページ座標)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:terrimap_core/map/projection.dart';
import 'package:terrimap_core/map/region_geometry.dart';
import 'package:terrimap_core/map/region_map_view.dart';
import 'package:terrimap_core/pack/region_pack.dart';
import 'package:web/web.dart' as web;

const _statusHeight = 48.0; // 地図の上端のページ座標(固定)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final q = Uri.base.queryParameters;
  final id = q['pack'] ?? 'us';
  final probes =
      (q['probe'] ?? '').split(',').where((e) => e.isNotEmpty).toList();
  Future<String> a(String f) => rootBundle.loadString('packs/$id/$f');
  final pack = RegionPack.parse(
    packJson: await a('pack.json'),
    regionsJson: await a('regions.json'),
    geoJson: await a('geo.geojson'),
    stringsJsonByLang: {'en': await a('strings/en.json')},
  );
  runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Demo(pack: pack, probes: probes)));
}

class Demo extends StatefulWidget {
  final RegionPack pack;
  final List<String> probes;
  const Demo({super.key, required this.pack, required this.probes});
  @override
  State<Demo> createState() => _DemoState();
}

class _DemoState extends State<Demo> {
  final _tc = TransformationController();
  String _tapped = 'none';

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pack = widget.pack;
    final MapProjection proj = pack.projectionType == 'planar'
        ? const Planar()
        : EquirectCos.fromRefLat(pack.refLat);
    return Scaffold(
      body: Column(children: [
        SizedBox(
          height: _statusHeight,
          child: Center(child: Text('tapped $_tapped')),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final geo = RegionGeometry(pack, proj, c.biggest);
            return Stack(children: [
              Positioned.fill(
                child: RegionMapView(
                  pack: pack,
                  controller: _tc,
                  showZoomControls: true,
                  colorOf: (id) => id == _tapped
                      ? const Color(0xFFFFB300)
                      : const Color(0xFFCFD8DC),
                  onTap: (id) => setState(() => _tapped = id),
                ),
              ),
              // 状態の読み出し用(画面には出さない): 変換が変わるたびに title を更新する
              Positioned(
                left: 0,
                top: 0,
                child: ListenableBuilder(
                  listenable: _tc,
                  builder: (context, _) {
                    final m = _tc.value;
                    final pos = [
                      for (final p in widget.probes)
                        if (geo.centroid[p] != null)
                          () {
                            final o =
                                MatrixUtils.transformPoint(m, geo.centroid[p]!);
                            return '$p:${o.dx.toStringAsFixed(1)}:${(o.dy + _statusHeight).toStringAsFixed(1)}';
                          }(),
                    ];
                    web.document.title =
                        'tapped=$_tapped;scale=${m.getMaxScaleOnAxis().toStringAsFixed(3)};pos=${pos.join(',')}';
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ]);
          }),
        ),
      ]),
    );
  }
}
