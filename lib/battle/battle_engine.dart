import 'dart:math' as math;

import '../pack/country_profile.dart';
import 'battle_model.dart';
import 'difficulty.dart';
import 'grid.dart';
import 'stage.dart';

export 'battle_model.dart';

/// バトルの計算（設計書 §6）。画面に依存しない純粋な計算で、乱数を使わないので、同じステージ・同じ操作なら同じ結果になる。
/// M2: 敵の移動・施設の攻撃（単体・範囲）・経済・勝敗。敵の能力と行動、ほかの撃ち方、天候・季節・限定施設、
/// ハードの施設への攻撃、スキル、クイズ連動は M3 以降。
class BattleEngine {
  final Stage stage;
  final CountryProfile? profile;
  BattleEngine(this.stage, {this.profile});

  /// 固定の時間刻み。画面のフレームレートに依存しないよう、[advance] はこの刻みで進める。
  static const step = 1 / 30;

  /// 範囲攻撃（splash）の半径（マス）と、巻き込んだ敵へのダメージの割合。M2の暫定値。
  static const splashRadius = 1.0, splashRatio = 0.6;

  DifficultyParams get _params => difficultyParams[stage.difficulty]!;

  // ── 開始・操作 ───────────────────────────────────────────

  BattleState start() => BattleState(
        phase: BattlePhase.prep,
        wave: 0,
        prepTimer: _params.waveBreakSeconds,
        spawned: 0,
        spawnAcc: 0,
        enemies: const [],
        facilities: const {},
        coins: (startCoinsBase[stage.difficulty]! * (profile?.startCoins ?? 1.0)).round(),
        baseHp: stage.baseHp,
        score: 0,
        mistakes: 0,
        time: 0,
      );

  /// 施設の値段（国の倍率を適用）。
  int costOf(FacilityType t) => math.max(1, (facilityBase[t]!.cost * (profile?.facilityCost ?? 1.0)).round());

  /// 施設を置く。置けなければ null（設置枠でない・すでに施設がある・コイン不足・終了後）。
  BattleState? place(BattleState s, FacilityType type, GridPos pos) {
    if (s.isOver || !stage.slots.contains(pos) || s.facilities.containsKey(pos)) return null;
    final cost = costOf(type);
    if (s.coins < cost) return null;
    return s.copyWith(coins: s.coins - cost, facilities: {...s.facilities, pos: Facility(type, pos)});
  }

  /// 準備を飛ばして、次の波を始める（準備中だけ）。
  TickResult startWave(BattleState s) {
    if (s.phase != BattlePhase.prep) return (state: s, events: const []);
    final events = <BattleEvent>[];
    return (state: _beginWave(s, events), events: events);
  }

  // ── 性能 ────────────────────────────────────────────────

  /// 施設の実効の性能（国の攻撃アクション・地域のボーナスを適用）。
  ({int damage, double range, double cooldown, String action}) facilityStats(Facility f) {
    final base = facilityBase[f.type]!;
    final act = profile?.attackActions[f.type.name];
    final bonus = profile?.traitOf(stage.regionId).facilityBonus[f.type.name] ?? 1.0;
    final dmg = base.damage * f.level * (act?.damage ?? 1.0) * bonus;
    return (
      damage: math.max(1, dmg.round()),
      range: (base.range + (f.level - 1) * 0.2) * (act?.range ?? 1.0),
      cooldown: (1 / base.attackSpeed) * (act?.cooldown ?? 1.0),
      action: act?.action ?? 'single',
    );
  }

