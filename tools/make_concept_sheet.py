"""profile.json から背景・施設・敵のイメージ案シートを生成する（仮絵。最終素材ではない）。
usage: python3 tools/make_concept_sheet.py de|us [out.png]"""
import json, math, random, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
CJK = "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc"
EMOJI = "/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf"

ICON = {  # skin id -> 仮アイコン(絵文字)
    "farm_windmill": "🌾", "harbor_cutter": "⛵", "automotive_plant": "🏭", "coal_mine": "⛏️",
    "hilltop_castle": "🏰", "chapel": "⛪", "rust_sprite": "🧚", "dash_gremlin": "👺",
    "iron_golem": "🤖", "forest_sprite": "🌿", "grain_silo": "🌽", "fishing_trawler": "🚢",
    "assembly_line": "⚙️", "oil_derrick": "🛢️", "capitol_hall": "🏛️", "town_church": "⛪",
    "dust_devil": "🌪️", "tumbleweed": "🌵", "rock_golem": "🪨", "cactus_nurse": "🩹",
}
MOTIF = {  # backdrop id -> 描くモチーフ
    "alps": "peaks", "rockies": "peaks", "tundra": "peaks", "black_forest": "forest", "appalachia": "forest",
    "bayou": "forest", "lakes": "water", "north_coast": "water", "atlantic_coast": "water",
    "pacific_coast": "water", "great_lakes": "water", "tropics": "water", "port": "city", "city": "city",
    "skyline": "city", "industry": "city", "vineyard": "rows", "farmland": "rows", "plains": "rows",
    "cornfield": "rows", "desert": "mesa", "castle_hills": "hills",
}

def hexrgb(h): return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))

def backdrop(pal, motif, w=300, h=190, seed=1):
    r = random.Random(seed)
    light, mid, dark = (hexrgb(c) for c in pal)
    im = Image.new("RGB", (w, h), light); d = ImageDraw.Draw(im)
    for y in range(h):  # 空のグラデーション
        t = y / h; d.line([(0, y), (w, y)], fill=tuple(int(light[i] * (1 - t * .25)) for i in range(3)))
    base = int(h * .62)
    if motif == "peaks":
        for k, col in ((0, mid), (1, dark)):
            pts = [(0, h)]
            for x in range(0, w + 40, 40):
                pts.append((x, base - r.randint(20, 70) + k * 18))
            pts.append((w, h)); d.polygon(pts, fill=col)
    elif motif == "forest":
        d.rectangle([0, base, w, h], fill=mid)
        for _ in range(26):
            x, s = r.randint(0, w), r.randint(18, 34); y = base + r.randint(-6, 40)
            d.polygon([(x, y - s), (x - s // 3, y), (x + s // 3, y)], fill=dark)
    elif motif == "water":
        d.rectangle([0, base, w, h], fill=mid)
        for i in range(5): d.arc([i * 60 - 20, base + 8 * i % 30, i * 60 + 40, base + 20 + 8 * i % 30], 200, 340, fill=light, width=2)
        d.polygon([(w - 60, base), (w - 50, base - 50), (w - 42, base)], fill=dark)  # 灯台/帆
    elif motif == "city":
        d.rectangle([0, base, w, h], fill=mid)
        x = 0
        while x < w:
            bw, bh = r.randint(18, 36), r.randint(30, 90); d.rectangle([x, base - bh, x + bw, base + 10], fill=dark); x += bw + 3
    elif motif == "rows":
        d.rectangle([0, base - 10, w, h], fill=mid)
        for i in range(8): d.line([(0, base + i * 12), (w, base - 6 + i * 12 + 6)], fill=dark, width=2)
    elif motif == "mesa":
        d.rectangle([0, base, w, h], fill=mid)
        for x in (50, 160, 235):
            bw = r.randint(40, 60); d.rectangle([x, base - 55, x + bw, base + 6], fill=dark)
    else:  # hills
        d.ellipse([-60, base - 20, 200, h + 80], fill=mid); d.ellipse([120, base, 380, h + 90], fill=dark)
    return im

def font(p, s):
    return ImageFont.truetype(p, s)

def main():
    cc = sys.argv[1]; out = sys.argv[2] if len(sys.argv) > 2 else str(ROOT / f"docs/concepts/{cc}_concept.png")
    pf = json.loads((ROOT / f"packs/{cc}/profile.json").read_text(encoding="utf-8"))
    th = pf["theme"]["backdrops"]; F = font(CJK, 15); T = font(CJK, 26)
    cols = 4; cw, ch = 300, 232; rows_bd = math.ceil(len(th) / cols)
    W = cols * (cw + 16) + 16; H = 60 + rows_bd * (ch + 12) + 40 + 2 * 150 + 40
    sheet = Image.new("RGB", (W, H), (250, 248, 244)); d = ImageDraw.Draw(sheet)
    d.text((16, 14), f"{cc.upper()}  背景・施設・敵 イメージ案（仮絵）", font=T, fill=(40, 40, 40))
    for i, (k, v) in enumerate(th.items()):
        x, y = 16 + (i % cols) * (cw + 16), 60 + (i // cols) * (ch + 12)
        sheet.paste(backdrop(v["palette"], MOTIF.get(k, "hills"), cw, 190, i + 1), (x, y))
        d.text((x, y + 194), f"{k}  {v.get('note','')}", font=F, fill=(40, 40, 40))
        for j, c in enumerate(v["palette"]): d.rectangle([x + j * 22, y + 216, x + j * 22 + 18, y + 230], fill=c)
    y = 60 + rows_bd * (ch + 12) + 10
    ef = font(EMOJI, 109)
    for title, grp in (("施設", pf["facilities"]), ("敵", pf["enemySkins"])):
        d.text((16, y), title, font=T, fill=(40, 40, 40)); y += 34
        for i, (k, v) in enumerate(grp.items()):
            x = 16 + i * 190
            d.rounded_rectangle([x, y, x + 176, y + 104], 12, fill=(255, 255, 255), outline=(210, 205, 195))
            tile = Image.new("RGBA", (136, 128), (0, 0, 0, 0)); ImageDraw.Draw(tile).text((0, 0), ICON.get(v["skin"], "?"), font=ef, embedded_color=True)
            sheet.paste(tile.resize((48, 48)), (x + 8, y + 6), tile.resize((48, 48)))
            d.text((x + 64, y + 10), k, font=F, fill=(120, 120, 120))
            d.text((x + 8, y + 62), v["name"]["ja"], font=F, fill=(30, 30, 30))
            d.text((x + 8, y + 82), v["skin"], font=font(CJK, 11), fill=(150, 150, 150))
        y += 124
    sheet.crop((0, 0, W, y + 10)).save(out)
    print(out)

main()
