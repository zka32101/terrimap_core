import 'dart:math' as math;

import '../pack/country_profile.dart';
import '../pack/region_pack.dart';
import '../quiz/quiz_engine.dart';
import '../quiz/rng.dart';
import 'battle_model.dart';
import 'difficulty.dart';
import 'exclusive.dart';
import 'grid.dart';
import 'signature.dart';
import 'stage.dart';
import 'weather.dart';

export 'battle_model.dart';

/// バトルの計算（設計書 §6）。画面に依存しない純粋な計算で、乱数は seed と刻みから決まる（クリティカル）ので、
/// 同じステージ・同じ操作なら同じ結果になる。
/// 入っているもの: 敵の移動・能力（shield・regen・swarm・flying・disrupt）・行動（heal_aura・ranged_disable・sabotage）・ボスのスキル、
/// 施設の攻撃（single・splash・chain・pierce・slow・burn）・クリティカル・アップグレード・撤去、経済、勝敗。
/// 限定施設（placeExclusive）、hard の施設の耐久・敵の攻撃・修理（repair）、スキル選択（skillChoices・chooseSkill）、天候（予告→開始→終了）と季節も入っている。クイズ連動は M3.6 以降。
class BattleEngine {
  final Stage stage;
  final CountryProfile? profile;
  /// クイズ連動（設計書 §6.12）に使う pack。省略するとクイズ連動は使えない。
  final RegionPack? pack;

  /// 国の目玉（`profile.signature.id`）。バトルの計算は、この窓口の倍率だけを使う。
  late final SignatureRule signature = SignatureRule.create(profile?.signatureId, stage: stage, pack: pack, profile: profile);

  /// クイズ連動のオン/オフ（設定）。オフなら、スキルは3つから選べ、修理はコインだけ。
  final bool quizAssist;

  /// 復習: 州ごとの出題の重み（[battleReviewWeights]）。渡すと、間違えた州がクイズ連動で出やすくなる。
  /// 問題の中身だけが変わり、戦闘の計算には影響しない（リプレイは正解・不正解の記録だけで再現できる）。
  final Map<String, double>? reviewWeights;
  BattleEngine(this.stage, {this.profile, this.pack, this.quizAssist = true, this.reviewWeights});

  /// クイズ連動が有効か。
  bool get assistEnabled => pack != null && quizAssist;

  /// 答える制限時間（秒）。hard だけ10秒で、ほかは時間制限なし（null）。時間切れは不正解として扱う（判定は画面側）。
  double? get assistTimeLimit => stage.difficulty == Difficulty.hard ? 10 : null;

  /// 固定の時間刻み。画面のフレームレートに依存しないよう、[advance] はこの刻みで進める。
  static const step = 1 / 30;

  // ── 調整用の数値（暫定。M4の自動対戦で調整する）──────────────
  static const splashRadius = 1.0, splashRatio = 0.6; // 範囲攻撃
  static const chainRatios = [0.7, 0.5], chainRadius = 1.5; // 連鎖: 2体目・3体目への割合と、跳ねる距離
  static const pierceArmorIgnore = 0.6; // 貫通: 装甲を無視する割合
  static const slowFactor = 0.6, slowSeconds = 2.0; // 鈍足
  static const burnRatio = 0.3, burnSeconds = 3.0; // 継続ダメージ: 威力の30%を毎秒、3秒
  static const critChance = 0.15, critMultiplier = 2.0;
  static const shieldMultiplier = 0.5; // shield: 最初の一撃
  static const regenInterval = 2.0, regenRatio = 0.04; // regen: 2秒ごとに最大HPの4%
  static const healAuraInterval = 3.0, healAuraRadius = 2.0, healAuraRatio = 0.05;
  static const disableInterval = 6.0, disableRadius = 3.0, disableSeconds = 3.0; // ranged_disable
  static const sabotageInterval = 8.0, sabotageRadius = 2.5, sabotageSeconds = 4.0, sabotageRatio = 0.5;
  static const disruptRadius = 2.0, disruptRange = 0.7; // disrupt: 近くの施設の射程を縮める
  static const swarmHp = 0.6; // swarm: 1体あたりのHPの割合（1回の出現で2体）
  static const bossSkillInterval = 8.0, bossHasteSeconds = 3.0, bossHasteFactor = 1.8, bossHealRatio = 0.10;
  static const bossSummonCount = 2, bossSummonHp = 0.5;
  // 地方決戦・エクストラは盤面が広く波も多いので、開始コインと撃破コインを増やす
  static const regionalCoins = 1.6, regionalReward = 1.3;
  // 進路の長さによる速さの補正: 短い進路は遅く、長い進路は速くして、拠点までかかる時間を近づける
  static const lengthReference = 25.0, lengthFactorMin = 0.6, lengthFactorMax = 1.25;
  static const upgradeCostRatio = 0.75, refundRatio = 0.6;
  // スキル（波の合間に3つから1つ選ぶ。効果は次の波だけ）
  static const waveSkills = ['waveAtkBonus', 'waveRangeBonus', 'waveCoinBonus', 'waveAtkSpeedBonus', 'slow', 'weatherBlock'];
  static const hardOnlySkills = ['repair'];
  static const skillChoiceCount = 3;
  /// クイズ正解の一時バフ（仮の数値）: 攻撃 +20%、10秒、連続正解で段数が増え最大 +50%。
  static const quizBuffSeconds = 10.0, quizBuffStep = 0.2, quizBuffMax = 0.5;
  static double quizBuffBonus(BattleState s) => s.time < s.buffUntil ? math.min(quizBuffMax, quizBuffStep + (s.buffStacks - 1) * 0.1) : 0;
  BattleState _withBuff(BattleState s) {
    final stacks = s.time < s.buffUntil ? s.buffStacks + 1 : 1;
    return s.copyWith(buffUntil: s.time + quizBuffSeconds, buffStacks: stacks);
  }

