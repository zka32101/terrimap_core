#!/usr/bin/env python3
"""Terrimap のマーク（地球儀の面を経緯線のタイルに分け、橙のタイルで「T」を塗る）を SVG と PNG で生成する。

使い方: tools/make_mark.py <出力ディレクトリ> [--bg indigo|teal|none]
出力: mark.svg / mark_1024.png / mark_512.png / mark_192.png / mark_48.png（背景つき。--bg none なら透明）、
      logo.svg / logo.png（横長: マーク + Terrimap の文字。PNG は Inter があればそれで描く）
依存: Pillow。結果は決定的。設計メモ: docs/brand_mark_v0_1.md
"""
import argparse, math, pathlib, sys
from PIL import Image, ImageDraw, ImageFont

COLORS = {"indigo": (43, 45, 119), "teal": (15, 76, 92)}
ORANGE, LAND = (244, 163, 0), (232, 241, 242)
TILT = 22  # 地球儀を北へ傾ける角度（北極側が見える）
INSET = 0.0  # タイルの隙間は、隙間をあけずに、背景色の線で区切る（縁が滑らかな円になる）
GAP = 0.011  # 区切り線の太さ（画像の幅に対する比）
LONS = [-198 + 36 * i for i in range(12)]  # 36度刻み。中央のタイルは経度 -18〜18
LATS = [-90, -60, -30, 0, 30, 60, 90]  # 北緯60度より北と南緯60度より南は、それぞれ1枚の「極のふた」
# T の字: 上段 = 北緯30〜60度の3枚、茎 = 北緯0〜30度と南緯30〜0度の2枚（中央の経度）
CENTER = LONS.index(-18)
T_CELLS = {(CENTER - 1, 3), (CENTER, 3), (CENTER + 1, 3), (CENTER, 2), (CENTER, 1)}


def project(lon, lat):
    """正射図法。裏側の点は縁（単位円）に寄せる。"""
    p0, l, p = math.radians(TILT), math.radians(lon), math.radians(lat)
    x = math.cos(p) * math.sin(l)
    y = math.cos(p0) * math.sin(p) - math.sin(p0) * math.cos(p) * math.cos(l)
    v = math.sin(p0) * math.sin(p) + math.cos(p0) * math.cos(p) * math.cos(l)
    if v < 0:
        n = math.hypot(x, y) or 1.0
        x, y = x / n, y / n
    return (x, y), v


def cells():
    """(色, [単位円上の点列], [各点の正面度 v]) の一覧。v<0 は裏側（縁に寄せた点）。"""
    out, n = [], 72
    for ri in range(len(LATS) - 1):
        a, b = LATS[ri], LATS[ri + 1]
        polar = ri in (0, len(LATS) - 2)
        spans = [(-180.0 + INSET, 180.0 - INSET)] if polar else [(LONS[ci] + INSET, LONS[ci + 1] - INSET) for ci in range(len(LONS) - 1)]
        for si, (la, lb) in enumerate(spans):
            pa, pb = a + INSET, b - INSET
            if polar:
                pa, pb = (a + INSET, 90.0) if ri == len(LATS) - 2 else (-90.0, b - INSET)
            top = [project(la + (lb - la) * i / n, pb) for i in range(n + 1)]
            bot = [project(lb + (la - lb) * i / n, pa) for i in range(n + 1)]
            if max(v for _, v in top + bot) <= 0.02:
                continue
            ci = None if polar else si
            color = ORANGE if (ci, ri) in T_CELLS else LAND
            out.append((color, [p for p, _ in top + bot], [v for _, v in top + bot]))
    return out


def visible_runs(pts, vs, closed=True):
    """区切り線として引く、正面側の連続した点列（縁に寄せた裏側の点は線にしない）。"""
    n = len(pts)
    seq = list(range(n)) + ([0] if closed else [])
    runs, cur = [], []
    for i in seq:
        if vs[i] > 0.03:
            cur.append(pts[i])
        else:
            if len(cur) > 1:
                runs.append(cur)
            cur = []
    if len(cur) > 1:
        runs.append(cur)
    return runs


