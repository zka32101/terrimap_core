"""必要な画像の一覧(表)と、置かれた画像の検査。
usage:
  python3 tools/art_manifest.py > docs/art_manifest.md     # 一覧（状態は ART_DIR を見て付く）
  python3 tools/art_manifest.py --check [--dir art]        # 画像のサイズ・透過を検査（NG があれば終了コード1）
  python3 tools/art_manifest.py --prototype                # 試作13枚だけ

置き場所: <dir>/<国>/{backdrops,facilities,exclusive,enemies,bosses,landmarks}/<id>.png と <dir>/common/weather/<id>.png
  backdrops=背景id / facilities=施設のskin / exclusive=限定施設id / enemies=敵のskin / bosses=エクストラid / landmarks=名所id（facts.json）
"""
import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WEATHER = ["hurricane", "tornado", "blizzard", "heatwave", "wildfire", "flood", "earthquake", "storm"]
# 試作（ドイツのみ）
PROTO = {("de", "backdrops", "alps"), ("de", "backdrops", "city")}
PROTO |= {("de", "facilities", s) for s in ["farm_windmill", "harbor_cutter", "automotive_plant", "coal_mine", "hilltop_castle", "chapel"]}
PROTO |= {("de", "enemies", s) for s in ["rust_sprite", "dash_gremlin", "iron_golem", "forest_sprite"]}
PROTO |= {("de", "bosses", "de_loreley")}

# 種類 -> (説明, 期待する形)。bg=縦長9:16(俯瞰)・不透明、sprite=正方形・背景透過、overlay=16:9・透過
KIND = {"backdrops": ("背景", "bg"), "facilities": ("施設", "sprite"), "exclusive": ("限定施設", "sprite"),
        "enemies": ("敵", "sprite"), "bosses": ("ボス", "sprite"), "landmarks": ("名所カード", "sprite"), "weather": ("天候", "overlay")}
GEN = {"bg": "768x1344", "sprite": "1024x1024", "overlay": "1344x768"}  # Leonardo の生成サイズ
FINAL = {"bg": "768x1344", "sprite": "512x512", "overlay": "1344x768"}  # アプリに入れるサイズ


def entries():
    """(国, 種類, id, 備考) の一覧。"""
    out = []
    for cc in ["de", "us"]:
        pf = json.loads((ROOT / "packs" / cc / "profile.json").read_text())
        for k, v in pf["theme"]["backdrops"].items():
            out.append((cc, "backdrops", k, v.get("note", "")))
        for t, v in pf["facilities"].items():
            out.append((cc, "facilities", v["skin"], f"{t} / {v['name']['ja']}"))
        ex = sorted({r["exclusiveFacility"] for r in pf["regions"].values() if r.get("exclusiveFacility")})
        for e in ex:
            out.append((cc, "exclusive", e, ""))
        for t, v in pf["enemySkins"].items():
            out.append((cc, "enemies", v["skin"], f"{t} / {v['name']['ja']}"))
        for e in pf["extras"]:
            out.append((cc, "bosses", e["id"], e["bossName"]["en"]))
        facts = ROOT / "packs" / cc / "facts.json"
        if facts.exists():
            for l in json.loads(facts.read_text()).get("landmarks", []):
                if l.get("use", True):
                    out.append((cc, "landmarks", l["id"], (l.get("name") or {}).get("en", "")))
    out += [("common", "weather", w, "") for w in WEATHER]
    return out


def path_of(base, cc, kind, id_):
    return base / cc / kind / f"{id_}.png"


def inspect(p):
    """画像を検査して問題の文字列リストを返す（空なら OK）。"""
    from PIL import Image
    im = Image.open(p)
    w, h = im.size
    shape = KIND[p.parent.name][1]
    bad = []
    if im.format != "PNG":
        bad.append(f"PNGではない({im.format})")
    if shape == "bg":
        if abs(w / h - 9 / 16) > 0.05:
            bad.append(f"9:16ではない({w}x{h})")
        if w < 720:
            bad.append(f"小さい({w}x{h}、幅720以上)")
    else:
        if shape == "sprite" and w != h:
            bad.append(f"正方形ではない({w}x{h})")
        if shape == "overlay" and abs(w / h - 16 / 9) > 0.05:
            bad.append(f"16:9ではない({w}x{h})")
        if shape == "sprite" and w < 256:
            bad.append(f"小さい({w}x{h}、256以上)")
        rgba = im.convert("RGBA")
        a = rgba.getchannel("A")
        if a.getextrema()[0] == 255:
            bad.append("透過がない（背景除去が未実施？）")
        elif shape == "sprite":
            corners = [a.getpixel(c) for c in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]]
            if max(corners) > 8:
                bad.append("四隅が不透明（白背景が残っている？）")
            bbox = a.point(lambda v: 255 if v > 8 else 0).getbbox()
            if bbox and (bbox[2] - bbox[0]) < w * 0.4 and (bbox[3] - bbox[1]) < h * 0.4:
                bad.append("絵が小さい（余白が大きすぎる）")
    if shape == "bg" and im.mode == "RGBA" and im.getchannel("A").getextrema()[0] < 255:
        bad.append("背景に透過がある")
    return bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=str(ROOT / "art"))
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--prototype", action="store_true")
    a = ap.parse_args()
    base = Path(a.dir)
    rows = [e for e in entries() if not a.prototype or (e[0], e[1], e[2]) in PROTO]
    status = {}
    for cc, kind, id_, _ in rows:
        p = path_of(base, cc, kind, id_)
        if not p.exists():
            status[(cc, kind, id_)] = "未作成"
        else:
            try:
                bad = inspect(p)
            except Exception as ex:  # 壊れた画像など
                bad = [f"読めない({ex})"]
            status[(cc, kind, id_)] = "OK" if not bad else "NG: " + " / ".join(bad)
    if a.check:
        ng = {k: v for k, v in status.items() if v.startswith("NG")}
        done = sum(1 for v in status.values() if v == "OK")
        for k, v in ng.items():
            print(f"{'/'.join(k)}: {v}")
        print(f"OK {done} / NG {len(ng)} / 未作成 {sum(1 for v in status.values() if v == '未作成')} / 全{len(status)}")
        sys.exit(1 if ng else 0)
    print("# 画像一覧 v0.1\n\n`tools/art_manifest.py` が profile.json から生成。状態は `art/` の中身で決まる（`--dir` で変更）。\n")
    print("- 生成サイズは Leonardo の設定、最終サイズはアプリに入れるサイズ（施設・敵・ボスは背景除去後に 512x512 へ縮小、PNG）。")
    print("- ★ = 試作13枚（ドイツ）。\n")
    for cc in ["de", "us", "common"]:
        sub = [r for r in rows if r[0] == cc]
        if not sub:
            continue
        print(f"## {cc.upper() if cc != 'common' else '共通'}（{len(sub)}枚）\n")
        print("| 試作 | 種類 | id | 備考 | 生成 | 最終 | ファイル | 状態 |\n|---|---|---|---|---|---|---|---|")
        for _, kind, id_, note in sub:
            label, shape = KIND[kind]
            star = "★" if (cc, kind, id_) in PROTO else ""
            f = f"{cc}/{kind}/{id_}.png"
            print(f"| {star} | {label} | {id_} | {note} | {GEN[shape]} | {FINAL[shape]} | `{f}` | {status[(cc, kind, id_)]} |")
        print()


if __name__ == "__main__":
    main()
