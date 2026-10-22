import numpy as np, sys, math
from PIL import Image

W = H = 192
SC = 1.56

def nrm(v):
    v = np.asarray(v, float); return v / np.linalg.norm(v)

D = nrm([1, 1, 1]); R = nrm([1, -1, 0]); U = nrm([-1, -1, 2])
L = nrm([0.35, 0.8, 1.3])
ox, oy = 83.7, 126.6
sx, sy = np.meshgrid((np.arange(W) + 0.5 - ox) / SC, (np.arange(H) + 0.5 - oy) / SC)
P0 = sx[..., None] * R + (-sy)[..., None] * U + 500 * D
RD = -D
Z = np.array([0, 0, 1.0])

RAMPS = {
    'orange': [(92, 38, 16), (176, 74, 14), (232, 120, 20), (252, 168, 40), (255, 214, 120)],
    'dark':   [(22, 24, 30), (44, 48, 58), (66, 72, 84), (92, 100, 114), (128, 138, 152)],
    'steel':  [(40, 44, 52), (88, 96, 110), (140, 150, 164), (190, 200, 210), (236, 240, 244)],
    'black':  [(10, 10, 14), (24, 24, 30), (38, 40, 48), (56, 60, 70), (80, 86, 98)],
    'yellow': [(90, 64, 8), (170, 128, 10), (230, 186, 20), (250, 222, 70), (255, 244, 160)],
    'red':    [(80, 10, 10), (150, 20, 20), (220, 40, 30), (250, 90, 70), (255, 160, 140)],
    'blue':   [(14, 30, 60), (24, 56, 110), (40, 90, 160), (70, 130, 200), (130, 180, 230)],
    'hole':   [(8, 8, 12)] * 5,
}

