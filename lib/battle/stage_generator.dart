import 'dart:math' as math;

import '../pack/country_profile.dart';
import '../pack/region_pack.dart';
import '../quiz/rng.dart';
import 'difficulty.dart';
import 'grid.dart';
import 'stage.dart';

/// 州の形で切り抜いたステージを作る（設計書 §5）。画面に依存しない純粋な計算で、同じ入力は同じ結果。
class StageGenerator {
  final RegionPack pack;
  StageGenerator(this.pack);

  CountryProfile? get _profile => pack.profile;

  // 解像度の基準の一辺（pathLength）。陸地マスが少ない州は上限まで上げる。
  static const _baseSize = {'short': 6, 'medium': 8, 'long': 10};
  static const _minSize = 4, _maxSize = 12, _minLand = 36;
  // 進路の長さ(陸地マスに対する割合)の目安。仮。
  static const _pathFraction = {'short': (0.25, 0.35), 'medium': (0.35, 0.45), 'long': (0.45, 0.55)};
  static const _minSlots = 6;
  static const _dfsBudget = 60000;

  Stage generate(String regionId, Difficulty difficulty, {StageKind kind = StageKind.normal}) {
    if (kind != StageKind.normal) {
      throw UnimplementedError('地方決戦・エクストラは M7 で作る（設計書 §6.9）');
    }
    final region = pack.regions.firstWhere((r) => r.id == regionId, orElse: () => throw ArgumentError('未知の地域: $regionId'));
    final seed = fnv1a('${pack.packId}|$regionId|${difficulty.name}|${kind.name}');
    final rng = Rng(seed);
    final params = difficultyParams[difficulty]!;
    final trait = _profile?.traitOf(regionId);
    final pathLength = _profile?.pathLength ?? 'medium';

    // 1. 州の形（投影後）。盤面にするのは**本土**1つだけ（州都を含むポリゴン。なければ最大のポリゴン）。
    //    小さな島や離れた土地は飾り。例: ハワイは州都（ホノルル）のあるオアフ島を盤面にする。
    final polys = [for (final p in region.polygons) _project(p)];
    final all = polys;
    final areas = [for (final p in polys) _area(p)];
    final maxArea = areas.reduce(math.max);
    final cap = region.capitalPos == null ? null : _projectPt(region.capitalPos![0], region.capitalPos![1]);
    var mainIdx = areas.indexOf(maxArea);
    if (cap != null) {
      for (var i = 0; i < polys.length; i++) {
        if (areas[i] >= maxArea * 0.05 && _inRing(cap[0], cap[1], polys[i])) {
          mainIdx = i;
          break;
        }
      }
    }
    final major = [polys[mainIdx]];
    final bb = _bbox(major);
    final bw = bb[2] - bb[0], bh = bb[3] - bb[1];
    final aspect = bw / bh;

    // 2. 盤面の解像度を決め、州の形で切り抜く（最大の連結成分だけを使う）。
    late _Grid grid;
    for (var size = _baseSize[pathLength] ?? 8; ; size++) {
      grid = _rasterize(major, bb, size, aspect);
      if (grid.land.length >= _minLand || size >= _maxSize) break;
    }
    if (grid.land.length < 12) throw StateError('$regionId: 陸地マスが少なすぎる(${grid.land.length})');

    // 3. 拠点 = 州都にいちばん近い陸地マス。
    final target = cap ?? [(bb[0] + bb[2]) / 2, (bb[1] + bb[3]) / 2];
    final base = _nearestLand(grid, target);

    // 4. 入口 = 隣の州との境界（なければ海・国境）。
    final neighborPolys = {
      for (final n in region.neighbors)
        n: [for (final p in pack.regions.firstWhere((r) => r.id == n).polygons) _project(p)]
    };
    final groups = _entranceGroups(grid, all, neighborPolys, base);
    var chosen = _chooseGroups(groups, params.maxEntrances, rng);
    // 拠点に近すぎる入口は、進路が短すぎて遊べないので外す（ほかに入口があるときだけ）
    final far = [for (final g in chosen) if (g.cells.any((c) => c.manhattan(base) >= _minEntranceDistance)) g];
    if (far.isNotEmpty) chosen = far;
    if (chosen.isEmpty) throw StateError('$regionId: 入口を作れない');

    // 5. 進路。入口ごとに、自分自身と交差しない経路を seed つきで探す。
    final frac = _pathFraction[pathLength] ?? (0.35, 0.45);
    final entrances = <StageEntrance>[];
    final paths = <List<GridPos>>[];
    final used = <GridPos>{};
    for (final g in chosen) {
      final cells = [...g.cells]..sort();
      // 拠点から遠い入口ほど長い進路を取れる。遠い側の4割から選ぶ。
      cells.sort((a, b) => b.manhattan(base) != a.manhattan(base) ? b.manhattan(base).compareTo(a.manhattan(base)) : a.compareTo(b));
      final pool = cells.sublist(0, math.max(1, (cells.length * 0.4).ceil()));
      final start = pool[rng.nextInt(pool.length)];
      final minLen = math.max(start.manhattan(base) + 1, (grid.land.length * frac.$1).round());
      final maxLen = math.max(minLen, (grid.land.length * frac.$2).round());
      final path = _findPath(grid, start, base, minLen, maxLen, used, rng);
      entrances.add(StageEntrance(start, g.neighborId, g.cells.length));
      paths.add(path);
      used.addAll(path.where((c) => c != base));
    }

    // 6. 設置枠 = 進路に隣接する陸地マス（8近傍）。足りなければ、進路に近いマスから足す。
    final onPath = {for (final p in paths) ...p};
    final slotSet = <GridPos>{};
    for (final c in onPath) {
      for (var dc = -1; dc <= 1; dc++) {
        for (var dr = -1; dr <= 1; dr++) {
          final n = GridPos(c.col + dc, c.row + dr);
          if (grid.land.contains(n) && !onPath.contains(n)) slotSet.add(n);
        }
      }
    }
    if (slotSet.length < _minSlots) {
      final rest = [for (final c in grid.land) if (!onPath.contains(c) && !slotSet.contains(c)) c];
      rest.sort((a, b) {
        final da = onPath.map((p) => p.manhattan(a)).reduce(math.min), db = onPath.map((p) => p.manhattan(b)).reduce(math.min);
        return da != db ? da.compareTo(db) : a.compareTo(b);
      });
      slotSet.addAll(rest.take(_minSlots - slotSet.length));
    }
    final slots = slotSet.toList()..sort();

    // 7. ウェーブ。
    final neighborBias = <String, Map<String, double>>{
      for (final e in entrances)
        if (e.neighborId != null) e.neighborId!: _profile?.traitOf(e.neighborId!).enemyBias ?? const {},
    };
    final waves = _waves(params, trait, entrances, neighborBias, seed, rng);

    return Stage(
      id: '$regionId:${difficulty.name}:${kind.name}',
      packId: pack.packId,
      regionId: regionId,
      difficulty: difficulty,
      kind: kind,
      seed: seed,
      cols: grid.cols,
      rows: grid.rows,
      originX: grid.originX,
      originY: grid.originY,
      cellW: grid.cellW,
      cellH: grid.cellH,
      land: grid.land,
      base: base,
      entrances: entrances,
      paths: paths,
      slots: slots,
      waves: waves,
      baseHp: math.max(1, 15 + params.heartBonus),
      season: _season(trait?.weatherEvent, rng),
      terrain: trait?.terrain,
      weatherEvent: trait?.weatherEvent,
      backdrop: trait?.backdrop,
      exclusiveFacility: trait?.exclusiveFacility,
    );
  }

