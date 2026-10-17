"""州都の位置と隣接を、地図に重ねた確認画像にする(目視用)。
usage: python3 tools/make_capital_check.py de|us [out.png]"""
import json, math, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
cc = sys.argv[1]; out = sys.argv[2] if len(sys.argv) > 2 else str(ROOT / f"docs/concepts/capitals_{cc}.png")
pk = json.loads((ROOT / f"packs/{cc}/pack.json").read_text())
geo = json.loads((ROOT / f"packs/{cc}/geo.geojson").read_text())
regs = {r["id"]: r for r in json.loads((ROOT / f"packs/{cc}/regions.json").read_text())["regions"]}
names = json.loads((ROOT / f"packs/{cc}/strings/en.json").read_text())
planar = pk["projection"]["type"] == "planar"
cosr = math.cos(math.radians(pk["projection"].get("refLat", 36)))
proj = (lambda x, y: (x, y)) if planar else (lambda x, y: (x * cosr, -y))
polys = {f["properties"]["id"]: [[proj(*p) for p in poly[0]] for poly in f["geometry"]["coordinates"]] for f in geo["features"]}
allp = [p for ps in polys.values() for r in ps for p in r]
minx, maxx = min(p[0] for p in allp), max(p[0] for p in allp); miny, maxy = min(p[1] for p in allp), max(p[1] for p in allp)
W = 1400; S = (W - 40) / (maxx - minx); H = int((maxy - miny) * S + 40)
tf = lambda p: (20 + (p[0] - minx) * S, 20 + (p[1] - miny) * S)
im = Image.new("RGB", (W, H), (250, 248, 244)); d = ImageDraw.Draw(im)
font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12)
for i, ps in polys.items():
    for r in ps:
        d.polygon([tf(p) for p in r], fill=(226, 232, 236), outline=(110, 125, 135))
cap = {i: tf(proj(regs[i]["capitalPos"]["x"], regs[i]["capitalPos"]["y"])) for i in regs}
for i, r in regs.items():
    for n in r["neighbors"]:
        if i < n: d.line([cap[i], cap[n]], fill=(120, 170, 220), width=1)
for i, (x, y) in cap.items():
    d.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(214, 40, 40), outline="white")
    d.text((x + 6, y - 7), names["capitals"][regs[i]["capitalId"]], fill=(30, 30, 30), font=font)
im.save(out); print(out)