class Scene:
    def __init__(self):
        self.depth = np.full((H, W), np.inf)
        self.nbuf = np.zeros((H, W, 3)); self.pbuf = np.zeros((H, W, 3))
        self.ibuf = np.full((H, W), -1); self.prims = []

    def commit(self, t, n, mat):
        pid = len(self.prims); self.prims.append(mat)
        m = t < self.depth
        self.depth = np.where(m, t, self.depth)
        self.nbuf[m] = n[m]; self.ibuf[m] = pid
        self.pbuf[m] = (P0 + t[..., None] * RD)[m]

    def box(self, c, ax, half, mat):
        c = np.asarray(c, float)
        tmin = np.full((H, W), -np.inf); tmax = np.full((H, W), np.inf)
        nn = np.zeros((H, W, 3))
        for a, h in zip(ax, half):
            a = nrm(a); o = (P0 - c) @ a; d = RD @ a
            if abs(d) < 1e-9:
                tmin[np.abs(o) > h] = np.inf; continue
            t1 = (-h - o) / d; t2 = (h - o) / d
            lo = np.minimum(t1, t2); hi = np.maximum(t1, t2)
            upd = lo > tmin
            nn[upd] = a * -np.sign(d)
            tmin = np.where(upd, lo, tmin); tmax = np.minimum(tmax, hi)
        hit = (tmin <= tmax) & np.isfinite(tmin)
        self.commit(np.where(hit, tmin, np.inf), nn, mat)

    def cyl(self, c, a, r, h, mat):
        c = np.asarray(c, float); a = nrm(a)
        o = P0 - c; oa = o @ a; da = RD @ a
        op = o - oa[..., None] * a; dp = RD - da * a
        A = dp @ dp; B = 2 * (op @ dp); Cc = (op * op).sum(-1) - r * r
        best = np.full((H, W), np.inf); nn = np.zeros((H, W, 3))
        if A > 1e-12:
            disc = B * B - 4 * A * Cc; ok = disc >= 0
            t = np.where(ok, (-B - np.sqrt(np.maximum(disc, 0))) / (2 * A), np.inf)
            ok &= np.abs(oa + t * da) <= h
            best = np.where(ok, t, best)
            with np.errstate(invalid='ignore'):
                p = o + t[..., None] * RD
                pn = p - (p @ a)[..., None] * a
            nn[ok] = (pn / r)[ok]
        if abs(da) > 1e-9:
            for s in (1, -1):
                t = (s * h - oa) / da
                p = o + t[..., None] * RD
                rr = ((p - (p @ a)[..., None] * a) ** 2).sum(-1)
                ok = (rr <= r * r) & (t < best)
                best = np.where(ok, t, best); nn[ok] = a * s
        self.commit(best, nn, mat)

    def image(self, belt_phase):
        img = np.zeros((H, W, 4), np.uint8)
        lam = np.clip(self.nbuf @ L, 0, 1)
        spec = np.clip(self.nbuf @ nrm(L + D), 0, 1) ** 24
        val = 0.22 + 0.78 * lam + 0.35 * spec
        k = np.clip(np.round(val * 4 - 0.4), 0, 4).astype(int)
        for y, x in zip(*np.where(self.ibuf >= 0)):
            mat = self.prims[self.ibuf[y, x]]; p = self.pbuf[y, x]; n = self.nbuf[y, x]
            if mat == 'hazard':
                edge = n[2] > 0.5 and (abs(p[0]) > 18.5 or abs(p[1]) > 18.5)
                mat = ('black' if ((p[0] + p[1]) % 6) < 3 else 'yellow') if edge else 'dark'
            elif mat == 'belt':
                mat = 'black'
                if n[2] > 0.5 and ((p @ BELT_DIR + belt_phase) % 5) < 1.2:
                    img[y, x, :3] = RAMPS['black'][3]; img[y, x, 3] = 255; continue
            img[y, x, :3] = RAMPS[mat][k[y, x]]; img[y, x, 3] = 255
        out = img.copy()
        ib, dp = self.ibuf, self.depth
        for y, x in zip(*np.where(ib >= 0)):
            i = ib[y, x]
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                X, Y = x + dx, y + dy
                if not (0 <= X < W and 0 <= Y < H) or ib[Y, X] < 0:
                    out[y, x, :3] = (16, 14, 20); break
                if ib[Y, X] != i and dp[Y, X] < dp[y, x] - 2.0:
                    mat = self.prims[i]
                    mat = {'hazard': 'dark', 'belt': 'black'}.get(mat, mat)
                    out[y, x, :3] = RAMPS[mat][0]; break
        return out

# ---------------- layout ----------------
def yaw_dir(deg):
    r = math.radians(deg); return np.array([math.cos(r), math.sin(r), 0.0])

YAW_PICK, YAW_PLACE = -22.0, 78.0
REACH = 44.0
PICK = yaw_dir(YAW_PICK) * REACH
PLACE = yaw_dir(YAW_PLACE) * (REACH - 2)
BELT_DIR = -nrm(np.cross(Z, yaw_dir(YAW_PICK)))     # parts travel along +BELT_DIR toward PICK
BELT_TOP = 12.0
BIN_TOP = 13.0
CUBE = 3.2
L2, L3 = 44.0, 40.0
TOOL = 17.0   # wrist -> cube centre

def solve(yaw, wrist_h):
    """Return (a, s, d2, d3, S, E, Wr) for a wrist point above radius REACH."""
    a = yaw_dir(yaw); s = nrm(np.cross(Z, a))
    S = 4 * a + Z * 33
    r = REACH - 4; h = wrist_h - 33
    Dd = math.hypot(r, h)
    c = (L2 * L2 + Dd * Dd - L3 * L3) / (2 * L2 * Dd)
    al2 = math.atan2(h, r) + math.acos(max(-1, min(1, c)))
    d2 = math.cos(al2) * a + math.sin(al2) * Z
    E = S + d2 * L2
    Wr = a * REACH + Z * wrist_h
    d3 = nrm(Wr - E)
    return a, s, d2, d3, S, E, Wr

