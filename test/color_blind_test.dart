import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/progress/region_progress.dart';

void main() {
  test('色覚に配慮した配色: 習得（青）とミス（オレンジ）が、明るさでも色相でも十分に違う。通常の配色とは別', () {
    final a = colorBlindRegionColor(RegionState.mastered), b = colorBlindRegionColor(RegionState.missed);
    expect(a == b, false);
    expect(a.b > a.r && a.b > a.g, true); // 青
    expect(b.r > b.b && b.g > b.b, true); // オレンジ（赤と緑の両方が高く、青が低い）
    expect(colorBlindRegionColor(RegionState.unseen), defaultRegionColor(RegionState.unseen));
    expect(colorBlindRegionColor(RegionState.mastered) == defaultRegionColor(RegionState.mastered), false);
  });

  test('正解・不正解の強調色: 通常は緑と赤、配慮ありは青とオレンジ', () {
    expect(answerCorrectColor(), const Color(0xFF66BB6A));
    expect(answerWrongColor(), const Color(0xFFEF9A9A));
    expect(answerCorrectColor(colorBlind: true), const Color(0xFF1E88E5));
    expect(answerWrongColor(colorBlind: true), const Color(0xFFFB8C00));
  });
}