  static const skillAtkBonus = 1.25, skillRangeBonus = 1.0, skillCoinBonus = 1.2, skillAtkSpeedBonus = 1.15, skillSlowFactor = 0.8;
  // hard: 施設の耐久と、敵の施設への攻撃（設計書 §6.2）
  static const facilityHpFactor = 1.5, castleHpFactor = 1.5, exclusiveHpFactor = 2.0; // 施設HP = 1波の基礎HP × 係数 × レベル
  static const enemyAttackRatio = 0.10, enemyAttackInterval = 1.5, enemyAttackRange = 1.0, enemyRangedAttackRange = 1.3; // 攻撃力 = 波の基礎HP × 比率 × 種類の倍率
  static const bossAttackFactor = 1.5, bossAoeRadius = 1.5;
  static const protectRatio = 0.7, protectRadius = 1.5; // 城・象徴が周囲の施設を守る（受ける被害 ×0.7）
  static const shrineHealRatio = 0.04, shrineHealInterval = 2.0, shrineHealRadius = 1.5;
  static const destroyRefundRatio = 0.5, repairCostRatio = 0.5;
  // 限定施設
  static const coreRadius = 1.5, coreBoost = 1.15;
  static const portRadius = 2.5, portSlow = 0.7;
  static const resourceCoin = 1.15;
  static const breweryRadius = 2.0, breweryDamageRatio = 0.06; // 1秒ごとに、その波の基礎HPの6%
  static const symbolHealInterval = 10.0;
  static const bossSkills = ['speedBurst', 'hpRegen', 'summon', 'stunFacility'];

  /// [wave]（1始まり）の季節の効果。エクストラは波ごとに季節が巡る。
  SeasonEffect _seasonAt(int wave) => Weather.seasons[stage.seasonAt(wave)]!;

  DifficultyParams get _params => difficultyParams[stage.difficulty]!;

  /// この地域のボスのスキル（地域idから決まる）。
  String get bossSkill => stage.bossSkill ?? bossSkills[fnv1a(stage.regionId) % bossSkills.length];

  // ── 開始・操作 ───────────────────────────────────────────

  BattleState start() => BattleState(
        phase: BattlePhase.prep,
        wave: 0,
        prepTimer: _params.waveBreakSeconds,
        spawned: 0,
        spawnAcc: 0,
        enemies: const [],
        facilities: const {},
        coins: (startCoinsBase[stage.difficulty]! * (profile?.startCoins ?? 1.0) * (stage.kind != StageKind.normal ? regionalCoins : 1.0)).round(),
        baseHp: stage.baseHp,
        score: 0,
        mistakes: 0,
        time: 0,
      );

  /// 施設の値段（国の倍率を適用）。
  int costOf(FacilityType t) => math.max(1, (facilityBase[t]!.cost * (profile?.facilityCost ?? 1.0)).round());

  /// 強化の値段（現在のレベル→次のレベル）。最大レベルなら null。
  int? upgradeCostOf(Facility f) =>
      f.level >= maxFacilityLevel ? null : math.max(1, (costOf(f.type) * f.level * upgradeCostRatio).round());

  /// 施設を置く。置けなければ null（設置枠でない・すでに施設がある・コイン不足・終了後）。
  BattleState? place(BattleState s, FacilityType type, GridPos pos) {
    if (s.isOver || !stage.slots.contains(pos) || s.facilities.containsKey(pos)) return null;
    final cost = costOf(type);
    if (s.coins < cost) return null;
    final f = Facility(type, pos, invested: cost);
    return s.copyWith(coins: s.coins - cost, facilities: {...s.facilities, pos: f.copyWith(hp: maxHpOf(f))});
  }

  /// このステージで置ける限定施設のid（重複なし）。通常は1つ、地方決戦は州ごと。
  List<String> get exclusiveIds => stage.exclusiveFacilities.isNotEmpty
      ? stage.exclusiveFacilities.toSet().toList()
      : [if (stage.exclusiveFacility != null) stage.exclusiveFacility!];

  /// まだ置いていない限定施設のid（置ける順）。
  List<String> exclusiveLeft(BattleState s) {
    final placed = {for (final f in s.facilities.values) if (f.exclusive != null) f.exclusive!};
    return [for (final id in exclusiveIds) if (!placed.contains(id)) id];
  }

  /// 限定施設を置く。[id] を省くと、まだ置いていない最初のもの。置けなければ null
  /// （限定施設がない・同じものがすでにある・設置枠でない・コイン不足）。
  BattleState? placeExclusive(BattleState s, GridPos pos, {String? id}) {
    final left = exclusiveLeft(s);
    final pick = id ?? (left.isEmpty ? null : left.first);
    final kind = exclusiveKinds[pick];
    if (pick == null || kind == null || !left.contains(pick) || s.isOver || !stage.slots.contains(pos) || s.facilities.containsKey(pos)) return null;
    final cost = exclusiveCostOf(pick);
    if (cost == null || s.coins < cost) return null;
    final f = Facility(FacilityType.castle, pos, invested: cost, exclusive: pick);
    return s.copyWith(coins: s.coins - cost, facilities: {...s.facilities, pos: f.copyWith(hp: maxHpOf(f))});
  }

