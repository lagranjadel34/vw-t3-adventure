"""T3 de techo alto según las fichas de Ara. Dehler Profi (1983): gris azulado liso, techo alto de fibra
más claro con claraboya elevada, ventana en el frente inclinado y escotilla, faros redondos,
parachoques negros y llantas de chapa con tapacubos. Carthago: ocre con techo alto
blanco redondeado, escotilla central, llantas de aleación, antinieblas amarillos y, en el lado
derecho, franja granate, rejillas de nevera y logo del tuareg. Importarlo registra el modelo en
t3gen.BUILDER."""
import math

import t3gen as T
from t3gen import (HL, HW, Z_FLOOR, Z_BELT, Z_ROOF, DECAL_BIAS, Poly, box, prism_y, rotate,
                   quad_on_side, quad_on_front, octagon, windshield_poly, rear_x_at, darken,
                   prism_y as _prism)

C_TRIM = (50, 53, 58)
C_GLASS = (40, 50, 58)
C_GLASS_HI = (103, 121, 121)
C_BUMPER = (48, 52, 55)
C_HUBCAP = (178, 188, 189)
C_HUBCAP_DARK = (120, 128, 130)
C_HATCH = (76, 75, 80)
C_PLATE = (226, 230, 232)
C_FOG = (220, 190, 30)
C_STRIPE = (96, 26, 38)
C_STRIPE_DARK = (40, 28, 30)
C_VENT = (196, 188, 168)
C_LOGO = (66, 112, 168)
C_LOGO_FACE = (226, 210, 178)

# Estilo de cada furgo de techo alto (mismo chasis T3, cambian techo, pintura y llantas)
DEHLER = dict(body=(86, 103, 113), roof=(148, 161, 167), roof_seam=(100, 117, 125),
              skylight=(147, 175, 178), roof_windows=True, round_nose=False,
              wheels="chapa", fog_lights=False, right_decor=False)
CARTHAGO = dict(body=(158, 106, 58), roof=(236, 236, 236), roof_seam=(196, 196, 196),
                skylight=None, roof_windows=False, round_nose=True,
                wheels="aleacion", fog_lights=True, right_decor=True)

Z_MOLDING = 0.56    # moldura negra baja
Z_HITOP = 2.34      # altura total con techo alto
SIDE = 0.89


def wheel(cx, cy_center, side, spin, steer, hubcap=True, alloy=False):
    r, w = 0.32, 0.22
    y0, y1 = cy_center - w / 2, cy_center + w / 2
    cols = [T.C_TIRE_A if k % 2 == 0 else T.C_TIRE_B for k in range(8)]
    polys = prism_y(octagon(cx, Z_FLOOR, r, spin), y0, y1, T.C_TIRE_A, edge_colors=cols)
    oy = y1 if side > 0 else y0
    if hubcap:
        polys.append(Poly([(x, oy, z) for x, z in octagon(cx, Z_FLOOR, 0.23, spin)],
                          C_HUBCAP, normal=(0, side, 0), bias=DECAL_BIAS))
        # Chapa: marca del tapacubos que gira; aleación: 5 radios
        spokes = [spin + k * 2 * math.pi / 5 for k in range(5)] if alloy else [spin]
        for a in spokes:
            dx, dz = 0.2 * math.cos(a), 0.2 * math.sin(a)
            if alloy:
                dx, dz = dx / 2, dz / 2
                cx_, cz_ = cx + dx * 1.2, Z_FLOOR + dz * 1.2
            else:
                cx_, cz_ = cx, Z_FLOOR
            px, pz = -0.03 * math.sin(a), 0.03 * math.cos(a)
            polys.append(Poly([(cx_ - dx - px, oy, cz_ - dz - pz), (cx_ + dx - px, oy, cz_ + dz - pz),
                               (cx_ + dx + px, oy, cz_ + dz + pz), (cx_ - dx + px, oy, cz_ - dz + pz)],
                              C_HUBCAP_DARK, normal=(0, side, 0), bias=DECAL_BIAS * 2))
    if steer:
        rotate(polys, (0, 0, 1), steer, (cx, cy_center, 0))
    return polys


