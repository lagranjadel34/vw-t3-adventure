"""Vista superior de la ficha de Ara -> sprite del juego (cámara cenital del mapa).

Con la cámara encima, el modelo 3D solo enseña el techo; la vista superior que Ara dibujó en
la ficha de cada furgo es mucho más reconocible. Este módulo:

1. `python3 tools/sprites/ficha_top.py` recorta esa vista de cada ficha (FICHAS) quitando el
   fondo y la guarda en tools/sprites/vistas/<furgo>/superior.png (morro a la derecha).
2. `sprite(...)` la gira a cualquier rumbo en píxel art (export_godot.py la usa si existe).
"""
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import t3gen as T

HERE = os.path.dirname(os.path.abspath(__file__))
VISTAS = os.path.join(HERE, "vistas")
# Ficha original (carpeta del proyecto) y caja de su "VISTA SUPERIOR" (px de la ficha).
FICHAS = {
    "dehler": ("/mnt/project-files/graficos/fichas-ara/dehler-profi-v2-azul.jpg", (735, 435, 1345, 720)),
    "carthago": ("/mnt/project-files/graficos/fichas-ara/carthago.jpg", (750, 440, 1350, 722)),
}
BG_TOLERANCE = 38       # distancia de color al fondo de la ficha
TOP_LENGTH_PX = 62      # largo en pantalla (T3 de 4,57 m a 13 px/m + techo alto en perspectiva)
SUPERSAMPLE = 4         # se gira a 4x y se reduce: bordes limpios sin antialiasing
PALETTE_COLORS = 24
DULL = [0, 0.12, 0.2, 0.3]
RUST = [0, 0.02, 0.05, 0.1]
LIGHT_PX = 2


def vista_path(model):
    return os.path.join(VISTAS, model, "superior.png")


def extract(model):
    path, box = FICHAS[model]
    src = np.asarray(Image.open(path).convert("RGB").crop(box)).astype(int)
    h, w, _ = src.shape
    corners = np.array([src[2, 2], src[2, -3], src[-3, 2], src[-3, -3]])
    bg = np.median(corners, axis=0)
    bg_like = np.linalg.norm(src - bg, axis=2) < BG_TOLERANCE
    # Fondo = lo parecido al fondo conectado con el borde (los cristales claros se salvan).
    outside = np.zeros_like(bg_like)
    outside[0, :] = outside[-1, :] = outside[:, 0] = outside[:, -1] = True
    outside &= bg_like
    while True:
        grow = outside.copy()
        grow[1:, :] |= outside[:-1, :]
        grow[:-1, :] |= outside[1:, :]
        grow[:, 1:] |= outside[:, :-1]
        grow[:, :-1] |= outside[:, 1:]
        grow &= bg_like
        if (grow == outside).all():
            break
        outside = grow
    ys, xs = np.where(~outside)
    rgba = np.zeros((h, w, 4), np.uint8)
    rgba[..., :3] = src
    rgba[..., 3] = np.where(outside, 0, 255)
    img = Image.fromarray(rgba, "RGBA").crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    os.makedirs(os.path.dirname(vista_path(model)), exist_ok=True)
    img.save(vista_path(model))
    return img


def _base(top, lights, damage):
    """Vista superior a tamaño de juego (sin girar), con daño y luces."""
    w = TOP_LENGTH_PX
    hgt = max(1, round(top.height * w / top.width))
    small = np.asarray(top.resize((w, hgt), Image.LANCZOS)).astype(float)
    small[..., 3] = np.where(small[..., 3] >= 128, 255, 0)
    rgb = small[..., :3]
    if DULL[damage]:
        grey = rgb.mean(axis=2, keepdims=True)
        rgb[:] = rgb * (1 - DULL[damage]) + grey * DULL[damage]
        rgb *= 1 - DULL[damage] / 2
    if RUST[damage]:
        # Óxido fijo (no baila al girar): mismo patrón para todos los rumbos.
        rng = np.random.default_rng(1983 + damage)
        spots = (rng.random(rgb.shape[:2]) < RUST[damage]) & (small[..., 3] > 0)
        rgb[spots] = T.C_RUST
    if lights:
        on = small[..., 3] > 0
        cols = np.where(on.any(axis=0))[0]
        rows = np.where(on.any(axis=1))[0]
        x0, x1, y0, y1 = cols.min(), cols.max(), rows.min(), rows.max()
        for y in (y0 + LIGHT_PX + 1, y1 - LIGHT_PX - 1):
            for x, col in ((x1, T.C_HEAD_ON), (x0, T.C_TAIL_ON)):
                rgb[y - 1:y + 1, max(x - 1, 0):x + 1] = col
    return Image.fromarray(np.clip(small, 0, 255).astype(np.uint8), "RGBA")


def _premul_box_down(img, factor):
    a = np.asarray(img).astype(float)
    a[..., :3] *= a[..., 3:4] / 255
    h, w = a.shape[0] // factor, a.shape[1] // factor
    a = a[:h * factor, :w * factor].reshape(h, factor, w, factor, 4).mean(axis=(1, 3))
    alpha = a[..., 3:4]
    a[..., :3] = np.where(alpha > 0, a[..., :3] * 255 / np.maximum(alpha, 1), 0)
    a[..., 3] = np.where(a[..., 3] >= 128, 255, 0)
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")


def _outline(img):
    a = np.asarray(img).copy()
    alpha = a[..., 3] > 0
    nb = np.zeros_like(alpha)
    nb[1:, :] |= alpha[:-1, :]
    nb[:-1, :] |= alpha[1:, :]
    nb[:, 1:] |= alpha[:, :-1]
    nb[:, :-1] |= alpha[:, 1:]
    a[nb & ~alpha] = (*T.OUTLINE, 255)
    return Image.fromarray(a, "RGBA")


def sprite(top, heading, lights=False, damage=0, size=T.CANVAS, pivot=T.PIVOT):
    """heading: radianes, 0 = derecha, positivo = antihorario (como t3gen.render)."""
    base = _base(top, lights, damage)
    palette = base.convert("RGB").quantize(PALETTE_COLORS, dither=Image.Dither.NONE)
    big = base.resize((base.width * SUPERSAMPLE, base.height * SUPERSAMPLE), Image.NEAREST)
    big = big.rotate(math.degrees(heading), resample=Image.BICUBIC, expand=True)
    body = _premul_box_down(big, SUPERSAMPLE)
    alpha = body.getchannel("A")
    body = body.convert("RGB").quantize(palette=palette, dither=Image.Dither.NONE).convert("RGBA")
    body.putalpha(alpha)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(body, (pivot[0] - body.width // 2, pivot[1] - body.height // 2))
    out = T.shadow(size=size, pivot=pivot, heading=heading)
    out.alpha_composite(_outline(canvas))
    return out


if __name__ == "__main__":
    for model in FICHAS:
        img = extract(model)
        print(model, img.size, "->", vista_path(model))