  /// 限定施設の値段（[id] を省くと、このステージの最初のもの。なければ null）。
  int? exclusiveCostOf([String? id]) {
    final kind = exclusiveKinds[id ?? (exclusiveIds.isEmpty ? null : exclusiveIds.first)];
    if (kind == null) return null;
    return math.max(1, (exclusiveSpecs[kind]!.cost * (profile?.facilityCost ?? 1.0)).round());
  }

  /// 施設の最大耐久。hard 以外は 0（壊れない）。
  int maxHpOf(Facility f) {
    if (stage.difficulty != Difficulty.hard) return 0;
    final base = stage.waves.first.baseHp * facilityHpFactor * f.level;
    final k = f.exclusive != null ? exclusiveHpFactor : (f.type == FacilityType.castle ? castleHpFactor : 1.0);
    return math.max(1, (base * k).round());
  }

  /// 修理の値段（不足分の割合 × 使ったコイン × 0.5）。耐久がない・満タンなら null。
  int? repairCostOf(Facility f) {
    final max = maxHpOf(f);
    if (max == 0 || f.hp >= max) return null;
    return math.max(1, ((max - f.hp) / max * f.invested * repairCostRatio).ceil());
  }

  /// 施設を修理する（満タンまで）。できなければ null。
  BattleState? repair(BattleState s, GridPos pos) {
    final f = s.facilities[pos];
    if (s.isOver || f == null) return null;
    final cost = repairCostOf(f);
    if (cost == null || s.coins < cost) return null;
    return s.copyWith(coins: s.coins - cost, facilities: {...s.facilities, pos: f.copyWith(hp: maxHpOf(f))});
  }

  /// 施設を強化する（最大レベル3）。できなければ null。
  BattleState? upgrade(BattleState s, GridPos pos) {
    final f = s.facilities[pos];
    if (s.isOver || f == null || f.exclusive != null) return null;
    final cost = upgradeCostOf(f);
    if (cost == null || s.coins < cost) return null;
    return s.copyWith(coins: s.coins - cost, facilities: {...s.facilities, pos: _upgraded(f, cost)});
  }

  Facility _upgraded(Facility f, int cost) {
    final g = f.copyWith(level: f.level + 1, invested: f.invested + cost);
    return g.copyWith(hp: maxHpOf(g));
  }

  /// 施設を撤去する。使ったコインの一部が戻る。なければ null。
  BattleState? remove(BattleState s, GridPos pos) {
    final f = s.facilities[pos];
    if (s.isOver || f == null) return null;
    final next = {...s.facilities}..remove(pos);
    return s.copyWith(coins: s.coins + (f.invested * refundRatio).round(), facilities: next);
  }

