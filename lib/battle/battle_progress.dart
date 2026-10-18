import 'dart:convert';

import '../pack/country_profile.dart';
import '../pack/region_pack.dart';
import 'difficulty.dart';
import 'grid.dart';

/// バトルのクリア記録と、地方決戦・エクストラの解放（設計書 §6.9・§10-7）。画面にも保存先にも依存しない純粋なデータ。
/// 保存はアプリ側（[toJson] / [fromJson] を端末に保存する）。
class BattleProgress {
  // ステージの鍵 '<種別>:<id>' → クリアした難易度
  final Map<String, Set<Difficulty>> _cleared;
  BattleProgress([Map<String, Set<Difficulty>>? cleared]) : _cleared = {for (final e in (cleared ?? {}).entries) e.key: {...e.value}};

  static String key(StageKind kind, String id) => '${kind.name}:$id';

  /// クリアを記録する。
  void recordClear(StageKind kind, String id, Difficulty difficulty) => (_cleared[key(kind, id)] ??= {}).add(difficulty);

  /// クリア済みか。[difficulty] を省くと、どの難易度でも。
  bool isCleared(StageKind kind, String id, {Difficulty? difficulty}) {
    final d = _cleared[key(kind, id)];
    if (d == null || d.isEmpty) return false;
    return difficulty == null ? true : d.contains(difficulty);
  }

  /// 通常のステージ（州）をクリアした数。
  int clearedStates(Iterable<String> regionIds, {Difficulty? difficulty}) =>
      regionIds.where((r) => isCleared(StageKind.normal, r, difficulty: difficulty)).length;

  /// その種別でクリアしたステージの数（難易度は問わない）。
  int clearedCountOf(StageKind kind) => _cleared.entries.where((e) => e.key.startsWith('${kind.name}:') && e.value.isNotEmpty).length;

  /// 地方決戦の解放: その地方の州の**過半数**をクリア（どの難易度でも）。
  bool regionalUnlocked(RegionGroup group) => clearedStates(group.regions) * 2 > group.regions.length;

  /// その地方で、クリアした州の数。
  int regionalProgress(RegionGroup group) => clearedStates(group.regions);

  /// エクストラの解放: **全州を hard でクリア**（ポストゲーム）。
  bool extraUnlocked(RegionPack pack) =>
      pack.regions.isNotEmpty && clearedStates(pack.regions.map((r) => r.id), difficulty: Difficulty.hard) == pack.regions.length;

  Map<String, dynamic> toJson() => {
        'v': 1,
        'cleared': {for (final e in _cleared.entries) e.key: [for (final d in e.value) d.name]},
      };

  String toJsonString() => jsonEncode(toJson());

  factory BattleProgress.fromJson(Map<String, dynamic> j) => BattleProgress({
        for (final e in ((j['cleared'] as Map?) ?? const {}).entries)
          e.key as String: {
            for (final d in (e.value as List))
              if (Difficulty.values.any((x) => x.name == d)) Difficulty.values.byName(d as String),
          },
      });

  /// 壊れた・空の文字列は、空の記録として読む。
  factory BattleProgress.fromJsonString(String? s) {
    if (s == null || s.isEmpty) return BattleProgress();
    try {
      return BattleProgress.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return BattleProgress();
    }
  }
}
