# 敵・ミニボス画像 36体の生成・組み込み 引き継ぎ v0.1

敵キャラ再設計（`docs/enemy_redesign_v0_1.md`）で増えた敵の画像。**画像が無い間は図形で描かれて動く**ので、揃った分から入れてよい（1枚ずつでも可）。
共通の手順・規格は `docs/art_integration_v0_1.md`、画風の共通設定は `docs/art_prompts_v0_2.md`、ボス画像の前例は `docs/boss_art_handoff_v0_1.md` を参照。

## 対象（国ごとに18体、合計36体）

| 区分 | 数/国 | 置き場所（アプリ内） | ゲーム上の役割 |
|---|---|---|---|
| 新しい敵 | 4 | `assets/art/enemies/<skin>.png` | 5波〜に出る。飛ぶ・妨害・群れ・分裂 |
| hard だけの敵 | 2 | `assets/art/enemies/<skin>.png` | hard のときだけ出る強敵（ブルート・ジャマー） |
| 見た目違い | 8 | `assets/art/enemies/<skin>.png` | 基本の4種類（普通・足速・装甲・回復）の別の姿 |
| ミニボス | 4 | `assets/art/bosses/<skin>.png` | 地方ごとに1体。地方決戦・エクストラの中盤、エンドレスの10・20波 |

置き場所の宣言（`pubspec.yaml`）は、ドイツ版・米国版とも **すでにある**（`enemies/` `bosses/` を含む）。`boss_art_handoff_v0_1.md` の「米国版に宣言が無い」は古い記述で、いまは不要。

## 規格（既存と同じ）
- 生成 1024x1024（1:1）→ 背景除去 → **512x512 の透過 PNG**。ファイル名は `<skin>.png`（下の表の `skin` と同じ）。
- 1回4枚生成して1枚選ぶ。モデルは Leonardo Phoenix か Lucid Origin、スタイルは Illustration か Graphic Design。
- **画風の固定**: 作成済みの画像（`de_loreley`、または先に作った敵 1 枚）を Style Reference（強さ Mid〜High）に入れる。
- 敵は小さく表示される（マス目の 3 分の 1 ほど）ので、**輪郭をはっきり・パーツを少なく・色を濃いめ**に。ミニボスは敵より大きく表示される（通常のボスより小さい）。
- 画面では**種類が見た目で分かる**ことが大事。下の「見分けのポイント」を輪郭や色に出す。

## 共通のプロンプト部品

共通の Negative prompt:
`text, letters, logo, watermark, people, human face, weapon, blood, realistic, photo, 3d render, dark, scary, flags, emblem, road, path, background scenery`

共通の語尾（各プロンプトに含めた）:
`single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons`

共通の語（かわいくする）: `chibi, round shape, big eyes, friendly`

ミニボスは語尾を `single game mini-boss sprite, medium-large, front view, ...`（同じ残り）にする。

## ドイツ（`terrimap_ge`）

### 新しい敵（4）
| skin | 名前 | 種類 | 見分けのポイント |
|---|---|---|---|
| `wolpertinger` | ヴォルペルティンガー(羽うさぎ) | 飛ぶ敵 | 羽が目立つ。空を飛ぶ |
| `mine_imp` | 坑道のいたずら小鬼 | 妨害の敵 | 小さなランタンと火花（工具や武器は持たせない） |
| `bat_swarm` | こうもりの群れ | 群れの敵 | 小さなこうもりが 3 匹まとまる |
| `mud_blob` | 泥のかたまり | 分裂の敵 | ぷるぷるの丸い塊。2つに割れかけた形 |

```
wolpertinger: a cute winged rabbit with small antlers and white feathered wings, flying, chibi, round shape, big eyes, friendly, folk-tale style, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
mine_imp: a small mischievous mine imp with a glowing little lantern and sparks around its hands, chibi, round shape, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
bat_swarm: three tiny round bats flying close together, chibi, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
mud_blob: a round wobbly mud blob that looks like it is about to split into two halves, chibi, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
```

