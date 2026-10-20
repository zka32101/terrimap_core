# 画像の置き場所・命名・組み込み v0.1

一覧は `docs/art_manifest.md`（`python3 tools/art_manifest.py > docs/art_manifest.md` で更新）。

## 流れ（1枚ごと）

1. Leonardo で生成（設定は `docs/art_prompts_v0_2.md`）。選んだ1枚を `art_raw/<国>/<種類>/<id>.png` に保存（ここはコミットしない）。
2. 施設・敵・ボスは背景除去（Canva の背景除去など）→ 透過PNG → 512x512 に縮小。背景は俯瞰・縦長 768x1344(9:16)のまま(縮小しない)。
3. `art/<国>/<種類>/<id>.png` に置き、`python3 tools/art_manifest.py --check` で検査（形式・サイズ・背景は9:16・スプライトは透過・四隅・余白）。NG が出たら直す。
4. OK になった画像を、アプリ（`terrimap_ge` / `terrimap_us`）の `assets/art/<種類>/<id>.png` にコピー。`pubspec.yaml` の assets に各フォルダを追加（`assets/art/backdrops/` など）。

置き場所は国ごとの画像がアプリ側（画像はコアに入れない）。`art/` と `art_raw/` は `.gitignore`。天候は国共通（検査用の置き場所は `common/weather/`）。**組み込みは対応済み**: アプリの `assets/art/weather/<天候>.png`（8種類。768x1344・縦長9:16・透過。盤面と同じ向き）に置き、`pubspec.yaml` に `assets/art/weather/` を宣言すると、`ArtSet.weather(type)` が返し、`BattleView` が重ね画像として出す（ゆっくり揺れて濃さが呼吸する）。画像が無い天候は、従来の図形の演出で出る。

## 命名

| 種類 | フォルダ | ファイル名の id | 最終サイズ |
|---|---|---|---|
| 背景 | backdrops | `theme.backdrops` のキー | 768x1344(9:16・俯瞰) 不透明 |
| 施設 | facilities | `facilities.*.skin` | 512x512 透過 |
| 限定施設 | exclusive | `exclusiveFacility` の id | 512x512 透過 |
| 敵 | enemies | `enemySkins.*.skin` | 512x512 透過 |
| ボス | bosses | `extras[].id`（例 `de_loreley`） | 512x512 透過 |
| 名所カード | landmarks | `facts.json` の名所 id（例 `heidelberg_castle`。DE 20・US 36） | 512x512 透過 |

## 図鑑カードの名所画像

- `ArtSet.landmark(id)` が `assets/art/landmarks/<id>.png` を返す。図鑑（コレクション画面）のカードは、解放済みで画像があれば画像を、なければ 📍 のアイコンを出す（1枚ずつ判定。画像が無くても落ちない）。
- アプリの `pubspec.yaml` に `assets/art/landmarks/` を宣言する（フォルダが空でも宣言できるよう `.gitkeep` を置く）。

## 差し替え設計（実装済み: コアの `ArtSet` と `BattleView(art:)`）

- 描画は `BattleView` の `CustomPaint`。これまでは背景＝色、施設＝色の角丸四角（限定は金色＋★）、敵＝色の丸（ボスは大きい丸）。
- `ArtSet.load(rootBundle, facilitySkins:, enemySkins:, bossId:)` が `assets/art/` の PNG を読み、`BattleView(art: art)` に渡す。
  - アプリ側は `profile.facilitySkins` / `enemySkins` から `{種類: skin}` を作って渡す。ボスのあるステージだけ `bossId` を渡す。
- **フォールバック**: 画像が無い要素（1枚ずつ判定）は今の図形で描く。`art` を渡さない・assets が空・PNG が壊れていても落ちない。試作17枚（実際は13枚）が揃うまでは、あるものだけ置き換わる。
- 背景画像があるときは、全面に敷き、陸の地面の塗りは省いて**進路だけ**ゲーム側で重ねる（道は画像に描かない）。設置枠・拠点・入口・HPバーは従来どおり。
- 大きさ: 施設はマスの約92%、敵は直径0.64マス、ボスは1マス（図形時より大きめ。調整は `battle_view.dart` の `rad`）。

## 試作13枚が揃ったときの確認（バトル画面）

試作は **背景2＋施設6＋敵4＋ボス1＝13枚**（「17枚」は誤り）。

1. `python3 tools/art_manifest.py --prototype --check` が全部 OK。
2. DE アプリの `assets/art/` に13枚を入れ、`flutter run`。ステージ: 背景 alps（南部の州など）と city（ベルリン）、エクストラ `de_loreley`（ボス）。
3. 見るところ:
   - 敵が進路の上で見分けられるか（4種の形・色が小さい画面でも区別できるか）。
   - 施設6種が設置枠で見分けられるか。レベルの点・HPバー・★が絵と重なって読めるか。
   - 背景が明るすぎ・細かすぎて、進路（ベージュ）・設置枠（白線）・敵が埋もれないか。
   - ボスが通常の敵と明確に区別できる大きさか。
   - 季節の地面色が背景画像から浮かないか（背景がある場合は地面を塗らない）。
4. 気になる点は大きさ（`rad`）・背景の彩度（Leonardo の再生成か色調補正）で調整。良ければ残りを量産。

## 俯瞰の背景(9:16)

バトル盤面は縦長なので、背景は「真上から見た地面だけ」(空・地平線なし)の縦長にする。**中央は無地に近く空け、要素は左右の縁に置く**(進路帯・設置枠が見えるように)。

- 生成: Leonardo Phoenix 1.0 / Dynamic / 768x1344 / contrast 3.5 / enhancePrompt・alchemy・public オフ / 1回4枚(約18クレジット)
- 指示文: `flat ground texture of {場面} seen from above, {要素} only along the left and right borders, large empty plain {地面} area in the center, palette {3色}, no sky, no horizon, no buildings in the center, top-down view, bird's-eye, seamless, game map background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons`
- 除外: `text, letters, numbers, words, writing, logo, watermark, horizon, sky, perspective, vanishing point, characters, people, road markings`
- 彩度が強い絵(例: 赤い屋根)は、設置枠が見えにくくなる。地面の色は低彩度に。中央の模様が強いものは避ける。
- **Leonardo の出力は、拡張子が .png でも実体は JPEG のことがある。** コミット前に本物のPNGに変換する(`PIL.Image.save(..., format="PNG")`)。検査ツールが「PNGではない(JPEG)」で検出する。

## 天候の重ね画像（コードで描く）
- `tools/draw_weather.py <出力フォルダ>` が、天候8枚（768x1344・透過・パステル調）を Pillow で描く（乱数は固定なので、同じ画像ができる）。Leonardo は使わない
- 検査: `art/common/weather/` に置いて `python3 tools/art_manifest.py --check`
