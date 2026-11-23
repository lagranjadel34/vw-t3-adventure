"""VW T3 Dehler Profi en 3D medida sobre la ficha de Ara `graficos/fichas-ara/dehler-profi-1983.png`
(vista lateral a ~130 px/m, ruedas a ±1,23 m). Gris azulado en dos tonos: chapa baja pizarra,
franja alta clara hasta el canalón y techo alto pizarra con ventana lateral, escotilla y claraboya.
Ventanas con goma negra y esquinas redondas, moldura a la altura de las manetas, llantas de chapa
con tapacubos, dos rejillas negras con faros redondos y parachoques negros envolventes.

Mismo método y formato de salida que t3_sdf.py (SDF + marching cubes, binario para el prototipo).
Uso: python3 t3_ficha3d.py salida.bin [paso_m]"""
import json
import math
import sys

import numpy as np
from skimage.measure import marching_cubes

from t3_sdf import sd_poly, sd_round_rect, sd_box, sd_cyl_y, sd_cyl_x, smax, smin, arc, rbox, disc


def rgb(*c):
    return np.array(c) / 255


# Paleta muestreada de la ficha
LOWER = rgb(86, 103, 113)
UPPER = rgb(128, 143, 150)
HITOP = rgb(146, 160, 166)    # techo alto: mismo gris claro que la franja alta (ficha)
ROOF_TOP = rgb(150, 164, 168)   # techo visto desde arriba (vista superior de la ficha)
RUB = rgb(50, 53, 58)
MOLDING = rgb(70, 84, 94)      # moldura de las manetas (banda media de la ficha)
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
Z_SILL = 0.38
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
# 2026-11-23: costados más rectos y techo alto más ancho arriba (medido fila a fila en la trasera
# de la ficha) para quitar el aspecto de cono truncado.
_R = [(HW, Z_SILL), (HW, 1.06), (0.905, 1.16), (0.89, 1.30), (0.85, 1.50), (0.815, 1.65), (0.78, 1.78),
      (0.755, Z_WIN1), (0.735, 1.90), (0.70, 1.97), (0.665, 2.08), (0.61, 2.18), (0.56, 2.24),
      (0.50, 2.29), (0.42, 2.32), (0.30, Z_TOP)]
FRONT = _R + [(-y, z) for y, z in reversed(_R)]
CX = (X_FRONT + X_REAR) / 2
HX = (X_FRONT - X_REAR) / 2 + 0.03

# Lunas laterales medidas en la ficha (x, z), por dentro de la goma. La trasera tiene el canto
# de atrás inclinado como el pilar; la de la puerta, el de delante inclinado como el parabrisas.
WINDOWS = (
    [(-1.548, 1.4235), (-0.57, 1.4235), (-0.57, 1.7865), (-1.478, 1.7865)],
    [(-0.41, 1.4235), (0.625, 1.4235), (0.625, 1.7865), (-0.41, 1.7865)],
    [(0.875, 1.4385), (1.795, 1.4385), (1.62, 1.7615), (0.875, 1.7615)],   # ficha: delante 1,62 arriba / 1,87 abajo
)
# Luneta trasera: abajo igual de ancha; arriba se estrecha siguiendo el costado de la caja.
_RB, _RT = 1.28, Z_WIN1 - 0.03 - G    # ficha: luneta de 1,256 a 1,80 (menos 5 px)
_RYB = 0.73 - G
_RYT = _RYB - 0.243 * (_RT - _RB)
REAR_GLASS = [(-_RYB, _RB), (_RYB, _RB), (_RYT, _RT), (-_RYT, _RT)]
WS_SHRINK = 0.039                            # parabrisas 10 px menor (5 px por lado, ficha 129 px/m)
# Parabrisas: igual que la luneta, abajo mantiene ancho y arriba se estrecha siguiendo el costado.
_FB, _FT = 1.29 + G + WS_SHRINK, 1.86 - G - WS_SHRINK
_FYB = 0.81 - G - WS_SHRINK
_FYT = _FYB - 0.243 * (_FT - _FB)
FRONT_GLASS = [(-_FYB, _FB), (_FYB, _FB), (_FYT, _FT), (-_FYT, _FT)]
MULLION_X, MULLION_Z = 0.104, 1.605          # cruz de la ventana del medio
VENT = ((1.595, 1.4385), (1.595, 1.7615))      # junta vertical: rectángulo detrás, triángulo delante (ficha)


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


