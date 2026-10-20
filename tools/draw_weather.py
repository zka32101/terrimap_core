# terrimap 天候オーバーレイ8枚をコードで描く(Pillow)。768x1344(9:16)・透過PNG。やわらかいパステル調。
# 使い方: python draw_weather.py <出力フォルダ>
import math, random, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops

W, H = 768, 1344
K = 2


def canvas():
    return Image.new("RGBA", (W * K, H * K), (0, 0, 0, 0))


def fin(im, name, out):
    im.resize((W, H), Image.LANCZOS).save(f"{out}/{name}.png")


def blur(im, r):
    return im.filter(ImageFilter.GaussianBlur(r * K))


def cloud(d, cx, cy, w, h, col):
    for dx, dy, rw, rh in [(-0.28, 0.05, 0.42, 0.7), (0.0, -0.12, 0.5, 0.9), (0.28, 0.04, 0.42, 0.7), (0.1, 0.12, 0.6, 0.6), (-0.12, 0.14, 0.55, 0.6)]:
        d.ellipse((cx + (dx - rw / 2) * w, cy + (dy - rh / 2) * h, cx + (dx + rw / 2) * w, cy + (dy + rh / 2) * h), fill=col)


def streaks(d, n, col, ln, wd, ang, rng, y0=0, y1=H):
    dx, dy = math.sin(math.radians(ang)), math.cos(math.radians(ang))
    for _ in range(n):
        x = rng.uniform(0, W)
        y = rng.uniform(y0, y1)
        l = ln * rng.uniform(0.6, 1.2)
        d.line((x * K, y * K, (x + dx * l) * K, (y + dy * l) * K), fill=col, width=int(wd * K))


def dot(d, x, y, r, col):
    d.ellipse(((x - r) * K, (y - r) * K, (x + r) * K, (y + r) * K), fill=col)


def blizzard(out):
    rng = random.Random(1)
    im = canvas()
    haze = canvas()
    hd = ImageDraw.Draw(haze)
    for i in range(7):
        cloud(hd, rng.uniform(0, W) * K, rng.uniform(0.05, 0.95) * H * K, rng.uniform(380, 560) * K, rng.uniform(160, 240) * K, (235, 244, 252, 70))
    im.alpha_composite(blur(haze, 22))
    d = ImageDraw.Draw(im)
    streaks(d, 90, (255, 255, 255, 120), 70, 3, 28, rng)
    for _ in range(260):
        dot(d, rng.uniform(0, W), rng.uniform(0, H), rng.uniform(2, 8), (255, 255, 255, rng.randint(150, 235)))
    fin(im, "blizzard", out)


def storm(out):
    rng = random.Random(2)
    im = canvas()
    cl = canvas()
    cd = ImageDraw.Draw(cl)
    for i in range(6):
        cloud(cd, (i + 0.5) * W / 6 * K, rng.uniform(40, 170) * K, rng.uniform(300, 420) * K, rng.uniform(200, 260) * K, (70, 80, 110, 175))
    for i in range(5):
        cloud(cd, rng.uniform(0, W) * K, rng.uniform(60, 260) * K, rng.uniform(240, 340) * K, rng.uniform(140, 200) * K, (96, 104, 134, 150))
    im.alpha_composite(blur(cl, 6))
    d = ImageDraw.Draw(im)
    streaks(d, 150, (205, 225, 250, 135), 55, 3, 16, rng, y0=120)
    bx, by = W * 0.62, 170
    pts = [(bx, by), (bx - 40, by + 130), (bx - 4, by + 130), (bx - 62, by + 290), (bx + 30, by + 120), (bx - 6, by + 118), (bx + 34, by)]
    gl = canvas()
    gd = ImageDraw.Draw(gl)
    gd.polygon([(x * K, y * K) for x, y in pts], fill=(255, 240, 150, 200))
    im.alpha_composite(blur(gl, 10))
    d.polygon([(x * K, y * K) for x, y in pts], fill=(255, 248, 190, 235))
    fin(im, "storm", out)


