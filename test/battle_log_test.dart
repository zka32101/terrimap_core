import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_log.dart';

void main() {
  test('空の記録: 回数は0、勝率はなし', () {
    const l = BattleLog();
    expect((l.wins, l.losses, l.games, l.playSeconds), (0, 0, 0, 0));
    expect(l.winRatePercent, isNull);
  });

  test('勝ち・負け・途中でやめた（時間だけ）が数えられる。勝率は四捨五入', () {
    var l = const BattleLog();
    l = l.record(won: true, seconds: 120);
    l = l.record(won: true, seconds: 100);
    l = l.record(won: false, seconds: 80.5);
    l = l.record(seconds: 30); // 途中でやめた: 勝敗には数えない
    expect((l.wins, l.losses, l.games), (2, 1, 3));
    expect(l.playSeconds, closeTo(330.5, 1e-9));
    expect(l.winRatePercent, 67); // 2/3
  });

  test('負やNaNの時間は無視する', () {
    final l = const BattleLog().record(won: true, seconds: -5).record(won: false, seconds: double.nan).record(seconds: double.infinity);
    expect((l.wins, l.losses, l.playSeconds), (1, 1, 0));
  });

  test('保存と読み込み: 往復できる。壊れた・空・型違いのデータは、読めた項目だけ使う', () {
    final l = const BattleLog(wins: 5, losses: 2, playSeconds: 1234.5);
    final back = BattleLog.fromJsonString(l.toJsonString());
    expect((back.wins, back.losses, back.playSeconds), (5, 2, 1234.5));
    expect(BattleLog.fromJsonString(null).games, 0);
    expect(BattleLog.fromJsonString('').games, 0);
    expect(BattleLog.fromJsonString('{broken').games, 0);
    final odd = BattleLog.fromJsonString('{"wins":"x","losses":3,"playSeconds":-1}');
    expect((odd.wins, odd.losses, odd.playSeconds), (0, 3, 0));
  });
}
