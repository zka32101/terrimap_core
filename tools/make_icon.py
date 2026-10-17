#!/usr/bin/env python3
"""Terrimap シリーズのアイコン(基本版)を packs の実データから生成する。設計: docs/terrimap_icon_design_v0_1.md

使い方: tools/make_icon.py <de|us> <出力.png> [--size 1024]
依存: Pillow(`pip install pillow`)。結果は決定的(同じ入力なら同じ画像)。
"""
import argparse, json, math, pathlib, sys
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
ORANGE = (244, 163, 0)

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


def render(country, size=1024):
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
    return img.resize((size, size), Image.LANCZOS)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("country", choices=sorted(CONFIG))
    ap.add_argument("out")
    ap.add_argument("--size", type=int, default=1024)
    a = ap.parse_args()
    render(a.country, a.size).save(a.out)
    print(f"wrote {a.out}")


if __name__ == "__main__":
    sys.exit(main())