def spiral(d, cx, cy, r0, r1, turns, arms, col, wd):
    for a in range(arms):
        pts = []
        for i in range(0, 181):
            t = i / 180
            ang = a * 2 * math.pi / arms + t * turns * 2 * math.pi
            r = r0 + (r1 - r0) * t
            pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
        for i in range(len(pts) - 1):
            w = wd * (0.35 + 0.65 * (i / 180))
            d.line((pts[i][0] * K, pts[i][1] * K, pts[i + 1][0] * K, pts[i + 1][1] * K), fill=col, width=int(w * K))


def hurricane(out):
    rng = random.Random(3)
    im = canvas()
    cx, cy = W / 2, H * 0.42
    sp = canvas()
    sd = ImageDraw.Draw(sp)
    for arm in range(4):
        for i in range(0, 120):
            t = i / 119
            ang = arm * math.pi / 2 + t * 1.25 * 2 * math.pi
            r = 70 + 500 * t
            x = cx + r * math.cos(ang)
            y = cy + r * math.sin(ang)
            rad = 30 + 52 * t
            sd.ellipse(((x - rad) * K, (y - rad * 0.8) * K, (x + rad) * K, (y + rad * 0.8) * K), fill=(238, 243, 252, 120))
    sh = blur(sp, 4)
    im.alpha_composite(sh)
    sp2 = canvas()
    sd2 = ImageDraw.Draw(sp2)
    for arm in range(4):
        for i in range(0, 120):
            t = i / 119
            ang = arm * math.pi / 2 + t * 1.25 * 2 * math.pi + 0.07
            r = 70 + 500 * t
            x = cx + r * math.cos(ang)
            y = cy + r * math.sin(ang) + 8
            rad = 16 + 30 * t
            sd2.ellipse(((x - rad) * K, (y - rad * 0.8) * K, (x + rad) * K, (y + rad * 0.8) * K), fill=(120, 140, 184, 95))
    im.alpha_composite(blur(sp2, 3))
    eye = canvas()
    ed = ImageDraw.Draw(eye)
    ed.ellipse(((cx - 52) * K, (cy - 52) * K, (cx + 52) * K, (cy + 52) * K), fill=(255, 255, 255, 150))
    im.alpha_composite(blur(eye, 3))
    d = ImageDraw.Draw(im)
    streaks(d, 130, (200, 220, 245, 120), 60, 3, 24, rng)
    fin(im, "hurricane", out)


def tornado(out):
    rng = random.Random(4)
    im = canvas()
    d = ImageDraw.Draw(im)
    cx = W * 0.5
    for i in range(30):
        t = i / 29
        y = H * (0.14 + 0.62 * t)
        w = 330 * (1 - t) ** 1.1 + 34
        h = 70 - t * 20
        sh = int(150 + 55 * t)
        col = (sh, int(sh * 0.92), int(sh * 0.82), 170)
        off = math.sin(t * 5.2) * 60
        d.ellipse(((cx + off - w / 2) * K, (y - h / 2) * K, (cx + off + w / 2) * K, (y + h / 2) * K), fill=col, outline=(120, 104, 90, 120), width=2 * K)
    sw = canvas()
    sd = ImageDraw.Draw(sw)
    for i in range(14):
        t = i / 13
        y = H * (0.17 + 0.58 * t)
        w = 300 * (1 - t) ** 1.1 + 20
        off = math.sin(t * 5.2) * 60
        sd.arc(((cx + off - w / 2) * K, (y - 18) * K, (cx + off + w / 2) * K, (y + 18) * K), 200, 340, fill=(255, 250, 235, 170), width=5 * K)
    im.alpha_composite(sw)
    d = ImageDraw.Draw(im)
    for _ in range(46):
        a = rng.uniform(0, 2 * math.pi)
        r = rng.uniform(40, 300)
        x = cx + r * math.cos(a)
        y = H * rng.uniform(0.2, 0.8) + 30 * math.sin(a)
        d.ellipse((x * K, y * K, (x + rng.uniform(6, 14)) * K, (y + rng.uniform(4, 9)) * K), fill=(168, 128, 84, 200))
    cl = canvas()
    cd = ImageDraw.Draw(cl)
    for i in range(4):
        cloud(cd, (i + 0.5) * W / 4 * K, 40 * K, 380 * K, 200 * K, (110, 104, 120, 160))
    im.alpha_composite(blur(cl, 6))
    dust = canvas()
    dd = ImageDraw.Draw(dust)
    for i in range(6):
        cloud(dd, rng.uniform(150, 620) * K, H * 0.78 * K, rng.uniform(200, 320) * K, 90 * K, (196, 164, 120, 120))
    im.alpha_composite(blur(dust, 8))
    fin(im, "tornado", out)


