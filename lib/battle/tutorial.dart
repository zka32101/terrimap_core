import 'battle_model.dart';

/// 初回のバトルで出す案内の段階（画面にも保存先にも依存しない）。状況から、いま出す案内を決める。
enum TutorialStep {
  placeSlot, // 設置枠をタップして、施設を置く
  placeFacility, // 枠を選んだ。施設を選ぶ
  startWave, // 施設を置いた。波を始める
  defend, // 最初の波の最中
  skill, // 最初の波のあと、スキルが選べる
}

class Tutorial {
  /// いま出す案内。出さない場面（最初の波のあと・勝敗が決まった・2波目以降）は null。
  /// [selecting] は設置枠を選んでいるか、[skillReady] はスキルを選べるか。
  static TutorialStep? stepFor(BattleState st, {required bool selecting, required bool skillReady}) {
    switch (st.phase) {
      case BattlePhase.victory:
      case BattlePhase.defeat:
        return null;
      case BattlePhase.wave:
        return st.wave <= 1 ? TutorialStep.defend : null;
      case BattlePhase.prep:
        if (st.facilities.isEmpty) return selecting ? TutorialStep.placeFacility : TutorialStep.placeSlot;
        if (st.wave == 0) return TutorialStep.startWave;
        return st.wave == 1 && skillReady ? TutorialStep.skill : null;
    }
  }

  /// 案内を終えてよいか。最初の波を守り切って、（スキルが選べるなら選ぶ機会を見せたあと）次の波に進んだ・勝った。
  static bool finished(BattleState st, {required bool skillReady}) {
    if (st.phase == BattlePhase.defeat) return false;
    if (st.phase == BattlePhase.victory || st.wave >= 2) return true;
    return st.wave == 1 && st.phase == BattlePhase.prep && !skillReady;
  }
}
