"""VW T3 Dehler Profi en 3D medida sobre la ficha de Ara `graficos/fichas-ara/dehler-profi-1983.png`
(vista lateral a ~130 px/m, ruedas a ±1,23 m). Gris azulado en dos tonos: chapa baja pizarra,
franja alta clara hasta el canalón y techo alto pizarra con ventana lateral, escotilla y claraboya.
Ventanas con goma negra y esquinas redondas, moldura a la altura de las manetas, llantas de chapa
con tapacubos, dos rejillas negras con faros redondos y parachoques negros envolventes.

Mismo método y formato de salida que t3_sdf.py (SDF + marching cubes, binario para el prototipo).
Uso: python3 t3_ficha3d.py salida.bin [paso_m]"""
import math
import sys

import numpy as np
from skimage.measure import marching_cubes

from t3_sdf import sd_poly, sd_round_rect, sd_box, sd_cyl_y, sd_cyl_x, smax, arc, rbox, disc


def rgb(*c):
    return np.array(c) / 255


# Paleta muestreada de la ficha
LOWER = rgb(86, 103, 113)
UPPER = rgb(128, 143, 150)
HITOP = rgb(92, 109, 118)
ROOF_TOP = rgb(150, 164, 168)   # techo visto desde arriba (vista superior de la ficha)
RUB = rgb(50, 53, 58)
RUBBER = rgb(18, 26, 32)
GLASS = rgb(112, 130, 137)
GLASS_HI = rgb(169, 193, 197)
SEAM = rgb(48, 60, 68)
BLACK = rgb(32, 34, 38)
BUMPER = rgb(52, 54, 57)
CHROME = rgb(190, 198, 200)
LENS = rgb(232, 232, 216)
AMBER = rgb(222, 132, 40)
RED = rgb(150, 34, 32)
WHITE = rgb(232, 234, 230)
PLATE = rgb(230, 233, 234)
EU = rgb(40, 70, 160)
TYRE = rgb(36, 37, 40)
TYRE_WALL = rgb(50, 51, 54)
STEEL = rgb(40, 42, 46)
HUB = rgb(178, 188, 189)
HUB_DARK = rgb(120, 128, 130)
HATCH = rgb(76, 75, 80)
SKY = rgb(173, 194, 199)
EXHAUST = rgb(96, 96, 98)

# Medidas (m), ejes: x adelante, y izquierda, z arriba; suelo en z = 0
X_FRONT, X_REAR = 2.27, -2.12
HW = 0.92
Z_SILL = 0.40
Z_CREASE = 1.18      # moldura (altura de las manetas)
Z_WIN0, Z_WIN1 = 1.37, 1.84
Z_GUTTER = 1.89
Z_TOP = 2.32
WX, WZ, WR, WY, WHW = 1.23, 0.33, 0.33, 0.80, 0.105
ARCH_R = 0.45
ROUND = 0.06

SIDE = ([(X_REAR, Z_SILL), (2.24, Z_SILL), (2.28, 0.62), (2.29, 1.12), (2.26, 1.24), (1.70, 1.92),
         (1.40, 2.07), (1.08, 2.20), (0.80, 2.28), (0.55, Z_TOP), (-1.58, Z_TOP), (-1.76, 2.29),
         (-1.92, 2.18), (-2.02, 2.02), (-2.07, 1.85), (X_REAR, 1.2)])
_HT = 0.84   # medio ancho del techo alto (más estrecho que la caja, con hombros redondos)
FRONT = ([(-HW, Z_SILL), (HW, Z_SILL), (HW, Z_CREASE), (0.90, Z_WIN0), (0.865, Z_WIN1), (0.875, Z_GUTTER),
          (_HT, Z_GUTTER + 0.03), (_HT, 2.06)]
         + arc(_HT - 0.26, 2.06, 0.26, 0, math.pi / 2)[1:]
         + [(-x, z) for x, z in arc(_HT - 0.26, 2.06, 0.26, math.pi / 2, 0)][:-1]
         + [(-_HT, 2.06), (-_HT, Z_GUTTER + 0.03), (-0.875, Z_GUTTER), (-0.865, Z_WIN1), (-0.90, Z_WIN0),
            (-HW, Z_CREASE)])
CX = (X_FRONT + X_REAR) / 2
HX = (X_FRONT - X_REAR) / 2 + 0.03

# Ventanas laterales (x0, x1); la del medio va partida en cuatro
WINDOWS = ((-1.54, -0.54), (-0.42, 0.58), (0.85, 1.80))


