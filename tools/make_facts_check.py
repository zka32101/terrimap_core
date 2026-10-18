"""facts.json の名所から、出典の確認リストを作る。
usage: python3 tools/make_facts_check.py > docs/quiz_facts_check.md"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
out = ["# 名所クイズ 出典の確認リスト", "",
       "`tools/make_facts_check.py` が `packs/<国>/facts.json` から作る。**判定は作成者の記憶にもとづく（出典での確認はまだ）**。",
       "「この名所はどの州にある？」の問題に使う。州の誤りは、そのまま誤った知識を教えてしまうので、公開前に確認する。", "",
       "## 確認の手順", "",
       "1. 各名所の「所在の州」を、公式ページ（施設・自治体・国立公園局・ユネスコなど）で確かめる。州をまたぐものは、問題に向かないので `use` を false にする。",
       "2. 合っていれば `check` を `checked` にし、`source` に実際に見た出典（URLでなく名称でよい）を書く。誤りなら直す。",
       "3. `python3 tools/validate_pack.py packs/<国>` を通す。アプリ側の `packs/<国>/facts.json` も同期する。",
       "4. 表現: 名所の名前は、各言語の通称で。固有名詞なので機械翻訳に頼らない。", "",
       "## 注意（題材の決まり）", "",
       "- 戦争・差別・特定の歴史的事件を連想させる場所は入れない（戦跡、論争のある記念碑など）。",
       "- 実在の人物の顔・肖像は使わない。人名のついた名所は、名所の名前として扱う。",
       "- 州をまたぐ名所（イエローストーン、ナイアガラの滝の全体など）は、答えが一つに決まらないので使わない。", ""]
for cc, label in (("de", "ドイツ"), ("us", "米国")):
    f = json.loads((ROOT / f"packs/{cc}/facts.json").read_text(encoding="utf-8"))
    lm = f["landmarks"]
    out += [f"## {label}（{len(lm)}件、確認済み {sum(1 for l in lm if l.get('check') == 'checked')}件）", "",
            "| id | 名前(en) | 所在の州 | 確認 | 出典 | 確認日 | 直した点 |", "|---|---|---|---|---|---|---|"]
    for l in lm:
        out.append(f"| `{l['id']}` | {l['name']['en']} | {l['region']} | {l.get('check', 'unchecked')} | {l.get('source', '')} | | |")
    out.append("")
print("\n".join(out))
