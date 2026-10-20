import 'dart:convert';

/// 名所（ランドマーク）。「この名所はどの州にある？」の問題の元データ（`packs/<国>/facts.json`）。
class Landmark {
  final String id;
  final String regionId; // 名所のある州（1つ）
  final Map<String, String> name; // 言語→名前（en は必須）
  final bool use; // 問題に使うか
  final String check; // 出典の確認: unchecked（未確認）／checked（確認済み）
  final String source; // 確認先の目安（確認したら実際の出典に書き換える）
  const Landmark({required this.id, required this.regionId, required this.name, this.use = true, this.check = 'unchecked', this.source = ''});

  /// 表示名。言語がなければ英語。
  String nameIn(String lang) => name[lang] ?? name['en'] ?? id;

  factory Landmark.fromJson(Map<String, dynamic> j) => Landmark(
        id: j['id'] as String,
        regionId: j['region'] as String,
        name: {for (final e in (j['name'] as Map<String, dynamic>).entries) e.key: e.value as String},
        use: j['use'] as bool? ?? true,
        check: j['check'] as String? ?? 'unchecked',
        source: j['source'] as String? ?? '',
      );
}

/// 深い知識の問題の元データ（特産品・名物・企業・行事・自然など。`packs/<国>/facts.json` の `knowledge`）。
/// 「この名物はどの州のもの？」の問題に使う。名所と同じ形（州は1つ）で、種類（kind）で問題文を変える。
class KnowledgeItem {
  /// 種類: food（食べ物・飲み物）／product（製品・企業）／culture（行事・文化）／nature（自然）。
  static const kinds = {'food', 'product', 'culture', 'nature'};

  final String id;
  final String regionId;
  final String kind;
  final Map<String, String> name; // 言語→名前（en は必須）
  final bool use;
  final String check;
  final String source;
  const KnowledgeItem({required this.id, required this.regionId, required this.kind, required this.name, this.use = true, this.check = 'unchecked', this.source = ''});

  String nameIn(String lang) => name[lang] ?? name['en'] ?? id;

  factory KnowledgeItem.fromJson(Map<String, dynamic> j) => KnowledgeItem(
        id: j['id'] as String,
        regionId: j['region'] as String,
        kind: j['kind'] as String? ?? 'culture',
        name: {for (final e in (j['name'] as Map<String, dynamic>).entries) e.key: e.value as String},
        use: j['use'] as bool? ?? true,
        check: j['check'] as String? ?? 'unchecked',
        source: j['source'] as String? ?? '',
      );
}

/// 国の事実のデータ（任意。`facts.json` がなければ null）。名所と、深い知識（特産品など）。事実の追加は、出典の確認の記録（`check`）とセットで。
class PackFacts {
  static const checks = {'unchecked', 'checked'};
  final List<Landmark> landmarks;
  final List<KnowledgeItem> knowledge;
  const PackFacts(this.landmarks, [this.knowledge = const []]);

  factory PackFacts.parse(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    if (m['v'] != 1) throw FormatException('facts.json: 未対応の版 ${m['v']}');
    return PackFacts(
      [for (final l in (m['landmarks'] as List? ?? const [])) Landmark.fromJson(l as Map<String, dynamic>)],
      [for (final k in (m['knowledge'] as List? ?? const [])) KnowledgeItem.fromJson(k as Map<String, dynamic>)],
    );
  }

  /// 問題に使う名所（`use` が true）。
  List<Landmark> get usable => [for (final l in landmarks) if (l.use) l];

  /// 州の名所（問題に使うもの）。
  List<Landmark> inRegion(String regionId) => [for (final l in usable) if (l.regionId == regionId) l];

  /// 州の深い知識の問題の題材（問題に使うもの）。
  List<KnowledgeItem> knowledgeIn(String regionId) => [for (final k in knowledge) if (k.use && k.regionId == regionId) k];

  /// 深い知識の題材のある州。
  Set<String> get knowledgeRegionIds => {for (final k in knowledge) if (k.use) k.regionId};

  /// 検査。エラーの文言の一覧（空なら問題なし）。[regionIds] は pack の地域 id。
  List<String> validate(Set<String> regionIds) {
    final err = <String>[];
    final seen = <String>{};
    for (final l in landmarks) {
      if (!seen.add(l.id)) err.add('名所 id の重複: ${l.id}');
      if (!regionIds.contains(l.regionId)) err.add('${l.id}: 未知の地域 ${l.regionId}');
      if ((l.name['en'] ?? '').isEmpty) err.add('${l.id}: 英語の名前がない');
      if (!checks.contains(l.check)) err.add('${l.id}: check が不正 ${l.check}');
    }
    final seenK = <String>{};
    for (final k in knowledge) {
      if (!seenK.add(k.id)) err.add('知識 id の重複: ${k.id}');
      if (!regionIds.contains(k.regionId)) err.add('${k.id}: 未知の地域 ${k.regionId}');
      if ((k.name['en'] ?? '').isEmpty) err.add('${k.id}: 英語の名前がない');
      if (!KnowledgeItem.kinds.contains(k.kind)) err.add('${k.id}: kind が不正 ${k.kind}');
      if (!checks.contains(k.check)) err.add('${k.id}: check が不正 ${k.check}');
    }
    return err;
  }
}