def parts(x, y, z):
    body = smax(smax(sd_poly(x, z, SIDE), sd_round_rect(x - CX, y, HX, HW, 0.2), ROUND),
                sd_poly(y, z, FRONT), ROUND)
    for wx in (WX, -WX):
        arch = np.maximum(np.hypot(x - wx, z - WZ) - ARCH_R, 0.62 - np.abs(y))
        body = smax(body, -arch, 0.03)
    P = {"body": body}
    P["chassis"] = sd_box(x, y, z, (0.05, 0, 0.3), (2.0, 0.72, 0.12), 0.03)
    # Moldura de las manetas y moldura negra baja, en relieve
    rub = sd_box(x, y, z, (CX, 0, Z_CREASE), (HX - 0.04, HW + 0.012, 0.018), 0.012)
    low = sd_box(x, y, z, (CX, 0, 0.6), (HX - 0.05, HW + 0.012, 0.035), 0.012)
    for wx in (WX, -WX):  # se cortan en los pasos de rueda
        cut = np.hypot(x - wx, z - WZ) - ARCH_R - 0.02
        low = np.maximum(low, -cut)
    P["rub"] = rub
    P["molding"] = low
    P["bumper_f"] = sd_box(x, y, z, (2.31, 0, 0.53), (0.08, 0.95, 0.11), 0.045)
    P["bumper_r"] = sd_box(x, y, z, (-2.15, 0, 0.51), (0.08, 0.95, 0.10), 0.045)
    w = None
    for wx in (WX, -WX):
        for s in (1, -1):
            d = sd_cyl_y(x, y, z, wx, WY * s, WZ, WR, WHW, 0.07)
            w = d if w is None else np.minimum(w, d)
    P["wheel"] = w
    m = None
    for s in (1, -1):
        d = sd_box(x, y, z, (1.55, 0.99 * s, 1.48), (0.035, 0.05, 0.13), 0.025)
        d = np.minimum(d, sd_box(x, y, z, (1.58, 0.94 * s, 1.40), (0.015, 0.05, 0.015), 0.008))
        m = d if m is None else np.minimum(m, d)
    P["mirror"] = m
    P["hatch"] = sd_box(x, y, z, (0.18, 0, Z_TOP + 0.03), (0.29, 0.29, 0.06), 0.03)
    P["exhaust"] = sd_cyl_x(x, y, z, -2.26, -2.05, 0.5, 0.25, 0.035)
    return P