### hard だけの敵（2）
| skin | 名前 | 種類 | 見分けのポイント |
|---|---|---|---|
| `forest_ogre` | 森の大鬼 | ブルート（硬く重い） | 大きく丸い。こけと樹皮の鎧。他の敵より大きく |
| `fog_wisp` | 霧のいたずら火 | ジャマー（施設の射程を縮める） | 霧をまとう青白い火の玉 |

```
forest_ogre: a big round friendly forest ogre covered in moss and bark armor plates, chibi, round shape, big eyes, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
fog_wisp: a pale blue wisp flame wrapped in curling mist, small floating spirit, chibi, round shape, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
```

### 見た目違い（8）
| skin | 名前 | 元の種類 | 特性（目安） |
|---|---|---|---|
| `kobold_miner` | 鉱山のコボルト | 普通 | 少し硬い（鉱山の小人） |
| `wichtel` | ヴィヒテル(小人) | 普通 | 速くて脆い（赤い三角帽の小人。実在の人物に似せない） |
| `field_hare` | 疾走する野うさぎ | 足速 | 速い |
| `rat_pack` | ねずみの群れ | 足速 | 群れ（小さなねずみが 3 匹） |
| `stone_giant` | 石の巨人 | 装甲 | HP が高く遅い（岩の体） |
| `ice_golem` | 氷のゴーレム | 装甲 | 再生する（氷の体） |
| `water_nixie` | 水の精(ニクセ) | 回復 | 水色の精霊 |
| `flower_fairy` | 花の精 | 回復 | 花の妖精 |

```
kobold_miner: a small kobold miner with a round helmet lamp, stocky, chibi, round shape, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
wichtel: a tiny gnome-like house sprite with a red pointed hat and a white beard, chibi, round shape, big eyes, friendly, folk-tale style, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
field_hare: a fast field hare in mid-leap with long ears, chibi, round shape, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
rat_pack: three small round rats running together, chibi, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
stone_giant: a big round stone giant made of grey boulders with a mossy head, chibi, round shape, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
ice_golem: a round ice golem made of pale blue crystals with frosty sparkles, chibi, round shape, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
water_nixie: a gentle water nixie spirit made of flowing aqua water with small bubbles, healer, chibi, round shape, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
flower_fairy: a tiny flower fairy with petal wings and a flower crown, healer, chibi, round shape, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
```

### ミニボス（4。置き場所は `assets/art/bosses/`）
| skin | 名前 | 地方 | 使うスキル（見た目の手がかり） |
|---|---|---|---|
| `nebel_warden` | 霧の海の番人 | 北 | 施設を止める（霧の渦） |
| `mountain_keeper` | 山の岩の守り手 | 南 | HP を回復（どっしりした岩） |
| `black_forest_hunter` | 黒い森の狩人 | 西 | 手下を呼ぶ（森の獣の姿。人の顔は描かない） |
| `lake_master` | 湖の水の主 | 東 | 加速（大きな魚か水の獣） |

```
nebel_warden: a large round fog guardian made of drifting sea mist with two glowing blue eyes and a small lighthouse lantern on its head, chibi, big eyes, friendly, single game mini-boss sprite, medium-large, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
mountain_keeper: a large round mountain rock keeper with snow on its head and small pine trees on its shoulders, chibi, big eyes, friendly, single game mini-boss sprite, medium-large, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
black_forest_hunter: a large dark-green forest stag spirit with big antlers covered in fir branches and a small red mushroom hat, chibi, big eyes, friendly, single game mini-boss sprite, medium-large, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
lake_master: a large friendly lake pike fish spirit made of rippling blue water with a lily pad crown, chibi, big eyes, single game mini-boss sprite, medium-large, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
```

## 米国（`terrimap_us`）