  /// 敵の性能（難易度・国の敵の特性を適用）。[index] は波の中の何番目か（最後がボス）。
  Enemy makeEnemy(StageWave w, int index) {
    final kind = w.enemyKinds[index];
    final isBoss = w.hasBoss && index == w.enemyCount - 1;
    final b = enemyBase[kind]!;
    final t = profile?.enemyOf(kind);
    final hp = isBoss ? (w.baseHp * 2.5).round() : (w.baseHp * b.hpMult * (t?.hp ?? 1.0)).round();
    final speed = b.speedMult * (isBoss ? 0.6 : 1.2) * (t?.speed ?? 1.0) * _params.speedMultiplier;
    // 拠点への被害: 既存の規則（easyは常に1。ボス・装甲は重い）× 国の倍率
    final heavy = _params.heavyBreach;
    final base = !heavy ? 1 : (isBoss ? (stage.difficulty == Difficulty.hard ? 3 : 2) : (kind == 'armored' ? 2 : 1));
    return Enemy(
      id: 'e${w.number}_$index',
      kind: kind,
      pathIndex: w.entranceIndices[index % w.entranceIndices.length],
      hp: math.max(1, hp),
      maxHp: math.max(1, hp),
      speed: speed,
      progress: 0,
      isBoss: isBoss,
      armor: b.armor + (t?.armor ?? 0),
      breachDamage: math.max(1, (base * (t?.baseDamage ?? 1.0)).round()),
    );
  }

  int _killReward(Enemy e, int wave) {
    final base = e.isBoss ? 60 + wave * 5 : 12 + wave * 3;
    return math.max(1, (base * _params.rewardMultiplier * (profile?.income ?? 1.0)).round());
  }

  // ── 進める ──────────────────────────────────────────────

  /// [seconds] 秒ぶん、固定の刻みで進める。勝敗が決まったら止まる。
  TickResult advance(BattleState s, double seconds) {
    final events = <BattleEvent>[];
    var st = s;
    var left = seconds;
    while (left > 1e-9 && !st.isOver) {
      final dt = math.min(step, left);
      final r = tick(st, dt);
      st = r.state;
      events.addAll(r.events);
      left -= dt;
    }
    return (state: st, events: events);
  }

  /// 勝敗が決まるまで進める（自動対戦・テスト用）。[maxSeconds] を超えたら、そこで止める。
  TickResult runToEnd(BattleState s, {double maxSeconds = 3600}) {
    final events = <BattleEvent>[];
    var st = s;
    var t = 0.0;
    while (!st.isOver && t < maxSeconds) {
      final r = tick(st, step);
      st = r.state;
      events.addAll(r.events);
      t += step;
    }
    return (state: st, events: events);
  }

