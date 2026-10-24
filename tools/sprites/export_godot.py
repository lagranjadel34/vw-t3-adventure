"""Exporta las hojas de la T3 para Godot: python3 tools/sprites/export_godot.py

Una carpeta por furgo (dehler.MODELS) y una textura por estado (daño 0-3, luces sí/no):
godot/assets/sprites/<furgo>/d<daño>[_luces].png
Columnas: 24 direcciones (frame k = rumbo k·15° horario desde la derecha).
Filas: volante (izq, recto, dcha) × 4 frames de rueda girando.
"""
import math
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import t3gen as T
import dehler

DIRS = 24
SPIN_FRAMES = 4
SPIN_STEP = (math.pi / 4) / SPIN_FRAMES * 2
STEER = math.radians(25)
SPRITES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "godot", "assets",
                       "sprites")

for model, build in dehler.MODELS.items():
    T.BUILDER[0] = build
    out = os.path.join(SPRITES, model)
    os.makedirs(out, exist_ok=True)
    for damage in range(4):
        for lights in (False, True):
            sheet = Image.new("RGBA", (T.CANVAS * DIRS, T.CANVAS * 3 * SPIN_FRAMES), (0, 0, 0, 0))
            for si, steer in enumerate((STEER, 0.0, -STEER)):
                for f in range(SPIN_FRAMES):
                    for k in range(DIRS):
                        spr = T.sprite(-k * 2 * math.pi / DIRS, spin=f * SPIN_STEP, steer=steer,
                                       lights=lights, damage=damage)
                        sheet.alpha_composite(spr, (k * T.CANVAS, (si * SPIN_FRAMES + f) * T.CANVAS))
            name = f"d{damage}{'_luces' if lights else ''}.png"
            sheet.save(os.path.join(out, name), optimize=True)
            print(model, name)