def render(yaw, wrist_h, grip, held, cubes, belt_phase):
    sc = Scene()
    # floor props
    sc.box([0, 0, 2], [[1, 0, 0], [0, 1, 0], Z], [22, 22, 2], 'hazard')
    sc.box([0, 0, 4.6], [[1, 0, 0], [0, 1, 0], Z], [17, 17, 0.6], 'dark')
    for bx in (-14, 14):
        for by in (-14, 14):
            sc.cyl([bx, by, 4.8], Z, 1.6, 0.8, 'steel')
    # conveyor: ends at PICK, extends back along -BELT_DIR
    side = nrm(np.cross(Z, BELT_DIR)); blen = 26
    bc = PICK - BELT_DIR * (blen - 6)
    sc.box(bc + Z * (BELT_TOP - 1.2), [BELT_DIR, side, Z], [blen, 6, 1.2], 'belt')
    for sgn in (1, -1):
        sc.box(bc + side * sgn * 6.8 + Z * (BELT_TOP - 1.5), [BELT_DIR, side, Z], [blen, 0.8, 2.2], 'dark')
    for t in (-blen + 3, 0, blen - 3):
        for sgn in (1, -1):
            sc.box(bc + BELT_DIR * t + side * sgn * 5 + Z * (BELT_TOP - 3) / 2, [BELT_DIR, side, Z], [1, 1, (BELT_TOP - 3) / 2], 'dark')
    sc.cyl(bc + BELT_DIR * blen + Z * (BELT_TOP - 1.2), side, 1.6, 6.6, 'steel')
    # bin at PLACE
    pa = yaw_dir(YAW_PLACE); ps = nrm(np.cross(Z, pa))
    sc.box(PLACE + Z * BIN_TOP / 2, [pa, ps, Z], [8, 8, BIN_TOP / 2], 'blue')
    sc.box(PLACE + Z * (BIN_TOP + 0.01) / 2 + Z * 0.5, [pa, ps, Z], [6.6, 6.6, BIN_TOP / 2], 'hole')
    # loose cubes
    for c in cubes:
        sc.box(c, [BELT_DIR, side, Z], [CUBE, CUBE, CUBE], 'red')
    # robot
    a, s, d2, d3, S, E, Wr = solve(yaw, wrist_h)
    sc.cyl([0, 0, 10], Z, 12, 5, 'dark')
    sc.cyl([0, 0, 15.6], Z, 13, 0.8, 'steel')
    sc.cyl([0, 0, 20], Z, 11.5, 4, 'orange')
    sc.box(-2 * a + Z * 27, [a, s, Z], [10, 9, 4], 'orange')
    sc.box(S - Z * 1, [a, s, Z], [7, 8, 6], 'orange')
    sc.cyl(S + s * 10, s, 6.5, 2.2, 'dark')
    sc.cyl(S + s * 12.7, s, 4.5, 0.6, 'steel')
    sc.cyl(S - s * 9, s, 5, 1, 'steel')
    n2 = nrm(np.cross(d2, s))
    sc.cyl(S, s, 7.5, 7.5, 'orange')
    sc.box(S + d2 * (L2 / 2), [d2, s, n2], [L2 / 2, 5.5, 4.2], 'orange')
    sc.box(S + d2 * (L2 / 2) + s * 5.9, [d2, s, n2], [L2 / 2 - 9, 0.5, 1.6], 'dark')
    for i in range(8):
        sc.cyl(S + d2 * (6 + i * 4.6) - n2 * 5.2 - s * 2, d2, 1.6, 2.4, 'black')
    sc.cyl(E, s, 7, 7.2, 'orange')
    sc.cyl(E + s * 8.2, s, 5.2, 1.4, 'dark')
    sc.cyl(E - s * 8.2, s, 4, 1, 'steel')
    n3 = nrm(np.cross(d3, s))
    sc.box(E - d3 * 8, [d3, s, n3], [6, 6, 5.5], 'orange')
    sc.cyl(E - d3 * 14.5, d3, 4.2, 0.8, 'dark')
    sc.box(E + d3 * 9, [d3, s, n3], [10, 5.2, 4.8], 'orange')
    sc.cyl(E + d3 * 28, d3, 4.2, 10, 'orange')
    sc.cyl(E + d3 * 19, d3, 4.8, 0.7, 'black')
    sc.cyl(Wr, s, 4.2, 4.0, 'orange')
    sc.cyl(Wr + s * 4.6, s, 3, 0.6, 'steel')
    d5 = -Z; n5 = nrm(np.cross(d5, s))
    sc.cyl(Wr + d5 * 5.5, d5, 3.2, 1.6, 'steel')
    sc.cyl(Wr + d5 * 7.6, d5, 4.2, 0.6, 'dark')
    sc.box(Wr + d5 * 10.4, [d5, s, n5], [2.2, 4.5, 6.5], 'dark')
    gap = CUBE + 1.1 + grip * 2.6
    sc.box(Wr + d5 * 16 + n5 * gap, [d5, s, n5], [4.2, 2.6, 1.1], 'steel')
    sc.box(Wr + d5 * 16 - n5 * gap, [d5, s, n5], [4.2, 2.6, 1.1], 'steel')
    if held:
        sc.box(Wr + d5 * TOOL, [d5, s, n5], [CUBE, CUBE, CUBE], 'red')
    return sc.image(belt_phase)

