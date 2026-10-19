import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/battle/battle_engine.dart';
import 'package:terrimap_core/battle/difficulty.dart';
import 'package:terrimap_core/battle/stage_generator.dart';
import 'package:terrimap_core/battle/tutorial.dart';
import 'package:terrimap_core/pack/region_pack.dart';

RegionPack load(String id) {
  String r(String f) => File('packs/$id/$f').readAsStringSync();
  final langs = Directory('packs/$id/strings').listSync().map((e) => e.uri.pathSegments.last.replaceAll('.json', ''));
  return RegionPack.parse(
      packJson: r('pack.json'), regionsJson: r('regions.json'), geoJson: r('geo.geojson'),
      stringsJsonByLang: {for (final l in langs) l: r('strings/$l.json')},
      profileJson: r('profile.json'));
}

void main() {
  final de = load('de');
  final engine = BattleEngine(StageGenerator(de).generate('DE-BY', Difficulty.easy), profile: de.profile, pack: de, quizAssist: false);

  TutorialStep? step(BattleState s, {bool selecting = false, bool skill = false}) => Tutorial.stepFor(s, selecting: selecting, skillReady: skill);

  test('案内は、置く→施設を選ぶ→波を始める→守る の順に進む', () {
    final s0 = engine.start();
    expect(step(s0), TutorialStep.placeSlot);
    expect(step(s0, selecting: true), TutorialStep.placeFacility);
    final slot = engine.stage.slots.first;
    final placed = engine.place(s0.copyWith(coins: 999), FacilityType.farm, slot)!;
    expect(placed.facilities, isNotEmpty);
    expect(step(placed), TutorialStep.startWave);
    final waving = engine.startWave(placed).state;
    expect(waving.phase, BattlePhase.wave);
    expect(step(waving), TutorialStep.defend);
  });

  test('最初の波のあと: スキルが選べるなら案内を出し、選べなければ終える。2波目以降は出さない', () {
    final s = engine.start().copyWith(wave: 1, phase: BattlePhase.prep);
    final withFac = s.copyWith(facilities: engine.place(engine.start().copyWith(coins: 999), FacilityType.farm, engine.stage.slots.first)!.facilities);
    expect(step(withFac, skill: true), TutorialStep.skill);
    expect(Tutorial.finished(withFac, skillReady: true), isFalse); // スキルを見せる前は終えない
    expect(step(withFac), isNull);
    expect(Tutorial.finished(withFac, skillReady: false), isTrue);
    final second = withFac.copyWith(wave: 2, phase: BattlePhase.wave);
    expect(step(second, skill: true), isNull);
    expect(Tutorial.finished(second, skillReady: true), isTrue);
  });

  test('勝敗が決まったら出さない。負けたら終えた扱いにしない（もう一度見せる）', () {
    final s = engine.start();
    expect(step(s.copyWith(phase: BattlePhase.victory)), isNull);
    expect(step(s.copyWith(phase: BattlePhase.defeat)), isNull);
    expect(Tutorial.finished(s.copyWith(phase: BattlePhase.defeat, wave: 3), skillReady: false), isFalse);
    expect(Tutorial.finished(s.copyWith(phase: BattlePhase.victory, wave: 5), skillReady: false), isTrue);
    expect(Tutorial.finished(s, skillReady: false), isFalse); // 開始前
  });

  test('i18n: すべての案内に文言がある', () {
    final en = File('i18n/battle.en.json').readAsStringSync();
    for (final k in ['placeSlot', 'placeFacility', 'startWave', 'defend', 'skill', 'skip', 'done', 'replay', 'replayHelp']) {
      expect(en.contains('"tutorial.$k"'), isTrue, reason: k);
    }
    for (final st in TutorialStep.values) {
      expect(en.contains('"tutorial.${st.name}"'), isTrue, reason: st.name);
    }
  });
}
