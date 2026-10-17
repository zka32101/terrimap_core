import 'dart:convert';

import 'country_profile.dart';

/// packの整合性検査(tools/validate_pack.py のDart版)。エラー文字列の一覧を返し、空なら合格。
/// ファイル読込は呼び出し側。アプリ起動時やテストで同じ規則を使えるようにする。
class PackValidator {
  static const maxVerticesPerRegion = 20000;

  static List<String> validate({
    required String packJson,
    required String regionsJson,
    required String geoJson,
    required Map<String, String> stringsJsonByLang,
    String? profileJson, // 任意。あれば国の特性・戦い方も検査する
  }) {
    final err = <String>[];
    Map<String, dynamic> obj(String name, String src) {
      try {
        return jsonDecode(src) as Map<String, dynamic>;
      } catch (e) {
        err.add('$name: 読込失敗 $e');
        return {};
      }
    }

    final pack = obj('pack.json', packJson);
    final reg = obj('regions.json', regionsJson);
    final geo = obj('geo.geojson', geoJson);

    for (final k in ['packId', 'version', 'country', 'regionKind', 'languages', 'projection', 'attribution', 'license']) {
      final v = pack[k];
      if (v == null || (v is String && v.isEmpty) || (v is List && v.isEmpty) || (v is Map && v.isEmpty)) {
        err.add('pack.json: $k が空');
      }
    }
    final license = pack['license'];
    if (license is! Map || (license['name'] ?? '').toString().isEmpty) err.add('license.name が空');

    final regions = (reg['regions'] as List?) ?? const [];
    final ids = [for (final r in regions) (r as Map)['id'] as String];
    if (ids.length != ids.toSet().length) err.add('regions: id重複');

    final features = (geo['features'] as List?) ?? const [];
    final gids = [for (final f in features) (f['properties'] as Map)['id'] as String? ?? ''];
    final idSet = ids.toSet(), gSet = gids.toSet();
    if (idSet.length != gSet.length || !idSet.containsAll(gSet)) {
      err.add('id不一致 regionsのみ=${idSet.difference(gSet).toList()..sort()} '
          'geoのみ=${gSet.difference(idSet).toList()..sort()}');
    }
    if (gids.length != gSet.length) err.add('geo: id重複');

    final planar = ((pack['projection'] as Map?)?['type']) == 'planar';
    for (final f in features) {
      final id = (f['properties'] as Map)['id'];
      var n = 0;
      for (final poly in (f['geometry']['coordinates'] as List)) {
        for (final ring in (poly as List)) {
          final r = ring as List;
          n += r.length;
          if (r.length < 4 || !_same(r.first, r.last)) err.add('$id: リング不正');
          if (!planar && r.any((pt) => (pt[0] as num) < -180 || (pt[0] as num) > 180 || (pt[1] as num) < -90 || (pt[1] as num) > 90)) {
            err.add('$id: 座標範囲外');
          }
        }
      }
      if (n > maxVerticesPerRegion) err.add('$id: 頂点数超過 $n');
    }

    final caps = {for (final r in regions) if ((r as Map)['capitalId'] != null) r['capitalId'] as String};
    for (final lang in (pack['languages'] as List?) ?? const []) {
      final src = stringsJsonByLang[lang];
      if (src == null) {
        err.add('strings/$lang.json: なし');
        continue;
      }
      final s = obj('strings/$lang.json', src);
      final names = ((s['regions'] as Map?) ?? const {}).keys.toSet();
      final miss = idSet.difference(names).toList()..sort();
      if (miss.isNotEmpty) err.add('$lang: 地域名の欠落 $miss');
      final cn = ((s['capitals'] as Map?) ?? const {}).keys.toSet();
      final cm = caps.difference(cn);
      if (cm.isNotEmpty) err.add('$lang: 首都名の欠落 ${cm.length}件');
    }
    if (profileJson != null) err.addAll(_validateProfile(profileJson, idSet));
    return err;
  }

  static List<String> _validateProfile(String src, Set<String> regionIds) {
    final err = <String>[];
    Map<String, dynamic> m;
    try {
      m = jsonDecode(src) as Map<String, dynamic>;
    } catch (e) {
      return ['profile.json: 読込失敗 $e'];
    }
    if (((m['style'] ?? '') as Object).toString().isEmpty) err.add('profile.json: style が空');

    final mix = m['enemyMix'];
    if (mix is! Map || mix.isEmpty) {
      err.add('profile.json: enemyMix が空');
    } else {
      var sum = 0.0;
      mix.forEach((k, v) {
        if (!CountryProfile.enemyKinds.contains(k)) err.add('profile.json: enemyMix の未知の敵 $k');
        if (v is! num || v < 0) {
          err.add('profile.json: enemyMix.$k が負または数値でない');
        } else {
          sum += v;
        }
      });
      if ((sum - 1).abs() > 0.01) err.add('profile.json: enemyMix の合計が1でない($sum)');
    }

    final eco = m['economy'];
    if (eco is! Map) {
      err.add('profile.json: economy がない');
    } else {
      for (final k in ['startCoins', 'income', 'facilityCost']) {
        final v = eco[k];
        if (v is! num || v < 0.5 || v > 2.0) err.add('profile.json: economy.$k は0.5〜2.0');
      }
    }
    if (!CountryProfile.pathLengths.contains(m['pathLength'])) {
      err.add('profile.json: pathLength は ${CountryProfile.pathLengths.join('/')}');
    }
    final sig = m['signature'];
    if (sig is! Map || ((sig['id'] ?? '') as Object).toString().isEmpty) err.add('profile.json: signature.id が空');

    final regs = m['regions'];
    if (regs is Map) {
      regs.forEach((id, t) {
        if (!regionIds.contains(id)) err.add('profile.json: 未知の地域 $id');
        if (t is! Map) return;
        final terrain = t['terrain'];
        if (terrain != null && !CountryProfile.terrains.contains(terrain)) {
          err.add('profile.json: $id の terrain が不正 $terrain');
        }
        final fb = t['facilityBonus'];
        if (fb is Map) {
          fb.forEach((k, v) {
            if (v is! num || v < 1.0 || v > 2.0) err.add('profile.json: $id の facilityBonus.$k は1.0〜2.0');
          });
        }
      });
    }
    return err;
  }

  static bool _same(dynamic a, dynamic b) => a[0] == b[0] && a[1] == b[1];
}
