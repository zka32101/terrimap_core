import '../pack/pack_facts.dart';
import 'battle_progress.dart';
import 'grid.dart';

/// 集めるカード（名所）。州をクリアすると、その州の名所が集まる。
class CollectionCard {
  final Landmark landmark;
  final bool unlocked;
  const CollectionCard(this.landmark, this.unlocked);
}

/// 名所のコレクション（画面にも保存先にも依存しない）。
/// 解放: その州を、どの難易度でもクリア。名所のデータは `facts.json`（問題に使う `use` のもの）。
class Collection {
  final PackFacts? facts;
  final BattleProgress progress;
  const Collection(this.facts, this.progress);

  /// 全カード（データの順）。名所のデータがなければ空。
  List<CollectionCard> get cards =>
      [for (final l in facts?.usable ?? const <Landmark>[]) CollectionCard(l, progress.isCleared(StageKind.normal, l.regionId))];

  int get total => cards.length;
  int get unlockedCount => cards.where((c) => c.unlocked).length;

  /// 州をクリアしたときに手に入る名所（その州の、問題に使う名所）。
  List<Landmark> landmarksOf(String regionId) => facts?.inRegion(regionId) ?? const [];

  /// 解放済みの名所の id。
  Set<String> get unlockedIds => {for (final c in cards) if (c.unlocked) c.landmark.id};
}
