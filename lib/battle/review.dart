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