def svg_mark(bg, size=1024, radius=0.38, with_bg=True):
    c = size / 2
    r = size * radius
    f = lambda p: f"{c + r * p[0]:.1f},{c - r * p[1]:.1f}"
    hexc = lambda col: "#%02x%02x%02x" % col
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}" width="{size}" height="{size}">']
    if with_bg:
        parts.append(f'<rect width="{size}" height="{size}" fill="{hexc(bg)}"/>')
    parts.append(f'<clipPath id="g"><circle cx="{c}" cy="{c}" r="{r:.1f}"/></clipPath>')
    parts.append(f'<circle cx="{c}" cy="{c}" r="{r:.1f}" fill="{hexc(LAND)}"/>')
    parts.append(f'<g clip-path="url(#g)" stroke="{hexc(bg)}" stroke-width="{size * GAP:.1f}" stroke-linejoin="round">')
    for col, pts, vs in cells():
        parts.append(f'<polygon fill="{hexc(col)}" stroke="none" points="{" ".join(f(p) for p in pts)}"/>')
        for run in visible_runs(pts, vs):
            parts.append(f'<polyline fill="none" points="{" ".join(f(p) for p in run)}"/>')
    parts.append("</g>")
    parts.append(f'<circle cx="{c}" cy="{c}" r="{r:.1f}" fill="none" stroke="{hexc(bg)}" stroke-width="{size * GAP * 1.6:.1f}"/>')
    parts.append("</svg>")
    return "\n".join(parts)


def png_mark(bg, size, with_bg=True, radius=0.38):
    ss = 4
    S = size * ss
    c, r = S / 2, S * radius
    img = Image.new("RGBA", (S, S), (*bg, 255) if with_bg else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([c - r, c - r, c + r, c + r], fill=(*LAND, 255))
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    for col, pts, vs in cells():
        xy = [(c + r * x, c - r * y) for x, y in pts]
        ld.polygon(xy, fill=(*col, 255))
        for run in visible_runs(pts, vs):
            ld.line([(c + r * x, c - r * y) for x, y in run], fill=(*bg, 255), width=max(1, round(S * GAP)), joint="curve")
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse([c - r, c - r, c + r, c + r], fill=255)
    img.paste(layer, (0, 0), Image.composite(layer.getchannel("A"), Image.new("L", (S, S), 0), mask))
    w = max(2, round(S * GAP * 1.6))  # 縁の輪郭（切り抜きのわずかな凹みを隠し、円をくっきりさせる）
    ImageDraw.Draw(img).ellipse([c - r, c - r, c + r, c + r], outline=(*bg, 255), width=w)
    return img.resize((size, size), Image.LANCZOS)


FONTS = ["/usr/share/fonts/opentype/inter/InterDisplay-Bold.otf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"]


def logo_png(bg, height=512):
    """横長ロゴ: 透明背景のマーク + Terrimap（白地想定の濃色文字）。"""
    mark = png_mark(bg, height, with_bg=False, radius=0.46)
    font = None
    for p in FONTS:
        try:
            font = ImageFont.truetype(p, int(height * 0.46))
            break
        except OSError:
            pass
    font = font or ImageFont.load_default()
    tmp = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    b = tmp.textbbox((0, 0), "Terrimap", font=font)
    tw, th = b[2] - b[0], b[3] - b[1]
    W = height + int(height * 0.05) + tw + int(height * 0.1)
    img = Image.new("RGBA", (W, height), (255, 255, 255, 255))
    img.paste(mark, (0, 0), mark)
    ImageDraw.Draw(img).text((height + int(height * 0.05) - b[0], (height - th) // 2 - b[1]), "Terrimap", font=font, fill=(*bg, 255))
    return img


def svg_logo(bg, height=512):
    hexc = "#%02x%02x%02x" % bg
    inner = svg_mark(bg, height, with_bg=False, radius=0.46).split("\n")
    body = "\n".join(inner[1:-1])
    W = int(height * 2.55)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {height}" width="{W}" height="{height}">\n'
            f'<rect width="{W}" height="{height}" fill="#ffffff"/>\n{body}\n'
            f'<text x="{int(height * 1.07)}" y="{int(height * 0.66)}" font-family="Inter, Helvetica, Arial, sans-serif" '
            f'font-weight="700" font-size="{int(height * 0.46 * 1.1)}" fill="{hexc}">Terrimap</text>\n</svg>\n')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--bg", choices=["indigo", "teal", "none"], default="indigo")
    a = ap.parse_args()
    out = pathlib.Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    col = COLORS["indigo" if a.bg == "none" else a.bg]
    with_bg = a.bg != "none"
    (out / "mark.svg").write_text(svg_mark(col, with_bg=with_bg) + "\n")
    for s in (1024, 512, 192, 48):
        png_mark(col, s, with_bg=with_bg).save(out / f"mark_{s}.png")
    (out / "logo.svg").write_text(svg_logo(col))
    logo_png(col).save(out / "logo.png")
    print(f"wrote {out}")


if __name__ == "__main__":
    sys.exit(main())
