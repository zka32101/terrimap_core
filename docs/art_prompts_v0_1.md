# 画像生成プロンプト集 v0.1

`tools/make_art_prompts.py` が `profile.json` から生成（設定を変えたら作り直す）。Canva / Leonardo AI 用。

## 使い方

- 共通の画風: `cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons`（各プロンプトに含めてある）
- **最初の1枚**で画風を決め、気に入った画像を2枚目以降の参照画像(Image Guidance / Style Reference)にして画風を揃える。
- 背景: 横長 16:9。道は描かない（道はゲーム側で引く）。
- 施設・敵: 正方形 1:1。無地の白背景で作り、後で背景除去。
- 戦争・特定の歴史を連想させる表現、実在の紋章・ロゴは入れない。

## DE

### 背景

- **alps**（アルプスの山と雪）
  ```
  Alpine snowy peaks, green meadow, wooden chalet, game background without any road or path, wide scene, palette #DDE8F0, #6C8EAD, #3E5C76, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **black_forest**（深い森と丘）
  ```
  dense fir forest and rolling hills, game background without any road or path, wide scene, palette #2F5D3A, #7FA66B, #C8D8B0, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **north_coast**（北海・バルト海の海岸と風車）
  ```
  North Sea coast with wind turbines and a small lighthouse, game background without any road or path, wide scene, palette #CFE3EA, #5B8FA8, #2E5E78, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **port**（港とコンテナ）
  ```
  harbor with shipping containers and cranes, game background without any road or path, wide scene, palette #B8C4CC, #4A6572, #2B3A42, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **city**（都市のスカイライン）
  ```
  city skyline with modern towers, game background without any road or path, wide scene, palette #D9D9E3, #7A7A93, #44445A, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **vineyard**（川沿いのぶどう畑）
  ```
  riverside vineyard terraces, game background without any road or path, wide scene, palette #E3E8B8, #9BB05A, #5E7A34, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **farmland**（麦畑と風力発電）
  ```
  wheat fields with wind turbines, game background without any road or path, wide scene, palette #EFE6B5, #C9B458, #7E8C3A, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **industry**（工場と炭鉱の街）
  ```
  factories and a coal-mining town, game background without any road or path, wide scene, palette #C9C3BD, #7C6F64, #3C3530, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **lakes**（湖と森）
  ```
  forest lakes and calm water, game background without any road or path, wide scene, palette #D5E8E0, #5FA08A, #2F6B58, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **castle_hills**（丘の上の城）
  ```
  hilltop castle over green hills, game background without any road or path, wide scene, palette #E5DCC8, #9A8664, #5A4A32, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```

### 施設

- **farm_windmill**（農場と風車 / farm）
  ```
  a farm with a windmill and a small barn, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **harbor_cutter**（港の漁船 / fishery）
  ```
  a small fishing cutter boat at a harbor, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **automotive_plant**（自動車工場 / factory）
  ```
  a car factory with a chimney and a little car, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **coal_mine**（炭鉱 / mine）
  ```
  a coal mine with a headframe tower and a cart, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **hilltop_castle**（丘の城 / castle）
  ```
  a small castle on a hill, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **chapel**（聖堂 / shrine）
  ```
  a small stone chapel with a bell tower, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```

### 敵

- **rust_sprite**（さび妖精 / normal）
  ```
  a small rusty sprite creature, mischievous, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **dash_gremlin**（疾走グレムリン / speedy）
  ```
  a fast little gremlin running, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **iron_golem**（鉄のゴーレム / armored）
  ```
  a sturdy iron golem with armor plates, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **forest_sprite**（森の精 / healer）
  ```
  a gentle forest spirit with leaves, healer, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```

## US

### 背景

- **desert**（砂漠と赤い岩）
  ```
  desert with red rock mesas and cacti, game background without any road or path, wide scene, palette #F1D9A8, #D9985B, #8C4F2E, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **plains**（大平原と地平線）
  ```
  vast prairie with a far horizon, game background without any road or path, wide scene, palette #EAE2A8, #B7B04A, #6F7A2E, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **rockies**（ロッキーの山と雪）
  ```
  rocky mountains with snow, game background without any road or path, wide scene, palette #DCE6EE, #7C98B0, #46607A, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **bayou**（湿地とバイユー）
  ```
  swamp bayou with cypress trees and mist, game background without any road or path, wide scene, palette #CFE0C4, #5F8F5B, #2F5A3A, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **atlantic_coast**（大西洋岸の港と灯台）
  ```
  Atlantic harbor with a lighthouse, game background without any road or path, wide scene, palette #D3E4EC, #5C93AE, #2F5F7A, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **pacific_coast**（太平洋岸と霧）
  ```
  Pacific coast with sea fog and cliffs, game background without any road or path, wide scene, palette #D8E8E4, #4F9A94, #276A66, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **great_lakes**（五大湖と港町）
  ```
  great lakes port town, game background without any road or path, wide scene, palette #D5E4EE, #5A8DB0, #2E5F86, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **appalachia**（アパラチアの丘と霧）
  ```
  misty Appalachian forested hills, game background without any road or path, wide scene, palette #D9E0C8, #7B9468, #445E3A, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **skyline**（摩天楼の街）
  ```
  skyscraper city skyline, game background without any road or path, wide scene, palette #DADBE6, #7C7E9E, #454866, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **tundra**（氷原とオーロラ）
  ```
  icy tundra with aurora in the sky, game background without any road or path, wide scene, palette #E6EEF2, #9DB8C6, #5A7A8C, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **tropics**（亜熱帯の海と島）
  ```
  subtropical sea and small islands with palm trees, game background without any road or path, wide scene, palette #D6F0E0, #4DB88C, #1F7A5A, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **cornfield**（とうもろこし畑とサイロ）
  ```
  cornfield with a grain silo, game background without any road or path, wide scene, palette #F2E8B0, #D8B84A, #7C8A34, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```

### 施設

- **grain_silo**（穀物サイロ / farm）
  ```
  a grain silo next to a red barn, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **fishing_trawler**（底引き漁船 / fishery）
  ```
  a fishing trawler ship with nets, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **assembly_line**（組立ライン / factory）
  ```
  an assembly line factory with robotic arms, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **oil_derrick**（油井 / mine）
  ```
  an oil derrick pump, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **capitol_hall**（議事堂 / castle）
  ```
  a domed capitol hall building, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **town_church**（町の教会 / shrine）
  ```
  a white town church with a steeple, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```

### 敵

- **dust_devil**（つむじ風 / normal）
  ```
  a swirling dust devil creature with eyes, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **tumbleweed**（回転草 / speedy）
  ```
  a rolling tumbleweed creature, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **rock_golem**（岩のゴーレム / armored）
  ```
  a chunky red rock golem, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```
- **cactus_nurse**（サボテンの看護師 / healer）
  ```
  a cute cactus healer with a bandage, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
  ```

