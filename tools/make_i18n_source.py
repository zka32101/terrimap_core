"""翻訳の元になる文言を、種類ごとにまとめた一覧を作る（Google翻訳に出す前の全体像）。
usage: python3 tools/make_i18n_source.py [アプリのリポジトリのパス ...] > i18n/SOURCE_SUMMARY.md
アプリのパスを渡すと、そのアプリの lib/strings.dart の英語の文言（キー数・一覧）も入れる。"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LANGS = ["en", "de", "fr", "es", "it", "pt", "nl", "tr", "ja", "ko", "zh"]


def load(p):
    return json.loads((ROOT / p).read_text(encoding="utf-8"))


def app_strings(path):
    src = (Path(path) / "lib/strings.dart").read_text(encoding="utf-8")
    blocks = re.findall(r"^    '(\w+)': \{(.*?)^    \},", src, re.S | re.M)
    out = {}
    for lang, body in blocks:
        out[lang] = dict(re.findall(r"^\s+'(\w+)': '((?:[^'\\]|\\.)*)',", body, re.M))
    return out


def main():
    battle = load("i18n/battle.en.json")
    words = sum(len(v.split()) for v in battle.values())
    out = ["# 翻訳元情報まとめ", "",
           "`tools/make_i18n_source.py` が作る（元の文言を変えたら作り直す）。**原本は英語**。対象は11言語: " + "・".join(LANGS) + "。", "",
           "## 1. 全体像", "",
           "| # | 種類 | 場所 | 件数 | 今ある言語 | 訳す手順 |", "|---|---|---|---|---|---|",
           f"| A | バトル画面の文言 | `i18n/battle.en.json` | {len(battle)}件（約{words}語） | en | `tools/i18n_check.py missing/merge/check`（`i18n/README.md`） |"]
    rows = []
    for cc in ("de", "us"):
        pack = load(f"packs/{cc}/pack.json")
        pf = load(f"packs/{cc}/profile.json")
        n_reg = len(load(f"packs/{cc}/strings/en.json")["regions"])
        n_cap = len(load(f"packs/{cc}/strings/en.json")["capitals"])
        rows.append((cc, pack.get("languages", []), n_reg, n_cap, pf))
        out.append(f"| B-{cc.upper()} | 地域名・州都名 | `packs/{cc}/strings/<言語>.json` | 地域{n_reg}＋州都{n_cap} | {'・'.join(pack.get('languages', []))} | 固有名詞。各言語の通称で（機械翻訳は避け、Wikipedia の言語版などで確認） |")
    for cc, _, _, _, pf in rows:
        ng = len(pf["groups"])
        ne = len(pf["extras"])
        out.append(f"| C-{cc.upper()} | プロファイルの文言（地方名・エクストラ・施設/敵の名前） | `packs/{cc}/profile.json` | 地方{ng}・エクストラ{ne}・施設6・敵4 | en・ja（一部 de） | 下の§4。エクストラの `fact` は**先に事実確認**（§5） |")
    apps = [a for a in sys.argv[1:] if (Path(a) / "lib/strings.dart").exists()]
    for a in apps:
        st = app_strings(a)
        out.append(f"| D-{Path(a).name} | アプリのホーム・クイズ・設定など | `{Path(a).name}/lib/strings.dart` | {len(st.get('en', {}))}件 | {'・'.join(st)} | 文言を言語ごとの map に足す（`{{}}` などの引数は残す） |")
    out += ["", "## 2. 言語ごとの状況", "", "| 言語 | A バトル | B-DE | B-US | C-DE 地方・エクストラ | C-US 地方・エクストラ |" + "".join(f" D-{Path(a).name} |" for a in apps),
            "|---|---|---|---|---|---|" + "---|" * len(apps)]
    ex = {cc: pf for cc, _, _, _, pf in rows}
    have_b = {cc: set(langs) for cc, langs, _, _, _ in rows}
    for lang in LANGS:
        a = "✅" if (ROOT / f"i18n/battle.{lang}.json").exists() else "—"
        cells = [a]
        for cc in ("de", "us"):
            cells.append("✅" if lang in have_b[cc] else "—")
        for cc in ("de", "us"):
            pf = ex[cc]
            ok = all(lang in g["name"] for g in pf["groups"].values()) and all(lang in e["title"] and lang in e["summary"] and lang in e["bossName"] for e in pf["extras"])
            cells.append("✅" if ok else "—")
        for ap in apps:
            cells.append("✅" if lang in app_strings(ap) else "—")
        out.append(f"| {lang} | " + " | ".join(cells) + " |")
    out += ["", "（✅=ある、—=まだ。`profile.json` には ja/de があるが、en 以外は一部）", "",
            "## 3. A バトル画面の文言（原本の英語）", "",
            "Google翻訳に出す形は `python3 tools/i18n_check.py missing <言語>`。`{n}` `{name}` などの `{…}` は訳さず残す。", ""]
    groups = {}
    for k, v in battle.items():
        groups.setdefault(k.split(".")[0], []).append((k, v))
    out += ["| グループ | 件数 | 例 |", "|---|---|---|"]
    for g, items in groups.items():
        out.append(f"| `{g}.*` | {len(items)} | {items[0][1]} |")
    out += ["", "## 4. C プロファイルの文言（原本の英語）", ""]
    for cc, _, _, _, pf in rows:
        out += [f"### {cc.upper()}", "", "**地方名**: " + " / ".join(f"`{k}`={g['name']['en']}" for k, g in pf["groups"].items()), "",
                "**施設の名前**: " + " / ".join(f"`{v['skin']}`={v['name']['en']}" for v in pf["facilities"].values()), "",
                "**敵の名前**: " + " / ".join(f"`{v['skin']}`={v['name']['en']}" for v in pf["enemySkins"].values()), "",
                "**国のひとこと説明**: " + pf["summary"]["en"], "", "**エクストラ**", "",
                "| id | 種類 | タイトル | ボス | あらすじ | 事実の注記(fact) |", "|---|---|---|---|---|---|"]
        for e in pf["extras"]:
            out.append(f"| `{e['id']}` | {e['basis']} | {e['title']['en']} | {e['bossName']['en']} | {e['summary']['en']} | {e['fact']['en']} |")
        out.append("")
    out += ["## 5. 訳す前の注意", "",
            "- **エクストラの `fact`（事実の注記）は、公開前に事実を確認してから**訳す（今は仮）。伝承と事実の区別を崩さない。",
            "- 戦争・差別・特定の歴史を連想させる言い回し、国旗・紋章、実在の人物の顔は使わない。",
            "- 短い名前（施設・敵・ボス）は、機械翻訳のあと実機で見て直す。",
            "- 地域名・州都名は固有名詞。各言語の通称にそろえる（`packs/<国>/pack.json` の `languages` に言語を足して `python3 tools/validate_pack.py packs/<国>` で検査）。",
            "- 米国版（US）の優先は es、ドイツ版（DE）の優先は de・fr・en。", ""]
    if apps:
        out += ["## 6. D アプリの文言（原本の英語）", ""]
        for a in apps:
            st = app_strings(a).get("en", {})
            out += [f"### {Path(a).name}（{len(st)}件）", "", "| キー | 英語 |", "|---|---|"] + [f"| `{k}` | {v} |" for k, v in st.items()] + [""]
    print("\n".join(out))


main()
