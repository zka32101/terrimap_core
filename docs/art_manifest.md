# 画像一覧 v0.1

`tools/art_manifest.py` が profile.json から生成。状態は `art/` の中身で決まる（`--dir` で変更）。

- 生成サイズは Leonardo の設定、最終サイズはアプリに入れるサイズ（施設・敵・ボスは背景除去後に 512x512 へ縮小、PNG）。
- ★ = 試作13枚（ドイツ）。

## DE（53枚）

| 試作 | 種類 | id | 備考 | 生成 | 最終 | ファイル | 状態 |
|---|---|---|---|---|---|---|---|
| ★ | 背景 | alps | アルプスの山と雪 | 768x1344 | 768x1344 | `de/backdrops/alps.png` | 未作成 |
|  | 背景 | black_forest | 深い森と丘 | 768x1344 | 768x1344 | `de/backdrops/black_forest.png` | 未作成 |
|  | 背景 | north_coast | 北海・バルト海の海岸と風車 | 768x1344 | 768x1344 | `de/backdrops/north_coast.png` | 未作成 |
|  | 背景 | port | 港とコンテナ | 768x1344 | 768x1344 | `de/backdrops/port.png` | 未作成 |
| ★ | 背景 | city | 都市のスカイライン | 768x1344 | 768x1344 | `de/backdrops/city.png` | 未作成 |
|  | 背景 | vineyard | 川沿いのぶどう畑 | 768x1344 | 768x1344 | `de/backdrops/vineyard.png` | 未作成 |
|  | 背景 | farmland | 麦畑と風力発電 | 768x1344 | 768x1344 | `de/backdrops/farmland.png` | 未作成 |
|  | 背景 | industry | 工場と炭鉱の街 | 768x1344 | 768x1344 | `de/backdrops/industry.png` | 未作成 |
|  | 背景 | lakes | 湖と森 | 768x1344 | 768x1344 | `de/backdrops/lakes.png` | 未作成 |
|  | 背景 | castle_hills | 丘の上の城 | 768x1344 | 768x1344 | `de/backdrops/castle_hills.png` | 未作成 |
| ★ | 施設 | farm_windmill | farm / 農場と風車 | 1024x1024 | 512x512 | `de/facilities/farm_windmill.png` | 未作成 |
| ★ | 施設 | harbor_cutter | fishery / 港の漁船 | 1024x1024 | 512x512 | `de/facilities/harbor_cutter.png` | 未作成 |
| ★ | 施設 | automotive_plant | factory / 自動車工場 | 1024x1024 | 512x512 | `de/facilities/automotive_plant.png` | 未作成 |
| ★ | 施設 | coal_mine | mine / 炭鉱 | 1024x1024 | 512x512 | `de/facilities/coal_mine.png` | 未作成 |
| ★ | 施設 | hilltop_castle | castle / 丘の城 | 1024x1024 | 512x512 | `de/facilities/hilltop_castle.png` | 未作成 |
| ★ | 施設 | chapel | shrine / 聖堂 | 1024x1024 | 512x512 | `de/facilities/chapel.png` | 未作成 |
|  | 限定施設 | automotive_works |  | 1024x1024 | 512x512 | `de/exclusive/automotive_works.png` | 未作成 |
|  | 限定施設 | brewery |  | 1024x1024 | 512x512 | `de/exclusive/brewery.png` | 未作成 |
|  | 限定施設 | container_port |  | 1024x1024 | 512x512 | `de/exclusive/container_port.png` | 未作成 |
|  | 限定施設 | parliament |  | 1024x1024 | 512x512 | `de/exclusive/parliament.png` | 未作成 |
|  | 限定施設 | porcelain_works |  | 1024x1024 | 512x512 | `de/exclusive/porcelain_works.png` | 未作成 |
|  | 限定施設 | ruhr_works |  | 1024x1024 | 512x512 | `de/exclusive/ruhr_works.png` | 未作成 |
|  | 限定施設 | seaport |  | 1024x1024 | 512x512 | `de/exclusive/seaport.png` | 未作成 |
|  | 限定施設 | stock_exchange |  | 1024x1024 | 512x512 | `de/exclusive/stock_exchange.png` | 未作成 |
|  | 限定施設 | wartburg |  | 1024x1024 | 512x512 | `de/exclusive/wartburg.png` | 未作成 |
|  | 限定施設 | winery |  | 1024x1024 | 512x512 | `de/exclusive/winery.png` | 未作成 |
| ★ | 敵 | rust_sprite | normal / さび妖精 | 1024x1024 | 512x512 | `de/enemies/rust_sprite.png` | 未作成 |
| ★ | 敵 | dash_gremlin | speedy / 疾走グレムリン | 1024x1024 | 512x512 | `de/enemies/dash_gremlin.png` | 未作成 |
| ★ | 敵 | iron_golem | armored / 鉄のゴーレム | 1024x1024 | 512x512 | `de/enemies/iron_golem.png` | 未作成 |
| ★ | 敵 | forest_sprite | healer / 森の精 | 1024x1024 | 512x512 | `de/enemies/forest_sprite.png` | 未作成 |
| ★ | ボス | de_loreley | Water Nymph of the Rhine | 1024x1024 | 512x512 | `de/bosses/de_loreley.png` | 未作成 |
|  | ボス | de_grimm | The Great Grey Wolf | 1024x1024 | 512x512 | `de/bosses/de_grimm.png` | 未作成 |
|  | ボス | de_nibelung | The Cave Dragon | 1024x1024 | 512x512 | `de/bosses/de_nibelung.png` | 未作成 |
|  | 名所カード | heidelberg_castle | Heidelberg Castle | 1024x1024 | 512x512 | `de/landmarks/heidelberg_castle.png` | 未作成 |
|  | 名所カード | europa_park | Europa-Park (Rust) | 1024x1024 | 512x512 | `de/landmarks/europa_park.png` | 未作成 |
|  | 名所カード | neuschwanstein | Neuschwanstein Castle | 1024x1024 | 512x512 | `de/landmarks/neuschwanstein.png` | 未作成 |
|  | 名所カード | zugspitze | Zugspitze (highest mountain in Germany) | 1024x1024 | 512x512 | `de/landmarks/zugspitze.png` | 未作成 |
|  | 名所カード | brandenburg_gate | Brandenburg Gate | 1024x1024 | 512x512 | `de/landmarks/brandenburg_gate.png` | 未作成 |
|  | 名所カード | reichstag | Reichstag building | 1024x1024 | 512x512 | `de/landmarks/reichstag.png` | 未作成 |
|  | 名所カード | sanssouci | Sanssouci Palace (Potsdam) | 1024x1024 | 512x512 | `de/landmarks/sanssouci.png` | 未作成 |
|  | 名所カード | bremen_roland | Roland statue of Bremen | 1024x1024 | 512x512 | `de/landmarks/bremen_roland.png` | 未作成 |
|  | 名所カード | elbphilharmonie | Elbphilharmonie | 1024x1024 | 512x512 | `de/landmarks/elbphilharmonie.png` | 未作成 |
|  | 名所カード | bergpark_wilhelmshoehe | Bergpark Wilhelmshöhe (Kassel) | 1024x1024 | 512x512 | `de/landmarks/bergpark_wilhelmshoehe.png` | 未作成 |
|  | 名所カード | koenigsstuhl | Königsstuhl chalk cliff (Rügen) | 1024x1024 | 512x512 | `de/landmarks/koenigsstuhl.png` | 未作成 |
|  | 名所カード | hildesheim_cathedral | Hildesheim Cathedral | 1024x1024 | 512x512 | `de/landmarks/hildesheim_cathedral.png` | 未作成 |
|  | 名所カード | cologne_cathedral | Cologne Cathedral | 1024x1024 | 512x512 | `de/landmarks/cologne_cathedral.png` | 未作成 |
|  | 名所カード | zollverein | Zollverein Coal Mine (Essen) | 1024x1024 | 512x512 | `de/landmarks/zollverein.png` | 未作成 |
|  | 名所カード | porta_nigra | Porta Nigra (Trier) | 1024x1024 | 512x512 | `de/landmarks/porta_nigra.png` | 未作成 |
|  | 名所カード | saarschleife | Saarschleife (Saar Loop) | 1024x1024 | 512x512 | `de/landmarks/saarschleife.png` | 未作成 |
|  | 名所カード | dresden_frauenkirche | Dresden Frauenkirche | 1024x1024 | 512x512 | `de/landmarks/dresden_frauenkirche.png` | 未作成 |
|  | 名所カード | quedlinburg | Old town of Quedlinburg | 1024x1024 | 512x512 | `de/landmarks/quedlinburg.png` | 未作成 |
|  | 名所カード | holstentor | Holstentor (Lübeck) | 1024x1024 | 512x512 | `de/landmarks/holstentor.png` | 未作成 |
|  | 名所カード | wartburg | Wartburg Castle | 1024x1024 | 512x512 | `de/landmarks/wartburg.png` | 未作成 |

