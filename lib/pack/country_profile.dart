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
  // ゲーム側が実装する識別子の一覧(打ち間違いを検証で止める)。増やすときはここと検証を同時に更新する。
  static const enemyAbilities = {'none', 'shield', 'regen', 'swarm', 'flying', 'disrupt'};
  static const enemyActions = {'none', 'heal_aura', 'ranged_disable', 'sabotage'};
  static const facilityTypes = {'farm', 'fishery', 'factory', 'mine', 'castle', 'shrine'};
  static const facilityActions = {'single', 'splash', 'chain', 'pierce', 'slow', 'burn'};

  final String style; // 国の戦い方の型。UIの見出し・アイコン分けに使う識別子
  final Map<String, String> summary; // 言語→一言説明
  final Map<String, double> enemyMix; // 敵の種類→出現の重み(合計1)
  final double startCoins, income, facilityCost; // 経済の倍率(1.0が基準)
  final String pathLength;
  final String signatureId; // 国の目玉の仕組み(ゲーム側が解釈する識別子)
  final Map<String, RegionTrait> regions; // 地域id→特性(書かれていない地域は既定)
  final Map<String, EnemyTrait> enemies; // 敵の種類→この国での特性(書かれていない敵は標準)
  final Map<String, FacilityAction> attackActions; // 施設の種類→この国での攻撃アクション(書かれていない施設は標準)

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
    this.enemies = const {},
    this.attackActions = const {},
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
      enemies: _obj(m['enemies']).map((k, v) => MapEntry(k, EnemyTrait.fromJson(_obj(v)))),
      attackActions: _obj(m['attackActions']).map((k, v) => MapEntry(k, FacilityAction.fromJson(_obj(v)))),
    );
  }

  /// 敵の特性。書かれていない敵は標準(倍率1.0・能力/行動なし)。
  EnemyTrait enemyOf(String kind) => enemies[kind] ?? const EnemyTrait();

  /// 施設の攻撃アクション。書かれていない施設は null(ゲームの標準のまま)。
  FacilityAction? actionOf(String facility) => attackActions[facility];

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

/// この国での敵の特性。倍率は1.0が標準。ability は常時の性質、action は敵が自分から起こす行動。
class EnemyTrait {
  final double hp, speed, baseDamage; // 体力・速さ・拠点に到達したときの被害の倍率
  final int armor; // 装甲の加算
  final String ability; // none/shield/regen/swarm/flying/disrupt
  final String action; // none/heal_aura/ranged_disable/sabotage
  const EnemyTrait({
    this.hp = 1.0,
    this.speed = 1.0,
    this.baseDamage = 1.0,
    this.armor = 0,
    this.ability = 'none',
    this.action = 'none',
  });

  factory EnemyTrait.fromJson(Map<String, dynamic> j) => EnemyTrait(
        hp: (j['hp'] as num? ?? 1.0).toDouble(),
        speed: (j['speed'] as num? ?? 1.0).toDouble(),
        baseDamage: (j['baseDamage'] as num? ?? 1.0).toDouble(),
        armor: (j['armor'] as num? ?? 0).toInt(),
        ability: j['ability'] as String? ?? 'none',
        action: j['action'] as String? ?? 'none',
      );
}

/// この国での施設の攻撃アクション(撃ち方と、威力・射程・間隔の倍率)。
class FacilityAction {
  final String action; // single/splash/chain/pierce/slow/burn
  final double damage, range, cooldown;
  const FacilityAction({required this.action, this.damage = 1.0, this.range = 1.0, this.cooldown = 1.0});

  factory FacilityAction.fromJson(Map<String, dynamic> j) => FacilityAction(
        action: j['action'] as String,
        damage: (j['damage'] as num? ?? 1.0).toDouble(),
        range: (j['range'] as num? ?? 1.0).toDouble(),
        cooldown: (j['cooldown'] as num? ?? 1.0).toDouble(),
      );
}
