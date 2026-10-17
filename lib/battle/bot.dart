import 'dart:math' as math;

import '../quiz/rng.dart';
import 'battle_engine.dart';
import 'grid.dart';
import 'stage.dart';

/// 自動対戦のボットの強さ。バランス確認（設計書 §8）で、プレイヤーの腕前の代わりに使う。
class BotProfile {
  final String name;
  final double accuracy; // クイズの正解率
  final int thinkTicks; // 何刻みごとに操作するか（大きいほど反応が遅い）
  final double spendRatio; // 持っているコインのうち、使ってよい割合（1.0=全部使う）
  const BotProfile(this.name, {this.accuracy = 0.8, this.thinkTicks = 30, this.spendRatio = 1.0});

  static const casual = BotProfile('casual', accuracy: 0.55, thinkTicks: 90, spendRatio: 0.7);
  static const regular = BotProfile('regular', accuracy: 0.8, thinkTicks: 45);
  static const expert = BotProfile('expert', accuracy: 0.95, thinkTicks: 15);
}

class BotResult {
  final bool won;
  final int wave, waves, baseHp, maxBaseHp, facilities, mistakes;
  final double seconds;
  const BotResult(this.won, this.wave, this.waves, this.baseHp, this.maxBaseHp, this.facilities, this.mistakes, this.seconds);
}

/// 決定的な自動対戦のボット。設置枠の良さ（進路に近い）で場所を選び、施設を順に置いて強化し、スキルと修理を使う。
class BattleBot {
  final BattleEngine engine;
  final BotProfile profile;
  BattleBot(this.engine, this.profile);

  Stage get _stage => engine.stage;

  /// 敵の構成（このステージの全波の種類の割合）に対して、コインあたりの与ダメージが大きい施設を選ぶ。
  late final Map<String, double> _mix = () {
    final c = <String, int>{};
    for (final w in _stage.waves) {
      for (final k in w.enemyKinds) {
        c[k] = (c[k] ?? 0) + 1;
      }
    }
    final n = c.values.fold(0, (a, b) => a + b);
    return {for (final e in c.entries) e.key: e.value / n};
  }();

  double _value(FacilityType t) {
    final fs = engine.facilityStats(Facility(t, const GridPos(0, 0)));
    var eff = 0.0;
    for (final e in _mix.entries) {
      final armor = (enemyBase[e.key]!.armor + (engine.profile?.enemyOf(e.key).armor ?? 0)).toDouble();
      final ignore = fs.action == 'pierce' ? BattleEngine.pierceArmorIgnore : 0.0;
      eff += e.value * math.max(1.0, fs.damage - armor * (1 - ignore));
    }
    final area = fs.action == 'splash' ? 1.5 : (fs.action == 'chain' ? 1.4 : 1.0);
    return eff * area / fs.cooldown * (1 + (fs.range - 1) * 0.15) / engine.costOf(t);
  }

  /// 手持ちで買える中で、いちばん効率が良い施設。買えるものがなければ null。
  FacilityType? _pick(BattleState st, int budget) {
    final mine = [for (final f in st.facilities.values) if (f.exclusive == null) f.type];
    final cap = (mine.length / 3).ceil() + 1; // 1種類に偏りすぎない
    final candidates = [for (final t in FacilityType.values) if (t != FacilityType.shrine && engine.costOf(t) <= budget) t]
      ..sort((a, b) => _value(b) != _value(a) ? _value(b).compareTo(_value(a)) : a.index.compareTo(b.index));
    for (final t in candidates) {
      if (mine.where((x) => x == t).length < cap) return t;
    }
    return candidates.isEmpty ? null : candidates.first;
  }
  static const _skillPreference = ['waveAtkBonus', 'waveAtkSpeedBonus', 'waveCoinBonus', 'slow', 'waveRangeBonus', 'repair', 'weatherBlock'];

  late final List<GridPos> _rankedSlots = _rank();