### 新しい敵（4）
| skin | 名前 | 種類 | 見分けのポイント |
|---|---|---|---|
| `dust_crow` | ほこりのカラス | 飛ぶ敵 | 砂ぼこり色のカラス。翼を広げる |
| `prairie_trickster` | 大草原のいたずら者 | 妨害の敵 | コヨーテ風の小さな獣（いたずら顔） |
| `locust_swarm` | イナゴの群れ | 群れの敵 | 小さなイナゴが 3 匹 |
| `tar_blob` | タールのかたまり | 分裂の敵 | 黒いぷるぷるの塊（かわいい顔）。割れかけ |

```
dust_crow: a cute sand-colored crow with spread wings and a puff of dust trailing behind, flying, chibi, round shape, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
prairie_trickster: a small mischievous coyote-like prairie trickster with a big grin and a bandana, chibi, round shape, big eyes, friendly, folk-tale style, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
locust_swarm: three tiny round green locusts jumping together, chibi, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
tar_blob: a round wobbly dark tar blob with a cute face that looks like it is about to split into two halves, chibi, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
```

### hard だけの敵（2）
| skin | 名前 | 種類 | 見分けのポイント |
|---|---|---|---|
| `canyon_troll` | 峡谷のトロル | ブルート | 赤い岩の大きな体。他の敵より大きく |
| `static_spirit` | 静電気の精 | ジャマー | 黄色い火花と小さな稲妻をまとう |

```
canyon_troll: a big round friendly canyon troll made of layered red sandstone with small cactus on its shoulders, chibi, round shape, big eyes, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
static_spirit: a small floating static electricity spirit with yellow sparks and tiny lightning bolts around it, chibi, round shape, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
```

### 見た目違い（8）
| skin | 名前 | 元の種類 | 特性（目安） |
|---|---|---|---|
| `dust_imp` | ほこりの小鬼 | 普通 | 速め（ほこり色の小鬼） |
| `mud_gnome` | ぬかるみの小人 | 普通 | 硬くて遅め（泥まみれの小人） |
| `jackalope` | ジャッカロープ | 足速 | 速くてやや硬い（うさぎに小さな枝角） |
| `root_runner` | 走る木の根 | 足速 | 脆く、拠点への被害が大きい（根が足になった姿） |
| `fossil_turtle` | 化石の亀 | 装甲 | HP が高く遅い（化石の甲羅） |
| `scrap_bull` | 鉄くずの牛 | 装甲 | 被害が大きく速め（鉄くずを集めた牛。実在のブランドロゴは描かない） |
| `honey_sprite` | 蜂蜜の精 | 回復 | 回復の輪（黄金色の蜂蜜の精） |
| `rain_cloud_sprite` | 雨雲の精 | 回復 | 速め（小さな雨雲） |

```
dust_imp: a small round dust imp with sandy swirls and little horns, chibi, round shape, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
mud_gnome: a stocky mud-covered gnome with a drooping brown hat, chibi, round shape, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
jackalope: a jackalope, a cute rabbit with small antelope antlers, mid-leap, chibi, round shape, big eyes, friendly, folk-tale style, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
root_runner: a running tree root creature with two root legs and a small leafy tuft, chibi, round shape, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
fossil_turtle: a big round fossil turtle with a stone shell showing spiral fossil patterns, chibi, round shape, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
scrap_bull: a sturdy bull built from rusty scrap metal plates and gears, chibi, round shape, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
honey_sprite: a golden honey sprite with little translucent bee wings and a honey drop on its head, healer, chibi, round shape, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
rain_cloud_sprite: a small fluffy rain cloud sprite with tiny raindrops falling, healer, chibi, round shape, big eyes, friendly, single game sprite, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
```

