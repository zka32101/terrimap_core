import 'dart:math' as math;

import 'difficulty.dart';
import 'grid.dart';

/// 施設の種類（`profile.json` の facilityTypes と同じ名前）。限定施設は M3.5。
enum FacilityType { farm, fishery, factory, mine, castle, shrine }

/// 施設の基礎値。地理パズル王の既存の値（td_model.dart）を初期値にした。
class FacilityBase {
  final int cost, damage;
  final double range; // マス
  final double attackSpeed; // 1秒あたりの攻撃回数
  const FacilityBase(this.cost, this.damage, this.range, this.attackSpeed);
}

const Map<FacilityType, FacilityBase> facilityBase = {
  FacilityType.farm: FacilityBase(50, 10, 1.5, 1.0),
  FacilityType.fishery: FacilityBase(70, 18, 2.0, 0.8),
  FacilityType.factory: FacilityBase(100, 16, 1.2, 1.5),
  FacilityType.mine: FacilityBase(55, 22, 1.8, 0.5),
  FacilityType.castle: FacilityBase(150, 40, 2.5, 0.6),
  FacilityType.shrine: FacilityBase(100, 12, 2.2, 2.5),
};

/// 敵の種類ごとの基礎値（既存の EnemyType）。
class EnemyBase {
  final double hpMult, speedMult;
  final int armor; // ダメージから引く固定値
  const EnemyBase(this.hpMult, this.speedMult, this.armor);
}

const Map<String, EnemyBase> enemyBase = {
  'normal': EnemyBase(1.0, 1.0, 0),
  'speedy': EnemyBase(0.5, 1.8, 0),
  'armored': EnemyBase(2.0, 0.7, 8),
  'healer': EnemyBase(1.3, 1.0, 0),
};

class Facility {
  final FacilityType type;
  final GridPos pos;
  final int level; // 1〜3
  final double cooldown; // 次の攻撃までの残り秒（0以下=いつでも撃てる）
  final int invested; // 置く・強化に使ったコインの合計（撤去の払い戻しの基準）
  final double disabledUntil; // この時刻まで停止（敵の ranged_disable・ボスの stunFacility）
  final double sabotagedUntil; // この時刻まで威力が半分（敵の sabotage）
  final int hp; // 耐久（hard だけ。0 は耐久なし）
  final String? exclusive; // 限定施設の id（通常の施設は null）
  const Facility(this.type, this.pos,
      {this.level = 1, this.cooldown = 0, this.invested = 0, this.disabledUntil = 0, this.sabotagedUntil = 0, this.hp = 0, this.exclusive});
  Facility copyWith({int? level, double? cooldown, int? invested, double? disabledUntil, double? sabotagedUntil, int? hp}) => Facility(type, pos,
      exclusive: exclusive,
      hp: hp ?? this.hp,
      level: level ?? this.level,
      cooldown: cooldown ?? this.cooldown,
      invested: invested ?? this.invested,
      disabledUntil: disabledUntil ?? this.disabledUntil,
      sabotagedUntil: sabotagedUntil ?? this.sabotagedUntil);
}

const maxFacilityLevel = 3;

class Enemy {
  final String id; // 'e<波>_<番号>'
  final String kind;
  final int pathIndex; // Stage.paths の添字
  final int hp, maxHp;
  final double speed; // マス/秒
  final double progress; // 進路上の位置（0〜到達までの長さ）
  final bool isBoss;
  final int armor;
  final int breachDamage; // 拠点に届いたときの被害
  final String ability; // none/shield/regen/swarm/flying/disrupt（profile.enemies）
  final String action; // none/heal_aura/ranged_disable/sabotage
  final String? bossSkill; // speedBurst/hpRegen/summon/stunFacility
  final bool shielded; // shield の最初の一撃を軽減する分が残っている
  final double slowUntil, slowFactor; // 鈍足（slow）
  final double burnUntil; // 継続ダメージ（burn）
  final int burnDps;
  final double burnAcc; // 継続ダメージの端数
  final double hasteUntil; // ボスの speedBurst
  final double regenCd; // regen の次の回復までの秒
  final double actionCd; // 行動・ボスのスキルの次の発動までの秒
  final double attackCd; // 施設への攻撃（hard）の次までの秒
  const Enemy({
    required this.id,
    required this.kind,
    required this.pathIndex,
    required this.hp,
    required this.maxHp,
    required this.speed,
    required this.progress,
    required this.isBoss,
    required this.armor,
    required this.breachDamage,
    this.ability = 'none',
    this.action = 'none',
    this.bossSkill,
    this.shielded = false,
    this.slowUntil = 0,
    this.slowFactor = 1,
    this.burnUntil = 0,
    this.burnDps = 0,
    this.burnAcc = 0,
    this.hasteUntil = 0,
    this.regenCd = 0,
    this.actionCd = 0,
    this.attackCd = 0,
  });