  /// 次の波のスキルの候補（準備中で、まだ選んでいないときだけ）。seed と波の番号から決まる3つ。repair は hard だけ。
  List<String> skillChoices(BattleState s) {
    if (s.phase != BattlePhase.prep || s.skill != null) return const [];
    final pool = [...waveSkills, if (stage.difficulty == Difficulty.hard) ...hardOnlySkills];
    final next = s.wave + 1;
    final keyed = [for (final id in pool) (id, fnv1a('${stage.seed}|skill|$next|$id'))]..sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final k in keyed.take(skillChoiceCount)) k.$1];
  }

  /// クイズ連動の問題。ステージの州と隣の州から1問（seed・波・用途・位置で決まる）。クイズ連動が無効なら null。
  /// [forRepair] が null ならスキル選択用、施設の位置なら修理用。
  Question? assistQuestion(BattleState s, {GridPos? forRepair}) {
    if (!assistEnabled || s.isOver) return null;
    final ids = stage.memberIds.isEmpty ? [stage.regionId] : stage.memberIds;
    final regions = pack!.regions.where((r) => ids.contains(r.id)).toList();
    if (regions.isEmpty) return null;
    final pool = {...ids, for (final r in regions) ...r.neighbors};
    final seed = fnv1a('${stage.seed}|assist|${forRepair == null ? 'skill' : 'repair'}|${s.wave}|${forRepair?.col},${forRepair?.row}');
    final qs = QuizEngine(pack!, seed: seed).generate(
      count: 1,
      types: const [QuestionType.nameFromMap, QuestionType.capitalFromName, QuestionType.nameFromCapital, QuestionType.silhouette, QuestionType.neighborOf, QuestionType.landmarkOf],
      pool: pool,
      weights: reviewWeights,
    );
    return qs.isEmpty ? null : qs.first;
  }

  /// スキル選択のクイズの結果。正解なら3つから選べるようになり、不正解なら3つのうち1つが決まる。
  /// クイズ連動が無効なら何も変えない（そのまま選べる）。
  BattleState resolveSkillQuiz(BattleState s, {required bool correct}) {
    final choices = skillChoices(s);
    if (!assistEnabled || choices.isEmpty) return s;
    if (correct) return _withBuff(s.copyWith(skillUnlocked: true));
    final id = choices[fnv1a('${stage.seed}|autoskill|${s.wave + 1}') % choices.length];
    return _applySkill(s, id);
  }

  /// 修理のクイズの結果。正解なら無料、不正解ならコインを払って修理する（できなければ null）。
  BattleState? repairByQuiz(BattleState s, GridPos pos, {required bool correct}) {
    final f = s.facilities[pos];
    if (s.isOver || f == null || repairCostOf(f) == null) return null;
    if (!assistEnabled || !correct) return repair(s, pos);
    return _withBuff(s.copyWith(facilities: {...s.facilities, pos: f.copyWith(hp: maxHpOf(f))}));
  }

  /// スキルを選ぶ。候補にない・選択済みなら null。repair は選んだ時点で停止・妨害を直す。
  BattleState? chooseSkill(BattleState s, String id) {
    if (!skillChoices(s).contains(id)) return null;
    if (assistEnabled && !s.skillUnlocked) return null; // クイズに正解してから
    return _applySkill(s, id);
  }

  BattleState _applySkill(BattleState s, String id) {
    switch (id) {
      case 'repair':
        return s.copyWith(skill: id, facilities: {
          for (final e in s.facilities.entries) e.key: e.value.copyWith(disabledUntil: 0, sabotagedUntil: 0, hp: maxHpOf(e.value)),
        });
      case 'weatherBlock':
        return s.copyWith(skill: id, weatherBlocks: s.weatherBlocks + 1);
      default:
        return s.copyWith(skill: id);
    }
  }

  /// 準備を飛ばして、次の波を始める（準備中だけ）。
  TickResult startWave(BattleState s) {
    if (s.phase != BattlePhase.prep) return (state: s, events: const []);
    final events = <BattleEvent>[];
    return (state: _beginWave(s, events), events: events);
  }

  // ── 性能 ────────────────────────────────────────────────

  /// 施設の実効の性能（国の攻撃アクション・地域のボーナスを適用）。
  ({int damage, double range, double cooldown, String action}) facilityStats(Facility f, {int wave = 1}) {
    final season = _seasonAt(wave);
    final ex = f.exclusive == null ? null : exclusiveSpecs[exclusiveKinds[f.exclusive]];
    if (ex != null) return (damage: ex.damage, range: ex.range + (f.level - 1) * 0.2, cooldown: 1 / ex.attackSpeed, action: ex.action);
    final base = facilityBase[f.type]!;
    final act = profile?.attackActions[f.type.name];
    // 地方決戦では、盤面にある州の得意分野のうち、いちばん強いものを使う
    final ids = stage.memberIds.isEmpty ? [stage.regionId] : stage.memberIds;
    final bonus = ids.map((id) => profile?.traitOf(id).facilityBonus[f.type.name] ?? 1.0).reduce(math.max);
    final dmg = base.damage * f.level * (act?.damage ?? 1.0) * bonus * (season.typeDamage[f.type] ?? 1.0) * signature.facilityDamage(f.type);
    return (
      damage: math.max(1, dmg.round()),
      range: (base.range + (f.level - 1) * 0.2) * (act?.range ?? 1.0),
      cooldown: (1 / base.attackSpeed) * (act?.cooldown ?? 1.0) * (season.typeCooldown[f.type] ?? 1.0),
      action: act?.action ?? 'single',
    );
  }

  /// 進路の長さ（マス数）による敵の速さの倍率。
  double lengthFactor(int pathLength) => (pathLength / lengthReference).clamp(lengthFactorMin, lengthFactorMax);

  /// 敵の性能（難易度・国の敵の特性を適用）。[index] は波の中の何番目か（最後がボス）。
  Enemy makeEnemy(StageWave w, int index) {
    final kind = w.enemyKinds[index];
    final isBoss = w.hasBoss && index == w.enemyCount - 1;
    final b = enemyBase[kind]!;
    final t = profile?.enemyOf(kind);
    final ability = isBoss ? 'none' : (t?.ability ?? 'none'); // ボスには能力を付けない（スキルを使う）
    final action = isBoss ? 'none' : (t?.action ?? 'none');
    var hp = isBoss ? (w.baseHp * 2.5).round() : (w.baseHp * b.hpMult * (t?.hp ?? 1.0)).round();
    if (ability == 'swarm') hp = (hp * swarmHp).round();
    final season = _seasonAt(w.number);
    if (!isBoss && kind == 'normal') hp = (hp * season.normalHp).round();
    final speed = b.speedMult * (isBoss ? 0.6 : 1.2) * (t?.speed ?? 1.0) * _params.speedMultiplier * season.enemySpeed * (kind == 'speedy' ? season.speedySpeed : 1.0) * lengthFactor(stage.paths[w.entranceIndices[index % w.entranceIndices.length]].length);
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
      ability: ability,
      action: action,
      bossSkill: isBoss ? bossSkill : null,
      shielded: ability == 'shield',
      regenCd: ability == 'regen' ? regenInterval : 0,
      actionCd: isBoss
          ? bossSkillInterval
          : switch (action) {
              'heal_aura' => healAuraInterval,
              'ranged_disable' => disableInterval,
              'sabotage' => sabotageInterval,
              _ => 0,
            },
    );
  }

  int _killReward(Enemy e, int wave, String? skill, [double mult = 1.0]) {
    final base = e.isBoss ? 60 + wave * 5 : 12 + wave * 3;
    return math.max(1, (base * _params.rewardMultiplier * (profile?.income ?? 1.0) * (skill == 'waveCoinBonus' ? skillCoinBonus : 1.0) * _seasonAt(wave).coin * mult * (stage.kind != StageKind.normal ? regionalReward : 1.0)).round());
  }

  /// クリティカルか。seed・刻み・施設・敵から決まる（状態を持たない決定的な乱数）。
  bool isCrit(int tickCount, GridPos pos, String enemyId) =>
      fnv1a('${stage.seed}|$tickCount|${pos.col},${pos.row}|$enemyId') / 4294967296.0 < critChance;

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

  static double _dist(double ax, double ay, double bx, double by) => math.sqrt((ax - bx) * (ax - bx) + (ay - by) * (ay - by));

  /// 1刻み進める。順序は、出現→敵の行動・ボスのスキル→継続ダメージ→移動→施設の攻撃→撃破→拠点への到達→勝敗（設計書 §6.3）。
  TickResult tick(BattleState s, double dt) {
    if (s.isOver) return (state: s, events: const []);
    final events = <BattleEvent>[];
    var st = s.copyWith(time: s.time + dt, tickCount: s.tickCount + 1);
    final now = st.time;

    if (st.phase == BattlePhase.prep) {
      final left = st.prepTimer - dt;
      if (left > 0) return (state: st.copyWith(prepTimer: left), events: events);
      st = _beginWave(st, events);
    }

    final w = stage.waves[st.wave - 1];

    // 1. 出現（swarm は1回で2体）
    var list = [...st.enemies];
    var spawned = st.spawned;
    var acc = st.spawnAcc + dt;
    while (spawned < w.enemyCount && acc >= w.spawnInterval) {
      acc -= w.spawnInterval;
      final e = makeEnemy(w, spawned);
      list.add(e);
      events.add(BattleEvent(BattleEventType.spawn, enemyId: e.id, isBoss: e.isBoss));
      if (e.ability == 'swarm') {
        final twin = e.copyWith(id: '${e.id}b');
        list.add(twin);
        events.add(BattleEvent(BattleEventType.spawn, enemyId: twin.id));
      }
      spawned++;
    }

    // 以降は、敵の変化を書き込める形で扱う。
    final ms = [for (final e in list) _M(e)];
    final facilities = <GridPos, Facility>{...st.facilities};
    final order = facilities.keys.toList()..sort();
    var summoned = st.summoned;

    // 天候（予定は seed・波の番号から決まる。予告→開始→終了。防いだ天候は起きない）
    var weatherBlocks = st.weatherBlocks;
    final blocked = [...st.blockedWeather];
    var we = WeatherEffect.none;
    final slots = Weather.schedule(
        seed: stage.seed, wave: st.wave, type: stage.weatherEvent, season: stage.seasonAt(st.wave), difficulty: stage.difficulty, extra: signature.weatherExtra + stage.weatherBoost);
    final rel = now - st.waveStart, prev = rel - dt;
    var fire = false; // wildfire: 1秒をまたいだ
    for (final sl in slots) {
      final key = sl.key(st.wave);
      bool crossed(double t) => prev < t && rel >= t;
      if (crossed(sl.start - Weather.warningSeconds)) events.add(BattleEvent(BattleEventType.weatherWarning, detail: sl.type, value: st.wave));
      if (crossed(sl.start)) {
        if (weatherBlocks > 0) {
          weatherBlocks--;
          blocked.add(key);
          events.add(BattleEvent(BattleEventType.weatherBlocked, detail: sl.type, value: st.wave));
        } else {
          events.add(BattleEvent(BattleEventType.weatherStart, detail: sl.type, value: st.wave));
          if ((sl.type == 'tornado' || sl.type == 'earthquake') && order.isNotEmpty) {
            final pos = order[fnv1a('${stage.seed}|weather|${st.wave}|${sl.index}|f') % order.length];
            final secs = sl.type == 'earthquake' ? disableSeconds : sl.duration;
            facilities[pos] = facilities[pos]!.copyWith(disabledUntil: now + secs);
            events.add(BattleEvent(BattleEventType.facilityDisabled, facilityPos: pos, detail: sl.type));
          }
        }
      }
      if (blocked.contains(key)) continue;
      if (rel >= sl.start && rel < sl.end) {
        we = scaleWeather(Weather.effects[sl.type]!, signature.weatherIntensity);
        if (sl.type == 'wildfire' && rel.floor() != prev.floor()) fire = true;
      }
      if (crossed(sl.end)) events.add(BattleEvent(BattleEventType.weatherEnd, detail: sl.type, value: st.wave));
    }

    // 施設の耐久（hard）。城・象徴の近くでは被害が減り、壊れた施設は半額が戻る
    var refund = 0, baseBonus = 0;
    final hard = stage.difficulty == Difficulty.hard;
    bool guarded(GridPos pos) {
      for (final q in order) {
        if (q == pos) continue;
        final g = facilities[q]!;
        final guard = g.exclusive != null ? exclusiveKinds[g.exclusive] == ExclusiveKind.symbol : g.type == FacilityType.castle;
        if (guard && _dist(q.col.toDouble(), q.row.toDouble(), pos.col.toDouble(), pos.row.toDouble()) <= protectRadius) return true;
      }
      return false;
    }

    void damageFacility(GridPos pos, int amount) {
      final f = facilities[pos];
      if (f == null || maxHpOf(f) == 0) return;
      final dmg = guarded(pos) ? math.max(1, (amount * protectRatio).round()) : amount;
      final left = f.hp - dmg;
      if (left <= 0) {
        facilities.remove(pos);
        order.remove(pos);
        refund += (f.invested * destroyRefundRatio).round();
        events.add(BattleEvent(BattleEventType.facilityDestroyed, facilityPos: pos, value: dmg));
      } else {
        facilities[pos] = f.copyWith(hp: left);
        events.add(BattleEvent(BattleEventType.facilityDamaged, facilityPos: pos, value: dmg));
      }
    }

    bool every(double sec) => (now / sec).floor() != ((now - dt) / sec).floor();

    // 2. 敵の行動・ボスのスキル・regen
    final added = <_M>[];
    if (fire) {
      final dmg = math.max(1, (w.baseHp * Weather.wildfireDamageRatio).round());
      for (final m in ms) {
        if (m.hp > 0) m.hp -= dmg;
      }
      if (hard) {
        for (final pos in [...order]) {
          damageFacility(pos, dmg);
        }
      }
    }
    if (hard && every(shrineHealInterval)) {
      for (final pos in order) {
        final h = facilities[pos]!;
        if (h.exclusive != null || h.type != FacilityType.shrine) continue;
        for (final q in order) {
          final f = facilities[q]!;
          final max = maxHpOf(f);
          if (q == pos || max == 0 || f.hp >= max) continue;
          if (_dist(q.col.toDouble(), q.row.toDouble(), pos.col.toDouble(), pos.row.toDouble()) <= shrineHealRadius) {
            facilities[q] = f.copyWith(hp: math.min(max, f.hp + math.max(1, (max * shrineHealRatio).round())));
          }
        }
      }
    }
    ExclusiveKind? kindAt(GridPos p) {
      final id = facilities[p]?.exclusive;
      return id == null ? null : exclusiveKinds[id];
    }

    final exFacilities = [for (final pos in order) if (kindAt(pos) != null) pos];
    if (every(1.0)) {
      for (final pos in exFacilities) {
        if (kindAt(pos) != ExclusiveKind.brewery) continue;
        final dmg = math.max(1, (w.baseHp * breweryDamageRatio).round());
        for (final m in ms) {
          if (m.hp <= 0) continue;
          final q = m.pos(stage.paths[m.e.pathIndex]);
          if (_dist(q.x, q.y, pos.col.toDouble(), pos.row.toDouble()) <= breweryRadius) m.hp -= dmg;
        }
      }
    }
    if (every(symbolHealInterval) && exFacilities.any((p) => kindAt(p) == ExclusiveKind.symbol) && st.baseHp < stage.baseHp) {
      baseBonus = 1;
      events.add(const BattleEvent(BattleEventType.baseHeal, value: 1));
    }
    for (final m in ms) {
      if (m.hp <= 0) continue;
      final path = stage.paths[m.e.pathIndex];
      final p = m.pos(path);
      if (m.e.ability == 'regen') {
        m.regenCd -= dt;
        if (m.regenCd <= 0) {
          m.regenCd = regenInterval;
          m.hp = math.min(m.e.maxHp, m.hp + math.max(1, (m.e.maxHp * regenRatio * we.regen * _seasonAt(st.wave).regen).round()));
        }
      }
      if (m.e.action == 'none' && m.e.bossSkill == null) continue;
      m.actionCd -= dt;
      if (m.actionCd > 0) continue;
      if (m.e.bossSkill != null) {
        m.actionCd = bossSkillInterval;
        events.add(BattleEvent(BattleEventType.bossSkill, enemyId: m.e.id, detail: m.e.bossSkill, isBoss: true));
        switch (m.e.bossSkill) {
          case 'speedBurst':
            m.hasteUntil = now + bossHasteSeconds;
          case 'hpRegen':
            m.hp = math.min(m.e.maxHp, m.hp + (m.e.maxHp * bossHealRatio).round());
          case 'summon':
            for (var k = 0; k < bossSummonCount; k++) {
              final id = 'e${w.number}_s${summoned++}';
              final hp = math.max(1, (w.baseHp * bossSummonHp).round());
              final b = enemyBase['normal']!;
              final summon = Enemy(
                id: id, kind: 'normal', pathIndex: m.e.pathIndex, hp: hp, maxHp: hp,
                speed: b.speedMult * 1.2 * _params.speedMultiplier, progress: m.progress, isBoss: false, armor: 0, breachDamage: 1);
              added.add(_M(summon));
              events.add(BattleEvent(BattleEventType.spawn, enemyId: id));
            }
          case 'stunFacility':
            _disableNearest(facilities, order, p, disableRadius, now, events);
        }
        continue;
      }
      switch (m.e.action) {
        case 'heal_aura':
          m.actionCd = healAuraInterval;
          for (final o in ms) {
            if (o == m || o.hp <= 0) continue;
            final q = o.pos(stage.paths[o.e.pathIndex]);
            if (_dist(p.x, p.y, q.x, q.y) <= healAuraRadius) o.hp = math.min(o.e.maxHp, o.hp + math.max(1, (o.e.maxHp * healAuraRatio).round()));
          }
        case 'ranged_disable':
          m.actionCd = disableInterval;
          _disableNearest(facilities, order, p, disableRadius, now, events);
        case 'sabotage':
          m.actionCd = sabotageInterval;
          final pos = _nearestFacility(facilities, order, p, sabotageRadius);
          if (pos != null) {
            facilities[pos] = facilities[pos]!.copyWith(sabotagedUntil: now + sabotageSeconds);
            events.add(BattleEvent(BattleEventType.facilitySabotaged, facilityPos: pos));
          }
      }
    }

    ms.addAll(added);

    // 3. 継続ダメージ（burn）
    for (final m in ms) {
      if (m.hp <= 0 || m.burnUntil <= now) continue;
      m.burnAcc += m.burnDps * dt;
      final whole = m.burnAcc.floor();
      if (whole > 0) {
        m.burnAcc -= whole;
        m.hp -= whole;
      }
    }

    // 4. 移動（鈍足・ボスの加速）
    final ports = [for (final p in exFacilities) if (kindAt(p) == ExclusiveKind.port) p];
    for (final m in ms) {
      if (m.hp <= 0) continue;
      final here = m.pos(stage.paths[m.e.pathIndex]);
      // hard: 施設が射程にいると足を止めて攻撃する（足速型は走り抜ける）
      if (hard && m.e.kind != 'speedy' && order.isNotEmpty) {
        final reach = m.e.action == 'ranged_disable' ? enemyRangedAttackRange : enemyAttackRange;
        final target = _nearestFacility(facilities, order, here, reach);
        if (target != null) {
          m.attackCd -= dt;
          if (m.attackCd <= 0) {
            m.attackCd = enemyAttackInterval;
            final mult = m.e.isBoss ? bossAttackFactor : (m.e.kind == 'armored' ? 2.0 : (m.e.kind == 'healer' ? 0.5 : 1.0));
            final amount = math.max(1, (w.baseHp * enemyAttackRatio * mult).round());
            if (m.e.isBoss) {
              for (final q in [...order]) {
                if (_dist(q.col.toDouble(), q.row.toDouble(), target.col.toDouble(), target.row.toDouble()) <= bossAoeRadius) damageFacility(q, amount);
              }
            } else {
              damageFacility(target, amount);
            }
          }
          continue;
        }
      }
      var v = m.e.speed;
      if (ports.any((p) => _dist(here.x, here.y, p.col.toDouble(), p.row.toDouble()) <= portRadius)) v *= portSlow;
      if (m.slowUntil > now) v *= m.slowFactor;
      if (st.skill == 'slow') v *= skillSlowFactor;
      v *= we.enemySpeed;
      if (m.hasteUntil > now) v *= bossHasteFactor;
      m.progress += v * dt;
    }

    // 5. 施設の攻撃（位置の順。決定的）
    for (final pos in order) {
      final cur = facilities[pos];
      if (cur == null) continue;
      final f = cur;
      var cd = f.cooldown - dt;
      if (cd <= 0) {
        if (f.disabledUntil > now) {
          facilities[pos] = f.copyWith(cooldown: 0);
          continue;
        }
        final fs = facilityStats(f, wave: st.wave);
        if (fs.damage == 0) {
          facilities[pos] = f.copyWith(cooldown: 0);
          continue;
        }
        final boosted = f.exclusive == null &&
            exFacilities.any((p) => kindAt(p) == ExclusiveKind.core && _dist(p.col.toDouble(), p.row.toDouble(), pos.col.toDouble(), pos.row.toDouble()) <= coreRadius);
        // disrupt: 近くに妨害する敵がいると、射程が縮む
        var range = math.max(0.5, fs.range + we.rangeDelta + (st.skill == 'waveRangeBonus' ? skillRangeBonus : 0));
        for (final m in ms) {
          if (m.hp <= 0 || m.e.ability != 'disrupt') continue;
          final q = m.pos(stage.paths[m.e.pathIndex]);
          if (_dist(q.x, q.y, pos.col.toDouble(), pos.row.toDouble()) <= disruptRadius) {
            range *= disruptRange;
            break;
          }
        }
        _M? target;
        ({double x, double y})? tp;
        for (final m in ms) {
          if (m.hp <= 0) continue;
          final q = m.pos(stage.paths[m.e.pathIndex]);
          if (_dist(q.x, q.y, pos.col.toDouble(), pos.row.toDouble()) > range) continue;
          // 拠点にいちばん近い敵（進んだ距離が大きい）。同じなら id の順。
          if (target == null || m.progress > target.progress || (m.progress == target.progress && m.e.id.compareTo(target.e.id) < 0)) {
            target = m;
            tp = q;
          }
        }
        if (target != null) {
          final base = f.sabotagedUntil > now ? (fs.damage * sabotageRatio).round() : fs.damage;
          final power = (base * (boosted ? coreBoost : 1.0) * (st.skill == 'waveAtkBonus' ? skillAtkBonus : 1.0) * we.damage * (we.typeDamage[f.type] ?? 1.0) * (1 + quizBuffBonus(st))).round();
          final crit = isCrit(st.tickCount, pos, target.e.id);
          final raw = math.max(1, (power * (crit ? critMultiplier : 1.0)).round());
          int hit(_M m, int amount, {bool c = false, double armorIgnore = 0}) {
            var a = amount;
            if (m.shielded) {
              a = math.max(1, (a * shieldMultiplier).round());
              m.shielded = false;
            }
            final armor = (m.e.armor * (1 - armorIgnore)).round();
            final dmg = math.max(1, a - armor);
            m.hp -= dmg;
            events.add(BattleEvent(BattleEventType.hit, enemyId: m.e.id, facilityPos: pos, value: dmg, crit: c));
            return dmg;
          }

          final armorIgnore = fs.action == 'pierce' ? pierceArmorIgnore : 0.0;
          hit(target, raw, c: crit, armorIgnore: armorIgnore);
          switch (fs.action) {
            case 'splash':
              for (final m in ms) {
                if (m == target || m.hp <= 0) continue;
                final q = m.pos(stage.paths[m.e.pathIndex]);
                if (_dist(q.x, q.y, tp!.x, tp.y) <= splashRadius) hit(m, (raw * splashRatio).round());
              }
            case 'chain':
              var from = tp!;
              final done = <_M>{target};
              for (final ratio in chainRatios) {
                _M? next;
                var bd = double.infinity;
                for (final m in ms) {
                  if (done.contains(m) || m.hp <= 0) continue;
                  final q = m.pos(stage.paths[m.e.pathIndex]);
                  final d = _dist(q.x, q.y, from.x, from.y);
                  if (d <= chainRadius && (d < bd || (d == bd && m.e.id.compareTo(next!.e.id) < 0))) {
                    bd = d;
                    next = m;
                  }
                }
                if (next == null) break;
                done.add(next);
                hit(next, (raw * ratio).round());
                from = next.pos(stage.paths[next.e.pathIndex]);
              }
            case 'slow':
              target.slowUntil = now + slowSeconds;
              target.slowFactor = slowFactor;
            case 'burn':
              target.burnUntil = now + burnSeconds;
              target.burnDps = math.max(1, (raw * burnRatio * we.burnRatio).round());
          }
          cd = (st.skill == 'waveAtkSpeedBonus' ? fs.cooldown / skillAtkSpeedBonus : fs.cooldown) * we.cooldown / (boosted ? coreBoost : 1.0);
        } else {
          cd = 0; // 撃てる敵がいなければ、準備完了のまま待つ
        }
      }
      facilities[pos] = facilities[pos]!.copyWith(cooldown: cd);
    }

    // 6. 撃破（コイン・スコア）
    var coins = st.coins + refund, score = st.score;
    final resMul = exFacilities.any((p) => kindAt(p) == ExclusiveKind.resource) ? resourceCoin : 1.0;
    final alive = <_M>[];
    for (final m in ms) {
      if (m.hp <= 0) {
        final reward = _killReward(m.e, st.wave, st.skill, resMul);
        coins += reward;
        score += m.e.isBoss ? 200 : 50;
        events.add(BattleEvent(BattleEventType.kill, enemyId: m.e.id, value: reward, isBoss: m.e.isBoss));
      } else {
        alive.add(m);
      }
    }

    // 7. 拠点への到達
    var baseHp = math.min(stage.baseHp, st.baseHp + baseBonus), mistakes = st.mistakes;
    final remain = <Enemy>[];
    for (final m in alive) {
      if (m.progress >= m.e.reach(stage.paths[m.e.pathIndex])) {
        baseHp -= m.e.breachDamage;
        mistakes++;
        events.add(BattleEvent(BattleEventType.breach, enemyId: m.e.id, value: m.e.breachDamage, isBoss: m.e.isBoss));
      } else {
        remain.add(m.toEnemy());
      }
    }

    st = st.copyWith(
      enemies: remain, facilities: facilities, coins: coins, score: score, baseHp: baseHp,
      mistakes: mistakes, spawned: spawned, spawnAcc: acc, summoned: summoned,
      weatherBlocks: weatherBlocks, blockedWeather: blocked,
    );

    // 8. 勝敗・波の終わり
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
      return (state: st.copyWith(phase: BattlePhase.prep, prepTimer: _params.waveBreakSeconds, spawned: 0, spawnAcc: 0, clearSkill: true), events: events);
    }
    return (state: st, events: events);
  }

  GridPos? _nearestFacility(Map<GridPos, Facility> fs, List<GridPos> order, ({double x, double y}) p, double radius) {
    GridPos? best;
    var bd = double.infinity;
    for (final pos in order) {
      final d = _dist(p.x, p.y, pos.col.toDouble(), pos.row.toDouble());
      if (d <= radius && d < bd) {
        bd = d;
        best = pos;
      }
    }
    return best;
  }

  void _disableNearest(Map<GridPos, Facility> fs, List<GridPos> order, ({double x, double y}) p, double radius, double now, List<BattleEvent> events) {
    final pos = _nearestFacility(fs, order, p, radius);
    if (pos == null) return;
    fs[pos] = fs[pos]!.copyWith(disabledUntil: now + disableSeconds);
    events.add(BattleEvent(BattleEventType.facilityDisabled, facilityPos: pos));
  }

  BattleState _beginWave(BattleState s, List<BattleEvent> events) {
    final n = s.wave + 1;
    events.add(BattleEvent(BattleEventType.waveStart, value: n));
    return s.copyWith(phase: BattlePhase.wave, wave: n, spawned: 0, spawnAcc: 0, prepTimer: 0, waveStart: s.time);
  }
}

