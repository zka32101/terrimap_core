"""全ステージ（盤面・拠点・入口・進路・設置枠）を一覧画像にする（目視用）。
前提: DUMP_STAGES=1 flutter test test/stage_test.dart --plain-name 目視用 で build/stages_<pack>.json を作る。
usage: python3 tools/make_stage_sheet.py de|us [normal|hard|easy] [out.png]"""
import json, math, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
cc = sys.argv[1]; diff = sys.argv[2] if len(sys.argv) > 2 else "normal"
out = sys.argv[3] if len(sys.argv) > 3 else str(ROOT / f"docs/concepts/stages_{cc}_{diff}.png")
stages = [s for s in json.loads((ROOT / f"build/stages_{cc}.json").read_text()) if s["difficulty"] == diff]
names = json.loads((ROOT / f"packs/{cc}/strings/en.json").read_text())["regions"]
font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12)
small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 10)
CELL = 14; PAD = 8; COLS = 6
tw = 12 * CELL + 2 * PAD; th = 12 * CELL + 2 * PAD + 22
rows = math.ceil(len(stages) / COLS)
im = Image.new("RGB", (COLS * tw, rows * th), (250, 248, 244)); d = ImageDraw.Draw(im)
SEASON = {"spring": (214, 235, 200), "summer": (200, 232, 214), "autumn": (240, 224, 190), "winter": (222, 232, 242)}
for i, s in enumerate(stages):
    ox = (i % COLS) * tw + PAD; oy = (i // COLS) * th + PAD + 18
    d.text((ox, oy - 17), f'{s["regionId"][3:]} {names[s["regionId"]][:16]}', fill=(30, 30, 30), font=font)
    d.text((ox + 100, oy - 15), f'{s["cols"]}x{s["rows"]} {s["season"][:3]}', fill=(110, 110, 110), font=small)
    col = SEASON[s["season"]]
    for c, r in s["land"]:
        d.rectangle([ox + c * CELL, oy + r * CELL, ox + c * CELL + CELL - 1, oy + r * CELL + CELL - 1], fill=col, outline=(170, 180, 175))
    for c, r in s["slots"]:
        d.ellipse([ox + c * CELL + 4, oy + r * CELL + 4, ox + c * CELL + CELL - 5, oy + r * CELL + CELL - 5], fill=(130, 150, 170))
    for k, p in enumerate(s["paths"]):
        pts = [(ox + c * CELL + CELL / 2, oy + r * CELL + CELL / 2) for c, r in p]
        d.line(pts, fill=[(214, 40, 40), (230, 140, 30), (150, 60, 190)][k % 3], width=3)
    for k, e in enumerate(s["entrances"]):
        c, r = e["cell"]["col"], e["cell"]["row"]
        d.ellipse([ox + c * CELL + 2, oy + r * CELL + 2, ox + c * CELL + CELL - 3, oy + r * CELL + CELL - 3], outline=(214, 40, 40), width=2)
        d.text((ox + c * CELL + 1, oy + r * CELL - 11), (e["neighborId"] or "sea")[-2:], fill=(150, 30, 30), font=small)
    b = s["base"]
    d.rectangle([ox + b["col"] * CELL + 2, oy + b["row"] * CELL + 2, ox + b["col"] * CELL + CELL - 3, oy + b["row"] * CELL + CELL - 3], fill=(30, 30, 30))
im.save(out); print(out, len(stages))