def paint(part, x, y, z, n):
    N = len(x)
    c = np.tile(LOWER, (N, 1))
    nx, ny, nz = n[:, 0], n[:, 1], n[:, 2]
    ay = np.abs(y)

    def put(mask, col):
        c[mask] = col

    b = part == "body"
    side = b & (np.abs(ny) > 0.5)
    front = b & (nx > 0.55)
    rear = b & (nx < -0.55)
    top = b & (nz > 0.6)
    # Dos tonos: franja clara de la moldura al canalón; techo alto pizarra
    put(b & (z > Z_CREASE) & (z < Z_GUTTER), UPPER)
    put(b & (z >= Z_GUTTER), HITOP)
    put(top & (z > Z_TOP - 0.04), ROOF_TOP)
    put(b & ~top & (z >= Z_GUTTER) & (z < Z_GUTTER + 0.035), SEAM)
    # Ventana lateral del techo alto, claraboya delantera
    hs = b & (np.abs(ny) > 0.6) & (z > 1.95)
    put(hs & rbox(x, z, -0.34, 0.53, 2.03, 2.27, 0.05), RUBBER)
    put(hs & rbox(x, z, -0.31, 0.50, 2.06, 2.24, 0.04), GLASS_HI)
    put(b & (nx > 0.2) & (nz > 0.4) & (z > 2.0) & rbox(x, y, 1.0, 1.36, -0.37, 0.37, 0.05), RUBBER)
    put(b & (nx > 0.2) & (nz > 0.4) & (z > 2.0) & rbox(x, y, 1.03, 1.33, -0.34, 0.34, 0.04), SKY)
    # Ventanas laterales: goma negra, luna, reflejo
    for x0, x1 in WINDOWS:
        put(side & rbox(x, z, x0 - 0.03, x1 + 0.03, Z_WIN0 - 0.03, Z_WIN1 + 0.03, 0.08), RUBBER)
        put(side & rbox(x, z, x0, x1, Z_WIN0, Z_WIN1, 0.06), GLASS)
        d = (x - x0) / (x1 - x0) + (z - Z_WIN0) / (Z_WIN1 - Z_WIN0) * 0.5 * np.sign(y)
        put(side & (np.abs(d - 0.75) < 0.12) & rbox(x, z, x0 + 0.02, x1 - 0.02, Z_WIN0 + 0.02, Z_WIN1 - 0.02, 0.05),
            GLASS_HI)
    put(side & (np.abs(x - 0.08) < 0.012) & (z > Z_WIN0) & (z < Z_WIN1), RUBBER)
    put(side & (np.abs(z - 1.60) < 0.012) & (x > -0.42) & (x < 0.58), RUBBER)
    put(side & (np.abs(x - 1.52) < 0.012) & (z > Z_WIN0) & (z < Z_WIN1), RUBBER)   # ventanilla de la puerta
    # Rejilla del pilar trasero (lamas inclinadas)
    for k in range(7):
        z0 = 1.42 + k * 0.05
        put(side & (z > z0) & (z < z0 + 0.025) & (x > -1.94 + (z - 1.42) * 0.12) & (x < -1.66), RUBBER)
    # Juntas: puerta delantera, corredera (derecha, y < 0) y paneles; manetas; tapón
    for xs in (0.74, 1.98):
        put(side & (np.abs(x - xs) < 0.01) & (z > 0.45) & (z < Z_GUTTER), SEAM)
    for xs in (-0.47, -1.62):
        put(side & (y > 0) & (np.abs(x - xs) < 0.01) & (z > 0.45) & (z < Z_CREASE), SEAM)
    put(side & (y < 0) & (np.abs(x + 0.47) < 0.01) & (z > 0.45) & (z < Z_GUTTER), SEAM)
    put(side & (y < 0) & (np.abs(z - 1.33) < 0.01) & (x > -1.5) & (x < -0.47), SEAM)   # carril corredera
    put(side & (x > 0.85) & (x < 1.0) & (z > 1.21) & (z < 1.25), RUB)
    put(side & (y < 0) & (x > 0.52) & (x < 0.66) & (z > 1.21) & (z < 1.25), RUB)
    put(side & (y > 0) & disc(x, z, 0.85, 0.72, 0.045), SEAM)
    put(side & (y > 0) & disc(x, z, 0.85, 0.72, 0.03), LOWER)
    put(side & (x > 2.12) & (x < 2.2) & (z > 0.7) & (z < 0.77), AMBER)
    for wx in (WX, -WX):
        put(b & (np.hypot(x - wx, z - WZ) < ARCH_R + 0.012) & (ay < 0.93), BLACK)
    # Parabrisas con limpias
    ws = b & (nx > 0.4) & (nz > 0.25)
    put(ws & rbox(y, z, -0.84, 0.84, 1.27, 1.88, 0.1), RUBBER)
    put(ws & rbox(y, z, -0.81, 0.81, 1.29, 1.86, 0.08), GLASS)
    put(ws & (np.abs(y * 0.8 + (z - 1.57) - 0.35) < 0.07) & rbox(y, z, -0.78, 0.78, 1.32, 1.83, 0.07), GLASS_HI)
    put(ws & (z > 1.3) & (z < 1.33) & (ay > 0.06) & (ay < 0.68), BLACK)
    # Frontal: rejilla alta con logo y faros redondos, rejilla baja, intermitentes
    fz = front & (z < 1.26)
    put(fz & (ay < 0.62) & (z > 0.92) & (z < 1.09), BLACK)
    for zz in (0.96, 1.0, 1.04):
        put(fz & (ay < 0.6) & (np.abs(z - zz) < 0.005), RUB)
    put(fz & (ay < 0.55) & (z > 0.66) & (z < 0.80), BLACK)
    for zz in (0.7, 0.74):
        put(fz & (ay < 0.53) & (np.abs(z - zz) < 0.005), RUB)
    put(fz & disc(y, z, 0, 1.005, 0.08), CHROME)
    put(fz & disc(y, z, 0, 1.005, 0.06), BLACK)
    put(fz & (np.abs(ay - (1.06 - z) * 0.45) < 0.008) & (z > 0.96) & (z < 1.05), CHROME)
    for s in (1, -1):
        put(fz & disc(y, z, 0.74 * s, 1.0, 0.12), CHROME)
        put(fz & disc(y, z, 0.74 * s, 1.0, 0.095), LENS)
        put(fz & disc(y, z, 0.74 * s + 0.03, 1.03, 0.025), WHITE)
        put(fz & (np.sign(y) == s) & (ay > 0.62) & (ay < 0.86) & (z > 0.66) & (z < 0.80), AMBER)
    # Trasera: luneta, pilotos, matrícula, logo VW y placa DEHLER, tapa del motor
    put(rear & rbox(y, z, -0.76, 0.76, Z_WIN0 - 0.08, Z_WIN1 + 0.0, 0.1), RUBBER)
    put(rear & rbox(y, z, -0.73, 0.73, Z_WIN0 - 0.05, Z_WIN1 - 0.03, 0.08), GLASS)
    put(rear & (np.abs(-y * 0.8 + (z - 1.55) - 0.3) < 0.07) & rbox(y, z, -0.7, 0.7, Z_WIN0 - 0.02, Z_WIN1 - 0.06, 0.07),
        GLASS_HI)
    put(rear & (ay > 0.46) & (ay < 0.84) & (z > 0.66) & (z < 0.82), RED)
    put(rear & (ay > 0.74) & (ay < 0.84) & (z > 0.66) & (z < 0.82), AMBER)
    put(rear & (ay > 0.46) & (ay < 0.54) & (z > 0.66) & (z < 0.82), WHITE)
    put(rear & (ay < 0.27) & (z > 0.63) & (z < 0.74), PLATE)
    put(rear & disc(y, z, 0, 1.08, 0.065), CHROME)
    put(rear & disc(y, z, 0, 1.08, 0.048), LOWER)
    put(rear & (y > 0.28) & (y < 0.6) & (z > 1.05) & (z < 1.11), RUBBER)
    for k in range(6):
        yy = 0.31 + k * 0.05
        put(rear & (y > yy) & (y < yy + 0.03) & (z > 1.065) & (z < 1.095), CHROME)
    put(rear & (ay < 0.88) & ((np.abs(z - 1.2) < 0.008) | (np.abs(z - 0.86) < 0.008)), SEAM)
    # Otras piezas
    put(part == "chassis", BLACK)
    put(part == "rub", RUB)
    put(part == "molding", BLACK)
    for p in ("bumper_f", "bumper_r", "mirror"):
        put(part == p, BUMPER)
    put((part == "mirror") & (np.abs(ny) > 0.5) & (z > 1.37) & (z < 1.59) & (nx < 0.5), rgb(70, 82, 88))
    bf = (part == "bumper_f") & (nx > 0.6)
    put(bf & (ay < 0.26) & (z > 0.47) & (z < 0.59), PLATE)
    put(bf & (y > 0.21) & (y < 0.26) & (z > 0.47) & (z < 0.59), EU)
    for k in range(6):
        yy = 0.15 - k * 0.065
        put(bf & (y > yy - 0.04) & (y < yy) & (z > 0.5) & (z < 0.56), SEAM)
    put(part == "hatch", HITOP)
    put((part == "hatch") & (nz > 0.7), HATCH)
    put(part == "exhaust", EXHAUST)
    # Ruedas: neumático, llanta de chapa negra y tapacubos plateado
    wm = part == "wheel"
    wx = np.where(x > 0, WX, -WX)
    rr = np.hypot(x - wx, z - WZ)
    ang = np.arctan2(z - WZ, x - wx)
    put(wm, TYRE)
    put(wm & (rr > WR - 0.035) & (np.sin(ang * 28) > 0), TYRE_WALL)
    face = wm & (np.abs(ny) > 0.7) & (ay > WY)
    put(face & (rr < 0.22), STEEL)
    put(face & (rr < 0.17), HUB)
    put(face & (rr < 0.11) & (rr > 0.095), HUB_DARK)
    put(face & (rr < 0.035), HUB_DARK)
    return c


