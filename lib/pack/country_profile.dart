import 'dart:convert';

import '../quiz/rng.dart';

/// JSONのオブジェクトを Map<String, dynamic> として読む(無ければ空)。const {} は型が合わず落ちるので使わない。
Map<String, dynamic> _obj(Object? o) => o == null ? <String, dynamic>{} : Map<String, dynamic>.from(o as Map);

/// 国ごとの特性・戦い方のデータ(packs/<国>/profile.json)。
/// コアはデータの形と検証だけを持つ。ゲームの挙動(敵・施設・天候の処理)は各ゲーム側が実装し、
/// ここの値を読んで切り替える(タワーディフェンス本体はコアに置かない方針)。
class CountryProfile {
  /// ルール版2までの敵。`enemyMix` はこの4種類だけ（古い記録のステージを同じに作るため）。
  static const baseEnemyKinds = {'normal', 'speedy', 'armored', 'healer'};
  /// ルール版3から出る敵。出現の重みは `enemyMixV3`。
  static const newEnemyKinds = {'flyer', 'saboteur', 'swarmer', 'splitter'};
  /// ルール版4から、hard のステージだけに出る敵。出現の重みは `enemyMixHard`。
  static const hardEnemyKinds = {'brute', 'jammer'};
  static const enemyKinds = {...baseEnemyKinds, ...newEnemyKinds, ...hardEnemyKinds};
  static const terrains = {'sea', 'mountain', 'urban', 'agriculture', 'mixed'};
  static const pathLengths = {'short', 'medium', 'long'};
  // ゲーム側が実装する識別子の一覧(打ち間違いを検証で止める)。増やすときはここと検証を同時に更新する。
  static const enemyAbilities = {'none', 'shield', 'regen', 'swarm', 'flying', 'disrupt'};
  static const enemyActions = {'none', 'heal_aura', 'ranged_disable', 'sabotage'};
  static const facilityTypes = {'farm', 'fishery', 'factory', 'mine', 'castle', 'shrine'};
  static const facilityActions = {'single', 'splash', 'chain', 'pierce', 'slow', 'burn'};
  // 天候・災害イベント(地域の weatherEvent)。ゲーム側が演出と効果を実装する。
  static const weatherEvents = {'hurricane', 'tornado', 'blizzard', 'heatwave', 'wildfire', 'flood', 'earthquake', 'storm'};

  final String style; // 国の戦い方の型。UIの見出し・アイコン分けに使う識別子
  final Map<String, String> summary; // 言語→一言説明
  final Map<String, double> enemyMixHard; // ルール版4から、hard のときだけ enemyMix に足す敵→重み
  final Map<String, MiniBoss> miniBosses; // 地方のid→ミニボス（ルール版4から）
  final Map<String, double> enemyMixV3; // ルール版3から、enemyMix に足す敵の種類→重み（enemyMix と同じ単位で足し合わせる）
  final Map<String, double> enemyMix; // 敵の種類→出現の重み(合計1)
  final double startCoins, income, facilityCost; // 経済の倍率(1.0が基準)
  final String pathLength;
  final String signatureId; // 国の目玉の仕組み(ゲーム側が解釈する識別子)
  final Map<String, RegionTrait> regions; // 地域id→特性(書かれていない地域は既定)
  final Map<String, EnemyTrait> enemies; // 敵の種類→この国での特性(書かれていない敵は標準)
  final Map<String, FacilityAction> attackActions; // 施設の種類→この国での攻撃アクション(書かれていない施設は標準)
  final Map<String, Backdrop> backdrops; // 背景の種類id→配色(地域の backdrop が参照する)
  final Map<String, Skin> facilitySkins; // 施設の種類→この国での見た目と名前
  final Map<String, Skin> enemySkins; // 敵の種類→この国での見た目と名前
  final Map<String, List<EnemyVariant>> enemyVariants; // 敵の種類→見た目違い(強さは同じ。地方・州で出し分けられる)
  final Map<String, RegionGroup> groups; // 地方決戦の地方（id→州の集まり）。なければ地方決戦はない
  final List<ExtraStage> extras; // エクストラステージ（その国の歴史・伝記・伝説）。なければエクストラはない

  const CountryProfile({
    required this.style,
    required this.summary,
    required this.enemyMix,
    this.enemyMixV3 = const {},
    this.enemyMixHard = const {},
    this.miniBosses = const {},
    required this.startCoins,
    required this.income,
    required this.facilityCost,
    required this.pathLength,
    required this.signatureId,
    required this.regions,
    this.enemies = const {},
    this.attackActions = const {},
    this.backdrops = const {},
    this.facilitySkins = const {},
    this.enemySkins = const {},
    this.enemyVariants = const {},
    this.groups = const {},
    this.extras = const [],
  });

