#!/usr/bin/env python3
"""Natural Earth 10m admin-1 (パブリックドメイン) → region_core pack(de)。
使い方: convert_de.py <ne_10m_admin_1_states_provinces.geojson> <out packs/de>"""
import json, sys, pathlib, math
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
(out/'regions.json').write_text(json.dumps({"regions": [{"id": i, "capitalId": "cap_" + i} for i in ids]}, ensure_ascii=False, indent=1))
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
