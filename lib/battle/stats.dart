import '../daily/daily_streak.dart';
import '../progress/region_progress.dart';
import 'achievements.dart';
import 'battle_log.dart';
import 'battle_progress.dart';
import 'collection.dart';
import 'difficulty.dart';
import 'grid.dart';

/// 統計画面の数字（画面にも保存先にも依存しない）。今ある記録から、毎回計算する。
/// 勝敗の回数・プレイ時間は、[BattleLog]（アプリが保存する）があるときに出す。なければ 0。
class Stats {
  // クイズ（学習の進み）
  final int quizMastered, quizMissed, quizUnseen, quizTotal;

  // バトル（クリアした数。難易度ごとは「その難易度でクリア」）
  final int totalStates;
  final Map<Difficulty, int> statesCleared;
  final int statesClearedAny; // どの難易度でも
  final int regionalCleared, regionalTotal;
  final int extraCleared, extraTotal;

  // 勝敗・プレイ時間（BattleLog から）
  final int wins, losses;
  final int? winRatePercent; // まだ決まったバトルがなければ null
  final int playMinutes;

  // 毎日のバトル
  final int streakCurrent, streakBest;

  // 集める・実績
  final int cardsUnlocked, cardsTotal;
  final int achievementsUnlocked, achievementsTotal;

  const Stats({
    required this.quizMastered,
    required this.quizMissed,
    required this.quizUnseen,
    required this.quizTotal,
    required this.totalStates,
    required this.statesCleared,
    required this.statesClearedAny,
    required this.regionalCleared,
    required this.regionalTotal,
    required this.extraCleared,
    required this.extraTotal,
    required this.wins,
    required this.losses,
    required this.winRatePercent,
    required this.playMinutes,
    required this.streakCurrent,
    required this.streakBest,
    required this.cardsUnlocked,
    required this.cardsTotal,
    required this.achievementsUnlocked,
    required this.achievementsTotal,
  });

  /// [regionIds] は州（通常ステージ）の id、[regionalTotal]・[extraTotal] は地方決戦・エクストラの数。[today] は UTC の yyyy-MM-dd。
  factory Stats.compute({
    required List<String> regionIds,
    required RegionProgress regions,
    required BattleProgress battle,
    required Collection collection,
    required DailyStreak streak,
    required String today,
    int regionalTotal = 0,
    int extraTotal = 0,
    BattleLog log = const BattleLog(),
  }) {
    final ach = Achievements(regionIds: regionIds, progress: battle, collection: collection, bestStreak: streak.best, regions: regions);
    int count(RegionState s) => regions.states.values.where((v) => v == s).length;
    return Stats(
      quizMastered: count(RegionState.mastered),
      quizMissed: count(RegionState.missed),
      quizUnseen: count(RegionState.unseen),
      quizTotal: regions.total,
      totalStates: regionIds.length,
      statesCleared: {for (final d in Difficulty.values) d: battle.clearedStates(regionIds, difficulty: d)},
      statesClearedAny: battle.clearedStates(regionIds),
      regionalCleared: battle.clearedCountOf(StageKind.regional),
      regionalTotal: regionalTotal,
      extraCleared: battle.clearedCountOf(StageKind.extra),
      extraTotal: extraTotal,
      wins: log.wins,
      losses: log.losses,
      winRatePercent: log.winRatePercent,
      playMinutes: (log.playSeconds / 60).floor(),
      streakCurrent: streak.currentOn(today),
      streakBest: streak.best,
      cardsUnlocked: collection.unlockedCount,
      cardsTotal: collection.total,
      achievementsUnlocked: ach.unlockedCount,
      achievementsTotal: ach.all.length,
    );
  }
}