  factory CountryProfile.parse(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    final eco = m['economy'] as Map<String, dynamic>;
    return CountryProfile(
      style: m['style'] as String,
      summary: _obj(m['summary']).map((k, v) => MapEntry(k, v as String)),
      enemyMixHard: _obj(m['enemyMixHard']).map((k, v) => MapEntry(k, (v as num).toDouble())),
      miniBosses: _obj(m['miniBosses']).map((k, v) => MapEntry(k, MiniBoss.fromJson(_obj(v)))),
      enemyMixV3: _obj(m['enemyMixV3']).map((k, v) => MapEntry(k, (v as num).toDouble())),
      enemyMix: (m['enemyMix'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble())),
      startCoins: (eco['startCoins'] as num).toDouble(),
      income: (eco['income'] as num).toDouble(),
      facilityCost: (eco['facilityCost'] as num).toDouble(),
      pathLength: m['pathLength'] as String,
      signatureId: (m['signature'] as Map<String, dynamic>)['id'] as String,
      regions: _obj(m['regions']).map((k, v) => MapEntry(k, RegionTrait.fromJson(_obj(v)))),
      enemies: _obj(m['enemies']).map((k, v) => MapEntry(k, EnemyTrait.fromJson(_obj(v)))),
      attackActions: _obj(m['attackActions']).map((k, v) => MapEntry(k, FacilityAction.fromJson(_obj(v)))),
      backdrops: _obj(_obj(m['theme'])['backdrops']).map((k, v) => MapEntry(k, Backdrop.fromJson(_obj(v)))),
      facilitySkins: _obj(m['facilities']).map((k, v) => MapEntry(k, Skin.fromJson(_obj(v)))),
      enemySkins: _obj(m['enemySkins']).map((k, v) => MapEntry(k, Skin.fromJson(_obj(v)))),
      enemyVariants: _obj(m['enemyVariants']).map((k, v) => MapEntry(k, [for (final x in (v as List? ?? const [])) EnemyVariant.fromJson(_obj(x))])),
      extras: [for (final e in (m['extras'] as List? ?? const [])) ExtraStage.fromJson(_obj(e))],
      groups: _obj(m['groups']).map((k, v) => MapEntry(k, RegionGroup.fromJson(k, _obj(v)))),
    );
  }

  /// 敵の特性。書かれていない敵は標準(倍率1.0・能力/行動なし)。
  EnemyTrait enemyOf(String kind) => enemies[kind] ?? const EnemyTrait();

  /// 地域の背景。書かれていない地域は null(ゲームの標準の背景)。
  Backdrop? backdropOf(String regionId) {
    final id = traitOf(regionId).backdrop;
    return id == null ? null : backdrops[id];
  }

  /// 施設の攻撃アクション。書かれていない施設は null(ゲームの標準のまま)。
  FacilityAction? actionOf(String facility) => attackActions[facility];

  /// その州が入っている地方のid(地方に入っていない州・地方のない国は null)。
  String? groupOf(String regionId) {
    for (final g in groups.values) {
      if (g.regions.contains(regionId)) return g.id;
    }
    return null;
  }

  /// [kind] の敵の見た目の候補(skin id)。基本の見た目が先頭で、そのあとに、この州・地方で出る見た目違いが続く。
  /// 見た目違いは、強さ・能力が基本と同じで、見た目と名前だけが違う。
  List<String> enemySkinIds(String kind, {String? regionId, String? groupId}) {
    final out = <String>[];
    final base = enemySkins[kind]?.skin;
    if (base != null) out.add(base);
    final g = groupId ?? (regionId == null ? null : groupOf(regionId));
    for (final v in enemyVariants[kind] ?? const <EnemyVariant>[]) {
      if (v.matches(regionId: regionId, groupId: g) && !out.contains(v.skin)) out.add(v.skin);
    }
    return out;
  }

  /// この州・地方のミニボス。州が地方に入っていればその地方のもの、なければ地方idの先頭のもの。ミニボスがない国は null。
  MiniBoss? miniBossFor(String regionId, {String? groupId}) {
    if (miniBosses.isEmpty) return null;
    final g = groupId ?? groupOf(regionId);
    if (g != null && miniBosses.containsKey(g)) return miniBosses[g];
    return miniBosses[(miniBosses.keys.toList()..sort()).first];
  }

