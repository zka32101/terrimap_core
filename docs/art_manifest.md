# 画像一覧 v0.1

`tools/art_manifest.py` が profile.json から生成。状態は `art/` の中身で決まる（`--dir` で変更）。

- 生成サイズは Leonardo の設定、最終サイズはアプリに入れるサイズ（施設・敵・ボスは背景除去後に 512x512 へ縮小、PNG）。
- ★ = 試作13枚（ドイツ）。

## DE（72枚）

| 試作 | 種類 | id | 備考 | 生成 | 最終 | ファイル | 状態 |
|---|---|---|---|---|---|---|---|
| ★ | 背景 | alps | アルプスの山と雪 | 768x1344 | 768x1344 | `de/backdrops/alps.png` | OK |
|  | 背景 | black_forest | 深い森と丘 | 768x1344 | 768x1344 | `de/backdrops/black_forest.png` | OK |
|  | 背景 | north_coast | 北海・バルト海の海岸と風車 | 768x1344 | 768x1344 | `de/backdrops/north_coast.png` | OK |
|  | 背景 | port | 港とコンテナ | 768x1344 | 768x1344 | `de/backdrops/port.png` | OK |
| ★ | 背景 | city | 都市のスカイライン | 768x1344 | 768x1344 | `de/backdrops/city.png` | OK |
|  | 背景 | vineyard | 川沿いのぶどう畑 | 768x1344 | 768x1344 | `de/backdrops/vineyard.png` | OK |
|  | 背景 | farmland | 麦畑と風力発電 | 768x1344 | 768x1344 | `de/backdrops/farmland.png` | OK |
|  | 背景 | industry | 工場と炭鉱の街 | 768x1344 | 768x1344 | `de/backdrops/industry.png` | OK |
|  | 背景 | lakes | 湖と森 | 768x1344 | 768x1344 | `de/backdrops/lakes.png` | OK |
|  | 背景 | castle_hills | 丘の上の城 | 768x1344 | 768x1344 | `de/backdrops/castle_hills.png` | OK |
| ★ | 施設 | farm_windmill | farm / 農場と風車 | 1024x1024 | 512x512 | `de/facilities/farm_windmill.png` | OK |
| ★ | 施設 | harbor_cutter | fishery / 港の漁船 | 1024x1024 | 512x512 | `de/facilities/harbor_cutter.png` | OK |
| ★ | 施設 | automotive_plant | factory / 自動車工場 | 1024x1024 | 512x512 | `de/facilities/automotive_plant.png` | OK |
| ★ | 施設 | coal_mine | mine / 炭鉱 | 1024x1024 | 512x512 | `de/facilities/coal_mine.png` | OK |
| ★ | 施設 | hilltop_castle | castle / 丘の城 | 1024x1024 | 512x512 | `de/facilities/hilltop_castle.png` | OK |
| ★ | 施設 | chapel | shrine / 聖堂 | 1024x1024 | 512x512 | `de/facilities/chapel.png` | OK |
|  | 限定施設 | automotive_works |  | 1024x1024 | 512x512 | `de/exclusive/automotive_works.png` | OK |
|  | 限定施設 | brewery |  | 1024x1024 | 512x512 | `de/exclusive/brewery.png` | OK |
|  | 限定施設 | container_port |  | 1024x1024 | 512x512 | `de/exclusive/container_port.png` | OK |
|  | 限定施設 | parliament |  | 1024x1024 | 512x512 | `de/exclusive/parliament.png` | OK |
|  | 限定施設 | porcelain_works |  | 1024x1024 | 512x512 | `de/exclusive/porcelain_works.png` | OK |
|  | 限定施設 | ruhr_works |  | 1024x1024 | 512x512 | `de/exclusive/ruhr_works.png` | OK |
|  | 限定施設 | seaport |  | 1024x1024 | 512x512 | `de/exclusive/seaport.png` | OK |
|  | 限定施設 | stock_exchange |  | 1024x1024 | 512x512 | `de/exclusive/stock_exchange.png` | OK |
|  | 限定施設 | wartburg |  | 1024x1024 | 512x512 | `de/exclusive/wartburg.png` | OK |
|  | 限定施設 | winery |  | 1024x1024 | 512x512 | `de/exclusive/winery.png` | OK |
| ★ | 敵 | rust_sprite | normal / さび妖精 | 1024x1024 | 512x512 | `de/enemies/rust_sprite.png` | OK |
| ★ | 敵 | dash_gremlin | speedy / 疾走グレムリン | 1024x1024 | 512x512 | `de/enemies/dash_gremlin.png` | OK |
| ★ | 敵 | iron_golem | armored / 鉄のゴーレム | 1024x1024 | 512x512 | `de/enemies/iron_golem.png` | OK |
| ★ | 敵 | forest_sprite | healer / 森の精 | 1024x1024 | 512x512 | `de/enemies/forest_sprite.png` | OK |
|  | 敵 | wolpertinger | flyer / ヴォルペルティンガー(羽うさぎ) | 1024x1024 | 512x512 | `de/enemies/wolpertinger.png` | OK |
|  | 敵 | mine_imp | saboteur / 坑道のいたずら小鬼 | 1024x1024 | 512x512 | `de/enemies/mine_imp.png` | OK |
|  | 敵 | bat_swarm | swarmer / こうもりの群れ | 1024x1024 | 512x512 | `de/enemies/bat_swarm.png` | OK |
|  | 敵 | mud_blob | splitter / 泥のかたまり | 1024x1024 | 512x512 | `de/enemies/mud_blob.png` | OK |
|  | 敵 | forest_ogre | brute / 森の大鬼 | 1024x1024 | 512x512 | `de/enemies/forest_ogre.png` | OK |
|  | 敵 | fog_wisp | jammer / 霧のいたずら火 | 1024x1024 | 512x512 | `de/enemies/fog_wisp.png` | OK |
|  | 敵 | kobold_miner | normal（見た目違い）/ 鉱山のコボルト | 1024x1024 | 512x512 | `de/enemies/kobold_miner.png` | OK |
|  | 敵 | wichtel | normal（見た目違い）/ ヴィヒテル(小人) | 1024x1024 | 512x512 | `de/enemies/wichtel.png` | OK |
|  | 敵 | field_hare | speedy（見た目違い）/ 疾走する野うさぎ | 1024x1024 | 512x512 | `de/enemies/field_hare.png` | OK |
|  | 敵 | rat_pack | speedy（見た目違い）/ ねずみの群れ | 1024x1024 | 512x512 | `de/enemies/rat_pack.png` | OK |
|  | 敵 | stone_giant | armored（見た目違い）/ 石の巨人 | 1024x1024 | 512x512 | `de/enemies/stone_giant.png` | OK |
|  | 敵 | ice_golem | armored（見た目違い）/ 氷のゴーレム | 1024x1024 | 512x512 | `de/enemies/ice_golem.png` | OK |
|  | 敵 | water_nixie | healer（見た目違い）/ 水の精(ニクセ) | 1024x1024 | 512x512 | `de/enemies/water_nixie.png` | OK |
|  | 敵 | flower_fairy | healer（見た目違い）/ 花の精 | 1024x1024 | 512x512 | `de/enemies/flower_fairy.png` | OK |
|  | ボス | nebel_warden | ミニボス（north）/ 霧の海の番人 | 1024x1024 | 512x512 | `de/bosses/nebel_warden.png` | OK |
|  | ボス | mountain_keeper | ミニボス（south）/ 山の岩の守り手 | 1024x1024 | 512x512 | `de/bosses/mountain_keeper.png` | OK |
|  | ボス | black_forest_hunter | ミニボス（west）/ 黒い森の狩人 | 1024x1024 | 512x512 | `de/bosses/black_forest_hunter.png` | OK |
|  | ボス | lake_master | ミニボス（east）/ 湖の水の主 | 1024x1024 | 512x512 | `de/bosses/lake_master.png` | OK |
| ★ | ボス | de_loreley | Water Nymph of the Rhine | 1024x1024 | 512x512 | `de/bosses/de_loreley.png` | OK |
|  | ボス | de_grimm | The Great Grey Wolf | 1024x1024 | 512x512 | `de/bosses/de_grimm.png` | OK |
|  | ボス | de_nibelung | The Cave Dragon | 1024x1024 | 512x512 | `de/bosses/de_nibelung.png` | OK |
|  | ボス | de_gutenberg | The Ink Keeper | 1024x1024 | 512x512 | `de/bosses/de_gutenberg.png` | OK |
|  | 名所カード | heidelberg_castle | Heidelberg Castle | 1024x1024 | 512x512 | `de/landmarks/heidelberg_castle.png` | OK |
|  | 名所カード | europa_park | Europa-Park (Rust) | 1024x1024 | 512x512 | `de/landmarks/europa_park.png` | OK |
|  | 名所カード | neuschwanstein | Neuschwanstein Castle | 1024x1024 | 512x512 | `de/landmarks/neuschwanstein.png` | OK |
|  | 名所カード | zugspitze | Zugspitze (highest mountain in Germany) | 1024x1024 | 512x512 | `de/landmarks/zugspitze.png` | OK |
|  | 名所カード | brandenburg_gate | Brandenburg Gate | 1024x1024 | 512x512 | `de/landmarks/brandenburg_gate.png` | OK |
|  | 名所カード | reichstag | Reichstag building | 1024x1024 | 512x512 | `de/landmarks/reichstag.png` | OK |
|  | 名所カード | sanssouci | Sanssouci Palace (Potsdam) | 1024x1024 | 512x512 | `de/landmarks/sanssouci.png` | OK |
|  | 名所カード | bremen_roland | Roland statue of Bremen | 1024x1024 | 512x512 | `de/landmarks/bremen_roland.png` | OK |
|  | 名所カード | elbphilharmonie | Elbphilharmonie | 1024x1024 | 512x512 | `de/landmarks/elbphilharmonie.png` | OK |
|  | 名所カード | bergpark_wilhelmshoehe | Bergpark Wilhelmshöhe (Kassel) | 1024x1024 | 512x512 | `de/landmarks/bergpark_wilhelmshoehe.png` | OK |
|  | 名所カード | koenigsstuhl | Königsstuhl chalk cliff (Rügen) | 1024x1024 | 512x512 | `de/landmarks/koenigsstuhl.png` | OK |
|  | 名所カード | hildesheim_cathedral | Hildesheim Cathedral | 1024x1024 | 512x512 | `de/landmarks/hildesheim_cathedral.png` | OK |
|  | 名所カード | cologne_cathedral | Cologne Cathedral | 1024x1024 | 512x512 | `de/landmarks/cologne_cathedral.png` | OK |
|  | 名所カード | zollverein | Zollverein Coal Mine (Essen) | 1024x1024 | 512x512 | `de/landmarks/zollverein.png` | OK |
|  | 名所カード | porta_nigra | Porta Nigra (Trier) | 1024x1024 | 512x512 | `de/landmarks/porta_nigra.png` | OK |
|  | 名所カード | saarschleife | Saarschleife (Saar Loop) | 1024x1024 | 512x512 | `de/landmarks/saarschleife.png` | OK |
|  | 名所カード | dresden_frauenkirche | Dresden Frauenkirche | 1024x1024 | 512x512 | `de/landmarks/dresden_frauenkirche.png` | OK |
|  | 名所カード | quedlinburg | Old town of Quedlinburg | 1024x1024 | 512x512 | `de/landmarks/quedlinburg.png` | OK |
|  | 名所カード | holstentor | Holstentor (Lübeck) | 1024x1024 | 512x512 | `de/landmarks/holstentor.png` | OK |
|  | 名所カード | wartburg | Wartburg Castle | 1024x1024 | 512x512 | `de/landmarks/wartburg.png` | OK |

