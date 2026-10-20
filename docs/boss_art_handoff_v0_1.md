# ボス画像 5体の生成・組み込み 引き継ぎ v0.1

物語の章（`packs/<国>/story.json`）に結びつくボスの画像。画像が無い間は図形で描かれて動く。
共通の手順・規格は `docs/art_integration_v0_1.md`、画風の共通設定は `docs/art_prompts_v0_2.md` を参照。

## 対象（5体）

| 国 | ボスid | ボス名 | 元ネタ | 章 | 画像の置き場所 |
|---|---|---|---|---|---|
| DE | `de_grimm` | 大きな灰色の狼 | 伝説（グリム童話） | **章はまだ無い** | `terrimap_ge/assets/art/bosses/de_grimm.png` |
| DE | `de_nibelung` | 洞窟の竜 | 伝説（ニーベルンゲン） | **章はまだ無い** | `terrimap_ge/assets/art/bosses/de_nibelung.png` |
| US | `us_bunyan` | 巨大な青い牛 | 民話（バニヤン） | `us_ch_bunyan` | `terrimap_us/assets/art/bosses/us_bunyan.png` |
| US | `us_wright` | 疾風の精霊 | ゲームの創作（ライト兄弟の話の演出） | `us_ch_wright` | `terrimap_us/assets/art/bosses/us_wright.png` |
| US | `us_moon` | 月の番人 | ゲームの創作（アポロ11号の話の演出） | `us_ch_moon` | `terrimap_us/assets/art/bosses/us_moon.png` |

作成済み: `de_loreley`（ドイツ版）。**これを Style Reference に入れると画風がそろう。**
優先: 米国の3体（章がある）→ ドイツの2体。

## 規格（既存と同じ）
- 生成 1024x1024（1:1）→ 背景除去 → 512x512 の透過 PNG。ファイル名は `<ボスid>.png`。
- 1回4枚生成して1枚選ぶ。モデルは Leonardo Phoenix か Lucid Origin、スタイルは Illustration か Graphic Design。

## プロンプト（英語のまま貼る）

共通の Negative prompt:
`text, letters, logo, watermark, people, human face, weapon, blood, realistic, photo, 3d render, dark, scary, flags, emblem, road, path, background scenery`

共通の語尾（各プロンプトに含めた）:
`single game boss sprite, large, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons`

1. **us_bunyan**（巨大な青い牛）
   ```
   a giant friendly blue ox with large curved horns and a tiny red scarf, chibi, round shape, big eyes, smiling, folk-tale style, single game boss sprite, large, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
   ```
2. **us_wright**（疾風の精霊）
   ```
   a swirling wind spirit made of white and sky-blue air currents with a small propeller-like tail, chibi, round shape, big eyes, friendly, smiling, single game boss sprite, large, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
   ```
3. **us_moon**（月の番人）
   ```
   a round moon guardian creature with soft craters and a gentle glow, tiny stubby arms, chibi, big eyes, friendly, smiling, single game boss sprite, large, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
   ```
4. **de_grimm**（大きな灰色の狼）
   ```
   a huge fluffy grey wolf with glowing amber eyes and a big bushy tail, chibi, round shape, big eyes, friendly, storybook style, single game boss sprite, large, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
   ```
5. **de_nibelung**（洞窟の竜）
   ```
   a big round cave dragon with small wings curled around a pile of golden coins, chibi, big eyes, friendly, smiling, cartoon style, single game boss sprite, large, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
   ```

## 気をつけること
- **実在のものに似せない**: 実在の人物の顔・国旗・NASA などのロゴ・企業の機体や商標は入れない（月の番人に宇宙飛行士や旗を描かない。疾風の精霊は実在の飛行機の形にしない）。
- **怖くしない**: かわいく・やさしい顔。血・武器・暗い色は入れない。
- 物語の `note`（実在と創作を分ける注記）と矛盾しない。疾風の精霊・月の番人は「ゲームのために作ったキャラクター」。
- 利用規約: 有料プランで生成した画像を使う。Leonardo の最新の利用規約（商用利用・権利）を、公開前に確認する（未確認）。
- 敵の見た目・名前の追加は自由（決定: 「敵キャラクターは、物語ごとに新しく作ってよい」）。ただし**性能（体力・速さなど）を変える場合**は、エンジン・リプレイ・バランスの検証が要る。

## 組み込みの手順
1. 生成 → `art_raw/<国>/bosses/<id>.png`（コミットしない）→ 背景除去 → 512x512。
2. `art/<国>/bosses/<id>.png` に置いて、`python3 tools/art_manifest.py --check --dir art` で検査（NG は直す）。
3. アプリの `assets/art/bosses/<id>.png` にコピー。
4. **米国版（`terrimap_us`）は `pubspec.yaml` に `assets/art/bosses/` の宣言が無い**（いまは backdrops と landmarks だけ）。ボス画像を入れるときに追加する。敵・施設・限定施設の画像も入れるなら、`enemies/` `facilities/` `exclusive/` も宣言する。フォルダが空でも宣言できるよう `.gitkeep` を置く。
5. アプリのテスト・analyze を通して PR → CI が緑 → マージ。見た目（大きさ・背景との相性・読みやすさ）は実機で確認する。

## 次の章の作成（ドイツ）
`de_grimm` と `de_nibelung` には、物語の章がまだ無い。画像と並行して `packs/de/story.json` に章を足せる（ルール: `docs/story_design_v0_1.md`。伝説の章の `outro` には、実在と伝説を分ける `note` が必須）。
