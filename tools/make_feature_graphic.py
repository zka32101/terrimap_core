#!/usr/bin/env python3
"""Google Play のフィーチャーグラフィック（1024x500）を作る。左に地図、右にアプリ名とひとこと、Terrimap のマーク。

使い方: tools/make_feature_graphic.py <de|us> <言語> <出力.png>
言語: en / de（de 版アプリ）、en / es（us 版アプリ）。文言は docs/store_listing_v0_1.md のタイトルと短い説明に合わせる。
ルール: yourwish/docs/aso-rules.md（文字は少なく。「無料」「ベスト」などを入れない。絵文字なし）。依存: Pillow。結果は決定的。
"""
import argparse, importlib.util, pathlib, sys, tempfile
from PIL import Image, ImageDraw, ImageFont

HERE = pathlib.Path(__file__).resolve().parent


def load(name):
    spec = importlib.util.spec_from_file_location(name, HERE / f"{name}.py")
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


# (アプリ名, ひとこと)。ひとことは短く（掲載文の短い説明より短くする）。
TEXT = {
    ("de", "en"): ("State Master – Germany", "Learn the 16 states with map quizzes and tower defense"),
    ("de", "de"): ("Bundesländer-Meister", "Lerne die 16 Länder mit Karten-Quiz und Tower-Defense"),
    ("us", "en"): ("State Master – USA", "Learn all 50 states with map quizzes and tower defense"),
    ("us", "es"): ("Maestro de Estados – EE. UU.", "Aprende los 50 estados con cuestionarios de mapa y tower defense"),
}
FONT_BOLD = ["/usr/share/fonts/opentype/inter/InterDisplay-Bold.otf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"]
FONT_REG = ["/usr/share/fonts/opentype/inter/Inter-Regular.otf", "/usr/share/fonts/opentype/inter/InterDisplay-Regular.otf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"]


def font(paths, px):
    for p in paths:
        try:
            return ImageFont.truetype(p, px)
        except OSError:
            continue
    return ImageFont.load_default()


def wrap(draw, text, f, width):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if draw.textlength(t, font=f) <= width:
            cur = t
        else:
            lines.append(cur)
            cur = w
    return lines + ([cur] if cur else [])


def render(country, lang):
    mi, mm = load("make_icon"), load("make_mark")
    title, tag = TEXT[(country, lang)]
    W, H, ss = 1024, 500, 2
    cfg = mi.CONFIG[country]
    bg = cfg["bg"]
    # 背景: 背景色 + うっすら国旗（横長に引き伸ばさず、正方形で作って中央を切り出す）
    flag = mi.flag_overlay(country, W * ss, mi.FLAG_ALPHA[country])
    base = Image.alpha_composite(Image.new("RGBA", (W * ss, W * ss), (*bg, 255)), flag)
    top = (W * ss - H * ss) // 2
    img = base.crop((0, top, W * ss, top + H * ss))
    # 地図（アダプティブ用の前景を流用し、余白を切り詰めて高さ 420 に合わせる）
    with tempfile.TemporaryDirectory() as d:
        mi.render_adaptive(country, d, size=1024)
        fg = Image.open(pathlib.Path(d) / "foreground.png").convert("RGBA")
    box = fg.getchannel("A").getbbox()
    fg = fg.crop(box)
    mh = 400 * ss
    mw = round(fg.width * mh / fg.height)
    maxw = 480 * ss
    if mw > maxw:
        mw, mh = maxw, round(fg.height * maxw / fg.width)
    fg = fg.resize((mw, mh), Image.LANCZOS)
    mx = 40 * ss + (maxw - mw) // 2
    img.paste(fg, (mx, (H * ss - mh) // 2), fg)
    d = ImageDraw.Draw(img)
    # 右側: マーク（小さく）、アプリ名、ひとこと
    x0, wmax = 560 * ss, (W - 560 - 48) * ss
    mark = mm.png_mark(mm.COLORS["indigo"], 84 * ss, with_bg=False, radius=0.5)
    ring = Image.new("RGBA", (96 * ss, 96 * ss), (0, 0, 0, 0))
    ImageDraw.Draw(ring).ellipse([0, 0, 96 * ss - 1, 96 * ss - 1], fill=(255, 255, 255, 255))
    ring.paste(mark, (6 * ss, 6 * ss), mark)
    img.paste(ring, (x0, 70 * ss), ring)
    f_title = font(FONT_BOLD, 56 * ss)
    lines = wrap(d, title, f_title, wmax)
    while len(lines) > 2 or any(d.textlength(l, font=f_title) > wmax for l in lines):
        f_title = font(FONT_BOLD, int(f_title.size * 0.92))
        lines = wrap(d, title, f_title, wmax)
    y = 190 * ss
    for l in lines:
        d.text((x0, y), l, font=f_title, fill=(255, 255, 255))
        y += int(f_title.size * 1.15)
    # 橙の区切り線
    d.rectangle([x0, y + 10 * ss, x0 + 90 * ss, y + 16 * ss], fill=mi.ORANGE)
    f_tag = font(FONT_REG, 27 * ss)
    y += 34 * ss
    for l in wrap(d, tag, f_tag, wmax):
        d.text((x0, y), l, font=f_tag, fill=(222, 232, 236))
        y += int(f_tag.size * 1.35)
    return img.convert("RGB").resize((W, H), Image.LANCZOS)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("country", choices=["de", "us"])
    ap.add_argument("lang")
    ap.add_argument("out")
    a = ap.parse_args()
    if (a.country, a.lang) not in TEXT:
        sys.exit(f"文言がない組み合わせ: {a.country} {a.lang}（{sorted(TEXT)}）")
    render(a.country, a.lang).save(a.out)
    print(f"wrote {a.out}")


if __name__ == "__main__":
    sys.exit(main())
