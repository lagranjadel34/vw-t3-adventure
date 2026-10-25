"""Exporta las hojas de la T3 para Godot: python3 tools/sprites/export_godot.py

El juego ya no las usa (desde G15 gira la vista superior en HD de top_hd.py); se dejan
para volver a los frames girados si hiciera falta.

Una carpeta por furgo (dehler.MODELS) y una textura por estado (daño 0-3, luces sí/no):
godot/assets/sprites/<furgo>/d<daño>[_luces].png
Columnas: 24 direcciones (frame k = rumbo k·15° horario desde la derecha).
Filas: volante (izq, recto, dcha) × 4 frames de rueda girando.

Si la furgo tiene vista superior de su ficha (tools/sprites/vistas/<furgo>/superior.png, ver
ficha_top.py), el cuerpo sale de ella: con la cámara cenital es lo reconocible. Desde arriba
las ruedas no se ven, así que todas las filas repiten el mismo frame.
"""
import math
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import t3gen as T
import dehler
import ficha_top

DIRS = 24
SPIN_FRAMES = 4
SPIN_STEP = (math.pi / 4) / SPIN_FRAMES * 2
STEER = math.radians(25)
SPRITES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "godot", "assets",
                       "sprites")

for model, build in dehler.MODELS.items():
    T.BUILDER[0] = build
    top = Image.open(ficha_top.vista_path(model)) if os.path.exists(ficha_top.vista_path(model)) else None
    out = os.path.join(SPRITES, model)
    os.makedirs(out, exist_ok=True)
    for damage in range(4):
        for lights in (False, True):
            sheet = Image.new("RGBA", (T.CANVAS * DIRS, T.CANVAS * 3 * SPIN_FRAMES), (0, 0, 0, 0))
            frames = {}
            for si, steer in enumerate((STEER, 0.0, -STEER)):
                for f in range(SPIN_FRAMES):
                    for k in range(DIRS):
                        heading = -k * 2 * math.pi / DIRS
                        if top is not None:
                            if k not in frames:
                                frames[k] = ficha_top.sprite(top, heading, lights=lights, damage=damage)
                            spr = frames[k]
                        else:
                            spr = T.sprite(heading, spin=f * SPIN_STEP, steer=steer, lights=lights, damage=damage)
                        sheet.alpha_composite(spr, (k * T.CANVAS, (si * SPIN_FRAMES + f) * T.CANVAS))
            name = f"d{damage}{'_luces' if lights else ''}.png"
            sheet.save(os.path.join(out, name), optimize=True)
            print(model, name)
