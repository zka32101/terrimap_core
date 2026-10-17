import '../quiz/rng.dart';
import 'battle_model.dart';
import 'difficulty.dart';
import 'grid.dart';

/// 天候イベント1回ぶんの予定。時刻は、その波が始まってからの秒。
class WeatherSlot {
  final String type;
  final int index; // その波の何回目か
  final double start, duration;
  const WeatherSlot(this.type, this.index, this.start, this.duration);
  double get end => start + duration;
  String key(int wave) => '$wave:$index';
}

/// 天候が戦闘に与える影響（1.0が標準）。
class WeatherEffect {
  final double rangeDelta, enemySpeed, damage, cooldown; // cooldown は攻撃間隔の倍率（大きいほど遅い）
  final double burnRatio; // 継続ダメージの倍率
  final double regen; // 回復（regen）の敵の強さの倍率
  final Map<FacilityType, double> typeDamage;
  const WeatherEffect({
    this.rangeDelta = 0,
    this.enemySpeed = 1,
    this.damage = 1,
    this.cooldown = 1,
    this.burnRatio = 1,
    this.regen = 1,
    this.typeDamage = const {},
  });
  static const none = WeatherEffect();
}

/// 季節が戦闘に与える影響。
class SeasonEffect {
  final double enemySpeed, coin, regen;
  final double normalHp, speedySpeed;
  final Map<FacilityType, double> typeDamage, typeCooldown;
  const SeasonEffect({
    this.enemySpeed = 1,
    this.coin = 1,
    this.regen = 1,
    this.normalHp = 1,
    this.speedySpeed = 1,
    this.typeDamage = const {},
    this.typeCooldown = const {},
  });
}

/// 天候・季節の表（設計書 §6.4・§6.5。数値は暫定で、M4の自動対戦で調整する）。
class Weather {
  static const types = {'hurricane', 'tornado', 'blizzard', 'heatwave', 'wildfire', 'flood', 'earthquake', 'storm'};
  static const warningSeconds = 3.0;
  static const firstStart = 8.0, gap = 14.0; // 波の開始から最初の天候まで／次の天候までの間隔
  static const wildfireDamageRatio = 0.03; // 1秒ごとに、その波の基礎HPの3%を、すべての敵へ

  static const effects = <String, WeatherEffect>{
    'hurricane': WeatherEffect(rangeDelta: -1, enemySpeed: 0.85, damage: 0.9),
    'tornado': WeatherEffect(enemySpeed: 1.1),
    'blizzard': WeatherEffect(rangeDelta: -1, enemySpeed: 0.75, damage: 0.85, burnRatio: 0.5),
    'heatwave': WeatherEffect(rangeDelta: 1, cooldown: 1 / 0.9, regen: 1.5),
    'wildfire': WeatherEffect(),
    'flood': WeatherEffect(enemySpeed: 0.8, typeDamage: {FacilityType.farm: 1.15, FacilityType.fishery: 1.15}),
    'earthquake': WeatherEffect(),
    'storm': WeatherEffect(rangeDelta: -1, enemySpeed: 0.9, typeDamage: {FacilityType.fishery: 1.1}),
  };

  static const seasons = <Season, SeasonEffect>{
    Season.spring: SeasonEffect(regen: 1.5, typeDamage: {FacilityType.farm: 1.1}),
    Season.summer: SeasonEffect(speedySpeed: 1.05, typeDamage: {FacilityType.fishery: 1.1}, typeCooldown: {FacilityType.fishery: 1 / 0.95}),
    Season.autumn: SeasonEffect(normalHp: 1.05, coin: 1.1),
    Season.winter: SeasonEffect(enemySpeed: 0.9, typeDamage: {FacilityType.mine: 1.1, FacilityType.factory: 1.1}),
  };

  /// 季節と合わない天候は起きない。
  static bool fits(String type, Season s) => switch (type) {
        'blizzard' => s != Season.summer,
        'heatwave' || 'wildfire' => s != Season.winter,
        _ => true,
      };

  static int perWave(Difficulty d) => d == Difficulty.hard ? 2 : 1;

  /// その波の天候の予定（seed・波の番号から決まる）。天候がない地域・季節に合わない場合は空。
  static List<WeatherSlot> schedule({required int seed, required int wave, required String? type, required Season season, required Difficulty difficulty}) {
    if (type == null || !types.contains(type) || !fits(type, season)) return const [];
    return [
      for (var i = 0; i < perWave(difficulty); i++)
        WeatherSlot(
          type,
          i,
          firstStart + gap * i + fnv1a('$seed|weather|$wave|$i|s') % 6,
          6.0 + fnv1a('$seed|weather|$wave|$i|d') % 7,
        ),
    ];
  }
}
