/// 限定施設の原型（設計書 §6.6）。地域の `exclusiveFacility` の id から決まる。
enum ExclusiveKind {
  core, // 強化の核: 周囲1マスの施設の威力・攻撃速度 +15%
  port, // 港・交通: 近くの敵を鈍足にする
  resource, // 資源: 撃破コイン +15%
  brewery, // 醸造・工房: 範囲の敵に継続ダメージ
  symbol, // 象徴: 拠点HPをゆっくり回復し、周囲の施設を守る
  space, // 宇宙・先端: 長射程・貫通
}

const exclusiveKinds = <String, ExclusiveKind>{
  'automotive_works': ExclusiveKind.core,
  'aerospace_works': ExclusiveKind.core,
  'tech_campus': ExclusiveKind.core,
  'national_lab': ExclusiveKind.core,
  'seaport': ExclusiveKind.port,
  'container_port': ExclusiveKind.port,
  'pipeline': ExclusiveKind.port,
  'stock_exchange': ExclusiveKind.resource,
  'oil_derrick': ExclusiveKind.resource,
  'ruhr_works': ExclusiveKind.resource,
  'brewery': ExclusiveKind.brewery,
  'distillery': ExclusiveKind.brewery,
  'winery': ExclusiveKind.brewery,
  'porcelain_works': ExclusiveKind.brewery,
  'parliament': ExclusiveKind.symbol,
  'capitol': ExclusiveKind.symbol,
  'wartburg': ExclusiveKind.symbol,
  'space_center': ExclusiveKind.space,
};

/// 原型ごとの基礎値（暫定。M4の自動対戦で調整する）。damage が 0 の施設は自分では撃たない。
class ExclusiveSpec {
  final int cost, damage;
  final double range, attackSpeed;
  final String action;
  const ExclusiveSpec(this.cost, this.damage, this.range, this.attackSpeed, this.action);
}

const exclusiveSpecs = <ExclusiveKind, ExclusiveSpec>{
  ExclusiveKind.core: ExclusiveSpec(160, 0, 0, 1, 'single'),
  ExclusiveKind.port: ExclusiveSpec(120, 0, 0, 1, 'single'),
  ExclusiveKind.resource: ExclusiveSpec(140, 0, 0, 1, 'single'),
  ExclusiveKind.brewery: ExclusiveSpec(150, 0, 0, 1, 'single'),
  ExclusiveKind.symbol: ExclusiveSpec(180, 0, 0, 1, 'single'),
  ExclusiveKind.space: ExclusiveSpec(200, 40, 4.5, 0.7, 'pierce'),
};
