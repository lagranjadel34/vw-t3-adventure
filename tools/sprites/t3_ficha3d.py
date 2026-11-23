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
GLASS_DARK = rgb(52, 63, 70)        # ventana lateral trasera, oscurecida
GLASS_DARK_HI = rgb(84, 98, 104)
G = 0.019    # recorte de cada cristal por lado: 5 px de la ficha (130 px/m) entre los dos lados
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
HUB = rgb(150, 160, 163)
HUB_DARK = rgb(120, 128, 130)
HATCH = rgb(76, 75, 80)
SKY = rgb(173, 194, 199)
EXHAUST = rgb(96, 96, 98)

# Medidas (m), ejes: x adelante, y izquierda, z arriba; suelo en z = 0
X_FRONT, X_REAR = 2.30, -2.13
HW = 0.92
Z_SILL = 0.40
Z_CREASE = 1.12      # moldura (altura de las manetas); por encima los costados se cierran
Z_WIN0, Z_WIN1 = 1.37, 1.84
Z_GUTTER = 1.89
Z_TOP = 2.33
WX, WZ, WR, WY, WHW = 1.23, 0.33, 0.33, 0.755, 0.125   # rueda de 0,25 m de ancho (vista trasera)
ARCH_R = 0.45
ROUND = 0.09

# Contorno lateral sacado píxel a píxel de la ficha (130 px/m, suelo y = 383, x = 0 entre ejes).
# La trasera no es vertical: se inclina hacia delante desde la moldura hasta el techo alto.
SIDE = [(-2.08, Z_SILL), (2.22, Z_SILL), (2.25, 0.62), (2.27, 0.70), (2.30, 0.97), (2.30, 1.08), (2.26, 1.24),
        (1.68, 1.93), (1.58, 2.01), (1.45, 2.08), (1.19, 2.17), (0.96, 2.24), (0.81, 2.28), (0.58, Z_TOP),
        (-0.35, Z_TOP), (-0.65, 2.31), (-1.12, 2.29), (-1.50, 2.27), (-1.585, 2.24), (-1.65, 2.16),
        (-1.71, 2.08), (-1.79, 1.93), (-1.88, 1.78), (-1.95, 1.62), (-2.02, 1.47), (-2.08, 1.32),
        (-2.12, 1.20), (-2.13, 1.08), (-2.11, 0.93), (-2.08, 0.78), (-2.06, 0.62)]
# Sección (y, z) medida en la trasera de la ficha: costados que se cierran por encima de la moldura,
# canalón con reborde y techo alto en trapecio (más estrecho arriba) con esquinas suaves.
# Medido en la trasera de la ficha (129 px/m): 0,92 abajo, 0,72 en el canalón, techo de ±0,40 arriba.
# Techo alto sin escalón ni ángulos rectos: el contorno de la trasera de la ficha, punto a punto.
_R = [(HW, Z_SILL), (HW, 1.06), (0.89, Z_CREASE + 0.02), (0.80, 1.5), (0.72, Z_WIN1), (0.69, 1.90),
      (0.66, 1.98), (0.62, 2.07), (0.60, 2.14), (0.56, 2.21), (0.50, 2.27), (0.42, 2.31), (0.30, Z_TOP)]
FRONT = _R + [(-y, z) for y, z in reversed(_R)]
CX = (X_FRONT + X_REAR) / 2
HX = (X_FRONT - X_REAR) / 2 + 0.03

# Lunas laterales medidas en la ficha (x, z), por dentro de la goma. La trasera tiene el canto
# de atrás inclinado como el pilar; la de la puerta, el de delante inclinado como el parabrisas.
WINDOWS = (
    [(-1.555, 1.385), (-0.57, 1.385), (-0.57, 1.825), (-1.47, 1.825)],
    [(-0.41, 1.385), (0.625, 1.385), (0.625, 1.825), (-0.41, 1.825)],
    [(0.875, 1.40), (2.06, 1.40), (1.74, 1.80), (0.875, 1.80)],
)
MULLION_X, MULLION_Z = 0.104, 1.615          # cruz de la ventana del medio
VENT = ((1.466, 1.40), (1.712, 1.80))        # junta inclinada del cristal de la puerta


def inset(poly, r):
    """Encoge un polígono convexo (antihorario) r metros hacia dentro."""
    n = len(poly)
    lines = []
    for i in range(n):
        (x0, z0), (x1, z1) = poly[i], poly[(i + 1) % n]
        dx, dz = x1 - x0, z1 - z0
        L = math.hypot(dx, dz)
        nx, nz = -dz / L, dx / L          # normal hacia dentro (antihorario)
        lines.append(((x0 + nx * r, z0 + nz * r), (dx, dz)))
    out = []
    for i in range(n):
        (p, d), (q, e) = lines[i - 1], lines[i]
        den = d[0] * e[1] - d[1] * e[0]
        t = ((q[0] - p[0]) * e[1] - (q[1] - p[1]) * e[0]) / den
        out.append((p[0] + d[0] * t, p[1] + d[1] * t))
    return out