  /// 敵 [enemyId] の見た目違い。基本の見た目なら null。[ArtSet.enemy] と同じ選び方（[enemySkinIds] の並びから、id で決まる）なので、
  /// 画面に出る見た目と、効く特性がいつも一致する。
  EnemyVariant? variantFor(String kind, String enemyId, {String? regionId, String? groupId}) {
    final ids = enemySkinIds(kind, regionId: regionId, groupId: groupId);
    if (ids.length < 2) return null;
    final skin = ids[fnv1a(enemyId) % ids.length];
    if (skin == enemySkins[kind]?.skin) return null;
    for (final v in enemyVariants[kind] ?? const <EnemyVariant>[]) {
      if (v.skin == skin) return v;
    }
    return null;
  }

  /// 地域の特性。書かれていない地域は「特性なし」。
  RegionTrait traitOf(String regionId) => regions[regionId] ?? const RegionTrait();
}

class RegionTrait {
  final String? terrain;
  final List<String> tags;
  final Map<String, double> facilityBonus; // 施設の種類→効果の倍率(1.0以上)
  final String? weatherEvent;
  final String? backdrop; // 背景の種類id(profile の theme.backdrops のキー)
  final String? exclusiveFacility; // この地域だけで置ける限定施設のid(ゲーム側が定義)
  final Map<String, double> enemyBias; // 敵の種類→出現の重みの倍率(0.5〜2.0)
  final Map<String, String> blurb; // 言語→州の紹介文(解説ページに出す。足りない言語は英語)
  const RegionTrait({
    this.terrain,
    this.tags = const [],
    this.facilityBonus = const {},
    this.weatherEvent,
    this.backdrop,
    this.exclusiveFacility,
    this.enemyBias = const {},
    this.blurb = const {},
  });

  /// 紹介文。言語がなければ英語、英語もなければ空。
  String blurbIn(String lang) => blurb[lang] ?? blurb['en'] ?? '';

  factory RegionTrait.fromJson(Map<String, dynamic> j) => RegionTrait(
        terrain: j['terrain'] as String?,
        tags: [for (final t in (j['tags'] as List? ?? const [])) t as String],
        facilityBonus: _obj(j['facilityBonus']).map((k, v) => MapEntry(k, (v as num).toDouble())),
        weatherEvent: j['weatherEvent'] as String?,
        backdrop: j['backdrop'] as String?,
        exclusiveFacility: j['exclusiveFacility'] as String?,
        enemyBias: _obj(j['enemyBias']).map((k, v) => MapEntry(k, (v as num).toDouble())),
        blurb: _obj(j['blurb']).map((k, v) => MapEntry(k, '$v')),
      );
}

/// エクストラステージ（クリア後。設計書 §6.9）。主題はその国の歴史・伝記・伝説で、戦争・差別は扱わない。
class ExtraStage {
  static const bases = {'legend', 'biography', 'history'};
  static const seasonNames = {'spring', 'summer', 'autumn', 'winter'};
  static const bossSkills = {'speedBurst', 'hpRegen', 'summon', 'stunFacility'};

  final String id;
  final String basis; // legend（伝説・民話）／biography（伝記）／history（歴史・業績）
  final List<String> regions; // 舞台の州
  final String center; // 拠点（州都）の州
  final List<String> seasons; // 波ごとに巡る季節
  final String weatherEvent; // 天候
  final String? backdrop; // 背景
  final String bossSkill; // ボスのスキル
  final int waves; // 波の数（8〜10）
  final Map<String, String> title, summary, fact, bossName; // 言語→名前・あらすじ・事実の注記・ボスの名前
  const ExtraStage({
    required this.id,
    required this.basis,
    required this.regions,
    required this.center,
    required this.seasons,
    required this.weatherEvent,
    required this.bossSkill,
    required this.waves,
    required this.title,
    required this.summary,
    required this.fact,
    required this.bossName,
    this.backdrop,
  });

  factory ExtraStage.fromJson(Map<String, dynamic> j) => ExtraStage(
        id: j['id'] as String,
        basis: j['basis'] as String,
        regions: [for (final r in (j['regions'] as List)) r as String],
        center: j['center'] as String,
        seasons: [for (final x in (j['seasons'] as List)) x as String],
        weatherEvent: j['weatherEvent'] as String,
        backdrop: j['backdrop'] as String?,
        bossSkill: j['bossSkill'] as String,
        waves: (j['waves'] as num).toInt(),
        title: _obj(j['title']).map((k, v) => MapEntry(k, v as String)),
        summary: _obj(j['summary']).map((k, v) => MapEntry(k, v as String)),
        fact: _obj(j['fact']).map((k, v) => MapEntry(k, v as String)),
        bossName: _obj(j['bossName']).map((k, v) => MapEntry(k, v as String)),
      );

