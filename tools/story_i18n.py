#!/usr/bin/env python3
"""物語（packs/<国>/story.json）の訳を取り込む。

使い方:
  python3 tools/story_i18n.py list <pack>                 英語の文を、取り込む順に出す（番号付き）
  python3 tools/story_i18n.py merge <pack> <lang> <file>  <file>（文字列の配列。list と同じ順・同じ数）を story.json に入れる
  python3 tools/story_i18n.py apply                       tools/story_i18n/<pack>.<lang>.json を全部取り込む

順番: 章ごとに、題名 → intro → beforeBoss → outro。{} のような記号は使わない短い文だけ。
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "tools" / "story_i18n"


def slots(story):
    """(text の dict, 説明) を取り込む順に返す。"""
    out = []
    for ch in story["chapters"]:
        out.append((ch["title"], f"{ch['id']}.title"))
        for k in ("intro", "beforeBoss", "outro"):
            for i, line in enumerate(ch[k]):
                out.append((line["text"], f"{ch['id']}.{k}.{i}"))
    return out


def load(pack):
    return json.loads((ROOT / "packs" / pack / "story.json").read_text(encoding="utf-8"))


def save(pack, story):
    (ROOT / "packs" / pack / "story.json").write_text(json.dumps(story, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def merge(pack, lang, texts):
    story = load(pack)
    sl = slots(story)
    if len(texts) != len(sl):
        sys.exit(f"{pack}/{lang}: 数が違う（訳 {len(texts)} 件 / 文 {len(sl)} 件）")
    for (d, name), t in zip(sl, texts):
        if not isinstance(t, str) or not t.strip():
            sys.exit(f"{pack}/{lang}: 空の訳 {name}")
        d[lang] = t
    save(pack, story)


def main():
    a = sys.argv[1:]
    if a[:1] == ["list"]:
        for i, (d, name) in enumerate(slots(load(a[1]))):
            print(f"{i:2d} {name}: {d['en']}")
    elif a[:1] == ["merge"]:
        merge(a[1], a[2], json.loads(Path(a[3]).read_text(encoding="utf-8")))
    elif a[:1] == ["apply"]:
        for f in sorted(SRC.glob("*.json")):
            pack, lang, _ = f.name.split(".")
            merge(pack, lang, json.loads(f.read_text(encoding="utf-8")))
            print("取り込み", f.name)
    else:
        sys.exit(__doc__)


main()
