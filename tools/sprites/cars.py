"""Coches del tráfico de Sevilla, con el mismo render que la T3 (modelo 3D low-poly -> píxel art).

python3 tools/sprites/cars.py  ->  godot/assets/sprites/coches/coches.png
Columnas: 24 rumbos (frame k = rumbo k·15° horario desde la derecha). Filas: un modelo cada una.
"""
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import t3gen as T
from t3gen import Poly, box, prism_y, quad_on_side, quad_on_front, octagon, DECAL_BIAS

DIRS = 24
CANVAS = 64
PIVOT = (32, 32)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "godot", "assets",
                   "sprites", "coches")

# Turismo genérico (m): x adelante, y izquierda, z arriba.
HL, HW = 2.0, 0.85
Z_FLOOR, Z_BELT, Z_ROOF = 0.3, 0.85, 1.42
C_GLASS = (34, 40, 58)
C_TIRE = (28, 28, 32)

MODELS = [
    # Taxi de Sevilla: blanco con la franja diagonal amarilla.
    {"name": "taxi", "body": (236, 236, 232), "stripe": (232, 186, 40)},
    {"name": "rojo", "body": (178, 44, 40)},
    {"name": "azul", "body": (52, 96, 160)},
    {"name": "verde", "body": (66, 110, 72)},
]


def build_car(model):
    body = model["body"]
    P = []
    P += box(-HL, HL, -HW, HW, Z_FLOOR, Z_BELT, body)
    # Habitáculo: capó delante, maletero detrás, techo más estrecho.
    cab = [(1.0, Z_BELT), (0.45, Z_ROOF), (-0.95, Z_ROOF), (-1.35, Z_BELT)]
    P += prism_y(cab, -0.78, 0.78, body)
    n_front = np.array([0.55, 0, 0.55]) / math.hypot(0.55, 0.55)
    n_back = np.array([-0.57, 0, 0.4]) / math.hypot(0.57, 0.4)
    lerp = lambda a, b, t: (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
    for (a, b), n in (((cab[0], cab[1]), n_front), ((cab[3], cab[2]), n_back)):
        p0, p1 = lerp(a, b, 0.15), lerp(a, b, 0.85)
        P.append(Poly([(p0[0], -0.68, p0[1]), (p0[0], 0.68, p0[1]), (p1[0], 0.68, p1[1]), (p1[0], -0.68, p1[1])],
                      C_GLASS, normal=n, bias=DECAL_BIAS))
    for s in (1, -1):
        P.append(quad_on_side(0.78 * s, -0.85, 0.35, 0.92, 1.32, C_GLASS, s))
        if "stripe" in model:
            P.append(Poly([(-0.9, HW * s, 0.35), (-0.3, HW * s, 0.35), (0.6, HW * s, 0.8), (0.0, HW * s, 0.8)],
                          model["stripe"], normal=(0, s, 0), bias=DECAL_BIAS))
        for wx in (1.3, -1.3):
            P += prism_y(octagon(wx, Z_FLOOR, 0.3, 0.0), 0.86 * s - 0.1, 0.86 * s + 0.1, C_TIRE)
        y0, y1 = sorted((0.5 * s, 0.8 * s))
        P.append(quad_on_front(HL, y0, y1, 0.62, 0.76, T.C_HEAD, 1))
        P.append(quad_on_front(-HL, y0, y1, 0.62, 0.76, T.C_TAIL, -1))
    P += box(HL, HL + 0.06, -0.86, 0.86, 0.32, 0.46, T.C_BUMPER)
    P += box(-HL - 0.06, -HL, -0.86, 0.86, 0.32, 0.46, T.C_BUMPER)
    if model["name"] == "taxi":
        P += box(-0.35, -0.05, -0.2, 0.2, Z_ROOF, Z_ROOF + 0.1, (240, 240, 236))
    return P


def car_shadow(heading):
    e = math.radians(T.ELEVATION_DEG)
    img = np.zeros((CANVAS, CANVAS, 4), np.uint8)
    ys, xs = np.mgrid[0:CANVAS, 0:CANVAS]
    gx = (xs + 0.5 - PIVOT[0]) / T.PX_PER_M
    gy = -(ys + 0.5 - PIVOT[1] + 2) / (T.PX_PER_M * math.sin(e))
    c, s = math.cos(-heading), math.sin(-heading)
    m = (np.abs(gx * c - gy * s) < HL + 0.1) & (np.abs(gx * s + gy * c) < HW + 0.1)
    img[m] = (0, 0, 0, 70)
    return Image.fromarray(img, "RGBA")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    sheet = Image.new("RGBA", (CANVAS * DIRS, CANVAS * len(MODELS)), (0, 0, 0, 0))
    for r, model in enumerate(MODELS):
        polys = build_car(model)
        for k in range(DIRS):
            heading = -k * 2 * math.pi / DIRS
            spr = car_shadow(heading)
            spr.alpha_composite(T.render(polys, heading, size=CANVAS, pivot=PIVOT))
            sheet.alpha_composite(spr, (k * CANVAS, r * CANVAS))
    sheet.save(os.path.join(OUT, "coches.png"), optimize=True)
    print("coches.png", sheet.size)