  String titleIn(String lang) => title[lang] ?? title['en'] ?? id;
  String summaryIn(String lang) => summary[lang] ?? summary['en'] ?? '';
  String factIn(String lang) => fact[lang] ?? fact['en'] ?? '';
  String bossNameIn(String lang) => bossName[lang] ?? bossName['en'] ?? '';
}

/// 地方決戦の地方（州の集まり）。[center] の州都が拠点になる。
class RegionGroup {
  final String id;
  final List<String> regions;
  final String center;
  final Map<String, String> name; // 言語→地方の名前
  const RegionGroup({required this.id, required this.regions, required this.center, required this.name});

  factory RegionGroup.fromJson(String id, Map<String, dynamic> j) => RegionGroup(
        id: id,
        regions: [for (final r in (j['regions'] as List)) r as String],
        center: j['center'] as String,
        name: _obj(j['name']).map((k, v) => MapEntry(k, v as String)),
      );

  /// 表示名。言語がなければ英語、それもなければ id。
  String nameIn(String lang) => name[lang] ?? name['en'] ?? id;
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

/// 背景の配色(3色: 地面・アクセント・空の順)と一言説明。素材(絵)はゲーム側が id で引く。
class Backdrop {
  final List<String> palette; // '#RRGGBB'
  final String note;
  const Backdrop({required this.palette, this.note = ''});

  factory Backdrop.fromJson(Map<String, dynamic> j) => Backdrop(
        palette: [for (final c in (j['palette'] as List)) c as String],
        note: j['note'] as String? ?? '',
      );
}

/// 施設・敵のこの国での見た目(素材id)と名前(言語→名称)。
/// 敵の見た目違い。[groups]・[regions] のどちらも空なら、どこでも出る。どちらかに当てはまれば、その州・地方で出る。
/// 地方ごとのミニボス（見た目・名前・使うスキル）。画像は `bosses/<skin>`。
class MiniBoss {
  final String skin;
  final Map<String, String> name;
  final String skill; // speedBurst/hpRegen/summon/stunFacility
  const MiniBoss({required this.skin, required this.name, required this.skill});

  factory MiniBoss.fromJson(Map<String, dynamic> j) => MiniBoss(
        skin: j['skin'] as String,
        name: _obj(j['name']).map((k, v) => MapEntry(k, v as String)),
        skill: j['skill'] as String,
      );

  String nameIn(String lang) => name[lang] ?? name['en'] ?? skin;
}

class EnemyVariant {
  final String skin;
  final Map<String, String> name;
  final Set<String> groups, regions;

  /// この見た目の敵だけの特性（任意）。hp・speed・baseDamage は、その種類の国の特性に掛ける倍率、armor は足す値。
  /// ability・action は、'none' 以外を書くと、その種類の能力・行動の代わりになる（ルール版3から）。
  final EnemyTrait? trait;
  const EnemyVariant({required this.skin, required this.name, this.groups = const {}, this.regions = const {}, this.trait});

  factory EnemyVariant.fromJson(Map<String, dynamic> j) {
    final when = _obj(j['when']);
    return EnemyVariant(
      skin: j['skin'] as String,
      name: _obj(j['name']).map((k, v) => MapEntry(k, v as String)),
      groups: {for (final g in (when['groups'] as List? ?? const [])) g as String},
      regions: {for (final r in (when['regions'] as List? ?? const [])) r as String},
      trait: j['trait'] == null ? null : EnemyTrait.fromJson(_obj(j['trait'])),
    );
  }

  bool get everywhere => groups.isEmpty && regions.isEmpty;

  bool matches({String? regionId, String? groupId}) =>
      everywhere || (regionId != null && regions.contains(regionId)) || (groupId != null && groups.contains(groupId));

  /// 表示名。言語がなければ英語、それもなければ素材id。
  String nameIn(String lang) => name[lang] ?? name['en'] ?? skin;
}

class Skin {
  final String skin;
  final Map<String, String> name;
  const Skin({required this.skin, required this.name});

  factory Skin.fromJson(Map<String, dynamic> j) => Skin(
        skin: j['skin'] as String,
        name: _obj(j['name']).map((k, v) => MapEntry(k, v as String)),
      );

  /// 表示名。言語がなければ英語、それもなければ素材id。
  String nameIn(String lang) => name[lang] ?? name['en'] ?? skin;
}
