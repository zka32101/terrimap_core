import 'dart:math' as math;
import 'dart:ui';

abstract class MapProjection { Offset project(double x, double y); }

/// 焼き込み済みの平面座標(Albers+インセット等)。そのまま使う。
class Planar implements MapProjection {
  const Planar();
  @override
  Offset project(double x, double y) => Offset(x, y);
}

/// 等距円筒(cos補正)。x=(lng-lng0)*cos(refLat), y=-lat。
class EquirectCos implements MapProjection {
  final double cosRef;
  const EquirectCos(this.cosRef);
  factory EquirectCos.fromRefLat(double refLatDeg) =>
      EquirectCos(math.cos(refLatDeg * math.pi / 180));
  @override
  Offset project(double lng, double lat) => Offset(lng * cosRef, -lat);
}
