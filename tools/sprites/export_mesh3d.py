"""Exporta el modelo 3D low-poly de una furgo (dehler.py) a JSON de triángulos con color,
para cargarlo en Godot 3D (prototipos/voxel3d). Con --detalle añade piezas que en los sprites
cenitales no se ven pero en 3D sí (ruedas redondas con llantas de 5 agujeros, juntas de puertas,
manetas, logo VW, matrículas, limpias, escape, bajos...). No toca los sprites del juego.

Ejes: modelo x adelante, y izquierda, z arriba -> Godot Z adelante, X izquierda, Y arriba.
Uso: python3 export_mesh3d.py dehler salida.json [--detalle]"""
import json
import math
import sys

import t3gen as T
import dehler as D
from t3gen import HL, HW, Z_FLOOR, Z_BELT, Z_ROOF, DECAL_BIAS as B, Poly, box, prism_y, quad_on_side, \
    quad_on_front, windshield_poly

WHEEL_X = 1.23
WHEEL_Y = 0.83
WHEEL_R = 0.32
WHEEL_W = 0.22
SEGMENTS = 20
C_SEAM = (26, 34, 58)
C_CHROME = (196, 204, 210)
C_RIM = (172, 180, 186)
C_RIM_DARK = (70, 74, 80)
C_TREAD = (38, 38, 42)
C_WALL = (24, 24, 27)
C_EU = (40, 70, 160)
C_LENS = (236, 234, 214)
C_AMBER = (226, 140, 40)
C_REVERSE = (230, 230, 220)
C_CHASSIS = (30, 30, 34)
C_RAIL = (170, 176, 182)
C_EXHAUST = (90, 90, 92)
WHEEL_COLORS = {T.C_TIRE_A, T.C_TIRE_B, D.C_HUBCAP, D.C_HUBCAP_DARK}


def circle(cx, cz, r, n=SEGMENTS, phase=0.0):
    return [(cx + r * math.cos(phase + 2 * math.pi * k / n), cz + r * math.sin(phase + 2 * math.pi * k / n))
            for k in range(n)]


def is_old_wheel(p):
    c = p.v.mean(axis=0)
    return (p.color in WHEEL_COLORS and abs(abs(c[0]) - WHEEL_X) < 0.45 and c[2] < 0.7 and abs(c[1]) > 0.6)


def side_disc(cx, cz, y, s, r, color, bias, n=SEGMENTS, phase=0.0):
    return Poly([(x, y, z) for x, z in circle(cx, cz, r, n, phase)][::s], color, normal=(0, s, 0), bias=bias)


def front_disc(x, cy, cz, r, color, sign, bias, n=SEGMENTS):
    return Poly([(x, cy + a, cz + b) for a, b in circle(0, 0, r, n)], color, normal=(sign, 0, 0), bias=bias)


def wheel(cx, s):
    """Neumático de 20 caras con dibujo, flanco y llanta de aleación de 5 agujeros (ficha de Ara)."""
    y = WHEEL_Y * s
    y0, y1 = y - WHEEL_W / 2, y + WHEEL_W / 2
    edges = [C_TREAD if k % 2 else T.C_TIRE_B for k in range(SEGMENTS)]
    P = prism_y(circle(cx, Z_FLOOR, WHEEL_R), y0, y1, C_WALL, side_color=C_WALL, edge_colors=edges)
    oy = y1 if s > 0 else y0
    P.append(side_disc(cx, Z_FLOOR, oy, s, 0.22, C_RIM, B))
    for k in range(5):  # agujeros entre radios
        a0 = 2 * math.pi * k / 5 + 0.25
        a1 = a0 + 0.75
        pts = [(cx + r * math.cos(a), Z_FLOOR + r * math.sin(a)) for r, a in
               ((0.08, a0 + 0.12), (0.18, a0), (0.18, (a0 + a1) / 2), (0.18, a1), (0.08, a1 - 0.12))]
        P.append(Poly([(x, oy, z) for x, z in pts], C_RIM_DARK, normal=(0, s, 0), bias=B * 2))
    P.append(side_disc(cx, Z_FLOOR, oy, s, 0.06, C_CHROME, B * 3, n=10))
    P.append(side_disc(cx, Z_FLOOR, oy, s, 0.03, C_RIM_DARK, B * 4, n=8))
    return P


