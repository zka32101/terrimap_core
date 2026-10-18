import 'package:flutter/foundation.dart';

import '../battle/battle_engine.dart';
import '../battle/replay.dart';

/// リプレイの再生役（設計書 §6.13）。[BattleSession] と同じく、時間は画面のフレームから [tick] で渡す。
/// 記録の操作を、記録された刻み（`tickCount`）で適用するので、遊んだときと同じ結果になる。
class ReplayPlayer extends ChangeNotifier {
  final BattleEngine engine;
  final Replay replay;
  BattleState state;

  double speed = 1.0;
  bool paused = false;

  /// 記録の操作が適用できなかった（改ざん・版違い）。再生は止まる。
  bool corrupt = false;

  /// 直近のイベント（新しい順に最大 [maxLog] 件）。
  final List<BattleEvent> log = [];
  static const maxLog = 40;

  int _next = 0; // 次に適用する操作
  double _acc = 0; // 刻みに満たない残りの時間

  ReplayPlayer(this.engine, this.replay) : state = engine.start() {
    _applyDue(const []);
  }

  bool get isOver => state.isOver;
  bool get won => state.phase == BattlePhase.victory;
  bool get finished => isOver || corrupt;

  /// 再生した結果が、記録された結果と一致しているか（終わってから意味を持つ）。
  bool get matchesRecorded => isOver && ReplayResult.of(state, const []).won == replay.result.won && state.baseHp == replay.result.baseHp && state.score == replay.result.score;

  /// 進み具合（0〜1）。波の数で見る。
  double get progress => isOver ? 1.0 : (state.wave / engine.stage.waves.length).clamp(0.0, 1.0);

  void _applyDue(List<BattleEvent> events) {
    while (!corrupt && _next < replay.ops.length && replay.ops[_next].tick <= state.tickCount) {
      final op = replay.ops[_next++];
      if (op.kind == ReplayOp.startWave) {
        final r = engine.startWave(state);
        state = r.state;
        events.addAll(r.events);
        continue;
      }
      final n = op.apply(engine, state);
      if (n == null) {
        corrupt = true;
      } else {
        state = n;
      }
    }
  }

  void _step(List<BattleEvent> events) {
    _applyDue(events);
    if (corrupt || state.isOver) return;
    final r = engine.tick(state, BattleEngine.step);
    state = r.state;
    events.addAll(r.events);
  }

  void _add(List<BattleEvent> events) {
    if (events.isEmpty) return;
    log.insertAll(0, events.reversed);
    if (log.length > maxLog) log.removeRange(maxLog, log.length);
  }

  /// [seconds] 秒ぶん進める（一時停止中・終了後は進めない）。
  void tick(double seconds) {
    if (paused || finished || seconds <= 0) return;
    _acc += seconds * speed;
    final events = <BattleEvent>[];
    while (_acc >= BattleEngine.step - 1e-9 && !finished) {
      _step(events);
      _acc -= BattleEngine.step;
    }
    if (finished) _acc = 0;
    _add(events);
    notifyListeners();
  }

  /// 最後まで一気に進める（[maxSeconds] を超えたら止める）。
  void skipToEnd({double maxSeconds = 3600}) {
    final events = <BattleEvent>[];
    var t = 0.0;
    while (!finished && t < maxSeconds) {
      _step(events);
      t += BattleEngine.step;
    }
    _acc = 0;
    _add(events);
    notifyListeners();
  }

  /// 最初から見直す。
  void restart() {
    state = engine.start();
    _next = 0;
    _acc = 0;
    corrupt = false;
    log.clear();
    paused = false;
    _applyDue(const []);
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
}
