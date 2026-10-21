import 'dart:convert';

import '../pack/region_pack.dart';
import '../quiz/rng.dart';

/// エンドレスの1回の結果。[waves] は守り切った波の数（全波を守り切ったら最大）。
class EndlessResult {
  final String regionId;
  final int waves; // 守り切った波の数
  final int score; // バトルのスコア（同じ波数どうしの比べ用）
  const EndlessResult(this.regionId, this.waves, this.score);

  /// ランキング用の1つの数。波数が主で、同じ波数ならスコアの高い方（スコアは 999,999 まで）。
  int get rank => waves * 1000000 + score.clamp(0, 999999);
}

/// エンドレスの自己ベスト（州ごと）。保存先はアプリ側（[toJson] / [EndlessBoard.fromJson]）。
class EndlessBoard {
  final Map<String, EndlessResult> _best;
  const EndlessBoard._(this._best);
  const EndlessBoard.empty() : _best = const {};

  EndlessResult? bestOf(String regionId) => _best[regionId];

  /// 全州の中でいちばん良い記録。
  EndlessResult? get best {
    EndlessResult? b;
    for (final r in _best.values) {
      if (b == null || r.rank > b.rank) b = r;
    }
    return b;
  }

  /// 州別の記録を、良い順に。
  List<EndlessResult> get ranked => _best.values.toList()..sort((a, b) => b.rank.compareTo(a.rank));

  /// 結果を取り込んだ新しい記録。自己ベストを更新したかは [improved] で調べる（取り込む前の記録に対して）。
  EndlessBoard add(EndlessResult r) => improved(r) ? EndlessBoard._({..._best, r.regionId: r}) : this;

  bool improved(EndlessResult r) {
    if (r.waves <= 0) return false;
    final cur = _best[r.regionId];
    return cur == null || r.rank > cur.rank;
  }

  String toJson() => jsonEncode({for (final e in _best.entries) e.key: [e.value.waves, e.value.score]});

  /// 壊れた・空のデータは空の記録。
  static EndlessBoard fromJson(String? src) {
    if (src == null || src.isEmpty) return const EndlessBoard.empty();
    try {
      final m = jsonDecode(src) as Map<String, dynamic>;
      final out = <String, EndlessResult>{};
      for (final e in m.entries) {
        final v = e.value;
        if (v is List && v.length == 2 && v[0] is int && v[1] is int && (v[0] as int) > 0) out[e.key] = EndlessResult(e.key, v[0] as int, v[1] as int);
      }
      return EndlessBoard._(out);
    } catch (_) {
      return const EndlessBoard.empty();
    }
  }
}

/// 今日の州。日付と packId から決まる(全員が同じ州)。[allowedIds] を渡すと、その州だけから選ぶ(無料の間は無料の州に絞る、など)。
class EndlessDaily {
  EndlessDaily._();

  static String regionFor(RegionPack pack, String date, {Set<String>? allowedIds}) {
    final ids = [for (final r in pack.regions) if (allowedIds == null || allowedIds.contains(r.id)) r.id]..sort();
    if (ids.isEmpty) throw ArgumentError('選べる州がありません');
    return ids[fnv1a('endless-daily|$date|${pack.packId}') % ids.length];
  }
}
