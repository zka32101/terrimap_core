#!/usr/bin/env python3
"""Natural Earth 10m admin-1 → pack(us)。Albers投影+AK/HIのインセットを焼き込み、平面座標(planar)で出力。
使い方: convert_us.py <ne10.geojson> <out packs/us>"""
import json, sys, pathlib, math
sys.path.insert(0, str(pathlib.Path(__file__).parent))
import pack_extras
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

# 州都の位置(緯度, 経度)。市の中心の位置(一般に知られた公共の事実)。
CAP_LL = {'US-AL':(32.3770,-86.3000),'US-AK':(58.3019,-134.4197),'US-AZ':(33.4484,-112.0740),'US-AR':(34.7465,-92.2896),'US-CA':(38.5816,-121.4944),'US-CO':(39.7392,-104.9903),'US-CT':(41.7637,-72.6851),'US-DE':(39.1582,-75.5244),'US-DC':(38.9072,-77.0369),'US-FL':(30.4383,-84.2807),'US-GA':(33.7490,-84.3880),'US-HI':(21.3069,-157.8583),'US-ID':(43.6150,-116.2023),'US-IL':(39.7817,-89.6501),'US-IN':(39.7684,-86.1581),'US-IA':(41.5868,-93.6250),'US-KS':(39.0473,-95.6752),'US-KY':(38.2009,-84.8733),'US-LA':(30.4515,-91.1871),'US-ME':(44.3106,-69.7795),'US-MD':(38.9784,-76.4922),'US-MA':(42.3601,-71.0589),'US-MI':(42.7325,-84.5555),'US-MN':(44.9537,-93.0900),'US-MS':(32.2988,-90.1848),'US-MO':(38.5767,-92.1735),'US-MT':(46.5891,-112.0391),'US-NE':(40.8136,-96.7026),'US-NV':(39.1638,-119.7674),'US-NH':(43.2081,-71.5376),'US-NJ':(40.2171,-74.7429),'US-NM':(35.6870,-105.9378),'US-NY':(42.6526,-73.7562),'US-NC':(35.7796,-78.6382),'US-ND':(46.8083,-100.7837),'US-OH':(39.9612,-82.9988),'US-OK':(35.4676,-97.5164),'US-OR':(44.9429,-123.0351),'US-PA':(40.2732,-76.8867),'US-RI':(41.8240,-71.4128),'US-SC':(34.0007,-81.0348),'US-SD':(44.3683,-100.3510),'US-TN':(36.1627,-86.7816),'US-TX':(30.2672,-97.7431),'US-UT':(40.7608,-111.8910),'US-VT':(44.2601,-72.5754),'US-VA':(37.5407,-77.4360),'US-WA':(47.0379,-122.9007),'US-WV':(38.3498,-81.6326),'US-WI':(43.0731,-89.4012),'US-WY':(41.1400,-104.8202)}
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
polys = {f['properties']['id']: f['geometry']['coordinates'] for f in feats}
NB = pack_extras.neighbors(polys, tol=3.0, min_len=6.0)
regs = []
for i in ids:
    lat, lng = CAP_LL[i]
    px, py = place(i, lng, lat)
    x, y, moved = pack_extras.snap_inside(round((px-x0)*k, 2), round((py-y0)*k, 2), polys[i])
    if moved: print("州都の位置を形の内側へ寄せた:", i)
    regs.append({"id":i,"capitalId":"cap_"+i,"capitalPos":{"x":round(x,2),"y":round(y,2)},"neighbors":NB[i]})
(out/'regions.json').write_text(json.dumps({"regions":regs},indent=1))
(out/'strings/en.json').write_text(json.dumps({"regions":{i:CAP[i[3:]][0] for i in ids},"capitals":{"cap_"+i:CAP[i[3:]][1] for i in ids}},ensure_ascii=False,indent=1))
(out/'pack.json').write_text(json.dumps({
 "packId":"us","version":"0.1.0","country":"US","regionKind":"state","languages":["en"],"defaultLanguage":"en",
 "projection":{"type":"planar","note":"Albers USA相当(焼き込み済み)。座標は0..1000の平面"},
 "insets":[{"id":"US-AK","scale":0.35},{"id":"US-HI","scale":1.0}],
 "attribution":"Made with Natural Earth (naturalearthdata.com)",
 "license":{"name":"Public Domain (Natural Earth)","commercialConfirmed":True,"internalOnly":False}},indent=1))
print("ok", sum(len(r[0]) for f in feats for r in f['geometry']['coordinates']), "vertices")