### ミニボス（4。置き場所は `assets/art/bosses/`）
| skin | 名前 | 地方 | 使うスキル（見た目の手がかり） |
|---|---|---|---|
| `dust_storm_lord` | 砂嵐の主 | 西 | 加速（渦巻く砂嵐） |
| `autumn_great_tree` | 紅葉の大木 | 北東 | 手下を呼ぶ（枝から葉の小さな妖精） |
| `prairie_wind_king` | 大草原の風の王 | 中西部 | HP を回復（草と麦の穂のたてがみ） |
| `bayou_gator_king` | 沼地の大ワニ | 南 | 施設を止める（沼の苔をまとったワニ） |

```
dust_storm_lord: a large swirling sandstorm creature in warm tan and orange with two glowing eyes and a small rock crown, chibi, big eyes, friendly, single game mini-boss sprite, medium-large, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
autumn_great_tree: a large friendly great tree creature with red and orange maple leaves, a wide trunk face and small branch arms, chibi, big eyes, single game mini-boss sprite, medium-large, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
prairie_wind_king: a large lion-like prairie wind spirit with a mane of golden wheat and tall grass, chibi, big eyes, friendly, single game mini-boss sprite, medium-large, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
bayou_gator_king: a large friendly bayou alligator wearing a crown of moss and water lilies, chibi, big eyes, single game mini-boss sprite, medium-large, front view, plain white background, cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons
```

## 優先順
1. **画風を決める1枚**: `forest_ogre`（ドイツ）か `canyon_troll`（米国）。大きく目立つので、画面での見え方を早く確かめられる。
2. ミニボス 8 体（地方決戦・エクストラ・エンドレスで目立つ）。
3. 新しい敵 8 体 → hard だけの敵 4 体（`wolpertinger` `dust_crow` など、画面でよく出るもの先）。
4. 見た目違い 16 体。

## 気をつけること
- **実在のものに似せない**: 実在の人物の顔・国旗・企業ロゴ・商標は入れない。`scrap_bull` に実在ブランドのロゴを入れない。伝承の生き物は、一般的な民話に限る（実在の宗教の聖なる存在は避ける）。
- **怖くしない**: かわいく・やさしい顔。血・武器・暗い色は入れない（`black_forest_hunter` も人ではなく獣の姿で）。
- **種類の見分け**: 画面で同じ種類の別の見た目が混ざる。同じ種類の見た目違いは、色や輪郭が近すぎないようにしつつ、基本の見た目（`enemySkins` の画像）と同じ「役割の手がかり」（盾・羽・群れ・割れかけなど）を残す。
- 名前・見た目は**仮**（`packs/<国>/profile.json`）。画像を作る中で変えたくなったら、名前と `skin` を一緒に直す（`tools/validate_pack.py` が検査する）。
- 利用規約: 有料プランで生成した画像を使う。Leonardo の最新の利用規約（商用利用・権利）を、公開前に確認する（未確認）。

## 組み込みの手順
1. 生成 → `art_raw/<国>/{enemies,bosses}/<skin>.png`（コミットしない）→ 背景除去 → 512x512。
2. `art/<国>/{enemies,bosses}/<skin>.png` に置いて、`python3 tools/art_manifest.py --check --dir art` で検査（NG は直す）。一覧は `docs/art_manifest.md`（状態の欄が「未作成」→「作成済み」になる）。
3. アプリの `assets/art/enemies/<skin>.png` または `assets/art/bosses/<skin>.png` にコピー（`terrimap_ge` はドイツの分、`terrimap_us` は米国の分）。**コードの変更は不要**（敵の見た目は `ArtSet` が `enemies/<skin>` を、ミニボスは `bosses/<skin>` を読む）。
4. アプリのテスト・analyze を通して PR → CI が緑 → マージ。
5. **実機・ブラウザで見た目を確認**: 大きさ（敵は小さく表示される）、背景との相性、同じ種類の見た目違いの見分け、ミニボスの存在感。
6. 画像ができたら、`docs/art_manifest.md` を更新する（`python3 tools/art_manifest.py --dir art > docs/art_manifest.md`）。