/// 1刻みの間だけ使う、敵の書き込み用の入れ物。終わったら [toEnemy] で不変の敵に戻す。
class _M {
  final Enemy e;
  int hp;
  double progress, slowUntil, slowFactor, burnUntil, burnAcc, hasteUntil, regenCd, actionCd, attackCd;
  int burnDps;
  bool shielded;
  _M(this.e)
      : hp = e.hp,
        progress = e.progress,
        slowUntil = e.slowUntil,
        slowFactor = e.slowFactor,
        burnUntil = e.burnUntil,
        burnAcc = e.burnAcc,
        hasteUntil = e.hasteUntil,
        regenCd = e.regenCd,
        actionCd = e.actionCd,
        attackCd = e.attackCd,
        burnDps = e.burnDps,
        shielded = e.shielded;

  ({double x, double y}) pos(List<GridPos> path) => Enemy.positionAt(e.flying, progress, path);

  Enemy toEnemy() => e.copyWith(
        hp: hp, progress: progress, shielded: shielded, slowUntil: slowUntil, slowFactor: slowFactor, burnUntil: burnUntil,
        burnDps: burnDps, burnAcc: burnAcc, hasteUntil: hasteUntil, regenCd: regenCd, actionCd: actionCd, attackCd: attackCd);
}
