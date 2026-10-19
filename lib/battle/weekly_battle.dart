import 'dart:convert';

import '../pack/region_pack.dart';
import '../quiz/rng.dart';
import 'difficulty.dart';
import 'grid.dart';
import 'invite.dart';

/// 今週のチャレンジ。週（UTC・月曜はじまり）と packId から、ステージと難易度が決まる。全員が同じ条件で、1週に1回だけ挑戦できる。
/// 地方決戦がある国は地方決戦から、ない国は州から選ぶ。難易度は、hard 6 : normal 4。
/// 結果を送るときは、友だちへの招待（[Invite]）と同じコードを使う。
class WeeklyBattle {
  final String week; // 例 2026-W43
  final StageKind kind;
  final String stageId;
  final Difficulty difficulty;
  const WeeklyBattle(this.week, this.kind, this.stageId, this.difficulty);

  static DateTime _d(String s) {
    final p = s.split('-').map(int.parse).toList();
    return DateTime.utc(p[0], p[1], p[2]);
  }

  /// その日がある週の名前（ISO 8601 の週。年をまたぐ週も正しく数える）。
  static String weekOf(String date) {
    final d = _d(date);
    final thursday = d.add(Duration(days: 4 - d.weekday)); // その週の木曜が属する年が、週の年
    final jan1 = DateTime.utc(thursday.year, 1, 1);
    final n = 1 + thursday.difference(jan1).inDays ~/ 7;
    return '${thursday.year}-W${n.toString().padLeft(2, '0')}';
  }

  /// 週の終わり（日曜）まで、今日を入れて何日あるか（月曜=7、日曜=1）。
  static int daysLeft(String date) => 8 - _d(date).weekday;

  factory WeeklyBattle.forDate(RegionPack pack, String date) {
    final week = weekOf(date);
    final h = fnv1a('weekly-battle|$week|${pack.packId}');
    final groups = (pack.profile?.groups.keys.toList() ?? <String>[])..sort();
    final StageKind kind;
    final String id;
    final int rest;
    if (groups.isNotEmpty) {
      kind = StageKind.regional;
      id = groups[h % groups.length];
      rest = h ~/ groups.length;
    } else {
      final ids = [for (final r in pack.regions) r.id]..sort();
      if (ids.isEmpty) throw ArgumentError('選べる州がありません');
      kind = StageKind.normal;
      id = ids[h % ids.length];
      rest = h ~/ ids.length;
    }
    return WeeklyBattle(week, kind, id, rest % 10 < 6 ? Difficulty.hard : Difficulty.normal);
  }

  /// 友だちに送るときのコード（同じステージ・難易度で挑戦できる）。
  Invite invite(String packId, {bool? won, int? baseHp}) =>
      Invite(packId: packId, kind: kind, stageId: stageId, difficulty: difficulty, won: won, baseHp: baseHp);
}

/// 今週の挑戦の結果（1週に1回）。保存先はアプリ側（[toJson] / [WeeklyRecord.fromJson]）。
class WeeklyRecord {
  final String week;
  final bool won;
  final int baseHp;
  const WeeklyRecord(this.week, this.won, this.baseHp);

  /// 今週の挑戦を終えているか。
  bool doneIn(String currentWeek) => week == currentWeek;

  String toJson() => jsonEncode({'week': week, 'won': won, 'baseHp': baseHp});

  /// 壊れた・空のデータは null（まだ挑戦していない扱い）。
  static WeeklyRecord? fromJson(String? src) {
    if (src == null || src.isEmpty) return null;
    try {
      final m = jsonDecode(src) as Map<String, dynamic>;
      final w = m['week'], won = m['won'], hp = m['baseHp'];
      if (w is! String || won is! bool || hp is! int) return null;
      return WeeklyRecord(w, won, hp);
    } catch (_) {
      return null;
    }
  }
}