def heatwave(out):
    rng = random.Random(5)
    im = canvas()
    glow = Image.new("L", (W * K, H * K), 0)
    gd = ImageDraw.Draw(glow)
    gd.ellipse(((W * 0.7 - 420) * K, (-260) * K, (W * 0.7 + 420) * K, 520 * K), fill=210)
    glow = blur(glow, 60)
    og = Image.new("RGBA", (W * K, H * K), (255, 176, 88, 0))
    og.putalpha(glow.point(lambda v: int(v * 0.55)))
    im.alpha_composite(og)
    d = ImageDraw.Draw(im)
    d.ellipse(((W * 0.72 - 118) * K, (150 - 118) * K, (W * 0.72 + 118) * K, (150 + 118) * K), fill=(255, 214, 120, 255))
    for r, a in [(150, 90), (185, 50)]:
        d.ellipse(((W * 0.72 - r) * K, (150 - r) * K, (W * 0.72 + r) * K, (150 + r) * K), outline=(255, 226, 150, a), width=5 * K)
    sh = canvas()
    sd = ImageDraw.Draw(sh)
    for row in range(26):
        y = H * (0.12 + row * 0.033)
        amp = 7 + row * 0.4
        ph = rng.uniform(0, 6)
        pts = [(x * K, (y + amp * math.sin(x / 70 + ph + row)) * K) for x in range(0, W + 8, 8)]
        sd.line(pts, fill=(255, 243, 214, rng.randint(55, 95)), width=int(5 * K))
    im.alpha_composite(blur(sh, 1.2))
    ed = Image.new("L", (W * K, H * K), 0)
    e = ImageDraw.Draw(ed)
    e.rounded_rectangle((-60 * K, -60 * K, (W + 60) * K, (H + 60) * K), radius=380 * K, outline=255, width=120 * K)
    ed = blur(ed, 50)
    vg = Image.new("RGBA", (W * K, H * K), (255, 150, 60, 0))
    vg.putalpha(ed.point(lambda v: int(v * 0.35)))
    im.alpha_composite(vg)
    fin(im, "heatwave", out)


def wildfire(out):
    rng = random.Random(6)
    im = canvas()
    gl = Image.new("L", (W * K, H * K), 0)
    gd = ImageDraw.Draw(gl)
    gd.rectangle((0, int(H * 0.75) * K, W * K, H * K), fill=235)
    gl = blur(gl, 90)
    o = Image.new("RGBA", (W * K, H * K), (255, 128, 48, 0))
    o.putalpha(gl.point(lambda v: int(v * 0.6)))
    im.alpha_composite(o)
    sm = canvas()
    sd = ImageDraw.Draw(sm)
    for i in range(9):
        cloud(sd, rng.uniform(0, W) * K, rng.uniform(0.05, 0.55) * H * K, rng.uniform(260, 420) * K, rng.uniform(150, 230) * K, (96, 88, 92, rng.randint(80, 120)))
    im.alpha_composite(blur(sm, 16))
    for _ in range(170):
        x = rng.uniform(0, W)
        y = rng.uniform(0.1, 1.0) * H
        r = rng.uniform(2.5, 7)
        t = y / H
        col = (255, int(150 + 80 * (1 - t)), int(50 + 60 * (1 - t)), rng.randint(170, 255))
        gg = canvas()
        gdd = ImageDraw.Draw(gg)
        gdd.ellipse(((x - r * 2) * K, (y - r * 2) * K, (x + r * 2) * K, (y + r * 2) * K), fill=(255, 170, 60, 70))
        im.alpha_composite(blur(gg, 2))
        dot(ImageDraw.Draw(im), x, y, r, col)
    fin(im, "wildfire", out)