def main():
    out = sys.argv[1]
    step = float(sys.argv[2]) if len(sys.argv) > 2 else 0.02
    xs = np.arange(-2.45, 2.55, step)
    ys = np.arange(-1.15, 1.15, step)
    zs = np.arange(-0.05, 2.5, step)
    X, Y, Z = np.meshgrid(xs, ys, zs, indexing="ij")
    P = parts(X.ravel(), Y.ravel(), Z.ravel())
    names = list(P)
    field = np.stack([P[k] for k in names]).min(axis=0).reshape(X.shape)
    verts, faces, normals, _ = marching_cubes(field, 0.0, spacing=(step, step, step))
    verts += (xs[0], ys[0], zs[0])
    if np.mean(normals[:, 2][verts[:, 2] > Z_TOP - 0.02]) < 0:
        normals = -normals
    cen = verts[faces].mean(axis=1)
    fn = normals[faces].mean(axis=1)
    fn /= np.linalg.norm(fn, axis=1, keepdims=True) + 1e-9
    Pc = parts(cen[:, 0], cen[:, 1], cen[:, 2])
    part = np.array(names)[np.argmin(np.stack([Pc[k] for k in names]), axis=0)]
    col = paint(part, cen[:, 0], cen[:, 1], cen[:, 2], fn)
    # Centro de la furgo en el origen (para la cámara de la ficha y la física)
    verts[:, 0] -= CX
    v = verts[faces]
    nv = normals[faces]
    cv = np.repeat(col[:, None, :], 3, axis=1)
    g = lambda a: np.stack([a[..., 1], a[..., 2], a[..., 0]], axis=-1)
    np.concatenate([g(v), g(nv), cv], axis=-1).astype(np.float32).tofile(out)
    print(len(faces), "triángulos ->", out)


if __name__ == "__main__":
    main()
