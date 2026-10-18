# 画像一覧 v0.1

`tools/art_manifest.py` が profile.json から生成。状態は `art/` の中身で決まる（`--dir` で変更）。

- 生成サイズは Leonardo の設定、最終サイズはアプリに入れるサイズ（施設・敵・ボスは背景除去後に 512x512 へ縮小、PNG）。
- ★ = 試作13枚（ドイツ）。

## DE（33枚）

| 試作 | 種類 | id | 備考 | 生成 | 最終 | ファイル | 状態 |
|---|---|---|---|---|---|---|---|
| ★ | 背景 | alps | アルプスの山と雪 | 1344x768 | 1344x768 | `de/backdrops/alps.png` | 未作成 |
|  | 背景 | black_forest | 深い森と丘 | 1344x768 | 1344x768 | `de/backdrops/black_forest.png` | 未作成 |
|  | 背景 | north_coast | 北海・バルト海の海岸と風車 | 1344x768 | 1344x768 | `de/backdrops/north_coast.png` | 未作成 |
|  | 背景 | port | 港とコンテナ | 1344x768 | 1344x768 | `de/backdrops/port.png` | 未作成 |
| ★ | 背景 | city | 都市のスカイライン | 1344x768 | 1344x768 | `de/backdrops/city.png` | 未作成 |
|  | 背景 | vineyard | 川沿いのぶどう畑 | 1344x768 | 1344x768 | `de/backdrops/vineyard.png` | 未作成 |
|  | 背景 | farmland | 麦畑と風力発電 | 1344x768 | 1344x768 | `de/backdrops/farmland.png` | 未作成 |
|  | 背景 | industry | 工場と炭鉱の街 | 1344x768 | 1344x768 | `de/backdrops/industry.png` | 未作成 |
|  | 背景 | lakes | 湖と森 | 1344x768 | 1344x768 | `de/backdrops/lakes.png` | 未作成 |
|  | 背景 | castle_hills | 丘の上の城 | 1344x768 | 1344x768 | `de/backdrops/castle_hills.png` | 未作成 |
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

## US（34枚）

| 試作 | 種類 | id | 備考 | 生成 | 最終 | ファイル | 状態 |
|---|---|---|---|---|---|---|---|
|  | 背景 | desert | 砂漠と赤い岩 | 1344x768 | 1344x768 | `us/backdrops/desert.png` | 未作成 |
|  | 背景 | plains | 大平原と地平線 | 1344x768 | 1344x768 | `us/backdrops/plains.png` | 未作成 |
|  | 背景 | rockies | ロッキーの山と雪 | 1344x768 | 1344x768 | `us/backdrops/rockies.png` | 未作成 |
|  | 背景 | bayou | 湿地とバイユー | 1344x768 | 1344x768 | `us/backdrops/bayou.png` | 未作成 |
|  | 背景 | atlantic_coast | 大西洋岸の港と灯台 | 1344x768 | 1344x768 | `us/backdrops/atlantic_coast.png` | 未作成 |
|  | 背景 | pacific_coast | 太平洋岸と霧 | 1344x768 | 1344x768 | `us/backdrops/pacific_coast.png` | 未作成 |
|  | 背景 | great_lakes | 五大湖と港町 | 1344x768 | 1344x768 | `us/backdrops/great_lakes.png` | 未作成 |
|  | 背景 | appalachia | アパラチアの丘と霧 | 1344x768 | 1344x768 | `us/backdrops/appalachia.png` | 未作成 |
|  | 背景 | skyline | 摩天楼の街 | 1344x768 | 1344x768 | `us/backdrops/skyline.png` | 未作成 |
|  | 背景 | tundra | 氷原とオーロラ | 1344x768 | 1344x768 | `us/backdrops/tundra.png` | 未作成 |
|  | 背景 | tropics | 亜熱帯の海と島 | 1344x768 | 1344x768 | `us/backdrops/tropics.png` | 未作成 |
|  | 背景 | cornfield | とうもろこし畑とサイロ | 1344x768 | 1344x768 | `us/backdrops/cornfield.png` | 未作成 |
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