## US（70枚）

| 試作 | 種類 | id | 備考 | 生成 | 最終 | ファイル | 状態 |
|---|---|---|---|---|---|---|---|
|  | 背景 | desert | 砂漠と赤い岩 | 768x1344 | 768x1344 | `us/backdrops/desert.png` | 未作成 |
|  | 背景 | plains | 大平原と地平線 | 768x1344 | 768x1344 | `us/backdrops/plains.png` | 未作成 |
|  | 背景 | rockies | ロッキーの山と雪 | 768x1344 | 768x1344 | `us/backdrops/rockies.png` | 未作成 |
|  | 背景 | bayou | 湿地とバイユー | 768x1344 | 768x1344 | `us/backdrops/bayou.png` | 未作成 |
|  | 背景 | atlantic_coast | 大西洋岸の港と灯台 | 768x1344 | 768x1344 | `us/backdrops/atlantic_coast.png` | 未作成 |
|  | 背景 | pacific_coast | 太平洋岸と霧 | 768x1344 | 768x1344 | `us/backdrops/pacific_coast.png` | 未作成 |
|  | 背景 | great_lakes | 五大湖と港町 | 768x1344 | 768x1344 | `us/backdrops/great_lakes.png` | 未作成 |
|  | 背景 | appalachia | アパラチアの丘と霧 | 768x1344 | 768x1344 | `us/backdrops/appalachia.png` | 未作成 |
|  | 背景 | skyline | 摩天楼の街 | 768x1344 | 768x1344 | `us/backdrops/skyline.png` | 未作成 |
|  | 背景 | tundra | 氷原とオーロラ | 768x1344 | 768x1344 | `us/backdrops/tundra.png` | 未作成 |
|  | 背景 | tropics | 亜熱帯の海と島 | 768x1344 | 768x1344 | `us/backdrops/tropics.png` | 未作成 |
|  | 背景 | cornfield | とうもろこし畑とサイロ | 768x1344 | 768x1344 | `us/backdrops/cornfield.png` | 未作成 |
|  | 施設 | grain_silo | farm / 穀物サイロ | 1024x1024 | 512x512 | `us/facilities/grain_silo.png` | 未作成 |
|  | 施設 | fishing_trawler | fishery / 底引き漁船 | 1024x1024 | 512x512 | `us/facilities/fishing_trawler.png` | 未作成 |
|  | 施設 | assembly_line | factory / 組立ライン | 1024x1024 | 512x512 | `us/facilities/assembly_line.png` | 未作成 |
|  | 施設 | oil_derrick | mine / 油井 | 1024x1024 | 512x512 | `us/facilities/oil_derrick.png` | 未作成 |
|  | 施設 | capitol_hall | castle / 議事堂 | 1024x1024 | 512x512 | `us/facilities/capitol_hall.png` | 未作成 |
|  | 施設 | town_church | shrine / 町の教会 | 1024x1024 | 512x512 | `us/facilities/town_church.png` | 未作成 |
|  | 限定施設 | aerospace_works |  | 1024x1024 | 512x512 | `us/exclusive/aerospace_works.png` | 未作成 |
|  | 限定施設 | capitol |  | 1024x1024 | 512x512 | `us/exclusive/capitol.png` | 未作成 |
|  | 限定施設 | distillery |  | 1024x1024 | 512x512 | `us/exclusive/distillery.png` | 未作成 |
|  | 限定施設 | national_lab |  | 1024x1024 | 512x512 | `us/exclusive/national_lab.png` | 未作成 |
|  | 限定施設 | oil_derrick |  | 1024x1024 | 512x512 | `us/exclusive/oil_derrick.png` | 未作成 |
|  | 限定施設 | pipeline |  | 1024x1024 | 512x512 | `us/exclusive/pipeline.png` | 未作成 |
|  | 限定施設 | space_center |  | 1024x1024 | 512x512 | `us/exclusive/space_center.png` | 未作成 |
|  | 限定施設 | stock_exchange |  | 1024x1024 | 512x512 | `us/exclusive/stock_exchange.png` | 未作成 |
|  | 限定施設 | tech_campus |  | 1024x1024 | 512x512 | `us/exclusive/tech_campus.png` | 未作成 |
|  | 敵 | dust_devil | normal / つむじ風 | 1024x1024 | 512x512 | `us/enemies/dust_devil.png` | 未作成 |
|  | 敵 | tumbleweed | speedy / 回転草 | 1024x1024 | 512x512 | `us/enemies/tumbleweed.png` | 未作成 |
|  | 敵 | rock_golem | armored / 岩のゴーレム | 1024x1024 | 512x512 | `us/enemies/rock_golem.png` | 未作成 |
|  | 敵 | cactus_nurse | healer / サボテンの看護師 | 1024x1024 | 512x512 | `us/enemies/cactus_nurse.png` | 未作成 |
|  | ボス | us_bunyan | The Giant Blue Ox | 1024x1024 | 512x512 | `us/bosses/us_bunyan.png` | 未作成 |
|  | ボス | us_wright | The Gale Spirit | 1024x1024 | 512x512 | `us/bosses/us_wright.png` | 未作成 |
|  | ボス | us_moon | The Moon Keeper | 1024x1024 | 512x512 | `us/bosses/us_moon.png` | 未作成 |
|  | 名所カード | grand_canyon | Grand Canyon | 1024x1024 | 512x512 | `us/landmarks/grand_canyon.png` | 未作成 |
|  | 名所カード | golden_gate_bridge | Golden Gate Bridge | 1024x1024 | 512x512 | `us/landmarks/golden_gate_bridge.png` | 未作成 |
|  | 名所カード | mesa_verde | Mesa Verde National Park | 1024x1024 | 512x512 | `us/landmarks/mesa_verde.png` | 未作成 |
|  | 名所カード | kennedy_space_center | Kennedy Space Center | 1024x1024 | 512x512 | `us/landmarks/kennedy_space_center.png` | 未作成 |
|  | 名所カード | diamond_head | Diamond Head (Oahu) | 1024x1024 | 512x512 | `us/landmarks/diamond_head.png` | 未作成 |
|  | 名所カード | empire_state_building | Empire State Building | 1024x1024 | 512x512 | `us/landmarks/empire_state_building.png` | 未作成 |
|  | 名所カード | lincoln_memorial | Lincoln Memorial | 1024x1024 | 512x512 | `us/landmarks/lincoln_memorial.png` | 未作成 |
|  | 名所カード | willis_tower | Willis Tower | 1024x1024 | 512x512 | `us/landmarks/willis_tower.png` | 未作成 |
|  | 名所カード | fenway_park | Fenway Park | 1024x1024 | 512x512 | `us/landmarks/fenway_park.png` | 未作成 |
|  | 名所カード | las_vegas_strip | Las Vegas Strip | 1024x1024 | 512x512 | `us/landmarks/las_vegas_strip.png` | 未作成 |
|  | 名所カード | devils_tower | Devils Tower | 1024x1024 | 512x512 | `us/landmarks/devils_tower.png` | 未作成 |
|  | 名所カード | mount_rushmore | Mount Rushmore | 1024x1024 | 512x512 | `us/landmarks/mount_rushmore.png` | 未作成 |
|  | 名所カード | space_needle | Space Needle | 1024x1024 | 512x512 | `us/landmarks/space_needle.png` | 未作成 |
|  | 名所カード | johnson_space_center | Johnson Space Center (Houston) | 1024x1024 | 512x512 | `us/landmarks/johnson_space_center.png` | 未作成 |
|  | 名所カード | arches_np | Arches National Park | 1024x1024 | 512x512 | `us/landmarks/arches_np.png` | 未作成 |
|  | 名所カード | theodore_roosevelt_np | Theodore Roosevelt National Park | 1024x1024 | 512x512 | `us/landmarks/theodore_roosevelt_np.png` | 未作成 |
|  | 名所カード | acadia_np | Acadia National Park | 1024x1024 | 512x512 | `us/landmarks/acadia_np.png` | 未作成 |
|  | 名所カード | denali | Denali | 1024x1024 | 512x512 | `us/landmarks/denali.png` | 未作成 |
|  | 名所カード | french_quarter | French Quarter (New Orleans) | 1024x1024 | 512x512 | `us/landmarks/french_quarter.png` | 未作成 |
|  | 名所カード | liberty_bell | Liberty Bell (Philadelphia) | 1024x1024 | 512x512 | `us/landmarks/liberty_bell.png` | 未作成 |
|  | 名所カード | gateway_arch | Gateway Arch (St. Louis) | 1024x1024 | 512x512 | `us/landmarks/gateway_arch.png` | 未作成 |
|  | 名所カード | grand_ole_opry | Grand Ole Opry (Nashville) | 1024x1024 | 512x512 | `us/landmarks/grand_ole_opry.png` | 未作成 |
|  | 名所カード | mammoth_cave | Mammoth Cave National Park | 1024x1024 | 512x512 | `us/landmarks/mammoth_cave.png` | 未作成 |
|  | 名所カード | crater_lake | Crater Lake | 1024x1024 | 512x512 | `us/landmarks/crater_lake.png` | 未作成 |
|  | 名所カード | carlsbad_caverns | Carlsbad Caverns National Park | 1024x1024 | 512x512 | `us/landmarks/carlsbad_caverns.png` | 未作成 |
|  | 名所カード | mackinac_island | Mackinac Island | 1024x1024 | 512x512 | `us/landmarks/mackinac_island.png` | 未作成 |
|  | 名所カード | rock_hall | Rock and Roll Hall of Fame (Cleveland) | 1024x1024 | 512x512 | `us/landmarks/rock_hall.png` | 未作成 |
|  | 名所カード | indy_speedway | Indianapolis Motor Speedway | 1024x1024 | 512x512 | `us/landmarks/indy_speedway.png` | 未作成 |
|  | 名所カード | mall_of_america | Mall of America | 1024x1024 | 512x512 | `us/landmarks/mall_of_america.png` | 未作成 |
|  | 名所カード | chimney_rock | Chimney Rock | 1024x1024 | 512x512 | `us/landmarks/chimney_rock.png` | 未作成 |
|  | 名所カード | georgia_aquarium | Georgia Aquarium (Atlanta) | 1024x1024 | 512x512 | `us/landmarks/georgia_aquarium.png` | 未作成 |
|  | 名所カード | glacier_np | Glacier National Park | 1024x1024 | 512x512 | `us/landmarks/glacier_np.png` | 未作成 |
|  | 名所カード | mount_washington | Mount Washington | 1024x1024 | 512x512 | `us/landmarks/mount_washington.png` | 未作成 |
|  | 名所カード | lambeau_field | Lambeau Field (Green Bay) | 1024x1024 | 512x512 | `us/landmarks/lambeau_field.png` | 未作成 |
|  | 名所カード | space_rocket_center | U.S. Space & Rocket Center (Huntsville) | 1024x1024 | 512x512 | `us/landmarks/space_rocket_center.png` | 未作成 |
|  | 名所カード | biltmore | Biltmore Estate (Asheville) | 1024x1024 | 512x512 | `us/landmarks/biltmore.png` | 未作成 |

## 共通（8枚）

| 試作 | 種類 | id | 備考 | 生成 | 最終 | ファイル | 状態 |
|---|---|---|---|---|---|---|---|
|  | 天候 | hurricane |  | 1344x768 | 1344x768 | `common/weather/hurricane.png` | 未作成 |
|  | 天候 | tornado |  | 1344x768 | 1344x768 | `common/weather/tornado.png` | 未作成 |
|  | 天候 | blizzard |  | 1344x768 | 1344x768 | `common/weather/blizzard.png` | 未作成 |
|  | 天候 | heatwave |  | 1344x768 | 1344x768 | `common/weather/heatwave.png` | 未作成 |
|  | 天候 | wildfire |  | 1344x768 | 1344x768 | `common/weather/wildfire.png` | 未作成 |
|  | 天候 | flood |  | 1344x768 | 1344x768 | `common/weather/flood.png` | 未作成 |
|  | 天候 | earthquake |  | 1344x768 | 1344x768 | `common/weather/earthquake.png` | 未作成 |
|  | 天候 | storm |  | 1344x768 | 1344x768 | `common/weather/storm.png` | 未作成 |

