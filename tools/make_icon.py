#!/usr/bin/env python3
"""Terrimap シリーズのアイコン(基本版)を packs の実データから生成する。設計: docs/terrimap_icon_design_v0_1.md

使い方: tools/make_icon.py <de|us> <出力.png> [--size 1024] [--td] [--label] [--mark] [--flag] [--brand]
  --td: タワーディフェンス版(塔・射程円・敵の進路と敵を足す。試作。設計書の「タワーディフェンス版」)
  --label: 国の略称バッジ(DE/US)。バッジの下辺に国旗色の帯を入れる。左下（--mark と一緒なら左上）
  --mark: 左下に Terrimap のマーク（白い丸バッジの中。tools/make_mark.py）
  --flag: 背景に国旗をごく薄く敷く（地図の下）
  --brand: --label --mark --flag をまとめて指定
依存: Pillow(`pip install pillow`)。結果は決定的(同じ入力なら同じ画像)。
"""
import argparse, json, math, pathlib, sys
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
ORANGE = (244, 163, 0)
RED = (214, 48, 49)
TOWER = (38, 40, 52)

# 国の略称バッジ。帯は国旗の色(DE=黒・赤・金、US=赤・白・青)。文字は背景色と同じ濃色。
LABEL = {
    "de": dict(text="DE", bar=[(0, 0, 0), (221, 0, 0), (255, 206, 0)]),
    "us": dict(text="US", bar=[(178, 34, 52), (255, 255, 255), (60, 59, 110)]),
}
FONTS = [
    "/usr/share/fonts/opentype/inter/InterDisplay-Bold.otf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
]

# タワーディフェンス版の配置(画像に対する0..1の比率)。塗る地域を塔と進路で隠さない位置にする。
TD = {
    "de": dict(tower=(0.34, 0.43), path=[(0.82, 0.22), (0.70, 0.28), (0.60, 0.34), (0.52, 0.37), (0.46, 0.39)], enemies=[0.15, 0.45, 0.75]),
    "us": dict(tower=(0.45, 0.36), path=[(0.84, 0.18), (0.74, 0.22), (0.66, 0.26), (0.58, 0.29), (0.55, 0.31)], enemies=[0.15, 0.45, 0.75]),
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
    r = 0.18 * S
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
    w, h = 0.18 * S, 0.29 * S  # 塔は大きく(アイコンの縮小表示でも一目で分かるように)
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


def flag_overlay(country, S, alpha):
    """国旗を薄く描いた透明レイヤー（背景に重ねる）。DE=黒・赤・金の横3本、US=赤い横縞と左上の青い領域。"""
    L = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(L)
    if country == "de":
        for i, col in enumerate(LABEL["de"]["bar"]):
            d.rectangle([0, i * S / 3, S, (i + 1) * S / 3], fill=(*col, round(255 * alpha)))
    else:
        h = S / 13
        for i in range(0, 13, 2):
            d.rectangle([0, i * h, S, (i + 1) * h], fill=(178, 34, 52, round(255 * alpha)))
        d.rectangle([0, 0, S * 0.4, h * 7], fill=(255, 255, 255, round(255 * alpha * 0.6)))
    return L


def draw_mark(img):
    """左下に、白い丸いバッジに入れた Terrimap のマーク。"""
    import importlib.util
    spec = importlib.util.spec_from_file_location("make_mark", pathlib.Path(__file__).with_name("make_mark.py"))
    mm = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mm)
    S = img.size[0]
    d, pad = int(S * 0.20), int(S * 0.025)
    badge = Image.new("RGBA", (d + 2 * pad, d + 2 * pad), (0, 0, 0, 0))
    ImageDraw.Draw(badge).ellipse([0, 0, badge.width - 1, badge.height - 1], fill=(255, 255, 255, 255))
    mark = mm.png_mark(mm.COLORS["indigo"], d * 2, with_bg=False, radius=0.5).resize((d, d), Image.LANCZOS)
    badge.paste(mark, (pad, pad), mark)
    img.paste(badge, (int(S * 0.05), S - badge.height - int(S * 0.05)), badge)


def draw_label(img, country, top=False):
    """角丸の白いバッジ。国の略称と、下辺に国旗色の帯。左下。top=True なら左上。"""
    from PIL import ImageFont
    S = img.size[0]
    cfg = LABEL[country]
    font = None
    for path in FONTS:
        try:
            font = ImageFont.truetype(path, int(S * (0.10 if top else 0.13)))
            break
        except OSError:
            continue
    if font is None:
        font = ImageFont.load_default()
    d = ImageDraw.Draw(img)
    b = d.textbbox((0, 0), cfg["text"], font=font)
    tw, th = b[2] - b[0], b[3] - b[1]
    pad, bar = int(S * 0.03), int(S * 0.022)
    x0 = int(S * 0.05)
    y1 = int(S * 0.95)
    if top:
        y1 = int(S * 0.05) + th + 2 * pad + bar
    box = [x0, y1 - (th + 2 * pad + bar), x0 + tw + 2 * pad, y1]
    d.rounded_rectangle(box, int(S * 0.035), fill=(255, 255, 255))
    d.text((x0 + pad - b[0], box[1] + pad - b[1]), cfg["text"], font=font, fill=CONFIG[country]["bg"])
    # 国旗色の帯(角丸バッジの下辺に沿わせ、はみ出す部分は白で塗り戻して丸みを残す)
    n = len(cfg["bar"])
    x_start, x_end = box[0] + int(S * 0.012), box[2] - int(S * 0.012)
    seg = (x_end - x_start) / n
    by0, by1 = box[3] - bar - int(S * 0.012), box[3] - int(S * 0.012)
    for i, c in enumerate(cfg["bar"]):
        d.rectangle([x_start + i * seg, by0, x_start + (i + 1) * seg, by1], fill=c)
    if cfg["bar"][1] == (255, 255, 255):  # 白い帯は薄い枠線で見えるように
        d.rectangle([x_start, by0, x_end, by1], outline=(190, 190, 200), width=max(2, int(S * 0.002)))