  /// 1刻み進める。順序は、出現→移動→施設の攻撃→撃破→拠点への到達→勝敗（設計書 §6.3）。
  TickResult tick(BattleState s, double dt) {
    if (s.isOver) return (state: s, events: const []);
    final events = <BattleEvent>[];
    var st = s.copyWith(time: s.time + dt);

    if (st.phase == BattlePhase.prep) {
      final left = st.prepTimer - dt;
      if (left > 0) return (state: st.copyWith(prepTimer: left), events: events);
      st = _beginWave(st, events);
    }

    final w = stage.waves[st.wave - 1];

    // 1. 出現
    var enemies = [...st.enemies];
    var spawned = st.spawned;
    var acc = st.spawnAcc + dt;
    while (spawned < w.enemyCount && acc >= w.spawnInterval) {
      acc -= w.spawnInterval;
      final e = makeEnemy(w, spawned);
      enemies.add(e);
      events.add(BattleEvent(BattleEventType.spawn, enemyId: e.id, isBoss: e.isBoss));
      spawned++;
    }

    // 2. 移動
    enemies = [for (final e in enemies) e.copyWith(progress: e.progress + e.speed * dt)];

    // 3. 施設の攻撃（置いた順でなく、位置の順。決定的）
    var coins = st.coins, score = st.score;
    final facilities = <GridPos, Facility>{...st.facilities};
    final order = facilities.keys.toList()..sort();
    final hpOf = {for (final e in enemies) e.id: e.hp};
    for (final pos in order) {
      var f = facilities[pos]!;
      var cd = f.cooldown - dt;
      if (cd <= 0) {
        final fs = facilityStats(f);
        Enemy? target;
        ({double x, double y})? tp;
        for (final e in enemies) {
          if ((hpOf[e.id] ?? 0) <= 0) continue;
          final p = e.position(stage.paths[e.pathIndex]);
          final d = math.sqrt(math.pow(p.x - pos.col, 2) + math.pow(p.y - pos.row, 2));
          if (d > fs.range) continue;
          // 拠点にいちばん近い敵（進んだ距離が大きい）。同じなら id の順。
          if (target == null || e.progress > target.progress || (e.progress == target.progress && e.id.compareTo(target.id) < 0)) {
            target = e;
            tp = p;
          }
        }
        if (target != null) {
          void hit(Enemy e, int raw) {
            final dmg = math.max(1, raw - e.armor);
            hpOf[e.id] = hpOf[e.id]! - dmg;
            events.add(BattleEvent(BattleEventType.hit, enemyId: e.id, facilityPos: pos, value: dmg));
          }

          hit(target, fs.damage);
          if (fs.action == 'splash') {
            for (final e in enemies) {
              if (e.id == target.id || (hpOf[e.id] ?? 0) <= 0) continue;
              final p = e.position(stage.paths[e.pathIndex]);
              if (math.sqrt(math.pow(p.x - tp!.x, 2) + math.pow(p.y - tp.y, 2)) <= splashRadius) {
                hit(e, (fs.damage * splashRatio).round());
              }
            }
          }
          cd = fs.cooldown;
        } else {
          cd = 0; // 撃てる敵がいなければ、準備完了のまま待つ
        }
      }
      facilities[pos] = f.copyWith(cooldown: cd);
    }

    // 4. 撃破（コイン・スコア）
    final alive = <Enemy>[];
    for (final e in enemies) {
      final hp = hpOf[e.id]!;
      if (hp <= 0) {
        final reward = _killReward(e, st.wave);
        coins += reward;
        score += e.isBoss ? 200 : 50;
        events.add(BattleEvent(BattleEventType.kill, enemyId: e.id, value: reward, isBoss: e.isBoss));
      } else {
        alive.add(e.copyWith(hp: hp));
      }
    }

    // 5. 拠点への到達
    var baseHp = st.baseHp, mistakes = st.mistakes;
    final remain = <Enemy>[];
    for (final e in alive) {
      if (e.progress >= stage.paths[e.pathIndex].length - 1) {
        baseHp -= e.breachDamage;
        mistakes++;
        events.add(BattleEvent(BattleEventType.breach, enemyId: e.id, value: e.breachDamage, isBoss: e.isBoss));
      } else {
        remain.add(e);
      }
    }

    st = st.copyWith(
      enemies: remain, facilities: facilities, coins: coins, score: score, baseHp: baseHp,
      mistakes: mistakes, spawned: spawned, spawnAcc: acc,
    );

    // 6. 勝敗・波の終わり
    if (baseHp <= 0) {
      events.add(const BattleEvent(BattleEventType.defeat));
      return (state: st.copyWith(phase: BattlePhase.defeat, baseHp: 0), events: events);
    }
    if (spawned >= w.enemyCount && remain.isEmpty) {
      events.add(BattleEvent(BattleEventType.waveClear, value: w.number));
      if (w.number >= stage.waves.length) {
        events.add(const BattleEvent(BattleEventType.victory));
        return (state: st.copyWith(phase: BattlePhase.victory), events: events);
      }
      return (state: st.copyWith(phase: BattlePhase.prep, prepTimer: _params.waveBreakSeconds, spawned: 0, spawnAcc: 0), events: events);
    }
    return (state: st, events: events);
  }

  BattleState _beginWave(BattleState s, List<BattleEvent> events) {
    final n = s.wave + 1;
    events.add(BattleEvent(BattleEventType.waveStart, value: n));
    return s.copyWith(phase: BattlePhase.wave, wave: n, spawned: 0, spawnAcc: 0, prepTimer: 0);
  }
}
