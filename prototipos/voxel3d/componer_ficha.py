import sys
from PIL import Image, ImageDraw, ImageFont
S, FONT, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
D = S + "/ficha/"
W, H = 2400, 1500
BG = (220, 228, 230); INK = (20, 28, 48); SUB = (70, 90, 110); CARD = (234, 239, 240)
im = Image.new("RGB", (W, H), BG); d = ImageDraw.Draw(im)
def f(sz, wt=600):
    ft = ImageFont.truetype(FONT, sz)
    try: ft.set_variation_by_axes([wt])
    except Exception: pass
    return ft
d.text((W // 2, 50), "FICHA 3D: VW T3 DEHLER PROFI 1983", font=f(64, 700), fill=INK, anchor="mt")
d.text((W // 2, 130), "Modelo 3D con curvas · render pixelado en Godot (Compatibility) · prototipo de estilo",
       font=f(30, 400), fill=SUB, anchor="mt")
def put(name, box, label, crop=None):
    x, y, w, h = box
    d.rounded_rectangle((x, y, x + w, y + h), 18, fill=CARD)
    img = Image.open(D + name + ".png") if "/" not in name else Image.open(name)
    if crop: img = img.crop(crop)
    sc = min((w - 30) / img.width, (h - 70) / img.height)
    img = img.resize((int(img.width * sc), int(img.height * sc)), Image.NEAREST)
    im.paste(img, (x + (w - img.width) // 2, y + 15 + (h - 70 - img.height) // 2))
    d.text((x + w // 2, y + h - 22), label, font=f(28, 650), fill=INK, anchor="mb")
# fila 1: tres cuartos grande + trasera + en el mundo
put("tres_cuartos", (40, 190, 760, 600), "TRES CUARTOS DELANTERA", (60, 30, 900, 700))
put("tres_cuartos_trasera", (820, 190, 760, 600), "TRES CUARTOS TRASERA", (60, 30, 900, 700))
put(S + "/mundo.png", (1600, 190, 760, 600), "EN EL MUNDO (320x180, ATARDECER)", (40, 60, 1000, 660))
# fila 2: laterales, frontal, trasera, superior
put("lateral_izq", (40, 810, 600, 330), "LATERAL IZQUIERDA", (130, 160, 830, 560))
put("lateral_dcha", (660, 810, 600, 330), "LATERAL DERECHA", (130, 160, 830, 560))
put("frontal", (1280, 810, 300, 330), "FRONTAL", (200, 10, 760, 690))
put("trasera", (1600, 810, 300, 330), "TRASERA", (200, 10, 760, 690))
put("superior", (1920, 810, 440, 680), "SUPERIOR", (330, 0, 630, 720))
# datos
x, y = 40, 1160
d.rounded_rectangle((x, y, 1900, 1490), 18, fill=CARD)
rows = [("Año", "1983"), ("Motor", "1.9 gasolina, 90 CV · caja de 4 marchas"),
        ("Techo", "Alto de fibra: ventana lateral, escotilla y claraboya"),
        ("Medidas", "4,57 x 1,84 x 2,34 m · batalla 2,46 m"),
        ("Modelo 3D", "Medido y superpuesto sobre tu ficha dehler-profi-1983"),
        ("Render", "320x240 en 3D, ampliado x3 con píxel duro (nearest)")]
for i, (k, v) in enumerate(rows):
    yy = y + 25 + i * 50
    d.text((x + 30, yy), k, font=f(30, 700), fill=INK)
    d.text((x + 260, yy), v, font=f(30, 400), fill=INK)
# paleta
pal = [(86, 103, 113), (128, 143, 150), (92, 109, 118), (150, 164, 168), (18, 26, 32), (112, 130, 137), (178, 188, 189), (222, 132, 40)]
d.text((1560, y + 25), "Paleta", font=f(30, 700), fill=INK)
for i, c in enumerate(pal):
    cx, cy = 1560 + (i % 4) * 80, y + 90 + (i // 4) * 80
    d.rounded_rectangle((cx, cy, cx + 64, cy + 64), 8, fill=c, outline=INK, width=2)
d.text((W - 40, 30), "La Granja del 34", font=f(26, 500), fill=SUB, anchor="rt")
im.save(OUT)
