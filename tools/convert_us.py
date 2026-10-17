#!/usr/bin/env python3
"""Natural Earth 10m admin-1 → pack(us)。Albers投影+AK/HIのインセットを焼き込み、平面座標(planar)で出力。
使い方: convert_us.py <ne10.geojson> <out packs/us>"""
import json, sys, pathlib, math
sys.path.insert(0, str(pathlib.Path(__file__).parent))
src, out = sys.argv[1], pathlib.Path(sys.argv[2])
rad = math.radians

def albers(lon, lat, lon0, lat0, p1, p2):
    n = (math.sin(rad(p1)) + math.sin(rad(p2))) / 2
    C = math.cos(rad(p1)) ** 2 + 2 * n * math.sin(rad(p1))
    rho0 = math.sqrt(C - 2 * n * math.sin(rad(lat0))) / n
    rho = math.sqrt(C - 2 * n * math.sin(rad(lat))) / n
    th = n * rad(lon - lon0)
    return rho * math.sin(th), -(rho0 - rho * math.cos(th))   # y: 下向き正

L48 = lambda lo, la: albers(lo, la, -96, 37.5, 29.5, 45.5)
AK  = lambda lo, la: albers(lo, la, -154, 50, 55, 65)
HI  = lambda lo, la: albers(lo, la, -157, 13, 8, 18)
# (投影関数, 縮尺, 配置先(L48座標系の基準点 lon,lat), 元の中心 lon,lat)
INSET = {'US-AK': (AK, 0.35, (-117.5, 27.0), (-153, 64)),
         'US-HI': (HI, 1.0,  (-106.5, 26.0), (-157, 20.5))}
def place(rid, lo, la):
    if rid in INSET:
        f, k, (tl, tb), (cl, cb) = INSET[rid]
        cx, cy = f(cl, cb); tx, ty = L48(tl, tb); x, y = f(lo, la)
        return tx + (x - cx) * k, ty + (y - cy) * k
    return L48(lo, la)

SCALE = 1000.0; TOL = 1.0
def dp(pts, tol):
    if len(pts) < 3: return pts
    (x1, y1), (x2, y2) = pts[0], pts[-1]; dx, dy = x2-x1, y2-y1; L = math.hypot(dx, dy)
    best, bi = -1, 0
    for i in range(1, len(pts)-1):
        x, y = pts[i]; d = math.hypot(x-x1, y-y1) if L == 0 else abs(dy*x - dx*y + x2*y1 - y2*x1)/L
        if d > best: best, bi = d, i
    return [pts[0], pts[-1]] if best <= tol else dp(pts[:bi+1], tol)[:-1] + dp(pts[bi:], tol)

CAP = {'AL':('Alabama','Montgomery'),'AK':('Alaska','Juneau'),'AZ':('Arizona','Phoenix'),'AR':('Arkansas','Little Rock'),'CA':('California','Sacramento'),'CO':('Colorado','Denver'),'CT':('Connecticut','Hartford'),'DE':('Delaware','Dover'),'DC':('District of Columbia','Washington, D.C.'),'FL':('Florida','Tallahassee'),'GA':('Georgia','Atlanta'),'HI':('Hawaii','Honolulu'),'ID':('Idaho','Boise'),'IL':('Illinois','Springfield'),'IN':('Indiana','Indianapolis'),'IA':('Iowa','Des Moines'),'KS':('Kansas','Topeka'),'KY':('Kentucky','Frankfort'),'LA':('Louisiana','Baton Rouge'),'ME':('Maine','Augusta'),'MD':('Maryland','Annapolis'),'MA':('Massachusetts','Boston'),'MI':('Michigan','Lansing'),'MN':('Minnesota','Saint Paul'),'MS':('Mississippi','Jackson'),'MO':('Missouri','Jefferson City'),'MT':('Montana','Helena'),'NE':('Nebraska','Lincoln'),'NV':('Nevada','Carson City'),'NH':('New Hampshire','Concord'),'NJ':('New Jersey','Trenton'),'NM':('New Mexico','Santa Fe'),'NY':('New York','Albany'),'NC':('North Carolina','Raleigh'),'ND':('North Dakota','Bismarck'),'OH':('Ohio','Columbus'),'OK':('Oklahoma','Oklahoma City'),'OR':('Oregon','Salem'),'PA':('Pennsylvania','Harrisburg'),'RI':('Rhode Island','Providence'),'SC':('South Carolina','Columbia'),'SD':('South Dakota','Pierre'),'TN':('Tennessee','Nashville'),'TX':('Texas','Austin'),'UT':('Utah','Salt Lake City'),'VT':('Vermont','Montpelier'),'VA':('Virginia','Richmond'),'WA':('Washington','Olympia'),'WV':('West Virginia','Charleston'),'WI':('Wisconsin','Madison'),'WY':('Wyoming','Cheyenne')}
g = json.load(open(src)); raw = {}
for f in g['features']:
    p = f['properties']
    if p.get('iso_a2') != 'US': continue
    rid = p['iso_3166_2']
    if rid[3:] not in CAP: continue   # 準州(PR等)は除外
    t, c = f['geometry']['type'], f['geometry']['coordinates']
    polys = c if t == 'MultiPolygon' else [c]
    if rid == 'US-AK': polys = [q for q in polys if q[0][0][0] < 0]  # 日付変更線の西側(アリューシャン西端)は除外
    raw[rid] = [[place(rid, x, y) for x, y in poly[0]] for poly in polys]
assert len(raw) == 51, len(raw)
xs = [x for rs in raw.values() for r in rs for x, _ in r]; ys = [y for rs in raw.values() for r in rs for _, y in r]
x0, y0, k = min(xs), min(ys), SCALE / (max(xs) - min(xs))
feats = []
for rid in sorted(raw):
    polys = []
    for r in raw[rid]:
        r = [(round((x-x0)*k, 2), round((y-y0)*k, 2)) for x, y in r]
        if r[0] != r[-1]: r.append(r[0])
        s = dp(r, TOL)
        if len(s) < 4: s = r if len(r) >= 4 else None
        if s and abs(sum(a[0]*b[1]-b[0]*a[1] for a, b in zip(s, s[1:])))/2 >= 0.3:  # 極小の島は除外
            polys.append([[list(q) for q in s]])
    feats.append({"type":"Feature","properties":{"id":rid},"geometry":{"type":"MultiPolygon","coordinates":polys}})
(out/'geo.geojson').write_text(json.dumps({"type":"FeatureCollection","features":feats},separators=(',',':')))
ids = [f['properties']['id'] for f in feats]
(out/'regions.json').write_text(json.dumps({"regions":[{"id":i,"capitalId":"cap_"+i} for i in ids]},indent=1))
(out/'strings/en.json').write_text(json.dumps({"regions":{i:CAP[i[3:]][0] for i in ids},"capitals":{"cap_"+i:CAP[i[3:]][1] for i in ids}},ensure_ascii=False,indent=1))
(out/'pack.json').write_text(json.dumps({
 "packId":"us","version":"0.1.0","country":"US","regionKind":"state","languages":["en"],"defaultLanguage":"en",
 "projection":{"type":"planar","note":"Albers USA相当(焼き込み済み)。座標は0..1000の平面"},
 "insets":[{"id":"US-AK","scale":0.35},{"id":"US-HI","scale":1.0}],
 "attribution":"Made with Natural Earth (naturalearthdata.com)",
 "license":{"name":"Public Domain (Natural Earth)","commercialConfirmed":True,"internalOnly":False}},indent=1))
print("ok", sum(len(r[0]) for f in feats for r in f['geometry']['coordinates']), "vertices")