# Paragolpes: (cara exterior en x, fin de la aleta lateral en x, altura centro, media altura)
BUMPER_F = (2.29, 1.90, 0.53, 0.07)
BUMPER_R = (-2.13, -1.86, 0.45, 0.07)
BUMPER_T = 0.035          # medio grosor de la chapa
BUMPER_Y = 0.955          # costado exterior (encaja sobre la carrocería, HW = 0.92)


def bumper(x, y, z, spec):
    face, end, zc, hz = spec
    s = 1.0 if face > 0 else -1.0
    hx = 0.55
    cx = face - s * hx
    shell = np.abs(sd_round_rect(x - cx, y, hx, BUMPER_Y, 0.25)) - BUMPER_T
    shell = np.maximum(shell, s * (end - x))
    shell = np.maximum(shell, np.abs(z - zc) - hz)
    return shell - 0.012


# Entrada de aire del motor (pilar trasero, ambos lados): paralelogramo inclinado como el pilar,
# medido píxel a píxel en la ficha: abajo x -1,923..-1,754 (z 1,40), arriba -1,762..-1,600 (z 1,823).
LOUVRE = [(-1.923, 1.40), (-1.754, 1.40), (-1.600, 1.823), (-1.762, 1.823)]
LOUVRE_DEPTH = 0.02
LOUVRE_SLAT = 0.042       # paso de las lamas (10 lamas)


