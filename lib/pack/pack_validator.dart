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

    err.addAll(_validateGeometryExtras(regions, geo));

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

  /// 州都の位置(capitalPos)と隣接(neighbors)の検証。どちらも任意だが、1つでもあれば全地域に必要。
  static List<String> _validateGeometryExtras(List regions, Map geo) {
    final err = <String>[];
    final polys = <String, List>{
      for (final f in (geo['features'] as List))
        (f['properties'] as Map)['id'] as String: [for (final poly in (f['geometry']['coordinates'] as List)) (poly as List)[0] as List]
    };
    bool inRing(double x, double y, List ring) {
      var inside = false;
      for (var i = 0; i < ring.length - 1; i++) {
        final x1 = (ring[i][0] as num).toDouble(), y1 = (ring[i][1] as num).toDouble();
        final x2 = (ring[i + 1][0] as num).toDouble(), y2 = (ring[i + 1][1] as num).toDouble();
        if ((y1 > y) != (y2 > y) && x < x1 + (y - y1) / (y2 - y1) * (x2 - x1)) inside = !inside;
      }
      return inside;
    }

    final withPos = regions.where((r) => (r as Map)['capitalPos'] != null).length;
    final withNb = regions.where((r) => (r as Map)['neighbors'] != null).length;
    if (withPos != 0 && withPos != regions.length) err.add('capitalPos: 全地域に必要(${regions.length}件中$withPos件)');
    if (withNb != 0 && withNb != regions.length) err.add('neighbors: 全地域に必要(${regions.length}件中$withNb件)');
    final ids = {for (final r in regions) (r as Map)['id'] as String};
    final nb = <String, Set<String>>{};
    for (final r in regions) {
      final id = (r as Map)['id'] as String;
      final cp = r['capitalPos'];
      if (cp != null) {
        final x = cp is Map ? cp['x'] : null, y = cp is Map ? cp['y'] : null;
        if (x is! num || y is! num) {
          err.add('$id: capitalPos は {x, y}');
        } else if (!(polys[id] ?? const []).any((ring) => inRing(x.toDouble(), y.toDouble(), ring as List))) {
          err.add('$id: 州都の位置が州の形の外');
        }
      }
      final n = r['neighbors'];
      if (n != null) {
        final list = (n is List ? n : const []).map((e) => e.toString()).toList();
        if (list.toSet().length != list.length) err.add('$id: neighbors に重複');
        for (final o in list) {
          if (o == id) err.add('$id: neighbors に自分自身');
          if (!ids.contains(o)) err.add('$id: neighbors の未知の地域 $o');
        }
        nb[id] = list.toSet();
      }
    }
    nb.forEach((a, set) {
      for (final b in set) {
        if (nb.containsKey(b) && !nb[b]!.contains(a)) err.add('隣接が非対称: $a→$b だけ');
      }
    });
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
        if (!CountryProfile.baseEnemyKinds.contains(k)) err.add('profile.json: enemyMix の未知の敵 $k（新しい種類は enemyMixV3 に書く）');
        if (v is! num || v < 0) {
          err.add('profile.json: enemyMix.$k が負または数値でない');
        } else {
          sum += v;
        }
      });
      if ((sum - 1).abs() > 0.01) err.add('profile.json: enemyMix の合計が1でない($sum)');
    }

    final mix3 = m['enemyMixV3'];
    if (mix3 != null) {
      if (mix3 is! Map) {
        err.add('profile.json: enemyMixV3 がオブジェクトでない');
      } else {
        mix3.forEach((k, v) {
          if (!CountryProfile.newEnemyKinds.contains(k)) err.add('profile.json: enemyMixV3 の未知の敵 $k');
          if (v is! num || v < 0) err.add('profile.json: enemyMixV3.$k が負または数値でない');
        });
      }
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

    final enemies = m['enemies'];
    if (enemies is Map) {
      enemies.forEach((kind, t) {
        if (!CountryProfile.enemyKinds.contains(kind)) err.add('profile.json: enemies の未知の敵 $kind');
        if (t is! Map) return;
        for (final k in ['hp', 'speed', 'baseDamage']) {
          final v = t[k];
          if (v != null && (v is! num || v < 0.5 || v > 2.0)) err.add('profile.json: enemies.$kind.$k は0.5〜2.0');
        }
        final armor = t['armor'];
        if (armor != null && (armor is! int || armor < 0 || armor > 3)) err.add('profile.json: enemies.$kind.armor は0〜3の整数');
        final ab = t['ability'];
        if (ab != null && !CountryProfile.enemyAbilities.contains(ab)) err.add('profile.json: enemies.$kind.ability が不正 $ab');
        final ac = t['action'];
        if (ac != null && !CountryProfile.enemyActions.contains(ac)) err.add('profile.json: enemies.$kind.action が不正 $ac');
      });
    }
    final actions = m['attackActions'];
    if (actions is Map) {
      actions.forEach((fac, t) {
        if (!CountryProfile.facilityTypes.contains(fac)) err.add('profile.json: attackActions の未知の施設 $fac');
        if (t is! Map) return;
        if (!CountryProfile.facilityActions.contains(t['action'])) err.add('profile.json: attackActions.$fac.action が不正 ${t['action']}');
        for (final k in ['damage', 'range', 'cooldown']) {
          final v = t[k];
          if (v != null && (v is! num || v < 0.5 || v > 2.0)) err.add('profile.json: attackActions.$fac.$k は0.5〜2.0');
        }
      });
    }

    // 背景(theme.backdrops): 配色は#RRGGBBを3色以上
    final backdrops = <String>{};
    final theme = m['theme'];
    if (theme is Map && theme['backdrops'] is Map) {
      (theme['backdrops'] as Map).forEach((id, b) {
        backdrops.add('$id');
        final pal = b is Map ? b['palette'] : null;
        final hex = RegExp(r'^#[0-9A-Fa-f]{6}$');
        if (pal is! List || pal.length < 3 || pal.any((c) => c is! String || !hex.hasMatch(c))) {
          err.add('profile.json: theme.backdrops.$id の palette は#RRGGBBを3色以上');
        }
      });
    }
    // 施設・敵の見た目(skin と、英語を含む名前)
    void skins(String key, Set<String> allowed, String label) {
      final v = m[key];
      if (v is! Map) return;
      v.forEach((k, t) {
        if (!allowed.contains(k)) err.add('profile.json: $key の未知の$label $k');
        if (t is! Map || ((t['skin'] ?? '') as Object).toString().isEmpty) {
          err.add('profile.json: $key.$k の skin が空');
        }
        final name = t is Map ? t['name'] : null;
        if (name is! Map || ((name['en'] ?? '') as Object).toString().isEmpty) {
          err.add('profile.json: $key.$k の name に英語がない');
        }
      });
    }
    skins('facilities', CountryProfile.facilityTypes, '施設');
    skins('enemySkins', CountryProfile.enemyKinds, '敵');

    // 敵の見た目違い: 種類は実在、skin は空でなく重複せず(基本の見た目とも)、英語の名前があり、when の州・地方は実在する
    final variants = m['enemyVariants'];
    if (variants is Map) {
      final used = <String>{
        if (m['enemySkins'] is Map) for (final t in (m['enemySkins'] as Map).values) if (t is Map && t['skin'] is String) t['skin'] as String,
      };
      final groupIds = m['groups'] is Map ? (m['groups'] as Map).keys.map((k) => '$k').toSet() : <String>{};
      variants.forEach((kind, list) {
        if (!CountryProfile.enemyKinds.contains(kind)) err.add('profile.json: enemyVariants の未知の敵 $kind');
        if (list is! List) {
          err.add('profile.json: enemyVariants.$kind が配列でない');
          return;
        }
        for (final v in list) {
          if (v is! Map) {
            err.add('profile.json: enemyVariants.$kind に、オブジェクトでない要素がある');
            continue;
          }
          final skin = '${v['skin'] ?? ''}';
          if (skin.isEmpty) {
            err.add('profile.json: enemyVariants.$kind の skin が空');
          } else if (!used.add(skin)) {
            err.add('profile.json: enemyVariants の skin $skin が重複');
          }
          final name = v['name'];
          if (name is! Map || '${name['en'] ?? ''}'.isEmpty) err.add('profile.json: enemyVariants.$kind.$skin の name に英語がない');
          final when = v['when'];
          if (when is Map) {
            for (final r in (when['regions'] as List? ?? const [])) {
              if (!regionIds.contains(r)) err.add('profile.json: enemyVariants.$kind.$skin の未知の州 $r');
            }
            for (final g in (when['groups'] as List? ?? const [])) {
              if (!groupIds.contains(g)) err.add('profile.json: enemyVariants.$kind.$skin の未知の地方 $g');
            }
          }
        }
      });
    }

    // 地方決戦の地方: 州は実在し、中心は地方の中に含まれ、地方どうしで重ならない
    final groups = m['groups'];
    if (groups is Map) {
      final seen = <String, String>{};
      groups.forEach((gid, g) {
        if (g is! Map) {
          err.add('profile.json: groups.$gid がオブジェクトでない');
          return;
        }
        final members = g['regions'];
        if (members is! List || members.length < 2) {
          err.add('profile.json: groups.$gid の regions は2つ以上');
          return;
        }
        for (final r in members) {
          if (!regionIds.contains(r)) err.add('profile.json: groups.$gid の未知の地域 $r');
          if (seen.containsKey(r)) err.add('profile.json: $r が groups.${seen[r]} と groups.$gid の両方にある');
          seen[r as String] = '$gid';
        }
        if (!members.contains(g['center'])) err.add('profile.json: groups.$gid の center が regions にない');
        final name = g['name'];
        if (name is! Map || ((name['en'] ?? '') as Object).toString().isEmpty) err.add('profile.json: groups.$gid の name に英語がない');
      });
    }

    // エクストラ: 題材（伝説・伝記・歴史）、舞台、季節の巡り、事実の注記が必須
    final extras = m['extras'];
    if (extras is List) {
      final seen = <String>{};
      for (final e in extras) {
        if (e is! Map) {
          err.add('profile.json: extras の要素がオブジェクトでない');
          continue;
        }
        final id = '${e['id']}';
        if (!seen.add(id)) err.add('profile.json: extras の id が重複 $id');
        if (!ExtraStage.bases.contains(e['basis'])) err.add('profile.json: extras.$id の basis は ${ExtraStage.bases.join('/')}');
        final regs = e['regions'];
        if (regs is! List || regs.isEmpty) {
          err.add('profile.json: extras.$id の regions が空');
        } else {
          for (final r in regs) {
            if (!regionIds.contains(r)) err.add('profile.json: extras.$id の未知の地域 $r');
          }
          if (!regs.contains(e['center'])) err.add('profile.json: extras.$id の center が regions にない');
        }
        final ss = e['seasons'];
        if (ss is! List || ss.isEmpty || ss.any((x) => !ExtraStage.seasonNames.contains(x))) err.add('profile.json: extras.$id の seasons が不正');
        if (!CountryProfile.weatherEvents.contains(e['weatherEvent'])) err.add('profile.json: extras.$id の weatherEvent が不正');
        if (!ExtraStage.bossSkills.contains(e['bossSkill'])) err.add('profile.json: extras.$id の bossSkill が不正');
        final w = e['waves'];
        if (w is! int || w < 8 || w > 10) err.add('profile.json: extras.$id の waves は8〜10');
        for (final k in ['title', 'summary', 'fact', 'bossName']) {
          final v = e[k];
          if (v is! Map || ((v['en'] ?? '') as Object).toString().isEmpty) err.add('profile.json: extras.$id の $k に英語がない');
        }
        final bd = e['backdrop'];
        if (bd != null && !backdrops.contains(bd)) err.add('profile.json: extras.$id の backdrop $bd が theme.backdrops にない');
      }
    }

    final regs = m['regions'];
    if (regs is Map) {
      regs.forEach((id, t) {
        if (!regionIds.contains(id)) err.add('profile.json: 未知の地域 $id');
        if (t is! Map) return;
        final terrain = t['terrain'];
        if (terrain != null && !CountryProfile.terrains.contains(terrain)) {
          err.add('profile.json: $id の terrain が不正 $terrain');
        }
        final we = t['weatherEvent'];
        if (we != null && !CountryProfile.weatherEvents.contains(we)) err.add('profile.json: $id の weatherEvent が不正 $we');
        final bd = t['backdrop'];
        if (bd != null && !backdrops.contains(bd)) err.add('profile.json: $id の backdrop $bd が theme.backdrops にない');
        final ex = t['exclusiveFacility'];
        if (ex != null && (ex is! String || ex.isEmpty)) err.add('profile.json: $id の exclusiveFacility が空');
        final bias = t['enemyBias'];
        if (bias is Map) {
          bias.forEach((k, v) {
            if (!CountryProfile.enemyKinds.contains(k)) err.add('profile.json: $id の enemyBias の未知の敵 $k');
            if (v is! num || v < 0.5 || v > 2.0) err.add('profile.json: $id の enemyBias.$k は0.5〜2.0');
          });
        }
        final fb = t['facilityBonus'];
        if (fb is Map) {
          fb.forEach((k, v) {
            if (!CountryProfile.facilityTypes.contains(k)) err.add('profile.json: $id の facilityBonus の未知の施設 $k');
            if (v is! num || v < 1.0 || v > 2.0) err.add('profile.json: $id の facilityBonus.$k は1.0〜2.0');
          });
        }
      });
    }
    return err;
  }

  static bool _same(dynamic a, dynamic b) => a[0] == b[0] && a[1] == b[1];
}
