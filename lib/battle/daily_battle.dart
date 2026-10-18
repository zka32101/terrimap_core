import '../pack/region_pack.dart';
import '../quiz/rng.dart';
import 'difficulty.dart';
import 'grid.dart';
import 'replay.dart';

/// 今日のバトル（設計書 §6.13）。日付（UTC の yyyy-MM-dd）と packId から、ステージと難易度が決まる。全員が同じ条件で遊ぶ。
class DailyBattle {
  final String date;
  final StageKind kind;
  final String stageId;
  final Difficulty difficulty;
  const DailyBattle(this.date, this.kind, this.stageId, this.difficulty);

  /// 今日のバトル。通常のステージ（州）から選ぶ。[allowedIds] を渡すと、その州だけから選ぶ（無料の州に絞るなど）。
  /// 難易度は、easy 3 : normal 5 : hard 2 の割合。
  factory DailyBattle.forDate(RegionPack pack, String date, {Set<String>? allowedIds}) {
    final ids = [for (final r in pack.regions) if (allowedIds == null || allowedIds.contains(r.id)) r.id]..sort();
    if (ids.isEmpty) throw ArgumentError('選べる州がありません');
    final h = fnv1a('daily-battle|$date|${pack.packId}');
    final id = ids[h % ids.length];
    final d = (h ~/ ids.length) % 10;
    final diff = d < 3 ? Difficulty.easy : (d < 8 ? Difficulty.normal : Difficulty.hard);
    return DailyBattle(date, StageKind.normal, id, diff);
  }

  /// 絵文字共有テキスト。波ごとに、無傷=🟩・被害あり=🟥・届かなかった波=⬛。拠点HPの残りを添える。
  /// [totalWaves] はステージの波の数、[maxBaseHp] は拠点HPの最大。
  String shareText(String appName, ReplayResult r, {required int totalWaves, required int maxBaseHp}) {
    final row = StringBuffer();
    for (var i = 0; i < totalWaves; i++) {
      row.write(i >= r.breaches.length ? '⬛' : (r.breaches[i] == 0 ? '🟩' : '🟥'));
    }
    final head = '$appName $date ${difficulty.name} ${r.won ? '✅' : '❌'} ♥${r.baseHp.clamp(0, maxBaseHp)}/$maxBaseHp';
    return '$head\n$row';
  }
}
