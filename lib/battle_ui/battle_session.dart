import 'package:flutter/foundation.dart';

import '../battle/battle_engine.dart';
import '../battle/grid.dart';
import '../quiz/quiz_engine.dart';

/// 画面とエンジンの間に入る、バトル1回ぶんの操作役。時間の進め方（速度・一時停止）、選択中のマス、直近のイベントを持つ。
/// 時間は画面のフレームから [tick] で渡す（エンジンは固定の刻みで進める）。
class BattleSession extends ChangeNotifier {
  final BattleEngine engine;
  BattleState state;

  /// 1倍・2倍などの速さ。
  double speed = 1.0;
  bool paused = false;

  /// 選択中のマス（設置枠、または施設のあるマス）。
  GridPos? selected;

  /// 直近のイベント（新しい順に最大 [maxLog] 件）。効果音・表示の通知に使う。
  final List<BattleEvent> log = [];
  static const maxLog = 40;

  BattleSession(this.engine) : state = engine.start();

  bool get isOver => state.isOver;
  bool get won => state.phase == BattlePhase.victory;
  bool get inPrep => state.phase == BattlePhase.prep;

  /// 選択中のマスにある施設。
  Facility? get selectedFacility => selected == null ? null : state.facilities[selected];

  void _add(Iterable<BattleEvent> events) {
    if (events.isEmpty) return;
    log.insertAll(0, events.toList().reversed);
    if (log.length > maxLog) log.removeRange(maxLog, log.length);
  }

  /// [seconds] 秒ぶん進める（一時停止中・終了後は進めない）。
  void tick(double seconds) {
    if (paused || isOver || seconds <= 0) return;
    final r = engine.advance(state, seconds * speed);
    state = r.state;
    _add(r.events);
    notifyListeners();
  }

  void setSpeed(double v) {
    speed = v;
    notifyListeners();
  }

  void togglePause() {
    paused = !paused;
    notifyListeners();
  }

  void select(GridPos? p) {
    selected = p;
    notifyListeners();
  }

  /// マスをタップしたときの選択（設置枠か施設のあるマスだけ選べる。同じマスをもう一度で解除）。
  void tapCell(GridPos p) {
    final ok = engine.stage.slots.contains(p) || state.facilities.containsKey(p);
    selected = !ok || selected == p ? null : p;
    notifyListeners();
  }

  bool _apply(BattleState? next) {
    if (next == null) return false;
    state = next;
    notifyListeners();
    return true;
  }

  /// 選択中の設置枠に施設を置く。
  bool place(FacilityType type) => selected != null && _apply(engine.place(state, type, selected!));

  bool placeExclusive() => selected != null && _apply(engine.placeExclusive(state, selected!));

  bool upgrade() => selected != null && _apply(engine.upgrade(state, selected!));

  bool remove() {
    final ok = selected != null && _apply(engine.remove(state, selected!));
    if (ok) selected = null;
    return ok;
  }

  /// 修理。[correct] が null ならコインで修理、true/false ならクイズの結果で修理する。
  bool repair({bool? correct}) {
    if (selected == null) return false;
    return _apply(correct == null ? engine.repair(state, selected!) : engine.repairByQuiz(state, selected!, correct: correct));
  }

  /// 準備を飛ばして波を始める。
  void startWave() {
    if (!inPrep) return;
    final r = engine.startWave(state);
    state = r.state;
    _add(r.events);
    notifyListeners();
  }

  // ── スキル選択 ──

  /// いま選べるスキルの候補（準備中でまだ選んでいないとき）。
  List<String> get skillChoices => engine.skillChoices(state);

  /// スキルを選ぶ前にクイズが必要か。
  bool get skillNeedsQuiz => engine.assistEnabled && skillChoices.isNotEmpty && !state.skillUnlocked;

  Question? get skillQuestion => engine.assistQuestion(state);

  Question? repairQuestion(GridPos pos) => engine.assistQuestion(state, forRepair: pos);

  /// スキル選択のクイズの結果を反映する。
  void answerSkillQuiz({required bool correct}) {
    state = engine.resolveSkillQuiz(state, correct: correct);
    notifyListeners();
  }

  bool chooseSkill(String id) => _apply(engine.chooseSkill(state, id));
}
