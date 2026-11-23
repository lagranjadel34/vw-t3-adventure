"""VW T3 Dehler Profi en 3D con curvas, para el prototipo 3D (prototipos/voxel3d).

En vez de cajas, la furgo es un volumen de distancias (SDF): perfil lateral, planta con
esquinas redondeadas y sección frontal con el techo abombado, unidos con intersección suave
(aristas redondeadas), pasos de rueda recortados, parachoques envolventes, ruedas, retrovisores,
escotilla y carriles. Se malla con marching cubes y se pinta por zonas según la ficha v2 de Ara
(ventanas, banda celeste, rejilla, faros, pilotos...). Normales suaves: nada de "caja de cartón".

Ejes del modelo: x adelante, y izquierda, z arriba (como t3gen). La salida va en ejes de Godot
(X = y, Y = z, Z = x): binario float32, 9 valores por vértice (posición, normal, color 0-1).
Uso: python3 t3_sdf.py salida.bin [paso_m]"""
import math
import sys

import numpy as np
from skimage.measure import marching_cubes

import dehler as D

ST = D.DEHLER
BODY = np.array(ST["body"]) / 255
ROOF = np.array(ST["roof"]) / 255
SEAM_ROOF = np.array(ST["roof_seam"]) / 255
CELESTE = np.array(ST["window_frame"]) / 255
ROOF_SLOPE = np.array(ST["roof_slope"]) / 255
SKY = np.array(ST["skylight"]) / 255


def rgb(*c):
    return np.array(c) / 255


GLASS = rgb(34, 44, 54)
GLASS_HI = rgb(88, 108, 116)
BLACK = rgb(30, 31, 36)
BUMPER = rgb(46, 49, 53)
CHROME = rgb(200, 206, 210)
LENS = rgb(236, 234, 214)
AMBER = rgb(226, 140, 40)
RED = rgb(150, 32, 30)
WHITE = rgb(230, 232, 228)
PLATE = rgb(228, 232, 234)
EU = rgb(40, 70, 160)
TYRE = rgb(28, 28, 31)
TYRE_WALL = rgb(40, 40, 44)
RIM = rgb(176, 184, 190)
RIM_DARK = rgb(64, 68, 74)
HATCH = rgb(76, 75, 80)
SEAM = rgb(24, 32, 56)
EXHAUST = rgb(96, 96, 98)

HL, HW = 2.285, 0.92
Z_BOT, Z_BELT, Z_ROOF, Z_TOP = 0.30, 1.0, 1.84, 2.34
WX, WZ, WR, WY, WHW = 1.23, 0.32, 0.32, 0.83, 0.11
ARCH_R = 0.41
ROUND = 0.07            # radio de las aristas de la carrocería


# --- primitivas SDF (vectorizadas) ---
def sd_poly(px, py, verts):
    v = np.array(verts, float)
    d = (px - v[0, 0]) ** 2 + (py - v[0, 1]) ** 2
    s = np.ones_like(px)
    j = len(v) - 1
    for i in range(len(v)):
        ex, ey = v[j] - v[i]
        wx, wy = px - v[i, 0], py - v[i, 1]
        t = np.clip((wx * ex + wy * ey) / (ex * ex + ey * ey), 0, 1)
        bx, by = wx - ex * t, wy - ey * t
        d = np.minimum(d, bx * bx + by * by)
        c1 = py >= v[i, 1]
        c2 = py < v[j, 1]
        c3 = ex * wy > ey * wx
        flip = (c1 & c2 & c3) | (~c1 & ~c2 & ~c3)
        s = np.where(flip, -s, s)
        j = i
    return s * np.sqrt(d)


def sd_round_rect(px, py, hx, hy, r):
    qx, qy = np.abs(px) - hx + r, np.abs(py) - hy + r
    return np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r


