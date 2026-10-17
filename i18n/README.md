# 画面の文言（多言語）

バトル画面など、アプリの共通の文言。言語ごとに `battle.<言語コード>.json`（キー→文言）。
**原本は英語（`battle.en.json`）**。足りない言語・キーは英語で表示される（アプリは落ちない）。
地域名・州都名は別（`packs/<国>/strings/<言語>.json`）。

## Google翻訳で訳す手順（ローカルのセッション用）
1. 訳す言語のコード（例 `fr`）で、足りない文言を出す。
   `python3 tools/i18n_check.py missing fr > /tmp/fr_todo.json`
2. `/tmp/fr_todo.json` の **値だけ** を翻訳する（キーは変えない）。Google翻訳の「文書」ではなく、JSONの値を並べて訳すか、1文ずつ訳す。
3. **`{n}` `{name}` `{s}` `{total}` `{capital}` `{names}` などの `{…}` はそのまま残す**（訳されたり、全角や空白が入ったりしやすい）。
4. 取り込む。崩れがあれば止まって教えてくれる。
   `python3 tools/i18n_check.py merge fr /tmp/fr_translated.json`
5. 全体の検査。 `python3 tools/i18n_check.py check`
6. 地域名・州都名も同じ言語で `packs/<国>/strings/fr.json` に足し、`pack.json` の `languages` に言語を足す（`python3 tools/validate_pack.py packs/<国>` で検査）。

## 翻訳のコツ
- 短い文言（ボタン・見出し）は、機械翻訳だと不自然になりやすい。実機で見て直す。
- `facility.*` `enemy.*` `skill.*` は名前なので、短く言い切りの形に。
- 戦争や特定の歴史を連想させる言い回し・国旗・紋章は使わない（`docs/aso-rules.md` も参照）。
- 人の顔写真・実在の人物名は入れない。

## アプリでの読み込み
`UiStrings.parse({'en': enJson, 'fr': frJson}, lang: 'fr')`。JSONは `rootBundle.loadString('packages/terrimap_core/i18n/battle.fr.json')` で読む。

## 対応言語（案。`lib/i18n/languages.dart` で変更）
en（原本）・de・fr・es・it・pt・nl・tr・ja・ko・zh（簡体字）の11言語。ドイツのアプリでは de、米国のアプリでは es を優先して訳すと効果が大きい。
言語を足す・減らすときは `languages.dart` と、地域名の `packs/<国>/strings/<言語>.json` をそろえる。