def build_hitop(st, spin=0.0, steer=0.0, lights=False, damage=0):
    C_BODY, C_ROOF, C_ROOF_SEAM = st["body"], st["roof"], st["roof_seam"]
    P = []
    # Carrocería gris azulado lisa (moldura negra baja)
    P += box(-HL, HL, -HW, HW, Z_FLOOR, Z_BELT, C_BODY)
    cab = [(2.25, Z_BELT), (1.82, Z_ROOF), (-2.22, Z_ROOF), (-2.26, Z_BELT)]
    P += prism_y(cab, -SIDE, SIDE, C_BODY)
    # Techo alto: frente inclinado sobre el parabrisas (redondeado en la Carthago), liso hasta atrás
    if st["round_nose"]:
        hitop = [(1.9, Z_ROOF), (1.75, Z_ROOF + 0.3), (1.45, Z_HITOP - 0.06), (1.2, Z_HITOP),
                 (-2.0, Z_HITOP), (-2.2, Z_HITOP - 0.12), (-2.22, Z_ROOF)]
    else:
        hitop = [(1.86, Z_ROOF), (1.35, Z_HITOP), (-2.05, Z_HITOP), (-2.22, Z_ROOF + 0.12), (-2.22, Z_ROOF)]
    P += prism_y(hitop, -0.86, 0.86, C_ROOF, side_color=C_ROOF)
    for s in (1, -1):  # junta techo-carrocería
        P.append(quad_on_side(0.86 * s, -2.2, 1.8, Z_ROOF, Z_ROOF + 0.06, C_ROOF_SEAM, s))
    # Ventana delantera del techo y escotilla elevada en el centro
    zt = Z_HITOP + 0.001
    def on_top(x0, x1, y0, y1, color, z=zt, bias=DECAL_BIAS):
        return Poly([(x0, y0, z), (x1, y0, z), (x1, y1, z), (x0, y1, z)], color,
                    normal=(0, 0, 1), bias=bias)
    if st["skylight"]:
        P.append(on_top(0.95, 1.3, -0.3, 0.3, st["skylight"]))
    P += box(-0.32, 0.32, -0.32, 0.32, Z_HITOP, Z_HITOP + 0.1, C_ROOF)
    P.append(on_top(-0.28, 0.28, -0.28, 0.28, C_HATCH, z=Z_HITOP + 0.101))
    for s in (1, -1):  # ventanitas laterales del techo
        if st["roof_windows"]:
            P.append(quad_on_side(0.86 * s, -1.6, -0.6, 2.0, 2.18, C_GLASS_HI, s))

    # Lunas, moldura negra, rejilla de ventilación en el pilar trasero
    P.append(windshield_poly(-0.8, 0.8, 1.08, 1.78, C_GLASS))
    P.append(windshield_poly(0.3, 0.5, 1.5, 1.72, C_GLASS_HI, bias=DECAL_BIAS * 2))
    for s in (1, -1):
        y = SIDE * s
        # Lado derecho de la Carthago: puerta y una ventana partida (sin la trasera)
        decor = st["right_decor"] and s == -1
        windows = ((1.0, 1.8), (-0.5, 0.6)) if decor else ((1.15, 1.8), (0.05, 1.0), (-1.2, -0.1))
        for x0, x1 in windows:
            P.append(quad_on_side(y, x0, x1, 1.14, 1.74, C_GLASS, s))
        mullion = 0.03 if decor else 0.5
        P.append(quad_on_side(y, mullion, mullion + 0.05, 1.14, 1.74, C_BODY, s, bias=DECAL_BIAS * 2))  # parteluz
        if decor:
            # Franja granate con filete oscuro, rejillas de nevera y el logo del tuareg
            P.append(quad_on_side(HW * s, -HL, 1.7, 0.86, 0.98, C_STRIPE, s, bias=DECAL_BIAS * 2))
            P.append(quad_on_side(HW * s, -HL, 1.4, 1.01, 1.04, C_STRIPE_DARK, s, bias=DECAL_BIAS * 2))
            P.append(quad_on_side(HW * s, -0.1, 0.6, 0.84, 1.0, C_VENT, s, bias=DECAL_BIAS * 3))
            P.append(quad_on_side(HW * s, 0.05, 0.6, 0.4, 0.56, C_VENT, s, bias=DECAL_BIAS * 3))
            P.append(quad_on_side(y, -1.46, -0.86, 1.2, 1.7, C_LOGO, s, bias=DECAL_BIAS * 2))
            P.append(quad_on_side(y, -1.22, -1.06, 1.5, 1.62, C_LOGO_FACE, s, bias=DECAL_BIAS * 3))
        for z in (1.2, 1.32, 1.44, 1.56):
            P.append(quad_on_side(y, -2.1, -1.6, z, z + 0.06, T.C_BLACK, s))
        P.append(quad_on_side(HW * s, -HL, HL, Z_MOLDING - 0.04, Z_MOLDING + 0.04, C_TRIM, s))
        for wx in (1.23, -1.23):
            P.append(Poly([(wx + 0.38, HW * s, Z_FLOOR)]
                          + [(x, HW * s, z) for x, z in octagon(wx, Z_FLOOR, 0.38, math.pi / 8)
                             if z > Z_FLOOR] + [(wx - 0.38, HW * s, Z_FLOOR)],
                          T.C_BLACK, normal=(0, s, 0), bias=DECAL_BIAS))
    P.append(Poly([(rear_x_at(1.12), 0.72, 1.12), (rear_x_at(1.12), -0.72, 1.12),
                   (rear_x_at(1.72), -0.72, 1.72), (rear_x_at(1.72), 0.72, 1.72)], C_GLASS,
                  normal=(-1, 0, 0.05), bias=DECAL_BIAS))

    # Frontal: faros redondos, rejilla negra con logo, intermitentes bajo los faros
    head = T.C_HEAD_ON if lights else T.C_HEAD
    P.append(quad_on_front(HL, -0.55, 0.55, 0.76, 0.94, T.C_BLACK, 1))
    P.append(quad_on_front(HL, -0.06, 0.06, 0.8, 0.9, C_HUBCAP, 1, bias=DECAL_BIAS * 2))
    P.append(quad_on_front(HL, -0.75, 0.75, 0.6, 0.7, T.C_BLACK, 1))
    for s in (1, -1):
        broken = damage >= 2 and s == -1
        hy = 0.72 * s
        P.append(Poly([(HL, hy + y, 0.85 + z) for y, z in octagon(0, 0, 0.1, math.pi / 8)],
                      T.C_BLACK if broken else head, normal=(1, 0, 0), bias=DECAL_BIAS * 2,
                      emissive=lights and not broken))
        iy0, iy1 = sorted((0.64 * s, 0.84 * s))
        P.append(quad_on_front(HL, iy0, iy1, 0.6, 0.7, T.C_INDICATOR, 1, bias=DECAL_BIAS * 2))
        # Trasera: pilotos bajos y anchos sobre el parachoques
        ty0, ty1 = sorted((0.5 * s, 0.86 * s))
        tail_ok = not (damage >= 3 and s == 1)
        P.append(quad_on_front(-HL, ty0, ty1, 0.58, 0.74, (T.C_TAIL_ON if lights else T.C_TAIL)
                               if tail_ok else T.C_BLACK, -1, emissive=lights and tail_ok))
    P.append(quad_on_front(-HL, -0.3, 0.3, 0.6, 0.72, C_PLATE, -1))
    if st["fog_lights"]:  # antinieblas amarillos en el parachoques
        for s in (1, -1):
            fy0, fy1 = sorted((0.62 * s, 0.78 * s))
            P.append(quad_on_front(HL + 0.12, fy0, fy1, 0.36, 0.46, C_FOG, 1, bias=DECAL_BIAS * 2))
    # Parachoques negros
    fb = box(HL, HL + 0.12, -0.95, 0.95, 0.32, 0.52, C_BUMPER)
    if damage >= 3:
        rotate(fb, (1, 0, 0), math.radians(-14), (HL, 0.95, 0.52))
    P += fb
    rb = box(-HL - 0.12, -HL, -0.95, 0.95, 0.32, 0.52, C_BUMPER)
    if damage >= 2:
        rotate(rb, (0, 0, 1), math.radians(6), (-HL, -0.95, 0.4))
    P += rb
    for s in (1, -1):  # retrovisores
        y0, y1 = sorted((0.92 * s, 1.06 * s))
        P += box(1.85, 1.95, y0, y1, 1.12, 1.3, T.C_BLACK)
    for wx, ws in ((1.23, steer), (-1.23, 0.0)):
        for s in (1, -1):
            P += wheel(wx, 0.83 * s, s, spin, ws, hubcap=not (damage >= 3 and wx < 0 and s == 1),
                       alloy=st["wheels"] == "aleacion")

    # Daños (0 bien · 1 desgastado · 2 averiado · 3 crítico)
    if damage >= 1:
        for s in (1, -1):
            for x0, z0, w, h in ((1.55, 0.6, 0.22, 0.12), (-0.85, 0.62, 0.3, 0.1),
                                 (-1.65, 0.7, 0.16, 0.14)):
                P.append(quad_on_side(HW * s, x0, x0 + w, z0, z0 + h, T.C_RUST, s, bias=DECAL_BIAS * 2))
    if damage >= 2:
        P.append(quad_on_side(-HW, 0.2, 0.75, 0.6, 0.86, darken(C_BODY, 0.6), -1, bias=DECAL_BIAS * 2))
        P.append(quad_on_side(HW, -1.2, -0.6, 0.62, 0.86, darken(C_BODY, 0.6), 1, bias=DECAL_BIAS * 2))
        pts = [(-0.6, 1.2), (-0.35, 1.38), (-0.45, 1.5), (-0.1, 1.68)]
        for (y0, z0), (y1, z1) in zip(pts, pts[1:]):
            P.append(windshield_poly(min(y0, y1), max(y0, y1) + 0.06, min(z0, z1),
                                     max(z0, z1), T.C_CRACK, bias=DECAL_BIAS * 2))
    if damage >= 3:
        for s in (1, -1):
            P.append(quad_on_side(HW * s, -2.2, -1.0, 0.32, 0.54, T.C_RUST_DARK, s, bias=DECAL_BIAS * 3))
            P.append(quad_on_side(HW * s, 1.0, 2.2, 0.32, 0.5, T.C_RUST_DARK, s, bias=DECAL_BIAS * 3))
        P.append(quad_on_side(HW, 0.1, 1.0, 0.6, 0.95, T.C_PRIMER, 1, bias=DECAL_BIAS * 3))
        zt = Z_HITOP + 0.002
        for x0, y0, w, h in ((-1.4, -0.45, 0.3, 0.2), (-1.2, -0.3, 0.18, 0.28), (0.4, 0.3, 0.16, 0.14)):
            P.append(Poly([(x0, y0, zt), (x0 + w, y0, zt), (x0 + w, y0 + h, zt), (x0, y0 + h, zt)],
                          darken(C_ROOF, 0.6), normal=(0, 0, 1), bias=DECAL_BIAS))
    return P


def build_dehler(spin=0.0, steer=0.0, lights=False, damage=0):
    return build_hitop(DEHLER, spin, steer, lights, damage)


def build_carthago(spin=0.0, steer=0.0, lights=False, damage=0):
    return build_hitop(CARTHAGO, spin, steer, lights, damage)


MODELS = {"dehler": build_dehler, "carthago": build_carthago}
T.BUILDER[0] = build_dehler
