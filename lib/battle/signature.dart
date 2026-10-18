import '../pack/country_profile.dart';
import '../pack/region_pack.dart';
import 'battle_model.dart';
import 'stage.dart';
import 'weather.dart';

/// 国の目玉（設計書 §6.11）。バトルの計算は、目玉の中身を知らず、この窓口だけを使う。
/// `profile.signature.id` ごとに実装を差し込む。知らない id は、何もしない（中立）。
abstract class SignatureRule {
  const SignatureRule();

  /// 施設の種類ごとの威力の倍率（1.0が標準）。
  double facilityDamage(FacilityType type) => 1.0;

  /// 1つの波に起きる天候の回数の加算。
  int get weatherExtra => 0;

  /// 天候の効果の強さ（1.0が標準。大きいほど、標準からの変化が大きい）。
  double get weatherIntensity => 1.0;

  static const neutral = _Neutral();

  static SignatureRule create(String? id, {required Stage stage, RegionPack? pack, CountryProfile? profile}) {
    switch (id) {
      case 'federal_specialties':
        return FederalSpecialties.forStage(stage, pack, profile);
      case 'weather_extremes':
        return const WeatherExtremes();
      default:
        return neutral;
    }
  }
}

class _Neutral extends SignatureRule {
  const _Neutral();
}

/// ドイツ: 州ごとの得意分野（`facilityBonus` に書いた施設の種類）。
/// 守る州とその隣の州のうち、同じ種類を得意とする州が多いほど、その種類の施設が強くなる。
/// 2州そろうと +5%、3州以上で +10%、4州以上で +15%（上限）。
class FederalSpecialties extends SignatureRule {
  static const perExtra = 0.05, maxBonus = 0.15;
  final Map<FacilityType, int> aligned; // 種類→得意とする州の数（自分を含む）
  const FederalSpecialties(this.aligned);

  factory FederalSpecialties.forStage(Stage stage, RegionPack? pack, CountryProfile? profile) {
    final count = <FacilityType, int>{};
    if (pack != null && profile != null) {
      final region = pack.regions.where((r) => r.id == stage.regionId);
      final ids = {stage.regionId, if (region.isNotEmpty) ...region.first.neighbors};
      for (final id in ids) {
        for (final t in FacilityType.values) {
          if (profile.traitOf(id).facilityBonus.containsKey(t.name)) count[t] = (count[t] ?? 0) + 1;
        }
      }
    }
    return FederalSpecialties(count);
  }

  @override
  double facilityDamage(FacilityType type) {
    final n = aligned[type] ?? 0;
    if (n < 2) return 1.0;
    return 1.0 + ((n - 1) * perExtra).clamp(0.0, maxBonus);
  }
}

/// 米国: 天候を強調する。1つの波に起きる回数が1回増え、効果の変化が25%大きくなる。
class WeatherExtremes extends SignatureRule {
  static const extra = 1, intensity = 1.25;
  const WeatherExtremes();

  @override
  int get weatherExtra => extra;

  @override
  double get weatherIntensity => intensity;
}

/// 天候の効果を、標準からの変化の大きさ [k] 倍にする。
WeatherEffect scaleWeather(WeatherEffect e, double k) {
  if (k == 1.0) return e;
  double s(double v) => 1.0 + (v - 1.0) * k;
  return WeatherEffect(
    rangeDelta: e.rangeDelta * k,
    enemySpeed: s(e.enemySpeed),
    damage: s(e.damage),
    cooldown: s(e.cooldown),
    burnRatio: s(e.burnRatio),
    regen: s(e.regen),
    typeDamage: {for (final x in e.typeDamage.entries) x.key: s(x.value)},
  );
}