def flood(out):
    rng = random.Random(7)
    im = canvas()
    top = H * 0.58
    fl = Image.new("RGBA", (W * K, H * K), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fl)
    pts = [(x * K, (top + 14 * math.sin(x / 45)) * K) for x in range(0, W + 6, 6)] + [(W * K, H * K), (0, H * K)]
    fd.polygon(pts, fill=(96, 170, 226, 120))
    g = Image.new("L", (W * K, H * K), 0)
    gd = ImageDraw.Draw(g)
    for y in range(int(top * K), H * K, 4):
        gd.line((0, y, W * K, y), fill=int(40 + 130 * (y / K - top) / (H - top)))
    deep = Image.new("RGBA", (W * K, H * K), (40, 108, 190, 0))
    deep.putalpha(ImageChops.multiply(g, fl.getchannel("A")))
    fl.alpha_composite(deep)
    im.alpha_composite(fl)
    d = ImageDraw.Draw(im)
    d.line([(x * K, (top + 14 * math.sin(x / 45)) * K) for x in range(0, W + 6, 6)], fill=(240, 250, 255, 220), width=7 * K)
    for _ in range(46):
        x = rng.uniform(40, W - 40)
        y = rng.uniform(top + 40, H - 30)
        rw = rng.uniform(40, 110)
        rh = rw * 0.26
        d.ellipse(((x - rw / 2) * K, (y - rh / 2) * K, (x + rw / 2) * K, (y + rh / 2) * K), outline=(236, 248, 255, 170), width=3 * K)
    fin(im, "flood", out)


def earthquake(out):
    rng = random.Random(8)
    im = canvas()
    d = ImageDraw.Draw(im)

    def crack(x, y, ang, length, wd, depth=0):
        pts = [(x, y)]
        base = ang
        for i in range(int(length / 26)):
            ang += rng.choice([-1, 1]) * rng.uniform(0.25, 0.75)
            ang = ang * 0.85 + 0.15 * base
            x += 26 * math.cos(ang)
            y += 26 * math.sin(ang)
            pts.append((x, y))
        for i in range(len(pts) - 1):
            w = wd * (1 - 0.55 * i / len(pts))
            seg = (pts[i][0] * K, pts[i][1] * K, pts[i + 1][0] * K, pts[i + 1][1] * K)
            d.line(seg, fill=(236, 218, 186, 190), width=max(3, int((w + 6) * K)))
            d.line(seg, fill=(58, 42, 34, 240), width=max(2, int(w * K)))
        if depth < 1:
            for j in range(3, len(pts) - 2, 4):
                if rng.random() < 0.5:
                    crack(pts[j][0], pts[j][1], ang + rng.choice([-1, 1]) * rng.uniform(0.7, 1.1), length * 0.4, wd * 0.6, depth + 1)

    starts = [(W * 0.2, 0, math.pi / 2), (W * 0.8, 0, math.pi / 2), (0, H * 0.5, 0.15), (W, H * 0.66, math.pi - 0.15), (W * 0.3, H, -math.pi / 2), (W * 0.74, H, -math.pi / 2)]
    for sx, sy, ang in starts:
        crack(sx, sy, ang, rng.uniform(380, 560), 13)
    dust = canvas()
    dd = ImageDraw.Draw(dust)
    for i in range(9):
        cloud(dd, rng.uniform(40, W - 40) * K, rng.uniform(0.45, 0.95) * H * K, rng.uniform(200, 320) * K, rng.uniform(80, 130) * K, (212, 184, 140, rng.randint(90, 140)))
    im.alpha_composite(blur(dust, 10))
    d = ImageDraw.Draw(im)
    for _ in range(80):
        dot(d, rng.uniform(0, W), rng.uniform(0.2, 1) * H, rng.uniform(2, 6), (176, 140, 100, 190))
    fin(im, "earthquake", out)


if __name__ == "__main__":
    out = sys.argv[1]
    for f in (blizzard, storm, hurricane, tornado, heatwave, wildfire, flood, earthquake):
        f(out)
    print("ok")
