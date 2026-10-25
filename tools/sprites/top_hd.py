"""Vista superior de la T3 en alta resolución para girarla en el juego: python3 tools/sprites/top_hd.py

En vez de 24 frames ya girados en píxel art, Godot gira esta textura sin escalones (con
filtro lineal y mipmaps), así que la furgo gira suave y conserva el detalle del dibujo de Ara.
Sale de la vista superior de cada ficha (ficha_top.py) a HD_SCALE veces el tamaño de juego,
morro a la derecha, con el daño y las luces de cada estado:
godot/assets/sprites/<furgo>/top_d<daño>[_luces].png
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import t3gen as T
import ficha_top as F

HD_SCALE = 4            # px de textura por px de juego (debe coincidir con VAN_TOP_HD_SCALE)
OUTLINE_PX = 2          # contorno oscuro (px de textura) para que se lea sobre el asfalto
LIGHT_RADIUS = 1.6      # px de juego
SPRITES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "godot", "assets", "sprites")


def hd(top, lights=False, damage=0):
    w = F.TOP_LENGTH_PX * HD_SCALE
    h = max(1, round(top.height * w / top.width))
    img = np.asarray(top.convert("RGBA").resize((w, h), Image.LANCZOS)).astype(float)
    rgb = img[..., :3]
    body = img[..., 3] > 0
    if F.DULL[damage]:
        grey = rgb.mean(axis=2, keepdims=True)
        rgb[:] = rgb * (1 - F.DULL[damage]) + grey * F.DULL[damage]
        rgb *= 1 - F.DULL[damage] / 2
    if F.RUST[damage]:
        # Manchas de óxido de varios píxeles (fijas: mismo patrón en cada rumbo).
        rng = np.random.default_rng(1983 + damage)
        small = (rng.random((h // HD_SCALE + 1, w // HD_SCALE + 1)) < F.RUST[damage])
        spots = np.kron(small, np.ones((HD_SCALE, HD_SCALE), bool))[:h, :w] & (img[..., 3] > 200)
        rgb[spots] = rgb[spots] * 0.4 + np.array(T.C_RUST) * 0.6
    if lights:
        ys, xs = np.mgrid[0:h, 0:w]
        rows = np.where(body.any(axis=1))[0]
        cols = np.where(body.any(axis=0))[0]
        r = LIGHT_RADIUS * HD_SCALE
        for y in (rows.min() + 3 * HD_SCALE, rows.max() - 3 * HD_SCALE):
            for x, col in ((cols.max() - r, T.C_HEAD_ON), (cols.min() + r, T.C_TAIL_ON)):
                m = ((xs - x) ** 2 + (ys - y) ** 2 < r * r) & body
                rgb[m] = col
    out = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGBA")
    # Contorno: silueta engordada en oscuro, debajo del cuerpo. Margen para los mipmaps.
    pad = OUTLINE_PX + HD_SCALE
    canvas = Image.new("RGBA", (w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    alpha = Image.new("L", canvas.size, 0)
    alpha.paste(out.getchannel("A"), (pad, pad))
    ring = alpha.filter(ImageFilter.MaxFilter(OUTLINE_PX * 2 + 1))
    canvas.paste(Image.new("RGBA", canvas.size, (*T.OUTLINE, 255)), (0, 0), ring)
    canvas.alpha_composite(out, (pad, pad))
    return canvas


if __name__ == "__main__":
    for model in F.FICHAS:
        top = Image.open(F.vista_path(model))
        for damage in range(4):
            for lights in (False, True):
                name = f"top_d{damage}{'_luces' if lights else ''}.png"
                hd(top, lights, damage).save(os.path.join(SPRITES, model, name), optimize=True)
                print(model, name)
