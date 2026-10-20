# 主人公(案内役)の設定 v0.1

物語の章に、その国の案内役が話す。勝敗・エンジンのルールには関わらない。

## 決定(ユーザー)
- 国ごとに1人。立場は「地図を持つ見習い測量士」。
- 使う範囲: 物語の章の会話 + 着せ替え(見た目パックと連動)。

## キャラクター

| 国 | id | 名前 | 一言 |
|---|---|---|---|
| DE | `de_hero` | Mila | 地図帳を持つ見習い測量士。明るく好奇心いっぱいで、州を旅しながら地図を埋めていく |
| US | `us_hero` | Jo | 同上(アメリカの旅) |

- 名前は言語によらず同じ。口ぐせは決めない(翻訳しやすさのため)。
- 性別・年齢は描かない(子どもにも大人にも合う、やわらかい旅の服)。国ごとに旅装を変える(下の「画像」)。実在の人物の似顔絵にしない。
- セリフは短く、その章の題材(川・森・洞窟・印刷・海岸…)に触れる。史実の話はナレーターと注記(note)に任せ、主人公は感想・気づき・次への期待を言う。

## データ
- `packs/<国>/story.json` のトップに `hero`(`id` / `name` / `role`)。語り手は `hero`。
- 各章に最低1行(導入の最後と、クリア後のナレーションの直後)。知らない語り手を読み飛ばす古いアプリでも壊れない。
- 検査: 主人公の文があるのに `hero` が無い、`hero` の名前の英語が無い、を見つける(Dart と `validate_pack.py`)。

## 画像(別セッションで作る)
- 規格: 512x512 の透過PNG、胸から上のアイコン。置き場所 `terrimap_ge/assets/art/hero/de_hero.png`、`terrimap_us/assets/art/hero/us_hero.png`。
- **国ごとに見た目を変える**(ユーザー決定)。同じ「見習い測量士」でも、その国の旅の風景に合う旅装にする。国旗柄・民族衣装は使わない。

  | 国 | 見た目の方針 | 色 |
  |---|---|---|
  | DE (Mila) | 森と川の旅。ウールの帽子、ティールのマフラー、茶色の肩かけかばん、丸めた地図 | ティール・茶・クリーム |
  | US (Jo) | 広い大地の旅。つばの広い麦わら帽子、デニムのベスト、赤いバンダナ、丸めた地図 | デニムブルー・赤・麦わら色 |

- 無い間は、名前の頭文字の丸いアイコンで表示する(色は国のテーマ色)。
- プロンプト(英語のまま。1回4枚生成して1枚選ぶ):
  - DE
    ```
    a cheerful young apprentice surveyor wearing a knit wool cap, a teal scarf and a brown satchel, holding a rolled map, simple friendly face, soft pastel colors, chibi, bust portrait, plain white background, cute flat vector illustration, clean shapes, mobile game character icon, no text, no logo, no flag, no weapon
    ```
  - US
    ```
    a cheerful young apprentice surveyor wearing a wide-brim straw hat, a denim vest and a red bandana, holding a rolled map, simple friendly face, soft pastel colors, chibi, bust portrait, plain white background, cute flat vector illustration, clean shapes, mobile game character icon, no text, no logo, no flag, no weapon
    ```
- 気をつけること: 国旗・企業ロゴ・実在の人物に似た顔・武器は入れない。

## 着せ替え(見た目パックと連動、あとで)
- 衣装は見た目パックの商品の一つ(例: 旅の服、季節の服、地域の風景に合う旅装)。基本の見た目は国ごとに違い、着せ替えの衣装も国ごとに作る。
- 衣装を変えても、セリフ・性能は同じ。衣装の画像は主人公アイコンと同じ規格(512x512 透過PNG)。
- 民族衣装・宗教的な服・国旗柄は使わない(誤解や差別を避ける)。

## アプリ側(次のPR)
- 物語の画面: 主人公の行にアイコンと名前を出す。画像が無ければ頭文字の丸。
- 設定画面/コレクションに主人公の紹介(名前・一言)。着せ替えは見た目パックの実装後。