FLAG_ALPHA = {"de": 0.10, "us": 0.09}


def render(country, size=1024, td=False, label=False, mark=False, flag=False):
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
    if flag:
        img = Image.alpha_composite(img.convert("RGBA"), flag_overlay(country, S, FLAG_ALPHA[country])).convert("RGB")
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
    if label:
        draw_label(img, country, top=mark)
    img = img.resize((size, size), Image.LANCZOS)
    if mark:  # マークは縮小後に重ねる（マーク側が自分で滑らかに描く）
        img = img.convert("RGBA")
        draw_mark(img)
        img = img.convert("RGB")
    return img


def render_adaptive(country, out_dir, size=1024, fit=None):
    """Android のアダプティブアイコン用の3枚を書き出す。
    background.png: 背景色 + うっすら国旗（全面）、foreground.png: 地図だけ（透明背景。中央の安全領域 66/108 に収める）、
    monochrome.png: 地図の輪郭を1色で（Android 13 のテーマアイコン用。塗る地域は同じ色で区別しない）。
    国の略称バッジとマークのバッジは、丸く切り抜かれると隅が欠けるので入れない（従来の正方形アイコンにだけ入る）。"""
    cfg = CONFIG[country]
    out = pathlib.Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    pack = json.loads((ROOT / "packs" / country / "pack.json").read_text())
    geo = json.loads((ROOT / "packs" / country / "geo.geojson").read_text())
    regions = []
    for f in geo["features"]:
        rid = f["properties"]["id"]
        if rid in cfg["exclude"]:
            continue
        regions.append((rid, [[project(pack, x, y) for x, y in poly[0]] for poly in f["geometry"]["coordinates"]]))
    xs = [x for _, rs in regions for r in rs for x, _ in r]
    ys = [y for _, rs in regions for r in rs for _, y in r]
    minx, maxx, miny, maxy = min(xs), max(xs), min(ys), max(ys)
    w, h = maxx - minx, maxy - miny
    fit = fit or {"de": 0.60, "us": 0.56}[country]
    ss = 2
    S = size * ss
    scale = fit * S / max(w, h)
    ox, oy = (S - w * scale) / 2, (S - h * scale) / 2
    tf = lambda p: (ox + (p[0] - minx) * scale, oy + (p[1] - miny) * scale)
    # 前景（透明背景）
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(fg)
    mono = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    md = ImageDraw.Draw(mono)
    for rid, rings in regions:
        color = ORANGE if rid in cfg["paint"] else cfg["land"]
        for r in rings:
            pts = [tf(p) for p in r]
            d.polygon(pts, fill=(*color, 255))
            md.polygon(pts, fill=(0, 0, 0, 255))
    line = max(2, round(S * 0.0035))
    for _, rings in regions:
        for r in rings:
            pts = [tf(p) for p in r]
            d.line(pts + [pts[0]], fill=(*cfg["bg"], 255), width=line, joint="curve")
    # 背景（背景色 + 国旗）
    bg = Image.new("RGBA", (S, S), (*cfg["bg"], 255))
    bg = Image.alpha_composite(bg, flag_overlay(country, S, FLAG_ALPHA[country]))
    for name, im in (("background", bg), ("foreground", fg), ("monochrome", mono)):
        im.resize((size, size), Image.LANCZOS).save(out / f"{name}.png")
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("country", choices=sorted(CONFIG))
    ap.add_argument("out")
    ap.add_argument("--size", type=int, default=1024)
    ap.add_argument("--td", action="store_true", help="タワーディフェンス版(試作)")
    ap.add_argument("--label", action="store_true", help="左下に国の略称バッジ(国旗色の帯つき)")
    ap.add_argument("--mark", action="store_true", help="左下に Terrimap のマーク（白い丸バッジ）")
    ap.add_argument("--flag", action="store_true", help="背景に国旗をごく薄く敷く")
    ap.add_argument("--brand", action="store_true", help="--label --mark --flag をまとめて指定")
    ap.add_argument("--adaptive", metavar="DIR", help="Android のアダプティブアイコン用の background/foreground/monochrome.png を DIR に書き出す（<出力.png> は使わない）")
    a = ap.parse_args()
    if a.adaptive:
        print(f"wrote {render_adaptive(a.country, a.adaptive, a.size)}")
        return
    if a.brand:
        a.label = a.mark = a.flag = True
    render(a.country, a.size, td=a.td, label=a.label, mark=a.mark, flag=a.flag).save(a.out)
    print(f"wrote {a.out}")


if __name__ == "__main__":
    sys.exit(main())
