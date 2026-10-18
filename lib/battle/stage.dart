import 'dart:convert';

import 'difficulty.dart';
import 'grid.dart';

/// 敵が入ってくる場所。隣の州の境界（[neighborId]）か、海・国境（null）。
class StageEntrance {
  final GridPos cell; // 盤面の中の入口のマス
  final String? neighborId; // 入口の向こう側の地域id（海・国境ならnull）
  final int borderCells; // その向こう側に接している陸地マスの数（境界の長さの目安）
  const StageEntrance(this.cell, this.neighborId, this.borderCells);
  Map<String, dynamic> toJson() => {'cell': cell.toJson(), 'neighborId': neighborId, 'borderCells': borderCells};
}

/// 1ウェーブの定義。敵の並びは決定的（同じステージは同じ並び）。
class StageWave {
  final int number; // 1始まり
  final int enemyCount;
  final int baseHp;
  final int baseAttack;
  final double spawnInterval; // 秒
  final bool hasBoss;
  final List<String> enemyKinds; // 出現順の敵の種類（normal/speedy/armored/healer）。長さ=enemyCount
  final List<int> entranceIndices; // このウェーブで使う入口（Stage.entrances の添字）
  const StageWave({
    required this.number,
    required this.enemyCount,
    required this.baseHp,
    required this.baseAttack,
    required this.spawnInterval,
    required this.hasBoss,
    required this.enemyKinds,
    required this.entranceIndices,
  });
  Map<String, dynamic> toJson() => {
        'number': number,
        'enemyCount': enemyCount,
        'baseHp': baseHp,
        'baseAttack': baseAttack,
        'spawnInterval': spawnInterval,
        'hasBoss': hasBoss,
        'enemyKinds': enemyKinds,
        'entranceIndices': entranceIndices,
      };
}

/// 州の形で切り抜いた盤面と、進路・設置枠・ウェーブ。`StageGenerator` が作る（同じ入力は同じ結果）。
class Stage {
  final String id; // '<regionId>:<difficulty>:<kind>'
  final String packId, regionId;
  final Difficulty difficulty;
  final StageKind kind;
  final int seed;

  /// 盤面の大きさ。州ごとに違う（設計書 §5.1）。
  final int cols, rows;

  /// 盤面の左上と1マスの大きさ（投影後の座標。州の形を重ねて描くときに使う）。
  final double originX, originY, cellW, cellH;

  /// 州の形の内側にあるマス（使えるマス）。
  final Set<GridPos> land;

  /// 拠点（州都にいちばん近い陸地マス）。
  final GridPos base;

  /// 入口（隣の州の方向）。[paths] と同じ順で、先頭が主な入口。
  final List<StageEntrance> entrances;

  /// 入口ごとの進路（入口のマス→拠点のマス。4近傍でつながる）。
  final List<List<GridPos>> paths;

  /// 施設を置ける枠（進路に隣接する陸地マス。進路上は含まない）。
  final List<GridPos> slots;
  final List<StageWave> waves;
  final int baseHp;
  final Season season;

  // 地域の特性（profile.json があるときだけ入る）
  final String? terrain, weatherEvent, backdrop, exclusiveFacility;

  /// 地方決戦: 地方のid、盤面にある州のid、置ける限定施設（州ごと）。通常のステージでは null・[regionId] だけ・[exclusiveFacility] だけ。
  final String? groupId;
  final List<String> memberIds;
  final List<String> exclusiveFacilities;

  const Stage({
    required this.id,
    required this.packId,
    required this.regionId,
    required this.difficulty,
    required this.kind,
    required this.seed,
    required this.cols,
    required this.rows,
    required this.originX,
    required this.originY,
    required this.cellW,
    required this.cellH,
    required this.land,
    required this.base,
    required this.entrances,
    required this.paths,
    required this.slots,
    required this.waves,
    required this.baseHp,
    required this.season,
    this.terrain,
    this.weatherEvent,
    this.backdrop,
    this.exclusiveFacility,
    this.groupId,
    this.memberIds = const [],
    this.exclusiveFacilities = const [],
  });

  /// 季節だけを変えた複製（天候・季節の効果の確認用）。
  Stage withSeason(Season s) => Stage(
        id: id, packId: packId, regionId: regionId, difficulty: difficulty, kind: kind, seed: seed, cols: cols, rows: rows,
        originX: originX, originY: originY, cellW: cellW, cellH: cellH, land: land, base: base, entrances: entrances,
        paths: paths, slots: slots, waves: waves, baseHp: baseHp, season: s, terrain: terrain, weatherEvent: weatherEvent,
        backdrop: backdrop, exclusiveFacility: exclusiveFacility,
        groupId: groupId, memberIds: memberIds, exclusiveFacilities: exclusiveFacilities,
      );

  bool isLand(int col, int row) => land.contains(GridPos(col, row));

  Map<String, dynamic> toJson() => {
        'id': id,
        'packId': packId,
        'regionId': regionId,
        'difficulty': difficulty.name,
        'kind': kind.name,
        'seed': seed,
        'cols': cols,
        'rows': rows,
        'origin': [originX, originY],
        'cell': [cellW, cellH],
        'land': [for (final p in (land.toList()..sort())) [p.col, p.row]],
        'base': base.toJson(),
        'entrances': [for (final e in entrances) e.toJson()],
        'paths': [for (final p in paths) [for (final c in p) [c.col, c.row]]],
        'slots': [for (final c in slots) [c.col, c.row]],
        'waves': [for (final w in waves) w.toJson()],
        'baseHp': baseHp,
        'season': season.name,
        'terrain': terrain,
        'weatherEvent': weatherEvent,
        'backdrop': backdrop,
        'exclusiveFacility': exclusiveFacility,
        'groupId': groupId,
        'memberIds': memberIds,
        'exclusiveFacilities': exclusiveFacilities,
      };

  /// 同じステージかを比べる／保存するための文字列。
  String toJsonString() => jsonEncode(toJson());
}
