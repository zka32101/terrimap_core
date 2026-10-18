# 翻訳元情報まとめ

`tools/make_i18n_source.py` が作る（元の文言を変えたら作り直す）。**原本は英語**。対象は11言語: en・de・fr・es・it・pt・nl・tr・ja・ko・zh。

## 1. 全体像

| # | 種類 | 場所 | 件数 | 今ある言語 | 訳す手順 |
|---|---|---|---|---|---|
| A | バトル画面の文言 | `i18n/battle.en.json` | 161件（約487語） | en | `tools/i18n_check.py missing/merge/check`（`i18n/README.md`） |
| B-DE | 地域名・州都名 | `packs/de/strings/<言語>.json` | 地域16＋州都16 | en・de | 固有名詞。各言語の通称で（機械翻訳は避け、Wikipedia の言語版などで確認） |
| B-US | 地域名・州都名 | `packs/us/strings/<言語>.json` | 地域51＋州都51 | en | 固有名詞。各言語の通称で（機械翻訳は避け、Wikipedia の言語版などで確認） |
| C-DE | プロファイルの文言（地方名・エクストラ・施設/敵の名前） | `packs/de/profile.json` | 地方4・エクストラ3・施設6・敵4 | en・ja（一部 de） | 下の§4。エクストラの `fact` は**先に事実確認**（§5） |
| C-US | プロファイルの文言（地方名・エクストラ・施設/敵の名前） | `packs/us/profile.json` | 地方4・エクストラ3・施設6・敵4 | en・ja（一部 de） | 下の§4。エクストラの `fact` は**先に事実確認**（§5） |
| D-terrimap_ge | アプリのホーム・クイズ・設定など | `terrimap_ge/lib/strings.dart` | 35件 | en・de | 文言を言語ごとの map に足す（`{}` などの引数は残す） |
| D-terrimap_us | アプリのホーム・クイズ・設定など | `terrimap_us/lib/strings.dart` | 35件 | en | 文言を言語ごとの map に足す（`{}` などの引数は残す） |

## 2. 言語ごとの状況

| 言語 | A バトル | B-DE | B-US | C-DE 地方・エクストラ | C-US 地方・エクストラ | D-terrimap_ge | D-terrimap_us |
|---|---|---|---|---|---|---|---|
| en | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| de | — | ✅ | — | ✅ | — | ✅ | — |
| fr | — | — | — | — | — | — | — |
| es | — | — | — | — | — | — | — |
| it | — | — | — | — | — | — | — |
| pt | — | — | — | — | — | — | — |
| nl | — | — | — | — | — | — | — |
| tr | — | — | — | — | — | — | — |
| ja | — | — | — | ✅ | ✅ | — | — |
| ko | — | — | — | — | — | — | — |
| zh | — | — | — | — | — | — | — |

（✅=ある、—=まだ。`profile.json` には ja/de があるが、en 以外は一部）

## 3. A バトル画面の文言（原本の英語）

Google翻訳に出す形は `python3 tools/i18n_check.py missing <言語>`。`{n}` `{name}` などの `{…}` は訳さず残す。

| グループ | 件数 | 例 |
|---|---|---|
| `hud.*` | 10 | Wave {n}/{total} |
| `difficulty.*` | 3 | Easy |
| `stage.*` | 22 | Choose a state to defend |
| `facility.*` | 22 | Farm |
| `exclusive.*` | 24 | Boosts nearby buildings by 15%. |
| `enemy.*` | 13 | Raider |
| `boss.*` | 4 | The boss speeds up! |
| `skill.*` | 16 | Choose a skill for the next wave |
| `assist.*` | 9 | Answer correctly to choose your skill |
| `weather.*` | 12 | Hurricane |
| `season.*` | 4 | Spring |
| `result.*` | 6 | Victory! |
| `base.*` | 2 | An enemy reached the base! |
| `daily.*` | 7 | Daily Battle |
| `replay.*` | 7 | Watch replay |

## 4. C プロファイルの文言（原本の英語）

### DE

**地方名**: `north`=North / `east`=East / `west`=West / `south`=South

**施設の名前**: `farm_windmill`=Farm & Windmill / `harbor_cutter`=Harbor Cutter / `automotive_plant`=Automotive Plant / `coal_mine`=Coal Mine / `hilltop_castle`=Hilltop Castle / `chapel`=Chapel

**敵の名前**: `rust_sprite`=Rust Sprite / `dash_gremlin`=Dash Gremlin / `iron_golem`=Iron Golem / `forest_sprite`=Forest Sprite

**国のひとこと説明**: Steady and planned. Armored enemies are common; combine each state's specialty to defend.

**エクストラ**

| id | 種類 | タイトル | ボス | あらすじ | 事実の注記(fact) |
|---|---|---|---|---|---|
| `de_loreley` | legend | The Rock of Loreley | Water Nymph of the Rhine | Along the Rhine, a siren is said to sing from a high rock. Defend the river valley as her song stirs the mist. | The Loreley is a real rock above the Rhine near Sankt Goarshausen. The singing siren is a legend, made famous by Clemens Brentano (1801) and Heinrich Heine's poem (1824). |
| `de_grimm` | legend | The Grimm Forest | The Great Grey Wolf | Wolves, wandering animals and swarms of mice from the old folk tales fill the forest. Hold the path through the trees. | Jacob and Wilhelm Grimm collected folk tales and published them as Children's and Household Tales (first edition 1812). The creatures here are inspired by those tales, not by a historical event. |
| `de_nibelung` | legend | The Dragon of the Nibelungs | The Cave Dragon | In a medieval hero legend, a dragon guards a cave of treasure. Hold the castle hills against its guardians. | The Nibelungenlied is a medieval German epic poem written around 1200. Worms, in today's Rhineland-Palatinate, is one of its settings. Siegfried's dragon fight is told in it as a legend; a dragon guarding a hoard in a cave is closer to the Norse versions. The hero and the dragon are legendary. |