def details(st):
    body = st["body"]
    celeste = st["window_frame"]
    P = []
    for wx in (WHEEL_X, -WHEEL_X):
        for s in (1, -1):
            P += wheel(wx, s)
    # Bajos: chasis oscuro para que no se vea a través entre las ruedas
    P += box(-2.1, 2.1, -0.78, 0.78, 0.14, Z_FLOOR, C_CHASSIS)
    for s in (1, -1):
        y, ys = D.HW * s, D.SIDE * s
        # Juntas de la puerta delantera (chapa y marco de la ventana)
        P.append(quad_on_side(y, 1.06, 1.08, 0.42, Z_BELT, C_SEAM, s, bias=B * 3))
        P.append(quad_on_side(ys, 1.06, 1.08, Z_BELT, 1.8, C_SEAM, s, bias=B * 3))
        P.append(quad_on_side(y, 2.12, 2.14, 0.42, Z_BELT, C_SEAM, s, bias=B * 3))
        # Maneta delantera, intermitente lateral y cantonera cromada de la banda
        P += box(1.16, 1.3, min(y, y + 0.02 * s), max(y, y + 0.02 * s), 0.96, 1.0, C_CHROME)
        P.append(quad_on_side(y, 1.78, 1.86, 0.72, 0.78, C_AMBER, s, bias=B * 3))
        P.append(quad_on_side(y, -HL, HL, 0.6, 0.615, C_CHROME, s, bias=B * 3))
        # Paneles traseros: junta de la tapa del motor
        P.append(quad_on_side(y, -1.9, -1.88, 0.42, Z_BELT, C_SEAM, s, bias=B * 3))
    # Puerta corredera (lado derecho, y < 0): juntas, carril y maneta
    yr = -D.HW
    for x in (0.0, 1.0):
        P.append(quad_on_side(yr, x, x + 0.02, 0.42, Z_BELT, C_SEAM, -1, bias=B * 3))
        P.append(quad_on_side(-D.SIDE, x, x + 0.02, Z_BELT, 1.8, C_SEAM, -1, bias=B * 3))
    P.append(quad_on_side(-D.SIDE, -1.3, 0.0, 1.08, 1.11, C_SEAM, -1, bias=B * 3))
    P += box(0.06, 0.22, yr - 0.02, yr, 0.94, 0.98, C_CHROME)
    # Tapón de gasolina (lado derecho, detrás)
    P.append(quad_on_side(yr, -1.55, -1.4, 0.72, 0.84, T.darken(body, 0.7), -1, bias=B * 3))
    # Frontal: logo VW redondo, láminas de la rejilla, aros cromados de los faros, matrícula
    P.append(front_disc(HL, 0, 0.85, 0.085, C_CHROME, 1, B * 3))
    P.append(front_disc(HL, 0, 0.85, 0.06, body, 1, B * 4))
    for a, b in ((-0.035, 0.0), (0.0, 0.035)):  # la V del logo
        P.append(Poly([(HL, a, 0.88), (HL, a + 0.012, 0.88), (HL, (a + b) / 2 + 0.006, 0.82),
                       (HL, (a + b) / 2 - 0.006, 0.82)][::-1], C_CHROME, normal=(1, 0, 0), bias=B * 5))
    for z in (0.79, 0.91):
        for y0, y1 in ((-0.55, -0.11), (0.11, 0.55)):
            P.append(quad_on_front(HL, y0, y1, z, z + 0.012, C_SEAM, 1, bias=B * 3))
    for s in (1, -1):
        P.append(front_disc(HL, 0.72 * s, 0.85, 0.125, C_CHROME, 1, B * 1.5))
        P.append(front_disc(HL, 0.72 * s, 0.85, 0.085, C_LENS, 1, B * 2.5))
        P.append(front_disc(HL, 0.72 * s + 0.025, 0.875, 0.025, (255, 255, 255), 1, B * 3, n=8))
    bx = HL + 0.12
    P.append(quad_on_front(bx, -0.27, 0.27, 0.36, 0.48, D.C_PLATE, 1, bias=B))
    P.append(quad_on_front(bx, 0.22, 0.27, 0.36, 0.48, C_EU, 1, bias=B * 2))
    for k in range(6):  # caracteres de la matrícula
        y = 0.16 - k * 0.07
        P.append(quad_on_front(bx, y - 0.04, y, 0.39, 0.45, C_SEAM, 1, bias=B * 2))
    # Limpiaparabrisas en reposo
    P.append(windshield_poly(-0.68, -0.08, 1.1, 1.125, T.C_BLACK, bias=B * 3))
    P.append(windshield_poly(0.06, 0.66, 1.1, 1.125, T.C_BLACK, bias=B * 3))
    # Trasera: tapa del motor, intermitente y marcha atrás en los pilotos, logo, escape
    P.append(quad_on_front(-HL, -0.86, 0.86, 0.98, 1.0, C_SEAM, -1, bias=B * 3))
    P.append(quad_on_front(-HL, -0.86, 0.86, 0.8, 0.82, C_SEAM, -1, bias=B * 3))
    for s in (1, -1):
        y0, y1 = sorted((0.74 * s, 0.86 * s))
        P.append(quad_on_front(-HL, y0, y1, 0.58, 0.74, C_AMBER, -1, bias=B * 2))
        y0, y1 = sorted((0.5 * s, 0.58 * s))
        P.append(quad_on_front(-HL, y0, y1, 0.58, 0.74, C_REVERSE, -1, bias=B * 2))
        P.append(quad_on_front(-HL, 0.88 * s - 0.01, 0.88 * s + 0.01, 0.42, Z_BELT, C_SEAM, -1, bias=B * 3))
    P.append(front_disc(-HL, 0, 0.9, 0.06, C_CHROME, -1, B * 3))
    P.append(front_disc(-HL, 0, 0.9, 0.042, body, -1, B * 4))
    P += box(-HL - 0.2, -HL - 0.02, 0.45, 0.55, 0.2, 0.28, C_EXHAUST)
    # Techo: carriles laterales (ficha superior) y bisagra de la escotilla
    zt = D.Z_HITOP
    for s in (1, -1):
        y0, y1 = sorted((0.7 * s, 0.76 * s))
        P += box(-1.8, 0.9, y0, y1, zt, zt + 0.04, C_RAIL)
    P += box(0.3, 0.34, -0.3, 0.3, zt + 0.1, zt + 0.13, C_SEAM)
    # Reflejos en las ventanas laterales
    for s in (1, -1):
        for x0 in (1.25, 0.2, -1.0):
            P.append(quad_on_side(D.SIDE * s, x0, x0 + 0.08, 1.2, 1.68, D.C_GLASS_HI, s, bias=B * 2))
    return P


def main():
    name, out = sys.argv[1], sys.argv[2]
    detail = "--detalle" in sys.argv
    polys = D.MODELS[name](lights=False)
    if detail:
        st = D.DEHLER if name == "dehler" else D.CARTHAGO
        polys = [p for p in polys if not is_old_wheel(p)] + details(st)
    tris = []
    for p in polys:
        v = p.v + p.n * p.bias  # las calcomanías flotan un pelo sobre la chapa
        g = [(float(x[1]), float(x[2]), float(x[0])) for x in v]
        col = [c / 255.0 for c in p.color]
        n = [float(p.n[1]), float(p.n[2]), float(p.n[0])]
        for i in range(1, len(g) - 1):
            tris.append({"v": [g[0], g[i], g[i + 1]], "c": col, "n": n})
    json.dump({"tris": tris}, open(out, "w"))
    print(len(polys), "polígonos,", len(tris), "triángulos")


main()