def rpoly(a, b, poly, r, grow=0.0):
    """Polígono con esquinas redondeadas de radio r (y agrandado grow)."""
    return sd_poly(a, b, inset(poly, r)) < r + grow


def parts(x, y, z):
    body = smax(smax(sd_poly(x, z, SIDE), sd_round_rect(x - CX, y, HX, HW, 0.3), ROUND),
                sd_poly(y, z, FRONT), ROUND)
    for wx in (WX, -WX):
        arch = np.maximum(np.hypot(x - wx, z - WZ) - ARCH_R, 0.62 - np.abs(y))
        body = smax(body, -arch, 0.03)
    P = {"body": body}
    # Moldura de las manetas y moldura negra baja, en relieve
    rub = sd_box(x, y, z, (CX, 0, Z_CREASE), (HX - 0.04, HW + 0.012, 0.018), 0.012)
    low = sd_box(x, y, z, (CX, 0, 0.6), (HX - 0.05, HW + 0.012, 0.035), 0.012)
    for wx in (WX, -WX):  # se cortan en los pasos de rueda
        cut = np.hypot(x - wx, z - WZ) - ARCH_R - 0.02
        low = np.maximum(low, -cut)
    plan = sd_round_rect(x - CX, y, HX + 0.012, HW + 0.012, 0.3)   # las molduras siguen las esquinas
    rub = np.maximum(rub, plan)
    low = np.maximum(low, plan)
    P["rub"] = rub
    P["molding"] = low
    P["bumper_f"] = sd_box(x, y, z, (2.31, 0, 0.53), (0.08, 0.95, 0.11), 0.045)
    P["bumper_r"] = sd_box(x, y, z, (-2.15, 0, 0.47), (0.08, 0.95, 0.085), 0.045)
    w = None
    for wx in (WX, -WX):
        for s in (1, -1):
            d = sd_cyl_y(x, y, z, wx, WY * s, WZ, WR, WHW, 0.09)
            w = d if w is None else np.minimum(w, d)
    P["wheel"] = w
    m = None
    for s in (1, -1):
        d = sd_box(x, y, z, (1.55, 0.99 * s, 1.48), (0.035, 0.05, 0.13), 0.025)
        d = np.minimum(d, sd_box(x, y, z, (1.58, 0.87 * s, 1.40), (0.015, 0.12, 0.015), 0.008))
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
    put(hs & rbox(x, z, -0.34 + G, 0.53 - G, 2.03 + G, 2.27 - G, 0.05), RUBBER)
    put(hs & rbox(x, z, -0.31 + G, 0.50 - G, 2.06 + G, 2.24 - G, 0.04), GLASS_HI)
    sky = b & (nx > 0.2) & (nz > 0.4) & (z > 2.0)
    put(sky & rbox(x, y, 1.0 + G, 1.36 - G, -0.37 + G, 0.37 - G, 0.11), RUBBER)
    put(sky & rbox(x, y, 1.03 + G, 1.33 - G, -0.34 + G, 0.34 - G, 0.09), SKY)
    # Ventanas laterales: goma negra, luna, reflejo
    for i, w in enumerate(WINDOWS):
        x0, x1 = min(p[0] for p in w), max(p[0] for p in w)
        glass, hi = (GLASS_DARK, GLASS_DARK_HI) if i == 0 else (GLASS, GLASS_HI)
        put(side & rpoly(x, z, w, 0.06, grow=0.035 - G), RUBBER)
        put(side & rpoly(x, z, w, 0.06, grow=-G), glass)
        d = (x - x0) / (x1 - x0) + (z - Z_WIN0) / (Z_WIN1 - Z_WIN0) * 0.5 * np.sign(y)
        put(side & (np.abs(d - 0.75) < 0.12) & rpoly(x, z, w, 0.06, grow=-0.02 - G), hi)
    w1 = WINDOWS[1]
    put(side & (np.abs(x - MULLION_X) < 0.011) & (z > w1[0][1]) & (z < w1[2][1]), RUBBER)
    put(side & (np.abs(z - MULLION_Z) < 0.011) & (x > w1[0][0]) & (x < w1[1][0]), RUBBER)
    (vx0, vz0), (vx1, vz1) = VENT
    vx = vx0 + (z - vz0) * (vx1 - vx0) / (vz1 - vz0)
    put(side & (np.abs(x - vx) < 0.012) & (z > vz0) & (z < vz1), RUBBER)
    # Rejilla del pilar trasero: panel oscuro inclinado con lamas
    louv = side & (z > 1.36) & (z < 1.76) & (x > -2.04 + (z - 1.24) * 0.426) & (x < -1.63)
    put(louv, RUBBER)
    put(louv & (((z - 1.36) % 0.05) < 0.02), UPPER * 0.62)
    # Juntas: puerta delantera, corredera (derecha, y < 0) y paneles; manetas; tapón
    put(side & (np.abs(x - 0.74) < 0.01) & (z > 0.45) & (z < Z_GUTTER), SEAM)
    put(side & (np.abs(x - 2.12) < 0.01) & (z > 0.45) & (z < Z_CREASE), SEAM)
    for xs in (-0.47, -1.62):
        put(side & (y > 0) & (np.abs(x - xs) < 0.01) & (z > 0.45) & (z < Z_CREASE), SEAM)
    put(side & (y < 0) & (np.abs(x + 0.47) < 0.01) & (z > 0.45) & (z < Z_GUTTER), SEAM)
    put(side & (y < 0) & (np.abs(z - 1.33) < 0.01) & (x > -1.5) & (x < -0.47), SEAM)   # carril corredera
    put(side & (x > 0.85) & (x < 1.0) & (z > 1.21) & (z < 1.25), RUB)
    put(side & (y < 0) & (x > 0.52) & (x < 0.66) & (z > 1.21) & (z < 1.25), RUB)
    put(side & (y > 0) & disc(x, z, 0.85, 0.72, 0.045), SEAM)
    put(side & (y > 0) & disc(x, z, 0.85, 0.72, 0.03), LOWER)
    put(side & (x > 2.135) & (x < 2.185) & (z > 0.71) & (z < 0.76), AMBER)
    for wx in (WX, -WX):
        put(b & (np.hypot(x - wx, z - WZ) < ARCH_R + 0.012) & (ay < 0.93), BLACK)
    # Parabrisas con limpias
    ws = b & (nx > 0.4) & (nz > 0.25)
    put(ws & rbox(y, z, -0.84 + G, 0.84 - G, 1.27 + G, 1.88 - G, 0.1), RUBBER)
    put(ws & rbox(y, z, -0.81 + G, 0.81 - G, 1.29 + G, 1.86 - G, 0.08), GLASS)
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
        put(fz & (np.sign(y) == s) & (ay > 0.62) & (ay < 0.79) & (z > 0.68) & (z < 0.78), AMBER)
    # Trasera: luneta, pilotos, matrícula, logo VW y placa DEHLER, tapa del motor
    put(rear & rbox(y, z, -0.76 + G, 0.76 - G, Z_WIN0 - 0.08 + G, Z_WIN1 - G, 0.1), RUBBER)
    put(rear & rbox(y, z, -0.73 + G, 0.73 - G, Z_WIN0 - 0.05 + G, Z_WIN1 - 0.03 - G, 0.08), GLASS)
    put(rear & (np.abs(-y * 0.8 + (z - 1.55) - 0.3) < 0.07) & rbox(y, z, -0.7, 0.7, Z_WIN0 - 0.02, Z_WIN1 - 0.06, 0.07),
        GLASS_HI)
    put(rear & (ay > 0.48) & (ay < 0.84) & (z > 0.61) & (z < 0.77), RED)
    put(rear & (ay > 0.69) & (ay < 0.82) & (z > 0.725) & (z < 0.765), AMBER)
    put(rear & (ay > 0.48) & (ay < 0.66) & (z > 0.72) & (z < 0.77), WHITE)
    put(rear & (ay > 0.48) & (ay < 0.84) & (z > 0.61) & (z < 0.77)
        & ((np.abs(z - 0.72) < 0.006) | (np.abs(np.abs(y) - 0.66) < 0.006)), RUBBER)
    put(rear & (ay < 0.25) & (z > 0.61) & (z < 0.72), PLATE)
    put(rear & disc(y, z, 0, 1.0, 0.075), CHROME)
    put(rear & disc(y, z, 0, 1.0, 0.056), LOWER)
    put(rear & (y < -0.28) & (y > -0.62) & (z > 0.94) & (z < 1.01), RUBBER)
    for k in range(6):
        yy = -0.31 - k * 0.05
        put(rear & (y < yy) & (y > yy - 0.03) & (z > 0.955) & (z < 0.995), CHROME)
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
    put(face & (rr < 0.235), STEEL)
    put(face & (rr < 0.19), HUB)
    put(face & (rr < 0.135) & (rr > 0.12), HUB_DARK)
    put(face & (rr < 0.08) & (rr > 0.07), HUB_DARK)
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