def parts(x, y, z):
    body = smax(smax(sd_poly(x, z, SIDE), sd_round_rect(x - CX, y, HX, HW, 0.3), ROUND),
                sd_poly(y, z, FRONT), ROUND)
    cut = np.maximum(np.maximum(sd_poly(x, z, LOUVRE), -body - LOUVRE_DEPTH), 0.5 - np.abs(y))
    body = smax(body, -cut, 0.006)
    for wx in (WX, -WX):
        arch = np.maximum(np.hypot(x - wx, z - WZ) - ARCH_R, 0.62 - np.abs(y))
        body = smax(body, -arch, 0.03)
    # Guardabarros: labio toroidal en el borde del arco que sobresale del costado.
    for wx in (WX, -WX):
        rad = np.hypot(x - wx, z - WZ)
        flare = np.hypot(rad - (ARCH_R + 0.008), np.abs(y) - HW) - 0.014
        flare = np.maximum(flare, 0.46 - z)          # solo la ceja del arco, por encima del faldón
        body = smin(body, flare, 0.02)
    P = {"body": body}
    # Moldura de las manetas y moldura negra baja, en relieve
    rub = sd_box(x, y, z, (CX, 0, 1.142), (HX - 0.04, HW + 0.012, 0.035), 0.012)
    low = sd_box(x, y, z, (CX, 0, 0.607), (HX - 0.05, HW + 0.012, 0.025), 0.01)
    for wx in (WX, -WX):  # se cortan en los pasos de rueda
        cut = np.hypot(x - wx, z - WZ) - ARCH_R - 0.02
        low = np.maximum(low, -cut)
    plan = sd_round_rect(x - CX, y, HX + 0.012, HW + 0.012, 0.3)   # las molduras siguen las esquinas
    rub = np.maximum(rub, plan)
    low = np.maximum(low, plan)
    low = np.maximum(low, np.maximum(x - 2.10, -1.95 - x))   # solo en los costados (ficha)
    P["rub"] = rub
    P["molding"] = low
    # Paragolpes finos en U: barra frontal y aletas que abrazan el costado hasta cerca del paso
    # de rueda. Pieza independiente (se podrá deformar o caer con los golpes).
    P["bumper_f"] = bumper(x, y, z, BUMPER_F)
    P["bumper_r"] = bumper(x, y, z, BUMPER_R)
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
    zs = 2.04 + np.maximum(0, -0.4 - x) * 0.1          # franja del techo alto (sube hacia atrás)
    put(side & (np.abs(z - zs) < 0.007), SEAM)
    put(side & (np.abs(z - zs + 0.035) < 0.007), UPPER * 1.12)
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
        glass, hi = (GLASS_DARK, GLASS_DARK_HI) if i < 2 else (GLASS, GLASS_HI)
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
    louv = b & (ay > 0.5) & (sd_poly(x, z, LOUVRE) < 0.004)
    put(louv, RUBBER)
    put(louv & ((((z - 1.40) % LOUVRE_SLAT) / LOUVRE_SLAT) > 0.55) & (sd_poly(x, z, LOUVRE) < -0.012),
        UPPER * 0.55)
    # Juntas: puerta delantera, corredera (derecha, y < 0) y paneles; manetas; tapón
    put(side & (np.abs(x - 0.74) < 0.01) & (z > 0.45) & (z < Z_GUTTER), SEAM)
    put(side & (np.abs(x - 2.12) < 0.01) & (z > 0.45) & (z < Z_CREASE), SEAM)
    for xs in (-0.47, -1.69):
        put(side & (y > 0) & (np.abs(x - xs) < 0.01) & (z > 0.45) & (z < Z_CREASE), SEAM)
    put(side & (y < 0) & (np.abs(x + 0.47) < 0.01) & (z > 0.45) & (z < Z_GUTTER), SEAM)
    put(side & (y < 0) & (np.abs(z - 1.33) < 0.01) & (x > -1.5) & (x < -0.47), SEAM)   # carril corredera

    put(side & (y > 0) & disc(x, z, 0.85, 0.72, 0.045), SEAM)
    put(side & (y > 0) & disc(x, z, 0.85, 0.72, 0.03), LOWER)
    put(side & (x > 2.135) & (x < 2.185) & (z > 0.71) & (z < 0.76), AMBER)
    for wx in (WX, -WX):
        put(b & (np.hypot(x - wx, z - WZ) < ARCH_R + 0.012) & (ay < 0.93), BLACK)
    # Parabrisas con limpias
    ws = b & (nx > 0.4) & (nz > 0.25)
    put(ws & rpoly(y, z, FRONT_GLASS, 0.08, grow=0.03), RUBBER)
    put(ws & rpoly(y, z, FRONT_GLASS, 0.08), GLASS)
    put(ws & (np.abs(y * 0.8 + (z - 1.57) - 0.35) < 0.07) & rpoly(y, z, FRONT_GLASS, 0.08, grow=-0.03), GLASS_HI)
    put(ws & (z > 1.3) & (z < 1.33) & (ay > 0.06) & (ay < 0.68), BLACK)
    # Frontal: rejilla alta con logo y faros redondos, rejilla baja, intermitentes
    fz = front & (z < 1.26)
    put(fz & (ay < 0.86) & (z > 0.91) & (z < 1.10), BLACK)
    for zz in (0.96, 1.0, 1.04):
        put(fz & (ay < 0.6) & (np.abs(z - zz) < 0.005), RUB)
    put(fz & (ay < 0.62) & (z > 0.66) & (z < 0.80), BLACK)
    for zz in (0.7, 0.74):
        put(fz & (ay < 0.60) & (np.abs(z - zz) < 0.005), RUB)
    put(fz & disc(y, z, 0, 1.005, 0.08), CHROME)
    put(fz & disc(y, z, 0, 1.005, 0.06), BLACK)
    put(fz & (np.abs(ay - (1.06 - z) * 0.45) < 0.008) & (z > 0.96) & (z < 1.05), CHROME)
    for s in (1, -1):
        # Faro redondo dentro de la rejilla: aro fino y cristal claro (ficha: medio alto de rejilla)
        put(fz & disc(y, z, 0.74 * s, 1.005, 0.088), CHROME)
        put(fz & disc(y, z, 0.74 * s, 1.005, 0.078), LENS)
        put(fz & disc(y, z, 0.74 * s, 1.005, 0.078) & ~disc(y, z, 0.74 * s, 1.005, 0.06), LENS * 0.88)
        put(fz & disc(y, z, 0.74 * s + 0.022, 1.027, 0.018), WHITE)
        put(fz & (np.sign(y) == s) & (ay > 0.66) & (ay < 0.80) & (z > 0.68) & (z < 0.78), AMBER)
    # Trasera: luneta, pilotos, matrícula, logo VW y placa DEHLER, tapa del motor
    put(rear & rpoly(y, z, REAR_GLASS, 0.08, grow=0.03), RUBBER)
    put(rear & rpoly(y, z, REAR_GLASS, 0.08), GLASS)
    put(rear & (np.abs(-y * 0.8 + (z - 1.55) - 0.3) < 0.07) & rpoly(y, z, REAR_GLASS, 0.08, grow=-0.03), GLASS_HI)
    put(rear & (ay > 0.48) & (ay < 0.84) & (z > 0.54) & (z < 0.70), RED)
    put(rear & (ay > 0.67) & (ay < 0.83) & (z > 0.625) & (z < 0.695), AMBER)
    put(rear & (ay > 0.49) & (ay < 0.65) & (z > 0.625) & (z < 0.695), WHITE)
    put(rear & (ay > 0.48) & (ay < 0.84) & (z > 0.54) & (z < 0.70)
        & ((np.abs(z - 0.618) < 0.006) | (np.abs(np.abs(y) - 0.66) < 0.006)), RUBBER)
    put(rear & (ay < 0.245) & (z > 0.525) & (z < 0.645), PLATE)
    put(rear & disc(y, z, 0, 0.93, 0.07), CHROME)
    put(rear & disc(y, z, 0, 0.93, 0.052), LOWER)
    put(rear & disc(y, z, 0, 0.80, 0.016), RUBBER)                    # cerradura del portón
    put(rear & (y < -0.46) & (y > -0.80) & (z > 0.845) & (z < 0.92), RUBBER)
    for k in range(6):
        yy = -0.49 - k * 0.05
        put(rear & (y < yy) & (y > yy - 0.03) & (z > 0.865) & (z < 0.90), CHROME)
    put(rear & (ay < 0.88) & ((np.abs(z - 1.10) < 0.008) | (np.abs(z - 0.78) < 0.008)), SEAM)
    # Otras piezas
    put(part == "chassis", BLACK)
    put(part == "rub", MOLDING)
    put((part == "rub") & ((np.abs(z - 1.11) < 0.006) | (np.abs(z - 1.174) < 0.006)), SEAM)
    # Manetas en la moldura (ficha): puerta delantera 0,82-1,015 y corredera (derecha) 0,42-0,62
    hz = (part == "rub") & (z > 1.125) & (z < 1.158)
    put(hz & (x > 0.82) & (x < 1.015), BLACK)
    put(hz & (y < 0) & (x > 0.42) & (x < 0.62), BLACK)
    put(part == "molding", BLACK)
    for p in ("bumper_f", "bumper_r", "mirror"):
        put(part == p, BUMPER)
    put((part == "mirror") & (np.abs(ny) > 0.5) & (z > 1.37) & (z < 1.59) & (nx < 0.5), rgb(70, 82, 88))
    bf = (part == "bumper_f") & (nx > 0.6)
    put(bf & (ay < 0.26) & (z > 0.48) & (z < 0.58), PLATE)
    put(bf & (y > 0.21) & (y < 0.26) & (z > 0.48) & (z < 0.58), EU)
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


