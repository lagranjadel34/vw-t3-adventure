"""Giro de la furgo en el escaparate: python3 tools/sprites/export_turntable.py

Monta una caja con las cinco vistas de la ficha (vistas/<furgo>/*.png) como caras:
lateral izquierda y derecha, frontal, trasera y superior. Cada rumbo se dibuja con cámara
baja (ELEVATION_DEG) y las caras visibles se pegan con una transformación afín.
Salida: godot/assets/sprites/<furgo>/giro.png, 8 columnas x 3 filas = 24 rumbos (horario).
"""
import math
import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
VISTAS = os.path.join(HERE, "vistas")
OUT = os.path.join(HERE, "..", "..", "godot", "assets", "sprites")

L, W, H = 4.57, 1.84, 2.34     # medidas de la T3 (m)
ZMIN = -0.35                   # base de las ruedas bajo el suelo (m)
ELEVATION_DEG = 12.0           # cámara baja: se ven las caras de frente y de lado
PX_PER_M = 26.0
CELL = (150, 90)
COLS, ROWS = 8, 3


def faces(vehicle):
    """Caras: normal, textura y esquinas (superior izquierda, superior derecha, inferior izquierda) en m."""
    def load(name):
        return Image.open(os.path.join(VISTAS, vehicle, name + ".png")).convert("RGBA")
    return {
        "lat_izq": ((0, -1, 0), load("lat_izq"), ((-L/2, -W/2, H), (L/2, -W/2, H), (-L/2, -W/2, ZMIN))),
        "lat_der": ((0, 1, 0), load("lat_der"), ((L/2, W/2, H), (-L/2, W/2, H), (L/2, W/2, ZMIN))),
        "frontal": ((1, 0, 0), load("frontal"), ((L/2, -W/2, H), (L/2, W/2, H), (L/2, -W/2, ZMIN))),
        "trasera": ((-1, 0, 0), load("trasera"), ((-L/2, W/2, H), (-L/2, -W/2, H), (-L/2, W/2, ZMIN))),
        "superior": ((0, 0, 1), load("superior"), ((-L/2, W/2, H), (L/2, W/2, H), (-L/2, -W/2, H))),
    }


def rot_z(p, a):
    c, s = math.cos(a), math.sin(a)
    return np.array([c*p[0] - s*p[1], s*p[0] + c*p[1], p[2]])


def project(p):
    # Cámara en +x, elevada; a la derecha de la pantalla, +y. Devuelve (x, y_abajo) en metros.
    e = math.radians(ELEVATION_DEG)
    return np.array([p[1], -(-math.sin(e) * p[0] + math.cos(e) * p[2])])


def affine(tex, corners, origin):
    """Coeficientes pantalla -> textura para (esquina TL, TR, BL) proyectadas."""
    w, h = tex.size
    P = [project(c) * PX_PER_M + origin for c in corners]
    Vs = np.array([P[1] - P[0], P[2] - P[0]]).T
    M = np.array([[w, 0], [0, h]], float) @ np.linalg.inv(Vs)
    c0 = -M @ P[0]
    return (M[0, 0], M[0, 1], c0[0], M[1, 0], M[1, 1], c0[1])


def frame(faces_, heading):
    cam = np.array([math.cos(math.radians(ELEVATION_DEG)), 0, math.sin(math.radians(ELEVATION_DEG))])
    origin = np.array([CELL[0] / 2, CELL[1] / 2])
    visible = []
    for normal, tex, corners in faces_.values():
        if rot_z(np.array(normal, float), heading) @ cam <= 1e-6:
            continue
        cs = [rot_z(np.array(c, float), heading) for c in corners]
        visible.append((sum(c @ cam for c in cs), tex, cs))
    out = Image.new("RGBA", CELL, (0, 0, 0, 0))
    for _, tex, cs in sorted(visible, key=lambda v: v[0]):
        layer = tex.transform(CELL, Image.AFFINE, affine(tex, cs, origin), resample=Image.BICUBIC)
        out.alpha_composite(layer)
    return out


def export(vehicle):
    faces_ = faces(vehicle)
    sheet = Image.new("RGBA", (CELL[0] * COLS, CELL[1] * ROWS), (0, 0, 0, 0))
    for k in range(COLS * ROWS):
        heading = 2 * math.pi * k / (COLS * ROWS)
        sheet.alpha_composite(frame(faces_, heading), ((k % COLS) * CELL[0], (k // COLS) * CELL[1]))
    out = os.path.join(OUT, vehicle)
    os.makedirs(out, exist_ok=True)
    sheet.save(os.path.join(out, "giro.png"), optimize=True)
    print(vehicle, "giro.png")


if __name__ == "__main__":
    for vehicle in sorted(os.listdir(VISTAS)):
        export(vehicle)
