# 名所クイズ 出典の確認リスト

`tools/make_facts_check.py` が `packs/<国>/facts.json` から作る。**判定は作成者の記憶にもとづく（出典での確認はまだ）**。
「この名所はどの州にある？」の問題に使う。州の誤りは、そのまま誤った知識を教えてしまうので、公開前に確認する。

## 確認の手順

1. 各名所の「所在の州」を、公式ページ（施設・自治体・国立公園局・ユネスコなど）で確かめる。州をまたぐものは、問題に向かないので `use` を false にする。
2. 合っていれば `check` を `checked` にし、`source` に実際に見た出典（URLでなく名称でよい）を書く。誤りなら直す。
3. `python3 tools/validate_pack.py packs/<国>` を通す。アプリ側の `packs/<国>/facts.json` も同期する。
4. 表現: 名所の名前は、各言語の通称で。固有名詞なので機械翻訳に頼らない。

## 注意（題材の決まり）

- 戦争・差別・特定の歴史的事件を連想させる場所は入れない（戦跡、論争のある記念碑など）。
- 実在の人物の顔・肖像は使わない。人名のついた名所は、名所の名前として扱う。
- 州をまたぐ名所（イエローストーン、ナイアガラの滝の全体など）は、答えが一つに決まらないので使わない。

## ドイツ（20件、確認済み 0件）

| id | 名前(en) | 所在の州 | 確認 | 出典 | 確認日 | 直した点 |
|---|---|---|---|---|---|---|
| `heidelberg_castle` | Heidelberg Castle | DE-BW | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `europa_park` | Europa-Park (Rust) | DE-BW | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `neuschwanstein` | Neuschwanstein Castle | DE-BY | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `zugspitze` | Zugspitze (highest mountain in Germany) | DE-BY | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `brandenburg_gate` | Brandenburg Gate | DE-BE | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `reichstag` | Reichstag building | DE-BE | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `sanssouci` | Sanssouci Palace (Potsdam) | DE-BB | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `bremen_roland` | Roland statue of Bremen | DE-HB | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `elbphilharmonie` | Elbphilharmonie | DE-HH | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `bergpark_wilhelmshoehe` | Bergpark Wilhelmshöhe (Kassel) | DE-HE | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `koenigsstuhl` | Königsstuhl chalk cliff (Rügen) | DE-MV | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `hildesheim_cathedral` | Hildesheim Cathedral | DE-NI | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `cologne_cathedral` | Cologne Cathedral | DE-NW | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `zollverein` | Zollverein Coal Mine (Essen) | DE-NW | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `porta_nigra` | Porta Nigra (Trier) | DE-RP | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `saarschleife` | Saarschleife (Saar Loop) | DE-SL | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `dresden_frauenkirche` | Dresden Frauenkirche | DE-SN | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `quedlinburg` | Old town of Quedlinburg | DE-ST | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `holstentor` | Holstentor (Lübeck) | DE-SH | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |
| `wartburg` | Wartburg Castle | DE-TH | unchecked | UNESCO World Heritage List / 各施設・自治体の公式ページ | | |

## 米国（36件、確認済み 0件）

| id | 名前(en) | 所在の州 | 確認 | 出典 | 確認日 | 直した点 |
|---|---|---|---|---|---|---|
| `grand_canyon` | Grand Canyon | US-AZ | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `golden_gate_bridge` | Golden Gate Bridge | US-CA | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `mesa_verde` | Mesa Verde National Park | US-CO | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `kennedy_space_center` | Kennedy Space Center | US-FL | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `diamond_head` | Diamond Head (Oahu) | US-HI | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `empire_state_building` | Empire State Building | US-NY | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `lincoln_memorial` | Lincoln Memorial | US-DC | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `willis_tower` | Willis Tower | US-IL | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `fenway_park` | Fenway Park | US-MA | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `las_vegas_strip` | Las Vegas Strip | US-NV | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `devils_tower` | Devils Tower | US-WY | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `mount_rushmore` | Mount Rushmore | US-SD | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `space_needle` | Space Needle | US-WA | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `johnson_space_center` | Johnson Space Center (Houston) | US-TX | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `arches_np` | Arches National Park | US-UT | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `theodore_roosevelt_np` | Theodore Roosevelt National Park | US-ND | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `acadia_np` | Acadia National Park | US-ME | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `denali` | Denali | US-AK | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `french_quarter` | French Quarter (New Orleans) | US-LA | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `liberty_bell` | Liberty Bell (Philadelphia) | US-PA | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `gateway_arch` | Gateway Arch (St. Louis) | US-MO | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `grand_ole_opry` | Grand Ole Opry (Nashville) | US-TN | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `mammoth_cave` | Mammoth Cave National Park | US-KY | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `crater_lake` | Crater Lake | US-OR | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `carlsbad_caverns` | Carlsbad Caverns National Park | US-NM | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `mackinac_island` | Mackinac Island | US-MI | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `rock_hall` | Rock and Roll Hall of Fame (Cleveland) | US-OH | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `indy_speedway` | Indianapolis Motor Speedway | US-IN | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `mall_of_america` | Mall of America | US-MN | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `chimney_rock` | Chimney Rock | US-NE | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `georgia_aquarium` | Georgia Aquarium (Atlanta) | US-GA | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `glacier_np` | Glacier National Park | US-MT | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `mount_washington` | Mount Washington | US-NH | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `lambeau_field` | Lambeau Field (Green Bay) | US-WI | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `space_rocket_center` | U.S. Space & Rocket Center (Huntsville) | US-AL | unchecked | National Park Service / 各施設・自治体の公式ページ | | |
| `biltmore` | Biltmore Estate (Asheville) | US-NC | unchecked | National Park Service / 各施設・自治体の公式ページ | | |