  // ── 投影・形 ────────────────────────────────────────────

  List<double> _projectPt(double x, double y) =>
      pack.projectionType == 'planar' ? [x, y] : [x * math.cos(pack.refLat * math.pi / 180), -y];

  List<List<double>> _project(List<List<double>> ring) => [for (final p in ring) _projectPt(p[0], p[1])];

  static double _area(List<List<double>> r) {
    var s = 0.0;
    for (var i = 0; i < r.length - 1; i++) {
      s += r[i][0] * r[i + 1][1] - r[i + 1][0] * r[i][1];
    }
    return s.abs() / 2;
  }

  static List<double> _bbox(List<List<List<double>>> polys) {
    var x0 = double.infinity, y0 = double.infinity, x1 = -double.infinity, y1 = -double.infinity;
    for (final p in polys) {
      for (final q in p) {
        x0 = math.min(x0, q[0]);
        y0 = math.min(y0, q[1]);
        x1 = math.max(x1, q[0]);
        y1 = math.max(y1, q[1]);
      }
    }
    return [x0, y0, x1, y1];
  }

  static bool _inRing(double x, double y, List<List<double>> ring) {
    var inside = false;
    for (var i = 0; i < ring.length - 1; i++) {
      final a = ring[i], b = ring[i + 1];
      if ((a[1] > y) != (b[1] > y) && x < a[0] + (y - a[1]) / (b[1] - a[1]) * (b[0] - a[0])) inside = !inside;
    }
    return inside;
  }

