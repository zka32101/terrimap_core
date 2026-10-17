import 'dart:ui' show Size;
import '../map/projection.dart';
import '../map/region_geometry.dart';
import '../pack/region_pack.dart';

/// 形当ての難易度。描画面積の大きい地域ほど形が覚えやすい前提で、面積順に3分割する。
enum Difficulty { easy, normal, hard }

/// 描画面積の降順に並べた地域id（同面積はid順）。パックの投影で測る。
/// 注意: 米国のアラスカ・ハワイは地図上のインセット（縮小表示）の面積で測る。
List<String> regionsByArea(RegionPack pack) {
  final MapProjection proj = pack.projectionType == 'planar' ? const Planar() : EquirectCos.fromRefLat(pack.refLat);
  final area = RegionGeometry(pack, proj, const Size(1000, 1000)).area;
  final ids = pack.regions.map((r) => r.id).toList();
  ids.sort((a, b) {
    final c = (area[b] ?? 0).compareTo(area[a] ?? 0);
    return c != 0 ? c : a.compareTo(b);
  });
  return ids;
}

/// 難易度ごとの出題対象。`QuizEngine.generate(pool: ...)` にそのまま渡せる。
/// 大きい地域=easy / 中間=normal / 小さい地域=hard の3分割（重ならず、合わせて全地域）。
Set<String> regionsForDifficulty(RegionPack pack, Difficulty d) {
  final ids = regionsByArea(pack);
  final n = ids.length;
  final a = (n / 3).round(), b = (2 * n / 3).round();
  return switch (d) {
    Difficulty.easy => ids.sublist(0, a).toSet(),
    Difficulty.normal => ids.sublist(a, b).toSet(),
    Difficulty.hard => ids.sublist(b).toSet(),
  };
}
