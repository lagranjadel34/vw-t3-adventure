"""Muestra de textura de tierra para el camino del bosque, generada por código.

Sin arte: ruido de vetas (surcos), piedras y tonos claros/oscuros. Sale en PNG
para revisar el tono; la versión de Godot usará el mismo algoritmo.
Uso: python3 tools/sprites/tierra.py <salida.png>
"""
import sys

import numpy as np
from PIL import Image

SIZE = 64
SEED = 7
BASE = np.array([124, 96, 62], dtype=float)
DARK = np.array([82, 60, 38], dtype=float)
LIGHT = np.array([158, 126, 88], dtype=float)
STONE = np.array([112, 108, 100], dtype=float)


def tierra(size: int = SIZE, seed: int = SEED) -> np.ndarray:
    rng = np.random.default_rng(seed)
    # Ruido de grano: valor por píxel entre 0 y 1, suavizado con promedio de vecinos.
    grano = rng.random((size, size))
    for _ in range(2):
        grano = (grano + np.roll(grano, 1, 0) + np.roll(grano, 1, 1)) / 3.0
    grano = (grano - grano.min()) / (grano.max() - grano.min())
    # Surcos: franjas horizontales suaves que el camino repite.
    surcos = 0.5 + 0.5 * np.sin(np.arange(size)[:, None] * 0.9 + grano * 2.5)
    mezcla = np.clip(0.6 * grano + 0.4 * surcos, 0.0, 1.0)[..., None]
    img = DARK + (LIGHT - DARK) * mezcla
    # Piedras: manchas redondas grises, unas pocas.
    yy, xx = np.mgrid[0:size, 0:size]
    for _ in range(5):
        cy, cx = rng.integers(0, size, 2)
        r = rng.uniform(1.5, 3.0)
        mascara = (yy - cy) ** 2 + (xx - cx) ** 2 <= r * r
        img[mascara] = img[mascara] * 0.4 + STONE * 0.6
    return np.clip(img, 0, 255).astype(np.uint8)


if __name__ == "__main__":
    out = sys.argv[1]
    # Escalado nearest para ver el píxel tal cual (x8).
    Image.fromarray(tierra()).resize((SIZE * 8, SIZE * 8), Image.NEAREST).save(out)
    print(out)
