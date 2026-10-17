#!/usr/bin/env python3
"""Natural Earth 10m admin-1 (パブリックドメイン) → region_core pack(de)。
使い方: convert_de.py <ne_10m_admin_1_states_provinces.geojson> <out packs/de>"""
import json, sys, pathlib, math
sys.path.insert(0, str(pathlib.Path(__file__).parent))
import pack_extras
src, out = sys.argv[1], pathlib.Path(sys.argv[2])
TOL = 0.01  # 度。Douglas-Peucker

def dp(pts, tol):
    if len(pts) < 3: return pts
    (x1, y1), (x2, y2) = pts[0], pts[-1]
    dx, dy = x2 - x1, y2 - y1; L = math.hypot(dx, dy)
    best, bi = -1, 0
    for i in range(1, len(pts) - 1):
        x, y = pts[i]
        d = math.hypot(x - x1, y - y1) if L == 0 else abs(dy * x - dx * y + x2 * y1 - y2 * x1) / L
        if d > best: best, bi = d, i
    if best <= tol: return [pts[0], pts[-1]]
    return dp(pts[:bi + 1], tol)[:-1] + dp(pts[bi:], tol)

def ring(r):
    r = [[round(x, 4), round(y, 4)] for x, y in r[:-1]]
    s = dp(r + [r[0]], TOL)
    return s if len(s) >= 4 else r + [r[0]]

# 州都の位置(緯度, 経度)。市の中心の位置(一般に知られた公共の事実)。
CAP_LL = {
 'DE-BW': (48.7758, 9.1829), 'DE-BY': (48.1351, 11.5820), 'DE-BE': (52.5200, 13.4050), 'DE-BB': (52.3906, 13.0645),
 'DE-HB': (53.0793, 8.8017), 'DE-HH': (53.5511, 9.9937), 'DE-HE': (50.0782, 8.2398), 'DE-MV': (53.6355, 11.4012),
 'DE-NI': (52.3759, 9.7320), 'DE-NW': (51.2277, 6.7735), 'DE-RP': (49.9929, 8.2473), 'DE-SL': (49.2402, 6.9969),
 'DE-SN': (51.0504, 13.7373), 'DE-ST': (52.1205, 11.6276), 'DE-SH': (54.3233, 10.1228), 'DE-TH': (50.9848, 11.0299),
}
# id: (en, de, capital_en, capital_de)
M = {
 'DE-BW': ('Baden-Württemberg', 'Baden-Württemberg', 'Stuttgart', 'Stuttgart'),
 'DE-BY': ('Bavaria', 'Bayern', 'Munich', 'München'),
 'DE-BE': ('Berlin', 'Berlin', 'Berlin', 'Berlin'),
 'DE-BB': ('Brandenburg', 'Brandenburg', 'Potsdam', 'Potsdam'),
 'DE-HB': ('Bremen', 'Bremen', 'Bremen', 'Bremen'),
 'DE-HH': ('Hamburg', 'Hamburg', 'Hamburg', 'Hamburg'),
 'DE-HE': ('Hesse', 'Hessen', 'Wiesbaden', 'Wiesbaden'),
 'DE-MV': ('Mecklenburg-Western Pomerania', 'Mecklenburg-Vorpommern', 'Schwerin', 'Schwerin'),
 'DE-NI': ('Lower Saxony', 'Niedersachsen', 'Hanover', 'Hannover'),
 'DE-NW': ('North Rhine-Westphalia', 'Nordrhein-Westfalen', 'Düsseldorf', 'Düsseldorf'),
 'DE-RP': ('Rhineland-Palatinate', 'Rheinland-Pfalz', 'Mainz', 'Mainz'),
 'DE-SL': ('Saarland', 'Saarland', 'Saarbrücken', 'Saarbrücken'),
 'DE-SN': ('Saxony', 'Sachsen', 'Dresden', 'Dresden'),
 'DE-ST': ('Saxony-Anhalt', 'Sachsen-Anhalt', 'Magdeburg', 'Magdeburg'),
 'DE-SH': ('Schleswig-Holstein', 'Schleswig-Holstein', 'Kiel', 'Kiel'),
 'DE-TH': ('Thuringia', 'Thüringen', 'Erfurt', 'Erfurt'),
}
g = json.load(open(src))
feats = []
for f in g['features']:
    p = f['properties']
    if p.get('iso_a2') != 'DE': continue
    rid = p['iso_3166_2']; assert rid in M, rid
    t, c = f['geometry']['type'], f['geometry']['coordinates']
    polys = c if t == 'MultiPolygon' else [c]
    feats.append({"type": "Feature", "properties": {"id": rid},
      "geometry": {"type": "MultiPolygon", "coordinates": [[ring(poly[0])] for poly in polys]}})
assert len(feats) == 16
feats.sort(key=lambda f: f['properties']['id'])
(out/'geo.geojson').write_text(json.dumps({"type": "FeatureCollection", "features": feats}, ensure_ascii=False, separators=(',', ':')))
ids = [f['properties']['id'] for f in feats]
polys = {f['properties']['id']: f['geometry']['coordinates'] for f in feats}
NB = pack_extras.neighbors(polys, tol=0.03, min_len=0.04)
regs = []
for i in ids:
    lat, lng = CAP_LL[i]
    x, y, moved = pack_extras.snap_inside(lng, lat, polys[i])
    if moved: print("州都の位置を形の内側へ寄せた:", i)
    regs.append({"id": i, "capitalId": "cap_" + i, "capitalPos": {"x": round(x, 4), "y": round(y, 4)}, "neighbors": NB[i]})
(out/'regions.json').write_text(json.dumps({"regions": regs}, ensure_ascii=False, indent=1))
for k, lang in ((0, 'en'), (1, 'de')):
    (out/f'strings/{lang}.json').write_text(json.dumps({
      "regions": {i: M[i][k] for i in ids}, "capitals": {"cap_" + i: M[i][2 + k] for i in ids}}, ensure_ascii=False, indent=1))
(out/'pack.json').write_text(json.dumps({
 "packId": "de", "version": "0.1.0", "country": "DE", "regionKind": "state",
 "languages": ["en", "de"], "defaultLanguage": "en",
 "projection": {"type": "equirect_cos", "refLat": 51.0}, "insets": [],
 "attribution": "Made with Natural Earth (naturalearthdata.com)",
 "license": {"name": "Public Domain (Natural Earth)", "commercialConfirmed": True, "internalOnly": False}
}, ensure_ascii=False, indent=1))
print("ok", sum(len(r[0]) for f in feats for r in f['geometry']['coordinates']), "vertices")