  Enemy copyWith({
    String? id,
    int? hp,
    int? maxHp,
    double? progress,
    bool? shielded,
    double? slowUntil,
    double? slowFactor,
    double? burnUntil,
    int? burnDps,
    double? burnAcc,
    double? hasteUntil,
    double? regenCd,
    double? actionCd,
    double? attackCd,
  }) =>
      Enemy(
        id: id ?? this.id, kind: kind, pathIndex: pathIndex, hp: hp ?? this.hp, maxHp: maxHp ?? this.maxHp, speed: speed,
        progress: progress ?? this.progress, isBoss: isBoss, armor: armor, breachDamage: breachDamage,
        ability: ability, action: action, bossSkill: bossSkill,
        shielded: shielded ?? this.shielded, slowUntil: slowUntil ?? this.slowUntil, slowFactor: slowFactor ?? this.slowFactor,
        burnUntil: burnUntil ?? this.burnUntil, burnDps: burnDps ?? this.burnDps, burnAcc: burnAcc ?? this.burnAcc,
        hasteUntil: hasteUntil ?? this.hasteUntil, regenCd: regenCd ?? this.regenCd, actionCd: actionCd ?? this.actionCd,
        attackCd: attackCd ?? this.attackCd,
      );

  bool get flying => ability == 'flying';

  /// 拠点に届くまでの長さ。飛行は進路を無視して、入口から拠点へ直線で来る。
  double reach(List<GridPos> path) => flying
      ? math.sqrt(math.pow(path.last.col - path.first.col, 2) + math.pow(path.last.row - path.first.row, 2)).toDouble()
      : (path.length - 1).toDouble();

  /// 盤面上の位置（マスの座標。列・行の連続値）。
  ({double x, double y}) position(List<GridPos> path) => positionAt(flying, progress, path);

  /// [progress] の位置。飛行は入口→拠点の直線、それ以外は進路に沿う。
  static ({double x, double y}) positionAt(bool flying, double progress, List<GridPos> path) {
    if (flying) {
      final total = math.sqrt(math.pow(path.last.col - path.first.col, 2) + math.pow(path.last.row - path.first.row, 2)).toDouble();
      final f = (progress / total).clamp(0.0, 1.0);
      return (x: path.first.col + (path.last.col - path.first.col) * f, y: path.first.row + (path.last.row - path.first.row) * f);
    }
    final i = math.min(progress.floor(), path.length - 1);
    final j = math.min(i + 1, path.length - 1);
    final f = i >= path.length - 1 ? 0.0 : progress - i;
    return (x: path[i].col + (path[j].col - path[i].col) * f, y: path[i].row + (path[j].row - path[i].row) * f);
  }
}

enum BattlePhase { prep, wave, victory, defeat }

