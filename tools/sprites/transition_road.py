"""Pantalla de transición ciudad -> campo: python3 tools/sprites/transition_road.py

Parte de la imagen de Ara (vistas/transicion/carretera_campo.jpg): recorta la furgo pintada
como sprite (trasera) y la borra del fondo, rellenando monte y asfalto con sus líneas.
Godot dibuja después la furgo alejándose por la carretera (godot/ui/map_transition.gd).
Salen godot/assets/backgrounds/transicion_campo.png y godot/assets/sprites/transicion_furgo.png.
"""
import os

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "vistas", "transicion", "carretera_campo.jpg")
GODOT = os.path.join(HERE, "..", "..", "godot", "assets")

# Silueta de la furgo en píxeles de la imagen (techo redondeado, cuerpo, ruedas).
VAN_POLY = [(645, 590), (699, 590), (708, 595), (714, 604), (718, 616), (721, 630), (722, 710),
            (620, 710), (621, 630), (624, 616), (628, 604), (634, 595)]
VAN_BOX = (618, 586, 737, 716)   # zona a borrar del fondo (con margen)
HILL_X1 = 724                     # el monte solo se rellena hasta aquí (a la derecha hay sombra y señal)
ROAD_TOP_Y = 656                  # por encima, monte; por debajo, asfalto
HILL_SHIFT_X = -108               # el monte se rellena copiando el de la izquierda
ROAD_SAMPLE_X = (590, 612)        # asfalto limpio de cada fila, a la izquierda de la furgo
# Líneas pintadas que la furgo tapaba: (x, y) de abajo -> arriba.
CENTER_LINE = ((620, 675), (640, 656))
EDGE_LINE = ((742, 690), (697, 656))
LINE_COLOR = (225, 225, 232)


def _is_hill(px):
    r, g, b = (int(c) for c in px)
    # Tierra y matorral (cálidos, no muy oscuros); deja el contorno negro y los pilotos rojos.
    light = r > 150 and g < r // 2
    return r >= 50 and r > b + 10 and g <= r and g >= b - 10 and not light


def _drop_hill(a, mask):
    """Quita de la silueta el monte que queda entre el polígono y el contorno negro de la furgo."""
    m = np.array(mask)
    h, w = m.shape
    stack = [(x, y) for y in range(h) for x in range(w)
             if m[y, x] and y < ROAD_TOP_Y and _is_hill(a[y, x])
             and (not m[y, x - 1] or not m[y, x + 1] or not m[y - 1, x])]
    while stack:
        x, y = stack.pop()
        if not m[y, x] or y >= ROAD_TOP_Y or not _is_hill(a[y, x]):
            continue
        m[y, x] = 0
        stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    mask.paste(Image.fromarray(m))


def main():
    img = Image.open(SRC).convert("RGB")
    a = np.array(img)

    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(VAN_POLY, fill=255)
    _drop_hill(a, mask)
    van = img.convert("RGBA")
    van.putalpha(mask)
    van = van.crop(mask.getbbox())
    van.save(os.path.join(GODOT, "sprites", "transicion_furgo.png"))

    x0, y0, x1, y1 = VAN_BOX
    bg = a.copy()
    hill_end = min(ROAD_TOP_Y, y1)
    bg[y0:hill_end, x0:HILL_X1] = a[y0:hill_end, x0 + HILL_SHIFT_X:HILL_X1 + HILL_SHIFT_X]
    for y in range(ROAD_TOP_Y, y1):
        row = a[y, ROAD_SAMPLE_X[0]:ROAD_SAMPLE_X[1]].reshape(-1, 3)
        bg[y, x0:x1] = np.median(row, axis=0).astype(np.uint8)
    out = Image.fromarray(bg)
    d = ImageDraw.Draw(out)
    d.line(CENTER_LINE, fill=LINE_COLOR, width=3)
    d.line(EDGE_LINE, fill=LINE_COLOR, width=3)
    out.save(os.path.join(GODOT, "backgrounds", "transicion_campo.png"))


if __name__ == "__main__":
    main()
