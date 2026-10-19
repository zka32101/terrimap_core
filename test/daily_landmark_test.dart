import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/daily/daily_landmark.dart';
import 'package:terrimap_core/pack/pack_facts.dart';

void main() {
  PackFacts facts(List<(String, bool)> ls) => PackFacts([
        for (final (id, use) in ls) Landmark(id: id, regionId: 'R', name: {'en': id}, use: use),
      ]);

  test('同じ日なら同じ名所。問題に使わない名所は選ばない', () {
    final f = facts([('a', true), ('b', false), ('c', true), ('d', true)]);
    expect(DailyLandmark.pick(f, '2026-10-19')!.id, DailyLandmark.pick(f, '2026-10-19')!.id);
    for (var d = 1; d <= 28; d++) {
      expect(DailyLandmark.pick(f, '2026-02-${d.toString().padLeft(2, '0')}')!.id, isNot('b'));
    }
  });

  test('日が変わると名所もばらける。名所がなければ null', () {
    final f = facts([for (var i = 0; i < 10; i++) ('l$i', true)]);
    final ids = {for (var d = 1; d <= 30; d++) DailyLandmark.pick(f, '2026-09-${d.toString().padLeft(2, '0')}')!.id};
    expect(ids.length, greaterThan(5));
    expect(DailyLandmark.pick(null, '2026-10-19'), isNull);
    expect(DailyLandmark.pick(facts([]), '2026-10-19'), isNull);
  });
}
