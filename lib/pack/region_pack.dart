import 'dart:convert';

class Region {
  final String id;
  final String? capitalId;
  final List<List<List<double>>> polygons; // [ポリゴン][点][lng,lat] 外周のみ
  const Region(this.id, this.capitalId, this.polygons);
}

class RegionPack {
  final String packId, country, regionKind, attribution;
  final List<String> languages;
  final String projectionType; // equirect_cos | planar
  final double refLat;
  final List<Region> regions;
  final Map<String, Map<String, Map<String, String>>> strings; // lang→区分→id→文字列
  const RegionPack(this.packId, this.country, this.regionKind, this.attribution,
      this.languages, this.regions, this.strings,
      {this.projectionType = 'equirect_cos', this.refLat = 36.0});

  /// 文字列(JSON)からpackを組み立てる。ファイル読込は呼び出し側(rootBundle等)。
  factory RegionPack.parse({
    required String packJson,
    required String regionsJson,
    required String geoJson,
    required Map<String, String> stringsJsonByLang,
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
      regions.add(Region(id, meta[id]?['capitalId'] as String?, polys));
    }
    final strings = {
      for (final e in stringsJsonByLang.entries)
        e.key: (jsonDecode(e.value) as Map<String, dynamic>).map((k, v) =>
            MapEntry(k, (v as Map<String, dynamic>).map((a, b) => MapEntry(a, b as String))))
    };
    return RegionPack(p['packId'], p['country'], p['regionKind'], p['attribution'],
        List<String>.from(p['languages']), regions, strings,
        projectionType: p['projection']['type'] as String,
        refLat: ((p['projection']['refLat'] ?? 36.0) as num).toDouble());
  }
}