def sd_box(x, y, z, c, h, r):
    qx = np.abs(x - c[0]) - h[0] + r
    qy = np.abs(y - c[1]) - h[1] + r
    qz = np.abs(z - c[2]) - h[2] + r
    out = np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qy, 0) ** 2 + np.maximum(qz, 0) ** 2)
    return out + np.minimum(np.maximum(qx, np.maximum(qy, qz)), 0) - r


def sd_cyl_y(x, y, z, cx, cy, cz, r, hw, rr):
    """Cilindro de eje y con canto redondeado rr."""
    dr = np.hypot(x - cx, z - cz) - r + rr
    dy = np.abs(y - cy) - hw + rr
    return np.minimum(np.maximum(dr, dy), 0) + np.hypot(np.maximum(dr, 0), np.maximum(dy, 0)) - rr


def sd_cyl_x(x, y, z, x0, x1, cy, cz, r):
    dr = np.hypot(y - cy, z - cz) - r
    dx = np.abs(x - (x0 + x1) / 2) - (x1 - x0) / 2
    return np.minimum(np.maximum(dr, dx), 0) + np.hypot(np.maximum(dr, 0), np.maximum(dx, 0))


def smax(a, b, k):
    h = np.clip(0.5 - 0.5 * (b - a) / k, 0, 1)
    return b + (a - b) * h + k * h * (1 - h)


def smin(a, b, k):
    return -smax(-a, -b, k)


def arc(cx, cy, r, a0, a1, n=8):
    return [(cx + r * math.cos(a0 + (a1 - a0) * k / n), cy + r * math.sin(a0 + (a1 - a0) * k / n))
            for k in range(n + 1)]


# Perfil lateral (x, z): frente casi vertical, parabrisas inclinado, techo alto de la Dehler
# con frente en rampa redondeada y trasera caída.
SIDE = ([(-2.27, Z_BOT), (2.26, Z_BOT), (2.3, 0.6), (2.28, Z_BELT), (1.86, Z_ROOF)]
        + arc(1.18, 1.98, 0.36, math.radians(-10), math.radians(90))[1:]
        + [(-1.98, Z_TOP), (-2.2, 2.2), (-2.26, Z_BELT)])
# Sección frontal (y, z): cintura recta y caída hacia dentro arriba, techo abombado.
FRONT = ([(-HW, Z_BOT), (HW, Z_BOT), (HW, Z_BELT), (0.885, Z_ROOF), (0.875, 2.08)]
         + arc(0.875 - 0.26, 2.08, 0.26, 0, math.pi / 2)[1:]
         + [(-x, z) for x, z in arc(0.875 - 0.26, 2.08, 0.26, math.pi / 2, 0)][:-1]
         + [(-0.875, 2.08), (-0.885, Z_ROOF), (-HW, Z_BELT)])


def parts(x, y, z):
    """Distancia a cada pieza (diccionario); la carrocería ya lleva los pasos de rueda."""
    d_side = sd_poly(x, z, SIDE)
    d_plan = sd_round_rect(x, y, 2.3, HW, 0.22)
    d_front = sd_poly(y, z, FRONT)
    body = smax(smax(d_side, d_plan, ROUND), d_front, ROUND)
    for wx in (WX, -WX):
        arch = np.maximum(np.hypot(x - wx, z - WZ) - ARCH_R, 0.6 - np.abs(y))
        body = smax(body, -arch, 0.03)
    P = {"body": body}
    P["chassis"] = sd_box(x, y, z, (0, 0, 0.24), (2.05, 0.72, 0.1), 0.03)
    P["bumper_f"] = sd_box(x, y, z, (2.34, 0, 0.42), (0.09, 0.96, 0.1), 0.04)
    P["bumper_r"] = sd_box(x, y, z, (-2.34, 0, 0.42), (0.09, 0.96, 0.1), 0.04)
    w = None
    for wx in (WX, -WX):
        for s in (1, -1):
            d = sd_cyl_y(x, y, z, wx, WY * s, WZ, WR, WHW, 0.06)
            w = d if w is None else np.minimum(w, d)
    P["wheel"] = w
    m = None
    for s in (1, -1):
        d = sd_box(x, y, z, (1.9, 1.0 * s, 1.22), (0.05, 0.07, 0.1), 0.025)
        d = np.minimum(d, sd_box(x, y, z, (1.95, 0.94 * s, 1.12), (0.02, 0.05, 0.015), 0.008))
        m = d if m is None else np.minimum(m, d)
    P["mirror"] = m
    P["hatch"] = sd_box(x, y, z, (0, 0, Z_TOP + 0.04), (0.33, 0.33, 0.07), 0.03)
    r = None
    for s in (1, -1):
        d = sd_box(x, y, z, (-0.45, 0.72 * s, Z_TOP + 0.02), (1.35, 0.025, 0.035), 0.015)
        r = d if r is None else np.minimum(r, d)
    P["rail"] = r
    P["exhaust"] = sd_cyl_x(x, y, z, -2.5, -2.2, 0.5, 0.24, 0.035)
    return P