def mesh(P, lo, hi, step):
    """Malla de las piezas P (dict nombre -> función SDF) en la caja lo..hi: triángulos pintados."""
    xs, ys, zs = (np.arange(lo[k], hi[k], step) for k in range(3))
    X, Y, Z = np.meshgrid(xs, ys, zs, indexing="ij")
    F = P(X.ravel(), Y.ravel(), Z.ravel())
    names = list(F)
    field = np.stack([F[k] for k in names]).min(axis=0).reshape(X.shape)
    del F
    verts, faces, normals, _ = marching_cubes(field, 0.0, spacing=(step, step, step))
    verts += (xs[0], ys[0], zs[0])
    cen = verts[faces].mean(axis=1)
    fn = normals[faces].mean(axis=1)
    # marching_cubes da normales hacia el lado positivo del campo (fuera): las giramos si hace falta
    Fc = P(cen[:, 0], cen[:, 1], cen[:, 2])
    part = np.array(names)[np.argmin(np.stack([Fc[k] for k in names]), axis=0)]
    probe = cen + fn / (np.linalg.norm(fn, axis=1, keepdims=True) + 1e-9) * step * 0.5
    Fp = P(probe[:, 0], probe[:, 1], probe[:, 2])
    if np.mean(np.stack([Fp[k] for k in names]).min(axis=0) > 0) < 0.5:
        normals, fn = -normals, -fn
    fn /= np.linalg.norm(fn, axis=1, keepdims=True) + 1e-9
    col = paint(part, cen[:, 0], cen[:, 1], cen[:, 2], fn)
    return verts, faces, normals, col