## US（89枚）

| 試作 | 種類 | id | 備考 | 生成 | 最終 | ファイル | 状態 |
|---|---|---|---|---|---|---|---|
|  | 背景 | desert | 砂漠と赤い岩 | 768x1344 | 768x1344 | `us/backdrops/desert.png` | OK |
|  | 背景 | plains | 大平原と地平線 | 768x1344 | 768x1344 | `us/backdrops/plains.png` | OK |
|  | 背景 | rockies | ロッキーの山と雪 | 768x1344 | 768x1344 | `us/backdrops/rockies.png` | OK |
|  | 背景 | bayou | 湿地とバイユー | 768x1344 | 768x1344 | `us/backdrops/bayou.png` | OK |
|  | 背景 | atlantic_coast | 大西洋岸の港と灯台 | 768x1344 | 768x1344 | `us/backdrops/atlantic_coast.png` | OK |
|  | 背景 | pacific_coast | 太平洋岸と霧 | 768x1344 | 768x1344 | `us/backdrops/pacific_coast.png` | OK |
|  | 背景 | great_lakes | 五大湖と港町 | 768x1344 | 768x1344 | `us/backdrops/great_lakes.png` | OK |
|  | 背景 | appalachia | アパラチアの丘と霧 | 768x1344 | 768x1344 | `us/backdrops/appalachia.png` | OK |
|  | 背景 | skyline | 摩天楼の街 | 768x1344 | 768x1344 | `us/backdrops/skyline.png` | OK |
|  | 背景 | tundra | 氷原とオーロラ | 768x1344 | 768x1344 | `us/backdrops/tundra.png` | OK |
|  | 背景 | tropics | 亜熱帯の海と島 | 768x1344 | 768x1344 | `us/backdrops/tropics.png` | OK |
|  | 背景 | cornfield | とうもろこし畑とサイロ | 768x1344 | 768x1344 | `us/backdrops/cornfield.png` | OK |
|  | 施設 | grain_silo | farm / 穀物サイロ | 1024x1024 | 512x512 | `us/facilities/grain_silo.png` | OK |
|  | 施設 | fishing_trawler | fishery / 底引き漁船 | 1024x1024 | 512x512 | `us/facilities/fishing_trawler.png` | OK |
|  | 施設 | assembly_line | factory / 組立ライン | 1024x1024 | 512x512 | `us/facilities/assembly_line.png` | OK |
|  | 施設 | oil_derrick | mine / 油井 | 1024x1024 | 512x512 | `us/facilities/oil_derrick.png` | OK |
|  | 施設 | capitol_hall | castle / 議事堂 | 1024x1024 | 512x512 | `us/facilities/capitol_hall.png` | OK |
|  | 施設 | town_church | shrine / 町の教会 | 1024x1024 | 512x512 | `us/facilities/town_church.png` | OK |
|  | 限定施設 | aerospace_works |  | 1024x1024 | 512x512 | `us/exclusive/aerospace_works.png` | OK |
|  | 限定施設 | capitol |  | 1024x1024 | 512x512 | `us/exclusive/capitol.png` | OK |
|  | 限定施設 | distillery |  | 1024x1024 | 512x512 | `us/exclusive/distillery.png` | OK |
|  | 限定施設 | national_lab |  | 1024x1024 | 512x512 | `us/exclusive/national_lab.png` | OK |
|  | 限定施設 | oil_derrick |  | 1024x1024 | 512x512 | `us/exclusive/oil_derrick.png` | OK |
|  | 限定施設 | pipeline |  | 1024x1024 | 512x512 | `us/exclusive/pipeline.png` | OK |
|  | 限定施設 | space_center |  | 1024x1024 | 512x512 | `us/exclusive/space_center.png` | OK |
|  | 限定施設 | stock_exchange |  | 1024x1024 | 512x512 | `us/exclusive/stock_exchange.png` | OK |
|  | 限定施設 | tech_campus |  | 1024x1024 | 512x512 | `us/exclusive/tech_campus.png` | OK |
|  | 敵 | dust_devil | normal / つむじ風 | 1024x1024 | 512x512 | `us/enemies/dust_devil.png` | OK |
|  | 敵 | tumbleweed | speedy / 回転草 | 1024x1024 | 512x512 | `us/enemies/tumbleweed.png` | OK |
|  | 敵 | rock_golem | armored / 岩のゴーレム | 1024x1024 | 512x512 | `us/enemies/rock_golem.png` | OK |
|  | 敵 | cactus_nurse | healer / サボテンの看護師 | 1024x1024 | 512x512 | `us/enemies/cactus_nurse.png` | OK |
|  | 敵 | dust_crow | flyer / ほこりのカラス | 1024x1024 | 512x512 | `us/enemies/dust_crow.png` | OK |
|  | 敵 | prairie_trickster | saboteur / 大草原のいたずら者 | 1024x1024 | 512x512 | `us/enemies/prairie_trickster.png` | OK |
|  | 敵 | locust_swarm | swarmer / イナゴの群れ | 1024x1024 | 512x512 | `us/enemies/locust_swarm.png` | OK |
|  | 敵 | tar_blob | splitter / タールのかたまり | 1024x1024 | 512x512 | `us/enemies/tar_blob.png` | OK |
|  | 敵 | canyon_troll | brute / 峡谷のトロル | 1024x1024 | 512x512 | `us/enemies/canyon_troll.png` | OK |
|  | 敵 | static_spirit | jammer / 静電気の精 | 1024x1024 | 512x512 | `us/enemies/static_spirit.png` | OK |
|  | 敵 | dust_imp | normal（見た目違い）/ ほこりの小鬼 | 1024x1024 | 512x512 | `us/enemies/dust_imp.png` | OK |
|  | 敵 | mud_gnome | normal（見た目違い）/ ぬかるみの小人 | 1024x1024 | 512x512 | `us/enemies/mud_gnome.png` | OK |
|  | 敵 | jackalope | speedy（見た目違い）/ ジャッカロープ | 1024x1024 | 512x512 | `us/enemies/jackalope.png` | OK |
|  | 敵 | root_runner | speedy（見た目違い）/ 走る木の根 | 1024x1024 | 512x512 | `us/enemies/root_runner.png` | OK |
|  | 敵 | fossil_turtle | armored（見た目違い）/ 化石の亀 | 1024x1024 | 512x512 | `us/enemies/fossil_turtle.png` | OK |
|  | 敵 | scrap_bull | armored（見た目違い）/ 鉄くずの牛 | 1024x1024 | 512x512 | `us/enemies/scrap_bull.png` | OK |
|  | 敵 | honey_sprite | healer（見た目違い）/ 蜂蜜の精 | 1024x1024 | 512x512 | `us/enemies/honey_sprite.png` | OK |
|  | 敵 | rain_cloud_sprite | healer（見た目違い）/ 雨雲の精 | 1024x1024 | 512x512 | `us/enemies/rain_cloud_sprite.png` | OK |
|  | ボス | dust_storm_lord | ミニボス（west）/ 砂嵐の主 | 1024x1024 | 512x512 | `us/bosses/dust_storm_lord.png` | OK |
|  | ボス | autumn_great_tree | ミニボス（northeast）/ 紅葉の大木 | 1024x1024 | 512x512 | `us/bosses/autumn_great_tree.png` | OK |
|  | ボス | prairie_wind_king | ミニボス（midwest）/ 大草原の風の王 | 1024x1024 | 512x512 | `us/bosses/prairie_wind_king.png` | OK |
|  | ボス | bayou_gator_king | ミニボス（south）/ 沼地の大ワニ | 1024x1024 | 512x512 | `us/bosses/bayou_gator_king.png` | OK |
|  | ボス | us_bunyan | The Giant Blue Ox | 1024x1024 | 512x512 | `us/bosses/us_bunyan.png` | OK |
|  | ボス | us_wright | The Gale Spirit | 1024x1024 | 512x512 | `us/bosses/us_wright.png` | OK |
|  | ボス | us_moon | The Moon Keeper | 1024x1024 | 512x512 | `us/bosses/us_moon.png` | OK |
|  | ボス | us_pony | The Dust Devil | 1024x1024 | 512x512 | `us/bosses/us_pony.png` | OK |
|  | 名所カード | grand_canyon | Grand Canyon | 1024x1024 | 512x512 | `us/landmarks/grand_canyon.png` | OK |
|  | 名所カード | golden_gate_bridge | Golden Gate Bridge | 1024x1024 | 512x512 | `us/landmarks/golden_gate_bridge.png` | OK |
|  | 名所カード | mesa_verde | Mesa Verde National Park | 1024x1024 | 512x512 | `us/landmarks/mesa_verde.png` | OK |
|  | 名所カード | kennedy_space_center | Kennedy Space Center | 1024x1024 | 512x512 | `us/landmarks/kennedy_space_center.png` | OK |
|  | 名所カード | diamond_head | Diamond Head (Oahu) | 1024x1024 | 512x512 | `us/landmarks/diamond_head.png` | OK |
|  | 名所カード | empire_state_building | Empire State Building | 1024x1024 | 512x512 | `us/landmarks/empire_state_building.png` | OK |
|  | 名所カード | lincoln_memorial | Lincoln Memorial | 1024x1024 | 512x512 | `us/landmarks/lincoln_memorial.png` | OK |
|  | 名所カード | willis_tower | Willis Tower | 1024x1024 | 512x512 | `us/landmarks/willis_tower.png` | OK |
|  | 名所カード | fenway_park | Fenway Park | 1024x1024 | 512x512 | `us/landmarks/fenway_park.png` | OK |
|  | 名所カード | las_vegas_strip | Las Vegas Strip | 1024x1024 | 512x512 | `us/landmarks/las_vegas_strip.png` | OK |
|  | 名所カード | devils_tower | Devils Tower | 1024x1024 | 512x512 | `us/landmarks/devils_tower.png` | OK |
|  | 名所カード | mount_rushmore | Mount Rushmore | 1024x1024 | 512x512 | `us/landmarks/mount_rushmore.png` | OK |
|  | 名所カード | space_needle | Space Needle | 1024x1024 | 512x512 | `us/landmarks/space_needle.png` | OK |
|  | 名所カード | johnson_space_center | Johnson Space Center (Houston) | 1024x1024 | 512x512 | `us/landmarks/johnson_space_center.png` | OK |
|  | 名所カード | arches_np | Arches National Park | 1024x1024 | 512x512 | `us/landmarks/arches_np.png` | OK |
|  | 名所カード | theodore_roosevelt_np | Theodore Roosevelt National Park | 1024x1024 | 512x512 | `us/landmarks/theodore_roosevelt_np.png` | OK |
|  | 名所カード | acadia_np | Acadia National Park | 1024x1024 | 512x512 | `us/landmarks/acadia_np.png` | OK |
|  | 名所カード | denali | Denali | 1024x1024 | 512x512 | `us/landmarks/denali.png` | OK |
|  | 名所カード | french_quarter | French Quarter (New Orleans) | 1024x1024 | 512x512 | `us/landmarks/french_quarter.png` | OK |
|  | 名所カード | liberty_bell | Liberty Bell (Philadelphia) | 1024x1024 | 512x512 | `us/landmarks/liberty_bell.png` | OK |
|  | 名所カード | gateway_arch | Gateway Arch (St. Louis) | 1024x1024 | 512x512 | `us/landmarks/gateway_arch.png` | OK |
|  | 名所カード | grand_ole_opry | Grand Ole Opry (Nashville) | 1024x1024 | 512x512 | `us/landmarks/grand_ole_opry.png` | OK |
|  | 名所カード | mammoth_cave | Mammoth Cave National Park | 1024x1024 | 512x512 | `us/landmarks/mammoth_cave.png` | OK |
|  | 名所カード | crater_lake | Crater Lake | 1024x1024 | 512x512 | `us/landmarks/crater_lake.png` | OK |
|  | 名所カード | carlsbad_caverns | Carlsbad Caverns National Park | 1024x1024 | 512x512 | `us/landmarks/carlsbad_caverns.png` | OK |
|  | 名所カード | mackinac_island | Mackinac Island | 1024x1024 | 512x512 | `us/landmarks/mackinac_island.png` | OK |
|  | 名所カード | rock_hall | Rock and Roll Hall of Fame (Cleveland) | 1024x1024 | 512x512 | `us/landmarks/rock_hall.png` | OK |
|  | 名所カード | indy_speedway | Indianapolis Motor Speedway | 1024x1024 | 512x512 | `us/landmarks/indy_speedway.png` | OK |
|  | 名所カード | mall_of_america | Mall of America | 1024x1024 | 512x512 | `us/landmarks/mall_of_america.png` | OK |
|  | 名所カード | chimney_rock | Chimney Rock | 1024x1024 | 512x512 | `us/landmarks/chimney_rock.png` | OK |
|  | 名所カード | georgia_aquarium | Georgia Aquarium (Atlanta) | 1024x1024 | 512x512 | `us/landmarks/georgia_aquarium.png` | OK |
|  | 名所カード | glacier_np | Glacier National Park | 1024x1024 | 512x512 | `us/landmarks/glacier_np.png` | OK |
|  | 名所カード | mount_washington | Mount Washington | 1024x1024 | 512x512 | `us/landmarks/mount_washington.png` | OK |
|  | 名所カード | lambeau_field | Lambeau Field (Green Bay) | 1024x1024 | 512x512 | `us/landmarks/lambeau_field.png` | OK |
|  | 名所カード | space_rocket_center | U.S. Space & Rocket Center (Huntsville) | 1024x1024 | 512x512 | `us/landmarks/space_rocket_center.png` | OK |
|  | 名所カード | biltmore | Biltmore Estate (Asheville) | 1024x1024 | 512x512 | `us/landmarks/biltmore.png` | OK |

## 共通（8枚）

| 試作 | 種類 | id | 備考 | 生成 | 最終 | ファイル | 状態 |
|---|---|---|---|---|---|---|---|
|  | 天候 | hurricane |  | 768x1344 | 768x1344 | `common/weather/hurricane.png` | OK |
|  | 天候 | tornado |  | 768x1344 | 768x1344 | `common/weather/tornado.png` | OK |
|  | 天候 | blizzard |  | 768x1344 | 768x1344 | `common/weather/blizzard.png` | OK |
|  | 天候 | heatwave |  | 768x1344 | 768x1344 | `common/weather/heatwave.png` | OK |
|  | 天候 | wildfire |  | 768x1344 | 768x1344 | `common/weather/wildfire.png` | OK |
|  | 天候 | flood |  | 768x1344 | 768x1344 | `common/weather/flood.png` | OK |
|  | 天候 | earthquake |  | 768x1344 | 768x1344 | `common/weather/earthquake.png` | OK |
|  | 天候 | storm |  | 768x1344 | 768x1344 | `common/weather/storm.png` | OK |