# ---------------- timeline ----------------
def ease(t): return t * t * (3 - 2 * t)
def lerp(a, b, t): return a + (b - a) * t

N = 36
LIFT = 14.0
PICK_WH = BELT_TOP + CUBE + TOOL          # wrist height when cube sits on belt
PLACE_WH = BIN_TOP + CUBE + TOOL + 3      # release slightly above bin rim
HIGH = PICK_WH + LIFT
KEYS = [  # frame, yaw, wrist_h, grip(1=open)
    (0, YAW_PICK, HIGH, 1), (6, YAW_PICK, PICK_WH, 1), (9, YAW_PICK, PICK_WH, 0),
    (14, YAW_PICK, HIGH, 0), (22, YAW_PLACE, HIGH, 0), (25, YAW_PLACE, PLACE_WH, 0),
    (27, YAW_PLACE, PLACE_WH, 1), (36, YAW_PICK, HIGH, 1)]

def pose(f):
    for (f0, y0, h0, g0), (f1, y1, h1, g1) in zip(KEYS, KEYS[1:]):
        if f0 <= f <= f1:
            t = ease((f - f0) / (f1 - f0))
            return lerp(y0, y1, t), lerp(h0, h1, t), lerp(g0, g1, t)

def frame(f):
    yaw, wh, grip = pose(f)
    held = 8 <= f <= 26
    cube_on_belt = PICK + Z * (BELT_TOP + CUBE)
    cubes = []
    if f < 8:
        cubes.append(cube_on_belt)
    if f >= 22:      # next part rides in along the belt, arriving at frame 36 (= frame 0)
        t = (f - 22) / 14.0
        cubes.append(cube_on_belt - BELT_DIR * 35 * (1 - t))
    if 27 <= f <= 29:  # released part dropping into the bin
        Wr = solve(YAW_PLACE, PLACE_WH)[-1]
        cubes.append(Wr - Z * (TOOL + (f - 26) * 4.5))
    phase = -f * (35 / 14.0) if f >= 22 else -22 * (35 / 14.0)
    return render(yaw, wh, grip, held, cubes, phase)

if __name__ == '__main__':
    out = sys.argv[1]
    frames = [frame(f) for f in range(N)]
    np.save(out + '.npy', np.stack(frames))
    ims = []
    for fr in frames:
        im = Image.fromarray(fr, 'RGBA'); bg = Image.new('RGBA', im.size, (70, 74, 84, 255)); bg.alpha_composite(im)
        ims.append(bg.resize((W * 3, H * 3), Image.NEAREST).convert('P', palette=Image.ADAPTIVE))
    ims[0].save(out + '_prev.gif', save_all=True, append_images=ims[1:], duration=80, loop=0)
    allpx = np.stack(frames)
    ys, xs = np.where(allpx[..., 3].max(0) > 0)
    print('bbox', xs.min(), xs.max(), ys.min(), ys.max())