def disc(a, b, ca, cb, r):
    return (a - ca) ** 2 + (b - cb) ** 2 < r * r


def rbox(a, b, a0, a1, b0, b1, r):
    """Rectángulo de esquinas redondeadas (ventanas como las de la ficha)."""
    ca, cb = (a0 + a1) / 2, (b0 + b1) / 2
    return sd_round_rect(a - ca, b - cb, (a1 - a0) / 2, (b1 - b0) / 2, r) < 0


def windshield_z_ok(z):
    return (z > 1.08) & (z < 1.78)


def paint(part, x, y, z, n):
    """Color por cara según la pieza y la posición (ficha v2 de Ara)."""
    N = len(x)
    c = np.tile(BODY, (N, 1))
    nx, ny, nz = n[:, 0], n[:, 1], n[:, 2]
    ay = np.abs(y)

    def put(mask, col):
        c[mask] = col

    b = part == "body"
    side = b & (np.abs(ny) > 0.55)
    front = b & (nx > 0.55)
    rear = b & (nx < -0.55)
    top = b & (nz > 0.6)
    # Techo alto: color del techo, rampa delantera celeste, panel y claraboya
    put(b & (z > Z_ROOF + 0.03), ROOF)
    put(b & (z > Z_ROOF + 0.03) & (nx > 0.25) & (x > 1.0), ROOF_SLOPE)
    put(top & (z > Z_TOP - 0.05) & (x > ST["roof_panel"][0]) & (x < ST["roof_panel"][1]), ROOF_SLOPE)
    put(top & (z > Z_TOP - 0.05) & (x > 0.95) & (x < 1.3) & (ay < 0.3), SKY)
    put(b & ~top & (z > Z_ROOF) & (z < Z_ROOF + 0.05) & (x < 1.9), SEAM_ROOF)
    # Banda baja celeste con filete oscuro encima
    band = b & (np.abs(nz) < 0.75) & (z > 0.36) & (z < 0.6)
    put(band, CELESTE)
    put(b & (np.abs(nz) < 0.75) & (z >= 0.6) & (z < 0.625), SEAM)
    # Laterales: marco celeste de ventanas, lunas, parteluz, rejilla del pilar
    put(side & (x > -1.3) & (x < 1.95) & (z > 1.06) & (z < 1.8), CELESTE)
    for x0, x1 in ((1.15, 1.8), (0.05, 1.0), (-1.2, -0.1)):
        put(side & rbox(x, z, x0, x1, 1.14, 1.74, 0.07), GLASS)
        put(side & (x > x0 + 0.1) & (x < x0 + 0.17) & (z > 1.2) & (z < 1.68), GLASS_HI)
    put(side & (x > 0.5) & (x < 0.55) & (z > 1.14) & (z < 1.74), CELESTE)
    for zz in (1.2, 1.32, 1.44, 1.56):
        put(side & (x > -2.1) & (x < -1.6) & (z > zz) & (z < zz + 0.06), BLACK)
    # Juntas de puertas, corredera (lado derecho, y < 0), manetas, intermitente lateral
    for xs in (1.06, 2.12):
        put(side & (x > xs) & (x < xs + 0.022) & (z > 0.42) & (z < (1.8 if xs < 2 else Z_BELT)), SEAM)
    put(side & (x > -1.9) & (x < -1.88) & (z > 0.42) & (z < Z_BELT), SEAM)
    for xs in (0.0, 1.0):
        put(side & (y < 0) & (x > xs) & (x < xs + 0.022) & (z > 0.42) & (z < 1.8), SEAM)
    put(side & (y < 0) & (x > -1.3) & (x < 0.0) & (z > 1.075) & (z < 1.1), SEAM)
    put(side & (x > 1.16) & (x < 1.3) & (z > 0.95) & (z < 0.99), CHROME)
    put(side & (y < 0) & (x > 0.06) & (x < 0.22) & (z > 0.93) & (z < 0.97), CHROME)
    put(side & (x > 1.78) & (x < 1.86) & (z > 0.72) & (z < 0.78), AMBER)
    put(side & (y < 0) & (x > -1.55) & (x < -1.4) & (z > 0.72) & (z < 0.84), BODY * 0.72)
    # Paso de rueda: borde interior oscuro
    for wx in (WX, -WX):
        put(b & (np.hypot(x - wx, z - WZ) < ARCH_R + 0.015) & (ay < 0.9), BLACK)
    # Parabrisas
    put(b & (nx > 0.45) & (nz > 0.2) & rbox(y, z, -0.8, 0.8, 1.08, 1.78, 0.1), GLASS)
    put(b & (nx > 0.45) & (nz > 0.2) & (z > 1.5) & (z < 1.72) & (y > 0.3) & (y < 0.5), GLASS_HI)
    put(b & (nx > 0.45) & (nz > 0.2) & (z > 1.095) & (z < 1.125) & (ay > 0.06) & (ay < 0.66), BLACK)
    # Frontal: rejilla con láminas, logo VW, faros con aro cromado, intermitentes
    fz = front & (z < 1.05)
    put(fz & (ay < 0.55) & (z > 0.76) & (z < 0.94), BLACK)
    put(fz & (ay < 0.55) & (np.abs(z - 0.79) < 0.006) | fz & (ay < 0.55) & (np.abs(z - 0.91) < 0.006), SEAM)
    put(fz & (ay < 0.75) & (z > 0.6) & (z < 0.7), BLACK)
    put(fz & disc(y, z, 0, 0.85, 0.085), CHROME)
    put(fz & disc(y, z, 0, 0.85, 0.062), BODY)
    put(fz & (np.abs(np.abs(y) - (0.85 - z) * 0.45) < 0.008) & (z > 0.8) & (z < 0.9), CHROME)
    for s in (1, -1):
        put(fz & disc(y, z, 0.72 * s, 0.85, 0.125), CHROME)
        put(fz & disc(y, z, 0.72 * s, 0.85, 0.095), LENS)
        put(fz & disc(y, z, 0.72 * s + 0.03, 0.88, 0.025), WHITE)
        put(fz & (ay > 0.64) & (ay < 0.84) & (np.sign(y) == s) & (z > 0.6) & (z < 0.7), AMBER)
    # Trasera: luneta, pilotos (intermitente, freno, marcha atrás), matrícula, logo, tapa motor
    put(rear & rbox(y, z, -0.72, 0.72, 1.12, 1.72, 0.08), GLASS)
    put(rear & (ay > 0.5) & (ay < 0.86) & (z > 0.58) & (z < 0.74), RED)
    put(rear & (ay > 0.74) & (ay < 0.86) & (z > 0.58) & (z < 0.74), AMBER)
    put(rear & (ay > 0.5) & (ay < 0.58) & (z > 0.58) & (z < 0.74), WHITE)
    put(rear & (ay < 0.3) & (z > 0.6) & (z < 0.72), PLATE)
    put(rear & disc(y, z, 0, 0.9, 0.06), CHROME)
    put(rear & disc(y, z, 0, 0.9, 0.044), BODY)
    put(rear & (ay < 0.86) & ((np.abs(z - 0.99) < 0.01) | (np.abs(z - 0.81) < 0.01)), SEAM)
    # Otras piezas
    put(part == "chassis", BLACK)
    for p in ("bumper_f", "bumper_r", "mirror"):
        put(part == p, BUMPER)
    bf = (part == "bumper_f") & (nx > 0.6)
    put(bf & (ay < 0.27) & (z > 0.36) & (z < 0.48), PLATE)
    put(bf & (y > 0.22) & (y < 0.27) & (z > 0.36) & (z < 0.48), EU)
    for k in range(6):
        yy = 0.16 - k * 0.07
        put(bf & (y > yy - 0.04) & (y < yy) & (z > 0.39) & (z < 0.45), SEAM)
    put(part == "hatch", ROOF)
    put((part == "hatch") & (nz > 0.7), HATCH)
    put(part == "rail", CHROME)
    put(part == "exhaust", EXHAUST)
    # Ruedas: neumático con dibujo, llanta de aleación de 5 agujeros, tapacubos
    wm = part == "wheel"
    wx = np.where(x > 0, WX, -WX)
    rr = np.hypot(x - wx, z - WZ)
    ang = np.arctan2(z - WZ, x - wx)
    put(wm, TYRE)
    put(wm & (rr > WR - 0.04) & (np.sin(ang * 24) > 0), TYRE_WALL)
    face = wm & (np.abs(ny) > 0.7) & (ay > WY)
    put(face & (rr < 0.22), RIM)
    hole = ((ang * 5 / (2 * math.pi)) % 1.0)
    put(face & (rr > 0.08) & (rr < 0.18) & (hole > 0.18) & (hole < 0.78), RIM_DARK)
    put(face & (rr < 0.06), CHROME)
    put(face & (rr < 0.03), RIM_DARK)
    return c