  /// 設置枠を、近くを通る進路のマスの多さ（拠点に近いほど重い）で並べる。
  List<GridPos> _rank() {
    double score(GridPos s) {
      var v = 0.0;
      for (final p in _stage.paths) {
        for (var i = 0; i < p.length; i++) {
          final d = math.sqrt(math.pow(p[i].col - s.col, 2) + math.pow(p[i].row - s.row, 2));
          if (d <= 2.2) v += 1.0 + i / p.length;
        }
      }
      return v;
    }

    final keyed = [for (final s in _stage.slots) (s, score(s))];
    keyed.sort((a, b) => b.$2 != a.$2 ? b.$2.compareTo(a.$2) : a.$1.compareTo(b.$1));
    return [for (final k in keyed) k.$1];
  }

  bool _right(BattleState s, String tag) =>
      fnv1a('${_stage.seed}|bot|${profile.name}|$tag|${s.wave}|${s.tickCount}') / 4294967296.0 < profile.accuracy;

  /// 1回ぶんの操作（スキル→修理→購入→強化）。
  BattleState act(BattleState s) {
    var st = s;
    // スキル（準備中）
    final choices = engine.skillChoices(st);
    if (choices.isNotEmpty) {
      if (engine.assistEnabled) st = engine.resolveSkillQuiz(st, correct: _right(st, 'skill'));
      if (st.skill == null) {
        final pick = _skillPreference.firstWhere(choices.contains, orElse: () => choices.first);
        st = engine.chooseSkill(st, pick) ?? st;
      }
    }
    // 修理（hard）
    for (final pos in st.facilities.keys.toList()..sort()) {
      final f = st.facilities[pos]!;
      if (engine.repairCostOf(f) == null) continue;
      final r = engine.assistEnabled ? engine.repairByQuiz(st, pos, correct: _right(st, 'repair${pos.col},${pos.row}')) : engine.repair(st, pos);
      if (r != null) st = r;
    }
    var budget = (st.coins * profile.spendRatio).floor();
    // 限定施設（1つ）
    final exCost = engine.exclusiveCostOf();
    if (exCost != null && budget >= exCost && st.facilities.length >= 3 && !st.facilities.values.any((f) => f.exclusive != null)) {
      for (final pos in _rankedSlots) {
        if (st.facilities.containsKey(pos)) continue;
        final r = engine.placeExclusive(st, pos);
        if (r != null) {
          budget -= exCost;
          st = r;
        }
        break;
      }
    }
    // 購入と強化。レベル1→2は新しい施設より割安なので、最初の4つを置いたら先に強化する
    var guard = 0;
    while (guard++ < 20) {
      final free = _rankedSlots.where((p) => !st.facilities.containsKey(p)).toList();
      final normalFacs = [for (final f in st.facilities.values) if (f.exclusive == null) f];
      final type = _pick(st, math.min(budget, st.coins));
      final cost = type == null ? 1 << 30 : engine.costOf(type);

      GridPos? upgradeAt(int level) {
        for (final pos in _rankedSlots) {
          final f = st.facilities[pos];
          if (f != null && f.exclusive == null && f.level == level) return pos;
        }
        return null;
      }

      bool tryUpgrade(int level) {
        final pos = upgradeAt(level);
        if (pos == null) return false;
        final c = engine.upgradeCostOf(st.facilities[pos]!);
        if (c == null || budget < c || st.coins < c) return false;
        st = engine.upgrade(st, pos) ?? st;
        budget -= c;
        return true;
      }

      bool tryPlace() {
        if (type == null || free.isEmpty || budget < cost || st.coins < cost) return false;
        final r = engine.place(st, type, free.first);
        if (r == null) return false;
        st = r;
        budget -= cost;
        return true;
      }

      if (normalFacs.length < 4 && tryPlace()) continue;
      if (tryUpgrade(1)) continue;
      if (tryPlace()) continue;
      if (tryUpgrade(2)) continue;
      break;
    }
    return st;
  }

  /// 最後まで遊ぶ。[maxSeconds] を超えたら、そこで止めて負け扱いにする。
  BotResult play({double maxSeconds = 1800}) {
    var s = engine.start();
    var ticks = 0;
    final limit = (maxSeconds / BattleEngine.step).round();
    while (!s.isOver && ticks < limit) {
      if (ticks % profile.thinkTicks == 0) s = act(s);
      s = engine.tick(s, BattleEngine.step).state;
      ticks++;
    }
    return BotResult(s.phase == BattlePhase.victory, s.wave, _stage.waves.length, s.baseHp, _stage.baseHp,
        s.facilities.length, s.mistakes, s.time);
  }
}
