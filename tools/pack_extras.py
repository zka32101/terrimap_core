"""パックの追加データ(州都の位置・隣接)を作る共通処理。convert_de.py / convert_us.py から使う。
- capital_pos: 緯度経度の表から、パックの座標系の位置を作る(州の形の外なら、形の内側へ寄せる)
- neighbors: ポリゴンの共有する境界から、隣り合う地域を自動で求める(手書きしない)"""
import math

def _in_ring(x, y, ring):
    inside = False
    for (x1, y1), (x2, y2) in zip(ring, ring[1:]):
        if (y1 > y) != (y2 > y) and x < x1 + (y - y1) / (y2 - y1) * (x2 - x1):
            inside = not inside
    return inside

def inside_region(x, y, polys):
    """polys: [[ring,...],...](各ポリゴンの外周のみ使う)"""
    return any(_in_ring(x, y, poly[0]) for poly in polys)

def _seg_dist(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    L2 = dx * dx + dy * dy
    t = 0.0 if L2 == 0 else max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / L2))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))

def _centroid(polys):
    best, bc = -1, (0, 0)
    for poly in polys:
        r = poly[0]
        a = abs(sum(p[0] * q[1] - q[0] * p[1] for p, q in zip(r, r[1:]))) / 2
        if a > best:
            best, bc = a, (sum(p[0] for p in r) / len(r), sum(p[1] for p in r) / len(r))
    return bc

def snap_inside(x, y, polys):
    """(x,y)が形の中ならそのまま。外なら、最も大きいポリゴンの代表点の方向へ、中に入るまで少しずつ寄せる。戻り値: (x, y, 寄せたか)"""
    if inside_region(x, y, polys):
        return x, y, False
    cx, cy = _centroid(polys)
    for i in range(1, 201):
        t = i / 200
        nx, ny = x + (cx - x) * t, y + (cy - y) * t
        if inside_region(nx, ny, polys):
            return nx, ny, True
    raise ValueError("州の形の内側に寄せられない")

def _bbox(polys):
    xs = [p[0] for poly in polys for p in poly[0]]; ys = [p[1] for poly in polys for p in poly[0]]
    return min(xs), min(ys), max(xs), max(ys)

class _SegIndex:
    """線分の空間ハッシュ(近い線分だけ調べる)"""
    def __init__(self, polys, tol):
        self.tol = tol; self.c = max(tol * 4, 1e-9); self.cells = {}
        for poly in polys:
            r = poly[0]
            for a, b in zip(r, r[1:]):
                x0, x1 = sorted((a[0], b[0])); y0, y1 = sorted((a[1], b[1]))
                for i in range(int((x0 - tol) // self.c), int((x1 + tol) // self.c) + 1):
                    for j in range(int((y0 - tol) // self.c), int((y1 + tol) // self.c) + 1):
                        self.cells.setdefault((i, j), []).append((a, b))

    def near(self, x, y):
        for a, b in self.cells.get((int(x // self.c), int(y // self.c)), ()):
            if _seg_dist(x, y, a[0], a[1], b[0], b[1]) <= self.tol:
                return True
        return False

def shared_length(a_polys, b_polys, tol, index=None):
    """Aの境界のうち、Bの境界から tol 以内にある部分の長さ。辺を細かくサンプルして測る
    (簡略化で、両者の頂点の位置が違っても、同じ境界線上なら測れる)"""
    idx = index or _SegIndex(b_polys, tol)
    total = 0.0
    for poly in a_polys:
        r = poly[0]
        for p, q in zip(r, r[1:]):
            L = math.hypot(q[0] - p[0], q[1] - p[1])
            if L == 0:
                continue
            n = max(1, math.ceil(L / (tol * 0.5)))
            flags = [idx.near(p[0] + (q[0] - p[0]) * i / n, p[1] + (q[1] - p[1]) * i / n) for i in range(n + 1)]
            total += L * sum(1 for i in range(n) if flags[i] and flags[i + 1]) / n
    return total

def _enclosed(a_polys, b_polys):
    """Aの頂点の半数以上がBの外周の内側にある(飛び地: 例 ベルリンはブランデンブルクの中)。
    パックはポリゴンの穴を持たないため、境界の近さだけでは見つからない"""
    pts = [p for poly in a_polys for p in poly[0]]
    return sum(1 for p in pts if inside_region(p[0], p[1], b_polys)) >= len(pts) / 2

def neighbors(regions, tol, min_len):
    """regions: {id: polys}。戻り値: {id: [隣のid(昇順)]}。A→B と B→A の長さの大きい方で判定し、対称にする。
    湖の上の境界(例: ミシガン州とミネソタ州)も、ポリゴンが共有していれば隣とする。"""
    ids = sorted(regions)
    bb = {i: _bbox(regions[i]) for i in ids}
    idx = {i: _SegIndex(regions[i], tol) for i in ids}
    out = {i: set() for i in ids}
    for ai, a in enumerate(ids):
        for b in ids[ai + 1:]:
            A, B = bb[a], bb[b]
            if A[2] + tol < B[0] or B[2] + tol < A[0] or A[3] + tol < B[1] or B[3] + tol < A[1]:
                continue
            if (_enclosed(regions[a], regions[b]) or _enclosed(regions[b], regions[a])
                    or max(shared_length(regions[a], regions[b], tol, idx[b]),
                           shared_length(regions[b], regions[a], tol, idx[a])) >= min_len):
                out[a].add(b); out[b].add(a)
    return {i: sorted(v) for i, v in out.items()}
