#!/usr/bin/env python3
"""PackValidator(Python版)。使い方: validate_pack.py <packdir>。エラーがあれば終了コード1。"""
import json, sys, pathlib
p = pathlib.Path(sys.argv[1]); err = []
def load(n):
    try: return json.loads((p/n).read_text())
    except Exception as e: err.append(f"{n}: 読込失敗 {e}"); return {}
pack, reg, geo = load('pack.json'), load('regions.json'), load('geo.geojson')
for k in ("packId","version","country","regionKind","languages","projection","attribution","license"):
    if not pack.get(k): err.append(f"pack.json: {k} が空")
if not (pack.get("license") or {}).get("name"): err.append("license.name が空")
ids = [r["id"] for r in reg.get("regions", [])]
if len(ids) != len(set(ids)): err.append("regions: id重複")
gids = [f["properties"].get("id") for f in geo.get("features", [])]
if set(ids) != set(gids): err.append(f"id不一致 regionsのみ={set(ids)-set(gids)} geoのみ={set(gids)-set(ids)}")
if len(gids) != len(set(gids)): err.append("geo: id重複")
MAXV = 20000
planar = (pack.get('projection') or {}).get('type') == 'planar'
for f in geo.get("features", []):
    n = 0
    for poly in f["geometry"]["coordinates"]:
        for ring in poly:
            n += len(ring)
            if len(ring) < 4 or ring[0] != ring[-1]: err.append(f"{f['properties']['id']}: リング不正")
            for x, y in ring:
                if not planar and not (-180 <= x <= 180 and -90 <= y <= 90): err.append(f"{f['properties']['id']}: 座標範囲外"); break
    if n > MAXV: err.append(f"{f['properties']['id']}: 頂点数超過 {n}")
caps = {r.get("capitalId") for r in reg.get("regions", []) if r.get("capitalId")}
for lang in pack.get("languages", []):
    try: s = json.loads((p/f"strings/{lang}.json").read_text())
    except Exception as e: err.append(f"strings/{lang}.json: {e}"); continue
    miss = set(ids) - set(s.get("regions", {}))
    if miss: err.append(f"{lang}: 地域名の欠落 {sorted(miss)}")
    miss = caps - set(s.get("capitals", {}))
    if miss: err.append(f"{lang}: 首都名の欠落 {len(miss)}件")
# 国の特性・戦い方(任意)。Dart版(PackValidator)と同じ規則。
prof_path = p/"profile.json"
if prof_path.exists():
    try: prof = json.loads(prof_path.read_text())
    except Exception as e: prof = None; err.append(f"profile.json: 読込失敗 {e}")
    if prof is not None:
        ENEMIES = {"normal", "speedy", "armored", "healer"}
        TERRAINS = {"sea", "mountain", "urban", "agriculture", "mixed"}
        if not prof.get("style"): err.append("profile.json: style が空")
        mix = prof.get("enemyMix") or {}
        if not mix: err.append("profile.json: enemyMix が空")
        for k, v in mix.items():
            if k not in ENEMIES: err.append(f"profile.json: enemyMix の未知の敵 {k}")
            if not isinstance(v, (int, float)) or v < 0: err.append(f"profile.json: enemyMix.{k} が負または数値でない")
        if mix and abs(sum(v for v in mix.values() if isinstance(v, (int, float))) - 1) > 0.01:
            err.append("profile.json: enemyMix の合計が1でない")
        eco = prof.get("economy") or {}
        for k in ("startCoins", "income", "facilityCost"):
            v = eco.get(k)
            if not isinstance(v, (int, float)) or not (0.5 <= v <= 2.0): err.append(f"profile.json: economy.{k} は0.5〜2.0")
        if prof.get("pathLength") not in ("short", "medium", "long"): err.append("profile.json: pathLength は short/medium/long")
        if not (prof.get("signature") or {}).get("id"): err.append("profile.json: signature.id が空")
        ABIL = {"none", "shield", "regen", "swarm", "flying", "disrupt"}
        EACT = {"none", "heal_aura", "ranged_disable", "sabotage"}
        FACS = {"farm", "fishery", "factory", "mine", "castle", "shrine"}
        FACT = {"single", "splash", "chain", "pierce", "slow", "burn"}
        for kind, t in (prof.get("enemies") or {}).items():
            if kind not in ENEMIES: err.append(f"profile.json: enemies の未知の敵 {kind}")
            for k in ("hp", "speed", "baseDamage"):
                v = t.get(k)
                if v is not None and (not isinstance(v, (int, float)) or not (0.5 <= v <= 2.0)): err.append(f"profile.json: enemies.{kind}.{k} は0.5〜2.0")
            a = t.get("armor")
            if a is not None and (not isinstance(a, int) or not (0 <= a <= 3)): err.append(f"profile.json: enemies.{kind}.armor は0〜3の整数")
            if t.get("ability") is not None and t["ability"] not in ABIL: err.append(f"profile.json: enemies.{kind}.ability が不正")
            if t.get("action") is not None and t["action"] not in EACT: err.append(f"profile.json: enemies.{kind}.action が不正")
        for fac, t in (prof.get("attackActions") or {}).items():
            if fac not in FACS: err.append(f"profile.json: attackActions の未知の施設 {fac}")
            if t.get("action") not in FACT: err.append(f"profile.json: attackActions.{fac}.action が不正")
            for k in ("damage", "range", "cooldown"):
                v = t.get(k)
                if v is not None and (not isinstance(v, (int, float)) or not (0.5 <= v <= 2.0)): err.append(f"profile.json: attackActions.{fac}.{k} は0.5〜2.0")
        for rid, t in (prof.get("regions") or {}).items():
            if rid not in set(ids): err.append(f"profile.json: 未知の地域 {rid}")
            if t.get("terrain") is not None and t["terrain"] not in TERRAINS: err.append(f"profile.json: {rid} の terrain が不正")
            for k, v in (t.get("facilityBonus") or {}).items():
                if not isinstance(v, (int, float)) or not (1.0 <= v <= 2.0): err.append(f"profile.json: {rid} の facilityBonus.{k} は1.0〜2.0")
print("\n".join(err) if err else f"OK {pack.get('packId')}: {len(ids)}地域")
sys.exit(1 if err else 0)
