import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/progress/progress_store.dart';
import 'package:terrimap_core/progress/region_progress.dart';

void main() {
  test('称号の閾値', () {
    expect(regionTitleFor(0, 16), RegionTitle.beginner);
    expect(regionTitleFor(7, 16), RegionTitle.explorer); // 43.75%
    expect(regionTitleFor(12, 16), RegionTitle.expert); // 75%
    expect(regionTitleFor(16, 16), RegionTitle.master);
    expect(regionTitleFor(0, 0), RegionTitle.beginner);
  });

  test('RegionProgress: 正解済み/ミス/未出題の塗り分けと達成率', () async {
    final s = InMemoryProgressStore();
    await s.markMastered('de', 'DE-BY');
    await s.recordMiss('de', 'DE-BE');
    await s.recordMiss('de', 'DE-BY'); // 習得済みはmissedにしない
    final p = await RegionProgress.load(s, 'de', ['DE-BY', 'DE-BE', 'DE-HH', 'DE-HB']);
    expect(p.stateOf('DE-BY'), RegionState.mastered);
    expect(p.stateOf('DE-BE'), RegionState.missed);
    expect(p.stateOf('DE-HH'), RegionState.unseen);
    expect(p.stateOf('unknown'), RegionState.unseen);
    expect(p.masteredCount, 1);
    expect(p.ratio, 0.25);
    expect(p.title, RegionTitle.beginner);
  });

  test('JsonProgressStore: 保存→復元で同じ内容(packごとに独立)', () async {
    final a = JsonProgressStore();
    await a.markMastered('de', 'DE-BY');
    await a.markMastered('us', 'US-CA');
    await a.recordMiss('de', 'DE-BE');
    await a.recordMiss('de', 'DE-BE');
    final b = JsonProgressStore.fromJson(a.toJson());
    expect(await b.mastered('de'), {'DE-BY'});
    expect(await b.mastered('us'), {'US-CA'});
    expect(await b.misses('de'), {'DE-BE': 2});
    expect(await b.misses('us'), isEmpty);
  });

  test('空のJSONでも復元できる', () async {
    final s = JsonProgressStore.fromJson('{}');
    expect(await s.mastered('de'), isEmpty);
  });
}