### US

**地方名**: `northeast`=Northeast / `midwest`=Midwest / `south`=South / `west`=West

**施設の名前**: `grain_silo`=Grain Silo / `fishing_trawler`=Fishing Trawler / `assembly_line`=Assembly Line / `oil_derrick`=Oil Derrick / `capitol_hall`=Capitol Hall / `town_church`=Town Church

**敵の名前**: `dust_devil`=Dust Devil / `tumbleweed`=Tumbleweed / `rock_golem`=Rock Golem / `cactus_nurse`=Cactus Nurse

**国のひとこと説明**: Vast and varied. Fast enemies on long paths; prepare for regional extreme weather.

**エクストラ**

| id | 種類 | タイトル | ボス | あらすじ | 事実の注記(fact) |
|---|---|---|---|---|---|
| `us_bunyan` | legend | Paul Bunyan's Forest | The Giant Blue Ox | A giant lumberjack and his blue ox are the stars of tall tales from the north woods. Defend the lakes as giant animals and tree spirits roam. | Paul Bunyan is a folk hero of American logging tall tales, widely known through early 20th-century stories and advertising (around 1916). Babe the Blue Ox is part of the tale. These are tall tales, not history. |
| `us_wright` | biography | The Sky of the Wright Brothers | The Gale Spirit | Two brothers dreamed of flying. Hold the dunes as wind spirits race along the coast. | On December 17, 1903, near Kitty Hawk, North Carolina, Orville and Wilbur Wright made the first powered, controlled airplane flights. The wind spirits here are an invention of the game. |
| `us_moon` | history | Reaching for the Moon | The Moon Keeper | Along the Gulf Coast, engineers built the rockets that carried people to the Moon. Defend the launch sites from star creatures. | NASA's Apollo program landed the first humans on the Moon in 1969. Gulf Coast states hosted key sites: Kennedy Space Center (Florida), Johnson Space Center (Texas), Marshall Space Flight Center (Alabama), Stennis Space Center (Mississippi) and Michoud (Louisiana). The Moon Keeper is a fantasy figure. |

## 5. 訳す前の注意

- **エクストラの `fact`（事実の注記）は、公開前に事実を確認してから**訳す（今は仮）。伝承と事実の区別を崩さない。
- 戦争・差別・特定の歴史を連想させる言い回し、国旗・紋章、実在の人物の顔は使わない。
- 短い名前（施設・敵・ボス）は、機械翻訳のあと実機で見て直す。
- 地域名・州都名は固有名詞。各言語の通称にそろえる（`packs/<国>/pack.json` の `languages` に言語を足して `python3 tools/validate_pack.py packs/<国>` で検査）。
- 米国版（US）の優先は es、ドイツ版（DE）の優先は de・fr・en。

## 6. D アプリの文言（原本の英語）

### terrimap_ge（35件）

| キー | 英語 |
|---|---|
| `appTitle` | State Master – Germany |
| `quiz` | Quiz |
| `daily` | Daily challenge |
| `settings` | Settings |
| `progress` | Progress |
| `language` | Language |
| `attribution` | Data credits |
| `locate` | Tap this state on the map: |
| `nameFromMap` | Which state is highlighted? |
| `capitalFromName` | What is the capital of this state? |
| `nameFromCapital` | Which state has this capital? |
| `silhouette` | Which state has this shape? |
| `correct` | Correct! |
| `wrong` | Not quite. |
| `next` | Next |
| `finish` | Finish |
| `result` | Result |
| `again` | Play again |
| `home` | Home |
| `share` | Copy result |
| `copied` | Copied to clipboard |
| `answerWas` | Answer: |
| `beginner` | Beginner |
| `explorer` | Explorer |
| `expert` | Expert |
| `master` | Master |
| `locked` | Locked |
| `unlockTitle` | Unlock all 16 states |
| `unlockBody` | Play every state and remove ads with a one-time purchase. No subscription. |
| `unlockButton` | Unlock |
| `restore` | Restore purchases |
| `notNow` | Not now |
| `freeStates` | Free states |
| `battle` | Battle |
| `battleSubtitle` | Defend the state capital |

### terrimap_us（35件）

| キー | 英語 |
|---|---|
| `appTitle` | State Master – USA |
| `quiz` | Quiz |
| `daily` | Daily challenge |
| `settings` | Settings |
| `progress` | Progress |
| `language` | Language |
| `attribution` | Data credits |
| `locate` | Tap this state on the map: |
| `nameFromMap` | Which state is highlighted? |
| `capitalFromName` | What is the capital of this state? |
| `nameFromCapital` | Which state has this capital? |
| `silhouette` | Which state has this shape? |
| `correct` | Correct! |
| `wrong` | Not quite. |
| `next` | Next |
| `finish` | Finish |
| `result` | Result |
| `again` | Play again |
| `home` | Home |
| `share` | Copy result |
| `copied` | Copied to clipboard |
| `answerWas` | Answer: |
| `beginner` | Beginner |
| `explorer` | Explorer |
| `expert` | Expert |
| `master` | Master |
| `locked` | Locked |
| `unlockTitle` | Unlock all 51 states |
| `unlockBody` | Play every state and remove ads with a one-time purchase. No subscription. |
| `unlockButton` | Unlock |
| `restore` | Restore purchases |
| `notNow` | Not now |
| `freeStates` | Free states |
| `battle` | Battle |
| `battleSubtitle` | Defend the state capital |

