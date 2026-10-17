/// 難易度（3種）。地理パズル王の既存の値（difficulty_config.dart）を初期値にした。
enum Difficulty { easy, normal, hard }

class DifficultyParams {
  final double hpMultiplier; // 敵HPの倍率
  final int waveAddition; // ウェーブ数の加算
  final double scoreMultiplier;
  final double speedMultiplier; // 敵の速さの倍率
  final int heartBonus; // 拠点HPの加減
  final bool heavyBreach; // ボス・装甲が突破したとき、拠点を追加で減らすか
  final double rewardMultiplier; // 撃破コインの倍率
  final double waveBreakSeconds; // ウェーブ間の準備時間
  final bool facilitiesAttacked; // 敵が施設も攻撃するか（hardのみ。設計書 §6.2）
  final int maxEntrances; // 同時に使う入口の数の上限（隣の州の入口。設計書 §5.2）
  const DifficultyParams({
    required this.hpMultiplier,
    required this.waveAddition,
    required this.scoreMultiplier,
    required this.speedMultiplier,
    required this.heartBonus,
    required this.heavyBreach,
    required this.rewardMultiplier,
    required this.waveBreakSeconds,
    required this.facilitiesAttacked,
    required this.maxEntrances,
  });
}

const Map<Difficulty, DifficultyParams> difficultyParams = {
  Difficulty.easy: DifficultyParams(
      hpMultiplier: 0.65, waveAddition: -1, scoreMultiplier: 0.8, speedMultiplier: 0.8, heartBonus: 8,
      heavyBreach: false, rewardMultiplier: 1.25, waveBreakSeconds: 10, facilitiesAttacked: false, maxEntrances: 1),
  Difficulty.normal: DifficultyParams(
      hpMultiplier: 1.0, waveAddition: 0, scoreMultiplier: 1.0, speedMultiplier: 1.0, heartBonus: 0,
      heavyBreach: true, rewardMultiplier: 1.0, waveBreakSeconds: 6, facilitiesAttacked: false, maxEntrances: 1),
  Difficulty.hard: DifficultyParams(
      hpMultiplier: 1.15, waveAddition: 2, scoreMultiplier: 1.5, speedMultiplier: 1.08, heartBonus: -2,
      heavyBreach: true, rewardMultiplier: 1.0, waveBreakSeconds: 4, facilitiesAttacked: true, maxEntrances: 3),
};