class BattleState {
  final BattlePhase phase;
  final int wave; // 現在の波（1始まり。準備中は直前に終えた波。開始前は0）
  final double prepTimer; // 準備中の残り秒
  final int spawned; // 現在の波で出した敵の数
  final double spawnAcc; // 次の敵までの経過秒
  final List<Enemy> enemies;
  final Map<GridPos, Facility> facilities;
  final int coins, baseHp, score, mistakes;
  final double time; // 経過秒（バトル全体）
  final int tickCount; // 進めた刻みの数（クリティカルの決定的な乱数に使う）
  final int summoned; // ボスが呼んだ敵の数（id用）
  final String? skill; // 次（または今）の波で効くスキル（波が終わると外れる）
  final int weatherBlocks; // 天候の無効化の残り回数（次に起きる天候を1回防ぐ）
  final double waveStart; // 現在の波が始まった時刻（天候の予定の基準）
  final List<String> blockedWeather; // 防いだ天候（'波:番号'）
  const BattleState({
    required this.phase,
    required this.wave,
    required this.prepTimer,
    required this.spawned,
    required this.spawnAcc,
    required this.enemies,
    required this.facilities,
    required this.coins,
    required this.baseHp,
    required this.score,
    required this.mistakes,
    required this.time,
    this.tickCount = 0,
    this.summoned = 0,
    this.skill,
    this.weatherBlocks = 0,
    this.waveStart = 0,
    this.blockedWeather = const [],
  });

  BattleState copyWith({
    BattlePhase? phase,
    int? wave,
    double? prepTimer,
    int? spawned,
    double? spawnAcc,
    List<Enemy>? enemies,
    Map<GridPos, Facility>? facilities,
    int? coins,
    int? baseHp,
    int? score,
    int? mistakes,
    double? time,
    int? tickCount,
    int? summoned,
    String? skill,
    bool clearSkill = false,
    int? weatherBlocks,
    double? waveStart,
    List<String>? blockedWeather,
  }) =>
      BattleState(
        phase: phase ?? this.phase,
        wave: wave ?? this.wave,
        prepTimer: prepTimer ?? this.prepTimer,
        spawned: spawned ?? this.spawned,
        spawnAcc: spawnAcc ?? this.spawnAcc,
        enemies: enemies ?? this.enemies,
        facilities: facilities ?? this.facilities,
        coins: coins ?? this.coins,
        baseHp: baseHp ?? this.baseHp,
        score: score ?? this.score,
        mistakes: mistakes ?? this.mistakes,
        time: time ?? this.time,
        tickCount: tickCount ?? this.tickCount,
        summoned: summoned ?? this.summoned,
        skill: clearSkill ? null : (skill ?? this.skill),
        weatherBlocks: weatherBlocks ?? this.weatherBlocks,
        waveStart: waveStart ?? this.waveStart,
        blockedWeather: blockedWeather ?? this.blockedWeather,
      );

  bool get isOver => phase == BattlePhase.victory || phase == BattlePhase.defeat;

  /// 比較・記録用の短い文字列。
  String summary() =>
      '${phase.name} w$wave t${time.toStringAsFixed(2)} base$baseHp coins$coins score$score miss$mistakes '
      'fac${facilities.length} en${enemies.length}';
}

enum BattleEventType { waveStart, spawn, hit, kill, breach, waveClear, victory, defeat, bossSkill, facilityDisabled, facilitySabotaged, weatherWarning, weatherStart, weatherEnd, weatherBlocked, facilityDamaged, facilityDestroyed, baseHeal }

/// 画面・効果音が購読するイベント。使わない項目は null。
class BattleEvent {
  final BattleEventType type;
  final String? enemyId;
  final GridPos? facilityPos;
  final int? value; // hit=ダメージ、kill=得たコイン、breach=拠点への被害、waveStart/waveClear=波の番号
  final bool isBoss;
  final bool crit; // hit: クリティカル
  final String? detail; // bossSkill: スキル名、weather*: 天候の種類
  const BattleEvent(this.type, {this.enemyId, this.facilityPos, this.value, this.isBoss = false, this.crit = false, this.detail});
  @override
  String toString() => '${type.name}${enemyId != null ? ' $enemyId' : ''}${value != null ? ' $value' : ''}';
}

typedef TickResult = ({BattleState state, List<BattleEvent> events});

/// 難易度ごとの開始コイン（既存の値）。
const startCoinsBase = {Difficulty.easy: 220, Difficulty.normal: 160, Difficulty.hard: 140};
