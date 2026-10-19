import 'dart:convert';

/// バトルの勝敗の回数とプレイ時間（画面にも保存先にも依存しない純粋なデータ）。保存はアプリ側（[toJsonString] / [fromJsonString]）。
/// 勝ち負けが決まったバトルだけを数える（途中でやめたバトルは、時間だけ足す）。
class BattleLog {
  final int wins, losses;
  final double playSeconds;
  const BattleLog({this.wins = 0, this.losses = 0, this.playSeconds = 0});

  int get games => wins + losses;

  /// 勝率（％、四捨五入）。まだ決まったバトルがなければ null。
  int? get winRatePercent => games == 0 ? null : (wins * 100 / games).round();

  /// 記録を足す。[won] が null なら時間だけ（途中でやめた）。負やNaNの時間は無視する。
  BattleLog record({bool? won, double seconds = 0}) => BattleLog(
        wins: wins + (won == true ? 1 : 0),
        losses: losses + (won == false ? 1 : 0),
        playSeconds: playSeconds + (seconds.isFinite && seconds > 0 ? seconds : 0),
      );

  String toJsonString() => jsonEncode({'v': 1, 'wins': wins, 'losses': losses, 'playSeconds': playSeconds});

  /// 壊れた・空の文字列は、空の記録として読む。
  factory BattleLog.fromJsonString(String? s) {
    if (s == null || s.isEmpty) return const BattleLog();
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      int n(Object? v) => v is int && v >= 0 ? v : 0;
      final t = m['playSeconds'];
      return BattleLog(wins: n(m['wins']), losses: n(m['losses']), playSeconds: t is num && t.isFinite && t > 0 ? t.toDouble() : 0);
    } catch (_) {
      return const BattleLog();
    }
  }
}
