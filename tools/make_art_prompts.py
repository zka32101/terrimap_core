"""profile.json から画像生成(Canva / Leonardo AI)用プロンプト集を生成する。
usage: python3 tools/make_art_prompts.py > docs/art_prompts_v0_2.md"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STYLE = "cute flat vector illustration, soft pastel colors, clean shapes, mobile tower-defense game art, no text, no people, no weapons"
SCENE = {  # 背景id -> 英語の場面
    "alps": "Alpine snowy peaks, green meadow, wooden chalet", "black_forest": "dense fir forest and rolling hills",
    "north_coast": "North Sea coast with wind turbines and a small lighthouse", "port": "harbor with shipping containers and cranes",
    "city": "city skyline with modern towers", "vineyard": "riverside vineyard terraces",
    "farmland": "wheat fields with wind turbines", "industry": "factories and a coal-mining town",
    "lakes": "forest lakes and calm water", "castle_hills": "hilltop castle over green hills",
    "desert": "desert with red rock mesas and cacti", "plains": "vast prairie with a far horizon",
    "rockies": "rocky mountains with snow", "bayou": "swamp bayou with cypress trees and mist",
    "atlantic_coast": "Atlantic harbor with a lighthouse", "pacific_coast": "Pacific coast with sea fog and cliffs",
    "great_lakes": "great lakes port town", "appalachia": "misty Appalachian forested hills",
    "skyline": "skyscraper city skyline", "tundra": "icy tundra with aurora in the sky",
    "tropics": "subtropical sea and small islands with palm trees", "cornfield": "cornfield with a grain silo",
}
SPRITE = {  # skin id -> 英語の描写
    "farm_windmill": "a farm with a windmill and a small barn", "harbor_cutter": "a small fishing cutter boat at a harbor",
    "automotive_plant": "a car factory with a chimney and a little car", "coal_mine": "a coal mine with a headframe tower and a cart",
    "hilltop_castle": "a small castle on a hill", "chapel": "a small stone chapel with a bell tower",
    "grain_silo": "a grain silo next to a red barn", "fishing_trawler": "a fishing trawler ship with nets",
    "assembly_line": "an assembly line factory with robotic arms", "oil_derrick": "an oil derrick pump",
    "capitol_hall": "a domed capitol hall building", "town_church": "a white town church with a steeple",
    "rust_sprite": "a small rusty sprite creature, mischievous", "dash_gremlin": "a fast little gremlin running",
    "iron_golem": "a sturdy iron golem with armor plates", "forest_sprite": "a gentle forest spirit with leaves, healer",
    "dust_devil": "a swirling dust devil creature with eyes", "tumbleweed": "a rolling tumbleweed creature",
    "rock_golem": "a chunky red rock golem", "cactus_nurse": "a cute cactus healer with a bandage",
}

EXCLUSIVE = {  # 限定施設 id -> 英語の描写（実在の紋章・国旗・人物は描かない）
    "automotive_works": "a large car works with a test track", "brewery": "a traditional brewery with copper kettles",
    "container_port": "a container terminal with gantry cranes", "parliament": "a glass-domed parliament building",
    "porcelain_works": "a porcelain workshop with a kiln and tea set", "ruhr_works": "a steelworks with blast furnace towers",
    "seaport": "a seaport with a big cargo ship and cranes", "stock_exchange": "a stock exchange hall with columns and a bull statue",
    "wartburg": "a medieval hilltop fortress", "winery": "a winery with barrels and vine rows",
    "aerospace_works": "an aerospace factory with a rocket on a stand", "capitol": "a domed capitol building",
    "distillery": "a whiskey distillery with barrels", "national_lab": "a science laboratory with a radar dish",
    "oil_derrick": "a large oil derrick", "pipeline": "a pipeline pumping station with pipes",
    "space_center": "a space center launch pad with a rocket", "tech_campus": "a modern tech campus with round glass buildings",
}
BOSS = {  # ボス名 -> 英語の描写（実在の人物の顔は描かない）
    "Water Nymph of the Rhine": "a mysterious water nymph made of river mist sitting on a rock, no human face details",
    "The Great Grey Wolf": "a huge grey wolf with glowing eyes, storybook style",
    "The Cave Dragon": "a big cave dragon curled around a pile of gold, friendly cartoon style",
    "The Giant Blue Ox": "a giant blue ox with large horns, folk-tale style",
    "The Gale Spirit": "a swirling wind spirit with a small propeller-like tail",
    "The Moon Keeper": "a round moon guardian creature with craters and a gentle glow",
}
WEATHER = {  # 天候 -> 英語の演出
    "hurricane": "swirling hurricane clouds and heavy rain", "tornado": "a funnel tornado of dust and debris",
    "blizzard": "heavy blowing snow", "heatwave": "shimmering heat haze with a bright orange sun",
    "wildfire": "orange embers and smoke drifting", "flood": "rising blue water with ripples",
    "earthquake": "cracks in the ground and dust", "storm": "dark storm clouds with lightning",
}
SEASON = {"spring": "fresh green with blossoms", "summer": "bright sunny and saturated", "autumn": "orange and red leaves", "winter": "snow-covered and cool blue"}

def block(title, name, desc, extra):
    return [f"- **{name}**（{title}）", "  ```", f"  {desc}, {extra}, {STYLE}", "  ```"]

def main():
    out = ["# 画像生成プロンプト集 v0.2", "",
           "`tools/make_art_prompts.py` が `profile.json` から生成（設定を変えたら作り直す）。Canva / Leonardo AI 用。", "",
           "## 使い方", "",
           f"- 共通の画風: `{STYLE}`（各プロンプトに含めてある）",
           "- **最初の1枚**で画風を決め、気に入った画像を2枚目以降の参照画像(Image Guidance / Style Reference)にして画風を揃える。",
           "- 背景: 横長 16:9。道は描かない（道はゲーム側で引く）。",
           "- 施設・敵: 正方形 1:1。無地の白背景で作り、後で背景除去。",
           "- 戦争・特定の歴史を連想させる表現、実在の紋章・ロゴ・国旗・人物の顔は入れない。",
           "- ボス・限定施設・天候は、v0.2 で追加。数の目安は下の「枚数」を参照。", "",
           "## Leonardo AI の設定（かわいい世界観を保つ）", "",
           "- モデル: Leonardo Phoenix か Lucid Origin（フラットなベクター風が出やすい）。プリセットスタイルは Illustration か Graphic Design。",
           "- 背景: 16:9（1344x768 など）。施設・敵・ボス: 1:1（1024x1024）。1回4枚生成して1枚選ぶ。",
           "- Negative prompt（共通）: `text, letters, logo, watermark, people, human face, weapon, blood, realistic, photo, 3d render, dark, scary, flags, emblem, road, path`（施設・敵は `background scenery` も足して、無地の白背景にする）",
           "- 画風の固定: 最初に選んだ背景1枚を Style Reference（強さ Mid〜High）に入れる。施設・敵は、気に入った施設1枚を Character Reference ではなく Style Reference にして、同じ線の太さと色合いにそろえる。",
           "- 敵・ボスは、怖くせずにかわいく: プロンプトに `chibi, round shape, big eyes, friendly, smiling` を足す。",
           "- 商用利用: 有料プランで生成した画像を使う（無料プランの画像は公開される・商用不可の場合があるので、利用規約を最新で確認）。", "",
           "## 試作（まずドイツで13枚）", "",
           "1. **背景を2枚**: `alps` と `city`（画風と色の幅を見る）。1枚目で画風を決める。",
           "2. **施設を6枚**: `farm_windmill` 〜 `chapel`（1枚目の背景を参照画像に）。",
           "3. **敵を4枚**: `rust_sprite` 〜 `forest_sprite`。",
           "4. **ボスを1枚**: `Water Nymph of the Rhine`。",
           "5. 画面（バトル）に置いて、見やすさ・大きさ・背景との相性を確かめる。良ければ残りを量産。", ""]
    for cc in ("de", "us"):
        pf = json.loads((ROOT / f"packs/{cc}/profile.json").read_text(encoding="utf-8"))
        out += [f"## {cc.upper()}", "", "### 背景", ""]
        for k, v in pf["theme"]["backdrops"].items():
            out += [f"- **{k}**（{v.get('note','')}）", "  ```",
                    f"  {SCENE.get(k, k)}, game background without any road or path, wide scene, palette {', '.join(v['palette'])}, {STYLE}",
                    "  ```"]
        for title, grp in (("施設", pf["facilities"]), ("敵", pf["enemySkins"])):
            out += ["", f"### {title}", ""]
            for k, v in grp.items():
                out += [f"- **{v['skin']}**（{v['name']['ja']} / {k}）", "  ```",
                        f"  {SPRITE.get(v['skin'], v['skin'])}, single game sprite, front view, plain white background, {STYLE}",
                        "  ```"]
        vs = [(k, v) for k, lst in (pf.get("enemyVariants") or {}).items() for v in lst]
        if vs:
            out += ["", "### 敵（見た目違い）", ""]
            for k, v in vs:
                out += [f"- **{v['skin']}**（{v['name']['ja']} / {k}の見た目違い）", "  ```",
                        f"  {SPRITE.get(v['skin'], v['skin'])}, single game sprite, front view, plain white background, {STYLE}",
                        "  ```"]
        ex = sorted({r["exclusiveFacility"] for r in pf["regions"].values() if r.get("exclusiveFacility")})
        out += ["", "### 限定施設（州ごとに1つ置ける特別な施設）", ""]
        for k in ex:
            out += block(k, k, EXCLUSIVE.get(k, k), "single game sprite, front view, plain white background")
        out += ["", "### ボス（エクストラの敵。正方形 1:1・白背景）", ""]
        for e in pf["extras"]:
            n = e["bossName"]["en"]
            out += block(f"{e['id']} / {e['basis']}", n, BOSS.get(n, n), "single game boss sprite, large, front view, plain white background")
        out.append("")
    out += ["## 共通（国をまたいで使う）", "", "### 天候の演出（全面に重ねる透過PNG。16:9）", ""]
    for k, v in WEATHER.items():
        out += block("天候", k, f"{v}, transparent overlay layer", "no ground, no buildings, wide scene")
    out += ["", "### 季節（背景の色味。別画像にせず、色調補正で足りるか先に試す）", ""]
    for k, v in SEASON.items():
        out += [f"- **{k}**: {v}"]
    out += ["", "## 枚数", "",
            "| 分類 | 1国 | 備考 |", "|---|---|---|",
            "| 背景 | 10〜12 | エクストラ用（3）を含む |", "| 施設 | 6 | 国の見た目 |",
            "| 限定施設 | 9〜10 | 最小構成は系統ごとの1枚ずつに共通化（6系統） |",
            "| 敵 | 4 | 能力は色や飾りで足りる |", "| ボス | 3 | |",
            "| 天候 | 8 | 共通で2国に使う |", "| アイコン・ストア | 約10 | `docs/terrimap_icon_design_v0_1.md` 参照 |",
            "", "1国 約50枚、2国で約100枚（天候を共通にして）。最小構成で約30枚。", ""]
    print("\n".join(out))

main()
