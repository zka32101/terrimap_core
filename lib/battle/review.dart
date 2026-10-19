import '../progress/region_progress.dart';

/// バトルのクイズ連動で、間違えた州が出やすくなる重み（復習）。未習得でミスのある州ほど重く、習得済みは軽い。
/// 進捗は端末ごとに違うので、毎日のバトルなど全員が同じ条件で遊ぶ場面では使わない。
Map<String, double> battleReviewWeights(RegionProgress progress) => {
      for (final e in progress.states.entries)
        e.key: switch (e.value) {
          RegionState.missed => 3.0,
          RegionState.unseen => 1.5,
          RegionState.mastered => 0.4,
        },
    };

/// 復習モード（クイズだけの練習）で出す州: 間違えて、まだ習得していない州。[allowed] を渡すと、その中だけ（無料の間は解放済みの州に絞る、など）。
/// 正解すると習得済みになるので、練習するほど減っていく。何もなければ空。
Set<String> reviewPool(RegionProgress progress, {Set<String>? allowed}) => {
      for (final e in progress.states.entries)
        if (e.value == RegionState.missed && (allowed == null || allowed.contains(e.key))) e.key,
    };
