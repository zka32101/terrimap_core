import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/bot.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/stage_generator.dart';
import 'package:terrimap_core/pack/region_pack.dart';

RegionPack load(String id) {
  String r(String f) => File('packs/$id/$f').readAsStringSync();
  final langs = Directory('packs/$id/strings').listSync().map((e) => e.uri.pathSegments.last.replaceAll('.json', ''));
  return RegionPack.parse(
      packJson: r('pack.json'), regionsJson: r('regions.json'), geoJson: r('geo.geojson'),
      stringsJsonByLang: {for (final l in langs) l: r('strings/$l.json')},
      profileJson: r('profile.json'));
}

/// bot 戦績: 勝率[pack][bot][難易度]
Map<String, double> rates(RegionPack pack, BotProfile bot, {bool assist = true, Iterable<String>? only}) {
  final out = <String, double>{};
  for (final d in Difficulty.values) {
    var win = 0, n = 0;
    for (final r in pack.regions) {
      if (only != null && !only.contains(r.id)) continue;
      final stage = StageGenerator(pack).generate(r.id, d);
      final e = BattleEngine(stage, profile: pack.profile, pack: pack, quizAssist: assist);
      if (BattleBot(e, bot).play().won) win++;
      n++;
    }
    out[d.name] = win / n;
  }
  return out;
}

void main() {
  final de = load('de'), us = load('us');

  test('ボットは全地域×3難易度で最後まで遊べる（例外なし）', () {
    for (final pack in [de, us]) {
      for (final r in pack.regions.take(6)) {
        for (final d in Difficulty.values) {
          final e = BattleEngine(StageGenerator(pack).generate(r.id, d), profile: pack.profile, pack: pack);
          final res = BattleBot(e, BotProfile.regular).play();
          expect(res.wave, greaterThan(0), reason: '${r.id} ${d.name}');
        }
      }
    }
  });

  test('ボットは決定的（同じステージは同じ結果）', () {
    final stage = StageGenerator(us).generate('US-TX', Difficulty.normal);
    BotResult run() => BattleBot(BattleEngine(stage, profile: us.profile, pack: us), BotProfile.regular).play();
    final a = run(), b = run();
    expect((a.won, a.wave, a.baseHp, a.facilities, a.seconds), (b.won, b.wave, b.baseHp, b.facilities, b.seconds));
  });

  test('バランスの目安: easy は遊べ、hard は難しく、難易度の順に勝ちにくくなる', () {
    for (final entry in {'de': de, 'us': us}.entries) {
      final reg = rates(entry.value, BotProfile.regular), exp = rates(entry.value, BotProfile.expert);
      final k = entry.key;
      expect(reg['easy'], greaterThanOrEqualTo(0.9), reason: '$k easy regular');
      expect(reg['easy']!, greaterThanOrEqualTo(reg['normal']!), reason: '$k easy>=normal');
      expect(reg['normal']!, greaterThanOrEqualTo(reg['hard']!), reason: '$k normal>=hard');
      expect(reg['normal'], greaterThanOrEqualTo(0.3), reason: '$k normal regular は遊べる');
      expect(exp['hard'], lessThanOrEqualTo(0.6), reason: '$k hard expert は難しい');
    }
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('バランス表（BALANCE=1 のとき表示）', () {
    if (Platform.environment['BALANCE'] != '1') return;
    final b = StringBuffer();
    for (final entry in {'de': de, 'us': us}.entries) {
      for (final bot in [BotProfile.casual, BotProfile.regular, BotProfile.expert]) {
        final r = rates(entry.value, bot);
        b.writeln('${entry.key} ${bot.name.padRight(8)} easy ${(r['easy']! * 100).round()}%  normal ${(r['normal']! * 100).round()}%  hard ${(r['hard']! * 100).round()}%');
      }
    }
    // ignore: avoid_print
    print(b);
  }, timeout: const Timeout(Duration(minutes: 20)));
}
