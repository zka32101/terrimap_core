import '../progress/region_progress.dart';
import 'battle_progress.dart';
import 'collection.dart';
import 'difficulty.dart';
import 'grid.dart';

/// 実績1件の状態。達成は保存せず、毎回データから計算する（データ削除と必ず揃う）。
class Achievement {
  final String id;
  final int value; // 現在の値（目標を超えても、そのまま）
  final int goal;
  const Achievement(this.id, this.value, this.goal);

  bool get unlocked => goal > 0 && value >= goal;

  /// 0〜1の進み具合。
  double get ratio => goal <= 0 ? 0 : (value / goal).clamp(0.0, 1.0);

  /// 表示用の値（目標でとめる）。
  int get shown => value > goal ? goal : value;
}

/// 実績の一覧（画面にも保存先にも依存しない）。
class Achievements {
  final List<String> regionIds; // 通常ステージ（州）のid
  final BattleProgress progress;
  final Collection collection;
  final int bestStreak; // 今日のチャレンジの最長連続日数
  final RegionProgress? regions; // 学習の進み（なければ「全州マスター」は0）
  const Achievements({
    required this.regionIds,
    required this.progress,
    required this.collection,
    this.bestStreak = 0,
    this.regions,
  });

  static const streakGoals = [3, 7, 30];

  List<Achievement> get all {
    final total = regionIds.length;
    int cleared([Difficulty? d]) => progress.clearedStates(regionIds, difficulty: d);
    final cards = collection.unlockedCount;
    final cardTotal = collection.total;
    return [
      Achievement('firstClear', cleared() > 0 ? 1 : 0, 1),
      Achievement('allClear', cleared(), total),
      Achievement('allEasy', cleared(Difficulty.easy), total),
      Achievement('allNormal', cleared(Difficulty.normal), total),
      Achievement('allHard', cleared(Difficulty.hard), total),
      Achievement('regional', progress.clearedCountOf(StageKind.regional) > 0 ? 1 : 0, 1),
      Achievement('boss', progress.clearedCountOf(StageKind.extra) > 0 ? 1 : 0, 1),
      for (final n in streakGoals) Achievement('streak$n', bestStreak, n),
      Achievement('cards10', cards, cardTotal < 10 ? cardTotal : 10),
      Achievement('cardsAll', cards, cardTotal),
      Achievement('mastered', regions?.masteredCount ?? 0, regions?.total ?? 0),
    ];
  }

  int get unlockedCount => all.where((a) => a.unlocked).length;

  /// 達成済みの id。
  Set<String> get unlockedIds => {for (final a in all) if (a.unlocked) a.id};
}
