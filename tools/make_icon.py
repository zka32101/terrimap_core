#!/usr/bin/env python3
"""Terrimap シリーズのアイコン(基本版)を packs の実データから生成する。設計: docs/terrimap_icon_design_v0_1.md

使い方: tools/make_icon.py <de|us> <出力.png> [--size 1024] [--td]
  --td: タワーディフェンス版(塔・射程円・敵の進路と敵を足す。試作。設計書の「タワーディフェンス版」)
依存: Pillow(`pip install pillow`)。結果は決定的(同じ入力なら同じ画像)。
"""
import argparse, json, math, pathlib, sys
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
ORANGE = (244, 163, 0)
RED = (214, 48, 49)
TOWER = (38, 40, 52)

# タワーディフェンス版の配置(画像に対する0..1の比率)。塗る地域を塔と進路で隠さない位置にする。
TD = {
    "de": dict(tower=(0.36, 0.44), path=[(0.80, 0.20), (0.66, 0.26), (0.56, 0.32), (0.48, 0.38), (0.42, 0.42)], enemies=[0.15, 0.45, 0.75]),
    "us": dict(tower=(0.46, 0.38), path=[(0.84, 0.20), (0.74, 0.24), (0.66, 0.28), (0.58, 0.32), (0.53, 0.35)], enemies=[0.15, 0.45, 0.75]),
}

# 国ごとの差分(設計書の表)。fit は「地図の長い辺が画像の何割を占めるか」。
CONFIG = {
    "de": dict(bg=(15, 76, 92), land=(232, 241, 242), paint={"DE-BY", "DE-BE", "DE-HH"}, fit=0.68, exclude=set()),
    "us": dict(bg=(43, 45, 119), land=(240, 236, 224), paint={"US-TX", "US-CA", "US-NY"}, fit=0.84, exclude={"US-AK", "US-HI"}),
}


def project(pack, lng, lat):
    p = pack["projection"]
    if p["type"] == "planar":
        return (lng, lat)  # 焼き込み済みの平面座標
    return (lng * math.cos(p.get("refLat", 36.0) * math.pi / 180), -lat)


def draw_td(img, country):
    """塔・射程円・敵の進路(赤い点線)・敵(赤い丸)を重ねる。"""
    S = img.size[0]
    cfg = TD[country]
    px = lambda p: (p[0] * S, p[1] * S)
    # 射程円(半透明)
    cx, cy = px(cfg["tower"])
    r = 0.15 * S
    ov = Image.new("RGBA", img.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(ov)
    od.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 255, 255, 70), outline=(255, 255, 255, 190), width=max(3, round(S * 0.005)))
    img.paste(Image.alpha_composite(img.convert("RGBA"), ov).convert("RGB"))
    d = ImageDraw.Draw(img)
    # 進路(点線)
    pts = [px(p) for p in cfg["path"]]
    seg = []
    for a, b in zip(pts, pts[1:]):
        n = max(1, int(math.dist(a, b) / (0.03 * S)))
        for i in range(n):
            t0, t1 = i / n, (i + 0.55) / n
            seg.append(((a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0), (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1)))
    for a, b in seg:
        d.line([a, b], fill=RED, width=max(4, round(S * 0.008)))
    # 敵(進路上の赤い丸。白い縁つき)
    total = sum(math.dist(a, b) for a, b in zip(pts, pts[1:]))
    for frac in cfg["enemies"]:
        want, acc = frac * total, 0.0
        for a, b in zip(pts, pts[1:]):
            L = math.dist(a, b)
            if acc + L >= want:
                t = (want - acc) / L
                ex, ey = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
                er = 0.028 * S
                d.ellipse([ex - er - 4, ey - er - 4, ex + er + 4, ey + er + 4], fill=(255, 255, 255))
                d.ellipse([ex - er, ey - er, ex + er, ey + er], fill=RED)
                break
            acc += L
    # 塔(城塔: 胸壁3つ・橙の扉)
    w, h = 0.15 * S, 0.24 * S  # 塔は大きく(アイコンの縮小表示でも一目で分かるように)
    left, top = cx - w / 2, cy - h / 2
    ow = max(8, round(S * 0.009))
    d.rectangle([left - ow, top - ow, left + w + ow, top + h + ow], fill=(255, 255, 255))
    d.rectangle([left, top + h * 0.18, left + w, top + h], fill=TOWER)
    mw = w / 5
    for i in range(3):  # 胸壁
        x0 = left + i * 2 * mw
        d.rectangle([x0, top, x0 + mw, top + h * 0.18 + 1], fill=TOWER)
    dw, dh = w * 0.34, h * 0.36
    d.rectangle([cx - dw / 2, top + h - dh, cx + dw / 2, top + h], fill=ORANGE)
    d.pieslice([cx - dw / 2, top + h - dh - dw / 2, cx + dw / 2, top + h - dh + dw / 2], 180, 360, fill=ORANGE)


def render(country, size=1024, td=False):
    cfg = CONFIG[country]
    pack = json.loads((ROOT / "packs" / country / "pack.json").read_text())
    geo = json.loads((ROOT / "packs" / country / "geo.geojson").read_text())

    regions = []  # (id, [リング(外周)の点列])
    for f in geo["features"]:
        rid = f["properties"]["id"]
        if rid in cfg["exclude"]:
            continue
        rings = [[project(pack, x, y) for x, y in poly[0]] for poly in f["geometry"]["coordinates"]]
        regions.append((rid, rings))

    xs = [x for _, rings in regions for r in rings for x, _ in r]
    ys = [y for _, rings in regions for r in rings for _, y in r]
    minx, maxx, miny, maxy = min(xs), max(xs), min(ys), max(ys)
    w, h = maxx - minx, maxy - miny

    ss = 2  # 2倍で描いて縮小(縁をなめらかに)
    S = size * ss
    scale = cfg["fit"] * S / max(w, h)
    ox, oy = (S - w * scale) / 2, (S - h * scale) / 2
    tf = lambda p: (ox + (p[0] - minx) * scale, oy + (p[1] - miny) * scale)

    img = Image.new("RGB", (S, S), cfg["bg"])
    d = ImageDraw.Draw(img)
    for rid, rings in regions:
        color = ORANGE if rid in cfg["paint"] else cfg["land"]
        for r in rings:
            d.polygon([tf(p) for p in r], fill=color)
    line = max(2, round(S * 0.0035))  # 境界線は背景色で細く抜く
    for _, rings in regions:
        for r in rings:
            pts = [tf(p) for p in r]
            d.line(pts + [pts[0]], fill=cfg["bg"], width=line, joint="curve")
    if td:
        draw_td(img, country)
    return img.resize((size, size), Image.LANCZOS)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("country", choices=sorted(CONFIG))
    ap.add_argument("out")
    ap.add_argument("--size", type=int, default=1024)
    ap.add_argument("--td", action="store_true", help="タワーディフェンス版(試作)")
    a = ap.parse_args()
    render(a.country, a.size, td=a.td).save(a.out)
    print(f"wrote {a.out}")


if __name__ == "__main__":
    sys.exit(main())
