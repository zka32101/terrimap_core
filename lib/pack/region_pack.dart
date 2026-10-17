import 'dart:convert';

import 'country_profile.dart';

class Region {
  final String id;
  final String? capitalId;
  final List<List<List<double>>> polygons; // [ポリゴン][点][lng,lat] 外周のみ
  /// 州都の位置 [x, y](polygons と同じ座標系)。パックにない場合は null。州の形の内側にあることを検証で保証する。
  final List<double>? capitalPos;
  /// 隣り合う地域の id(昇順)。ポリゴンの共有する境界から求めたもの(湖の上の境界も含む)。対称。
  final List<String> neighbors;
  const Region(this.id, this.capitalId, this.polygons, {this.capitalPos, this.neighbors = const []});
}

class RegionPack {
  final String packId, country, regionKind, attribution;
  final List<String> languages;
  final String projectionType; // equirect_cos | planar
  final double refLat;
  final List<Region> regions;
  final Map<String, Map<String, Map<String, String>>> strings; // lang→区分→id→文字列
  /// 国ごとの特性・戦い方(任意。profile.json がない packは null)。
  final CountryProfile? profile;
  const RegionPack(this.packId, this.country, this.regionKind, this.attribution,
      this.languages, this.regions, this.strings,
      {this.projectionType = 'equirect_cos', this.refLat = 36.0, this.profile});

  /// 文字列(JSON)からpackを組み立てる。ファイル読込は呼び出し側(rootBundle等)。
  factory RegionPack.parse({
    required String packJson,
    required String regionsJson,
    required String geoJson,
    required Map<String, String> stringsJsonByLang,
    String? profileJson,
  }) {
    final p = jsonDecode(packJson) as Map<String, dynamic>;
    final meta = {for (final r in (jsonDecode(regionsJson)['regions'] as List)) r['id'] as String: r};
    final regions = <Region>[];
    for (final f in (jsonDecode(geoJson)['features'] as List)) {
      final id = f['properties']['id'] as String;
      final polys = <List<List<double>>>[
        for (final poly in (f['geometry']['coordinates'] as List))
          [for (final pt in (poly[0] as List)) [(pt[0] as num).toDouble(), (pt[1] as num).toDouble()]]
      ];
      final m = meta[id];
      final cp = m?['capitalPos'] as Map?;
      regions.add(Region(id, m?['capitalId'] as String?, polys,
          capitalPos: cp == null ? null : [(cp['x'] as num).toDouble(), (cp['y'] as num).toDouble()],
          neighbors: [for (final n in (m?['neighbors'] as List? ?? const [])) n as String]));
    }
    final strings = {
      for (final e in stringsJsonByLang.entries)
        e.key: (jsonDecode(e.value) as Map<String, dynamic>).map((k, v) =>
            MapEntry(k, (v as Map<String, dynamic>).map((a, b) => MapEntry(a, b as String))))
    };
    return RegionPack(p['packId'], p['country'], p['regionKind'], p['attribution'],
        List<String>.from(p['languages']), regions, strings,
        projectionType: p['projection']['type'] as String,
        refLat: ((p['projection']['refLat'] ?? 36.0) as num).toDouble(),
        profile: profileJson == null ? null : CountryProfile.parse(profileJson));
  }
}