  static bool _inPolys(double x, double y, List<List<List<double>>> polys) => polys.any((r) => _inRing(x, y, r));

  // ── 盤面 ────────────────────────────────────────────────

  _Grid _rasterize(List<List<List<double>>> major, List<double> bb, int size, double aspect) {
    final cols = (size * math.sqrt(aspect)).round().clamp(_minSize, _maxSize);
    final rows = (size / math.sqrt(aspect)).round().clamp(_minSize, _maxSize);
    final cw = (bb[2] - bb[0]) / cols, ch = (bb[3] - bb[1]) / rows;
    final land = <GridPos>{};
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (_inPolys(bb[0] + (c + 0.5) * cw, bb[1] + (r + 0.5) * ch, major)) land.add(GridPos(c, r));
      }
    }
    // 最大の連結成分（4近傍）だけを使う。同数なら、先に見つかった方（行・列の小さい方）。
    final seen = <GridPos>{};
    var best = <GridPos>{};
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final s = GridPos(c, r);
        if (!land.contains(s) || seen.contains(s)) continue;
        final comp = <GridPos>{s};
        final q = [s];
        while (q.isNotEmpty) {
          final p = q.removeLast();
          for (final n in _n4(p)) {
            if (land.contains(n) && comp.add(n)) q.add(n);
          }
        }
        seen.addAll(comp);
        if (comp.length > best.length) best = comp;
      }
    }
    if (best.isEmpty) return _Grid(cols, rows, bb[0], bb[1], cw, ch, <GridPos>{});
    // 余白の行・列を切り詰める（原点を更新する）
    final minC = best.map((p) => p.col).reduce(math.min), minR = best.map((p) => p.row).reduce(math.min);
    final maxC = best.map((p) => p.col).reduce(math.max), maxR = best.map((p) => p.row).reduce(math.max);
    return _Grid(maxC - minC + 1, maxR - minR + 1, bb[0] + minC * cw, bb[1] + minR * ch, cw, ch,
        {for (final p in best) GridPos(p.col - minC, p.row - minR)});
  }

  static Iterable<GridPos> _n4(GridPos p) =>
      [GridPos(p.col + 1, p.row), GridPos(p.col - 1, p.row), GridPos(p.col, p.row + 1), GridPos(p.col, p.row - 1)];

  GridPos _nearestLand(_Grid g, List<double> pt) {
    GridPos? best;
    var bd = double.infinity;
    for (final c in (g.land.toList()..sort())) {
      final d = math.pow(g.cx(c.col) - pt[0], 2) + math.pow(g.cy(c.row) - pt[1], 2);
      if (d < bd) {
        bd = d.toDouble();
        best = c;
      }
    }
    return best!;
  }

  // ── 入口 ────────────────────────────────────────────────

  /// 陸地マスの外側にある、隣のマスの中心が、どの地域に入るかで、入口の候補を分ける。
  /// 州の外側（隣の州の中）なら、その州。どの州でもなければ、海・国境(null)。州の内側（切り捨てた島など）は入口にしない。
  List<_Group> _entranceGroups(_Grid g, List<List<List<double>>> own, Map<String, List<List<List<double>>>> nb, GridPos base) {
    final by = <String?, Set<GridPos>>{};
    for (final c in g.land) {
      if (c == base) continue;
      for (final n in _n4(c)) {
        if (g.land.contains(n)) continue;
        final x = g.cx(n.col), y = g.cy(n.row);
        if (_inPolys(x, y, own)) continue; // 州の内側（盤面に入れなかった部分）
        String? hit;
        for (final e in (nb.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))) {
          if (_inPolys(x, y, e.value)) {
            hit = e.key;
            break;
          }
        }
        by.putIfAbsent(hit, () => <GridPos>{}).add(c);
      }
    }
    final out = [for (final e in by.entries) _Group(e.key, e.value.toList()..sort())];
    out.sort((a, b) {
      final c = b.cells.length.compareTo(a.cells.length);
      return c != 0 ? c : (a.neighborId ?? '~').compareTo(b.neighborId ?? '~');
    });
    return out;
  }

  /// 使う入口を選ぶ。隣の州の入口を優先し（長い境界ほど選ばれやすい）、隣がなければ海・国境。
  List<_Group> _chooseGroups(List<_Group> groups, int max, Rng rng) {
    final nbG = [for (final g in groups) if (g.neighborId != null) g];
    final seaG = [for (final g in groups) if (g.neighborId == null) g];
    final pool = nbG.isNotEmpty ? [...nbG] : [...seaG];
    final out = <_Group>[];
    while (out.length < max && pool.isNotEmpty) {
      final total = pool.fold<int>(0, (s, g) => s + g.cells.length);
      var r = rng.nextInt(total);
      var i = 0;
      while (r >= pool[i].cells.length) {
        r -= pool[i].cells.length;
        i++;
      }
      out.add(pool.removeAt(i));
    }
    return out;
  }

  // ── 進路 ────────────────────────────────────────────────

  /// 入口→拠点の、自分自身と交差しない経路。長さ[minLen]〜[maxLen]を目指し、無理なら短くして、最後は最短経路。
  List<GridPos> _findPath(_Grid g, GridPos start, GridPos base, int minLen, int maxLen, Set<GridPos> avoid, Rng rng) {
    var lo = minLen;
    for (var attempt = 0; attempt < 4; attempt++) {
      final r = _dfs(g, start, base, lo, math.max(lo, maxLen), avoid, rng);
      if (r != null) return r;
      lo = math.max(start.manhattan(base) + 1, (lo * 0.75).floor());
    }
    return _bfs(g, start, base, avoid) ?? _bfs(g, start, base, const {})!;
  }

  List<GridPos>? _dfs(_Grid g, GridPos start, GridPos base, int minLen, int maxLen, Set<GridPos> avoid, Rng rng) {
    final path = <GridPos>[start];
    final seen = <GridPos>{start};
    var budget = _dfsBudget;
    bool go(GridPos cur) {
      if (--budget < 0) return false;
      if (cur == base) return path.length >= minLen;
      if (path.length + cur.manhattan(base) > maxLen) return false;
      final next = [for (final n in _n4(cur)) if (g.land.contains(n) && !seen.contains(n) && (n == base || !avoid.contains(n))) n]..sort();
      // 拠点に近づく向きを、やや優先する（長く迷いすぎない。3回に2回）
      final shuffled = rng.shuffled(next);
      if (rng.nextInt(3) != 0) shuffled.sort((a, b) => a.manhattan(base).compareTo(b.manhattan(base)));
      for (final n in shuffled) {
        seen.add(n);
        path.add(n);
        if (go(n)) return true;
        path.removeLast();
        seen.remove(n);
      }
      return false;
    }

    return go(start) ? path : null;
  }

  List<GridPos>? _bfs(_Grid g, GridPos start, GridPos base, Set<GridPos> avoid) {
    final prev = <GridPos, GridPos?>{start: null};
    final q = [start];
    for (var i = 0; i < q.length; i++) {
      final c = q[i];
      if (c == base) break;
      for (final n in (_n4(c).toList()..sort())) {
        if (!g.land.contains(n) || prev.containsKey(n) || (n != base && avoid.contains(n))) continue;
        prev[n] = c;
        q.add(n);
      }
    }
    if (!prev.containsKey(base)) return null;
    final out = <GridPos>[];
    for (GridPos? c = base; c != null; c = prev[c]) {
      out.add(c);
    }
    return out.reversed.toList();
  }

  // ── ウェーブ・季節 ───────────────────────────────────────

  static const _minEntranceDistance = 6; // 入口と拠点の最短距離（マス）

  List<StageWave> _waves(DifficultyParams p, RegionTrait? trait, List<StageEntrance> entrances,
      Map<String, Map<String, double>> neighborBias, int seed, Rng rng) {
    final count = (5 + p.waveAddition).clamp(1, 10);
    final mix = _profile?.enemyMix ?? const {'normal': 1.0};
    return [
      for (var w = 1; w <= count; w++)
        () {
          final n = 3 + w * 2;
          // 使う入口: 前半は主な入口だけ。後半の波は、入口を増やす（hardのみ。入口が複数あるとき）。
          final k = entrances.length == 1 ? 1 : (w * 2 > count ? math.min(entrances.length, 1 + ((w * 2 - count) * (entrances.length - 1) / count).ceil()) : 1);
          final idx = [for (var i = 0; i < k; i++) i];
          final wr = Rng(seed ^ (w * 0x9E3779B1));
          final kinds = <String>[];
          for (var i = 0; i < n; i++) {
            final e = entrances[idx[i % idx.length]];
            kinds.add(_pickKind(mix, trait?.enemyBias ?? const {}, e.neighborId == null ? const {} : neighborBias[e.neighborId] ?? const {}, wr, w));
          }
          return StageWave(
            number: w,
            enemyCount: n,
            baseHp: (48 * w * p.hpMultiplier).round(),
            baseAttack: (5 + w * 2 * p.hpMultiplier).round(),
            spawnInterval: math.max(0.5, 1.5 - w * 0.15),
            hasBoss: w == count,
            enemyKinds: kinds,
            entranceIndices: idx,
          );
        }()
    ];
  }

  /// 敵の種類を、国の構成(enemyMix)×その州の偏り×入口の隣の州の偏り(0.5乗)を重みに選ぶ。
  /// 敵の種類が最初に出る波。段階的に出して、序盤は通常の敵で施設を整える時間を作る。
  static const kindUnlockWave = {'normal': 1, 'speedy': 2, 'healer': 3, 'armored': 4};

  static String _pickKind(Map<String, double> mix, Map<String, double> own, Map<String, double> neighbor, Rng r, int wave) {
    final keys = (mix.keys.toList()..sort());
    final w = [
      for (final k in keys)
        (wave < (kindUnlockWave[k] ?? 1) ? 0.0 : mix[k]! * (own[k] ?? 1.0) * math.sqrt(neighbor[k] ?? 1.0))
    ];
    final total = w.fold<double>(0, (a, b) => a + b);
    var x = r.nextDouble() * total;
    if (total <= 0) return keys.contains('normal') ? 'normal' : keys.first;
    for (var i = 0; i < keys.length; i++) {
      x -= w[i];
      if (x <= 0) return keys[i];
    }
    return keys.last;
  }

  /// 天候から推定（設計書 §6.5）。天候がなければ seed で決める。
  static Season _season(String? weather, Rng rng) => switch (weather) {
        'blizzard' => Season.winter,
        'heatwave' || 'wildfire' => Season.summer,
        'hurricane' || 'storm' => Season.autumn,
        'tornado' || 'flood' => Season.spring,
        _ => Season.values[rng.nextInt(4)],
      };
}

class _Grid {
  final int cols, rows;
  final double originX, originY, cellW, cellH;
  final Set<GridPos> land;
  _Grid(this.cols, this.rows, this.originX, this.originY, this.cellW, this.cellH, this.land);
  double cx(int c) => originX + (c + 0.5) * cellW;
  double cy(int r) => originY + (r + 0.5) * cellH;
}

class _Group {
  final String? neighborId;
  final List<GridPos> cells;
  _Group(this.neighborId, this.cells);
}
