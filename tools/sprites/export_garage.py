"""Hojas del escaparate "Elegir camperizador": python3 tools/sprites/export_garage.py

Una imagen por furgo (dehler.MODELS): godot/assets/sprites/<furgo>/garage.png.
Vista de frente, con la cámara baja (GARAGE_ELEVATION_DEG) para que la furgo gire sobre sí misma.
Columnas: 24 rumbos (frame k = rumbo k·15° horario desde la derecha). Filas: 4 frames de rueda.
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
GARAGE_ELEVATION_DEG = 12.0
SPRITES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "godot", "assets",
                       "sprites")

for model, build in dehler.MODELS.items():
    T.BUILDER[0] = build
    out = os.path.join(SPRITES, model)
    os.makedirs(out, exist_ok=True)
    sheet = Image.new("RGBA", (T.CANVAS * DIRS, T.CANVAS * SPIN_FRAMES), (0, 0, 0, 0))
    for f in range(SPIN_FRAMES):
        for k in range(DIRS):
            spr = T.sprite(-k * 2 * math.pi / DIRS, spin=f * SPIN_STEP,
                           elevation_deg=GARAGE_ELEVATION_DEG)
            sheet.alpha_composite(spr, (k * T.CANVAS, f * T.CANVAS))
    sheet.save(os.path.join(out, "garage.png"), optimize=True)
    print(model, "garage.png")