def save(path, verts, faces, normals, col, offset):
    """float32, 9 valores por vértice (posición, normal, color) en ejes de Godot (X=y, Y=z, Z=x)."""
    v = verts[faces] - offset
    nv = normals[faces]
    cv = np.repeat(col[:, None, :], 3, axis=1)
    g = lambda a: np.stack([a[..., 1], a[..., 2], a[..., 0]], axis=-1)
    np.concatenate([g(v), g(nv), cv], axis=-1).astype(np.float32).tofile(path)
    print(len(faces), "triángulos ->", path)


def main():
    """Uso: t3_ficha3d.py salida.bin [paso] [paso_rueda]
    Escribe la carrocería (sin ruedas) en salida.bin, una rueda (delantera izquierda, centrada en su
    buje) en salida_rueda.bin y la posición de las cuatro ruedas en salida_ruedas.json."""
    out = sys.argv[1]
    step = float(sys.argv[2]) if len(sys.argv) > 2 else 0.02
    wstep = float(sys.argv[3]) if len(sys.argv) > 3 else 0.008

    def body_parts(x, y, z):
        P = parts(x, y, z)
        del P["wheel"]
        return P

    v, f, n, c = mesh(body_parts, (-2.45, -1.15, -0.05), (2.55, 1.15, 2.5), step)
    save(out, v, f, n, c, np.array([CX, 0, 0]))

    def wheel_parts(x, y, z):
        return {"wheel": sd_cyl_y(x, y, z, WX, WY, WZ, WR, WHW, 0.09)}

    m = WR + 0.03
    v, f, n, c = mesh(wheel_parts, (WX - m, WY - WHW - 0.03, WZ - m), (WX + m, WY + WHW + 0.03, WZ + m), wstep)
    base = out[:-4] if out.endswith(".bin") else out
    save(base + "_rueda.bin", v, f, n, c, np.array([WX, WY, WZ]))
    # Ruedas en ejes de Godot: (y, z, x - CX); "espejo" = girada 180° (lado derecho, y < 0)
    wheels = []
    for wx, front in ((WX, True), (-WX, False)):
        for s in (1, -1):
            wheels.append({"pos": [WY * s, WZ, wx - CX], "front": front, "mirror": s < 0})
    with open(base + "_ruedas.json", "w") as fh:
        json.dump({"radius": WR, "wheels": wheels}, fh, indent=1)
    print("ruedas ->", base + "_ruedas.json")


if __name__ == "__main__":
    main()
