"""profile.json から画像生成(Canva / Leonardo AI)用プロンプト集を生成する。
usage: python3 tools/make_art_prompts.py > docs/art_prompts_v0_1.md"""
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

def main():
    out = ["# 画像生成プロンプト集 v0.1", "",
           "`tools/make_art_prompts.py` が `profile.json` から生成（設定を変えたら作り直す）。Canva / Leonardo AI 用。", "",
           "## 使い方", "",
           f"- 共通の画風: `{STYLE}`（各プロンプトに含めてある）",
           "- **最初の1枚**で画風を決め、気に入った画像を2枚目以降の参照画像(Image Guidance / Style Reference)にして画風を揃える。",
           "- 背景: 横長 16:9。道は描かない（道はゲーム側で引く）。",
           "- 施設・敵: 正方形 1:1。無地の白背景で作り、後で背景除去。",
           "- 戦争・特定の歴史を連想させる表現、実在の紋章・ロゴは入れない。", ""]
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
        out.append("")
    print("\n".join(out))

main()
