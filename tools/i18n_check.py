#!/usr/bin/env python3
"""画面の文言（i18n/battle.<言語>.json）の検査と、翻訳の取り込み。

使い方:
  python3 tools/i18n_check.py check                 全言語を検査（キーの過不足・{}の食い違い）
  python3 tools/i18n_check.py missing <lang>        <lang> に足りない文言を、翻訳用のJSONで出す（英語のまま）
  python3 tools/i18n_check.py merge <lang> <file>   翻訳したJSONを検査して i18n/battle.<lang>.json に取り込む

Google翻訳などで訳したあとの `{name}` の崩れ（全角化・空白・訳されてしまう）を検出する。
"""
import json
import re
import sys
from pathlib import Path

DIR = Path(__file__).resolve().parent.parent / "i18n"
PH = re.compile(r"\{(\w+)\}")
# 全角・空白の入った崩れ方も拾う（{ name }・｛name｝など）
BROKEN = re.compile(r"[｛｝]|\{\s+\w+|\w+\s+\}")


def load(lang):
    p = DIR / f"battle.{lang}.json"
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else None


def langs():
    return sorted(p.name.split(".")[1] for p in DIR.glob("battle.*.json"))


def problems(lang, base, table):
    """エラーだけ返す（足りないキーは英語で埋まるので警告扱い。cmd_check が数を出す）。"""
    out = []
    for k in table:
        if k not in base:
            out.append(f"{lang}: 余分 {k}")
    for k, v in table.items():
        if k not in base:
            continue
        if not isinstance(v, str) or not v.strip():
            out.append(f"{lang}: 空 {k}")
            continue
        if set(PH.findall(v)) != set(PH.findall(base[k])):
            out.append(f"{lang}: {{}}が英語と違う {k}: {v!r}（英語: {base[k]!r}）")
        elif BROKEN.search(v):
            out.append(f"{lang}: {{}}が崩れている {k}: {v!r}")
    return out


def cmd_check():
    base = load("en")
    if base is None:
        print("i18n/battle.en.json がありません")
        return 1
    errs = []
    for l in langs():
        if l == "en":
            continue
        t = load(l)
        errs += problems(l, base, t)
        miss = [k for k in base if k not in t]
        print(f"{l}: {len(t)}/{len(base)} 件を翻訳済み" + (f"（残り{len(miss)}件は英語で表示）" if miss else "（完了）"))
    for e in errs:
        print(e)
    print(f"{len(langs())}言語を検査: {'問題なし' if not errs else str(len(errs)) + '件の問題'}")
    return 1 if errs else 0


def cmd_missing(lang):
    base = load("en")
    own = load(lang) or {}
    todo = {k: v for k, v in base.items() if k not in own}
    print(json.dumps(todo, ensure_ascii=False, indent=2))
    return 0


def cmd_merge(lang, file):
    base = load("en")
    new = json.loads(Path(file).read_text(encoding="utf-8"))
    own = load(lang) or {}
    errs = problems(lang, {k: base[k] for k in new if k in base}, {k: v for k, v in new.items() if k in base})
    errs += [f"{lang}: 英語にないキー {k}" for k in new if k not in base]
    if errs:
        for e in errs:
            print(e)
        print("取り込みを中止しました（上の問題を直してください）")
        return 1
    own.update(new)
    ordered = {k: own[k] for k in base if k in own}
    (DIR / f"battle.{lang}.json").write_text(json.dumps(ordered, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    left = [k for k in base if k not in ordered]
    print(f"battle.{lang}.json に {len(new)} 件を取り込みました（残り {len(left)} 件が未翻訳）")
    return 0


if __name__ == "__main__":
    a = sys.argv[1:]
    if a[:1] == ["check"]:
        sys.exit(cmd_check())
    if len(a) == 2 and a[0] == "missing":
        sys.exit(cmd_missing(a[1]))
    if len(a) == 3 and a[0] == "merge":
        sys.exit(cmd_merge(a[1], a[2]))
    print(__doc__)
    sys.exit(2)
