import 'dart:convert';

/// 画面の文言。言語ごとのJSON（キー→文言）を読み、足りないキーは英語で埋める。
/// 文言の中の `{name}` のような部分は、[t] の `args` で置き換える。
class UiStrings {
  final String lang;
  final Map<String, String> _table;
  final Map<String, String> _fallback;

  UiStrings._(this.lang, this._table, this._fallback);

  /// [jsonByLang] は 言語コード→JSON文字列。[lang] がなければ [fallbackLang] を使う。
  factory UiStrings.parse(Map<String, String> jsonByLang, {required String lang, String fallbackLang = 'en'}) {
    Map<String, String> decode(String? s) =>
        s == null ? const {} : {for (final e in (jsonDecode(s) as Map<String, dynamic>).entries) e.key: e.value as String};
    final fb = decode(jsonByLang[fallbackLang]);
    final own = lang == fallbackLang ? fb : decode(jsonByLang[lang]);
    return UiStrings._(jsonByLang.containsKey(lang) ? lang : fallbackLang, own, fb);
  }

  /// キーが（その言語か英語に）あるか。
  bool has(String key) => _table.containsKey(key) || _fallback.containsKey(key);

  /// 文言を引く。その言語になければ英語、それもなければキーをそのまま返す。
  String t(String key, [Map<String, Object> args = const {}]) {
    var s = _table[key] ?? _fallback[key] ?? key;
    for (final e in args.entries) {
      s = s.replaceAll('{${e.key}}', '${e.value}');
    }
    return s;
  }

  /// 文言に含まれる `{名前}` の一覧（翻訳の検査用）。
  static Set<String> placeholders(String s) => {for (final m in RegExp(r'\{(\w+)\}').allMatches(s)) m.group(1)!};
}