def main():
    out = sys.argv[1]
    step = float(sys.argv[2]) if len(sys.argv) > 2 else 0.02
    xs = np.arange(-2.6, 2.6, step)
    ys = np.arange(-1.15, 1.15, step)
    zs = np.arange(0.0, 2.6, step)
    X, Y, Z = np.meshgrid(xs, ys, zs, indexing="ij")
    P = parts(X.ravel(), Y.ravel(), Z.ravel())
    names = list(P)
    stack = np.stack([P[k] for k in names])
    field = stack.min(axis=0).reshape(X.shape)
    verts, faces, normals, _ = marching_cubes(field, 0.0, spacing=(step, step, step))
    verts += (xs[0], ys[0], zs[0])
    # Normales hacia fuera: el campo crece hacia fuera, skimage las da hacia abajo del gradiente
    if np.mean(normals[:, 2][verts[:, 2] > 2.3]) < 0:
        normals = -normals
    cen = verts[faces].mean(axis=1)
    fn = normals[faces].mean(axis=1)
    fn /= np.linalg.norm(fn, axis=1, keepdims=True) + 1e-9
    Pc = parts(cen[:, 0], cen[:, 1], cen[:, 2])
    part = np.array(names)[np.argmin(np.stack([Pc[k] for k in names]), axis=0)]
    col = paint(part, cen[:, 0], cen[:, 1], cen[:, 2], fn)
    v = verts[faces]               # (F, 3, 3)
    nv = normals[faces]
    cv = np.repeat(col[:, None, :], 3, axis=1)
    g = lambda a: np.stack([a[..., 1], a[..., 2], a[..., 0]], axis=-1)  # a ejes de Godot
    data = np.concatenate([g(v), g(nv), cv], axis=-1).astype(np.float32)
    data.tofile(out)
    print(len(faces), "triángulos ->", out)


if __name__ == "__main__":
    main()
