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

/// 国の事実のデータ（任意。`facts.json` がなければ null）。今は名所だけ。事実の追加は、出典の確認の記録（`check`）とセットで。
class PackFacts {
  static const checks = {'unchecked', 'checked'};
  final List<Landmark> landmarks;
  const PackFacts(this.landmarks);

  factory PackFacts.parse(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    if (m['v'] != 1) throw FormatException('facts.json: 未対応の版 ${m['v']}');
    return PackFacts([for (final l in (m['landmarks'] as List? ?? const [])) Landmark.fromJson(l as Map<String, dynamic>)]);
  }

  /// 問題に使う名所（`use` が true）。
  List<Landmark> get usable => [for (final l in landmarks) if (l.use) l];

  /// 州の名所（問題に使うもの）。
  List<Landmark> inRegion(String regionId) => [for (final l in usable) if (l.regionId == regionId) l];

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
    return err;
  }
}
