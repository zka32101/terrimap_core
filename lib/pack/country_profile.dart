import 'dart:convert';

/// JSONのオブジェクトを Map<String, dynamic> として読む(無ければ空)。const {} は型が合わず落ちるので使わない。
Map<String, dynamic> _obj(Object? o) => o == null ? <String, dynamic>{} : Map<String, dynamic>.from(o as Map);

/// 国ごとの特性・戦い方のデータ(packs/<国>/profile.json)。
/// コアはデータの形と検証だけを持つ。ゲームの挙動(敵・施設・天候の処理)は各ゲーム側が実装し、
/// ここの値を読んで切り替える(タワーディフェンス本体はコアに置かない方針)。
class CountryProfile {
  static const enemyKinds = {'normal', 'speedy', 'armored', 'healer'};
  static const terrains = {'sea', 'mountain', 'urban', 'agriculture', 'mixed'};
  static const pathLengths = {'short', 'medium', 'long'};

  final String style; // 国の戦い方の型。UIの見出し・アイコン分けに使う識別子
  final Map<String, String> summary; // 言語→一言説明
  final Map<String, double> enemyMix; // 敵の種類→出現の重み(合計1)
  final double startCoins, income, facilityCost; // 経済の倍率(1.0が基準)
  final String pathLength;
  final String signatureId; // 国の目玉の仕組み(ゲーム側が解釈する識別子)
  final Map<String, RegionTrait> regions; // 地域id→特性(書かれていない地域は既定)

  const CountryProfile({
    required this.style,
    required this.summary,
    required this.enemyMix,
    required this.startCoins,
    required this.income,
    required this.facilityCost,
    required this.pathLength,
    required this.signatureId,
    required this.regions,
  });

  factory CountryProfile.parse(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    final eco = m['economy'] as Map<String, dynamic>;
    return CountryProfile(
      style: m['style'] as String,
      summary: _obj(m['summary']).map((k, v) => MapEntry(k, v as String)),
      enemyMix: (m['enemyMix'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble())),
      startCoins: (eco['startCoins'] as num).toDouble(),
      income: (eco['income'] as num).toDouble(),
      facilityCost: (eco['facilityCost'] as num).toDouble(),
      pathLength: m['pathLength'] as String,
      signatureId: (m['signature'] as Map<String, dynamic>)['id'] as String,
      regions: _obj(m['regions']).map((k, v) => MapEntry(k, RegionTrait.fromJson(_obj(v)))),
    );
  }

  /// 地域の特性。書かれていない地域は「特性なし」。
  RegionTrait traitOf(String regionId) => regions[regionId] ?? const RegionTrait();
}

class RegionTrait {
  final String? terrain;
  final List<String> tags;
  final Map<String, double> facilityBonus; // 施設の種類→効果の倍率(1.0以上)
  final String? weatherEvent;
  const RegionTrait({this.terrain, this.tags = const [], this.facilityBonus = const {}, this.weatherEvent});

  factory RegionTrait.fromJson(Map<String, dynamic> j) => RegionTrait(
        terrain: j['terrain'] as String?,
        tags: [for (final t in (j['tags'] as List? ?? const [])) t as String],
        facilityBonus: _obj(j['facilityBonus']).map((k, v) => MapEntry(k, (v as num).toDouble())),
        weatherEvent: j['weatherEvent'] as String?,
      );
}
