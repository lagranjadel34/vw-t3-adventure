"""VW T3 Dehler Profi: azul marino con faldón plata, techo alto de fibra, faros dobles
rectangulares, parachoques grandes de plástico gris y llantas de radios. Importarlo
registra el modelo en t3gen.BUILDER."""
import math

import t3gen as T
from t3gen import (HL, HW, Z_FLOOR, Z_BELT, Z_ROOF, DECAL_BIAS, Poly, box, prism_y, rotate,
                   quad_on_side, quad_on_front, octagon, windshield_poly, rear_x_at, darken,
                   prism_y as _prism)

C_NAVY = (48, 70, 122)
C_SILVER = (164, 168, 176)
C_TRIM = (116, 120, 128)
C_ROOF = (182, 186, 192)
C_ROOF_SEAM = (120, 124, 132)
C_AWNING = (196, 200, 206)
C_GLASS = (20, 24, 36)
C_GLASS_HI = (96, 112, 146)
C_BUMPER = (112, 116, 124)
C_SPOKES = (206, 210, 216)
C_SPOKES_DARK = (130, 134, 142)
C_SKYLIGHT = (44, 50, 66)

Z_SKIRT = 0.56      # faldón plata hasta aquí
Z_HITOP = 2.34      # altura total con techo Dehler
SIDE = 0.89


def wire_wheel(cx, cy_center, side, spin, steer, hubcap=True):
    r, w = 0.32, 0.22
    y0, y1 = cy_center - w / 2, cy_center + w / 2
    cols = [T.C_TIRE_A if k % 2 == 0 else T.C_TIRE_B for k in range(8)]
    polys = prism_y(octagon(cx, Z_FLOOR, r, spin), y0, y1, T.C_TIRE_A, edge_colors=cols)
    oy = y1 if side > 0 else y0
    if hubcap:
        polys.append(Poly([(x, oy, z) for x, z in octagon(cx, Z_FLOOR, 0.23, spin)],
                          C_SPOKES, normal=(0, side, 0), bias=DECAL_BIAS))
        # Radios: cruz que gira con la rueda
        for a in (spin, spin + math.pi / 2):
            dx, dz = 0.2 * math.cos(a), 0.2 * math.sin(a)
            px, pz = -0.03 * math.sin(a), 0.03 * math.cos(a)
            polys.append(Poly([(cx - dx - px, oy, Z_FLOOR - dz - pz), (cx + dx - px, oy, Z_FLOOR + dz - pz),
                               (cx + dx + px, oy, Z_FLOOR + dz + pz), (cx - dx + px, oy, Z_FLOOR - dz + pz)],
                              C_SPOKES_DARK, normal=(0, side, 0), bias=DECAL_BIAS * 2))
    if steer:
        rotate(polys, (0, 0, 1), steer, (cx, cy_center, 0))
    return polys


def build_dehler(spin=0.0, steer=0.0, lights=False, damage=0):
    P = []
    # Carrocería: faldón plata abajo, azul marino arriba
    P += box(-HL, HL, -HW, HW, Z_FLOOR, Z_SKIRT, C_SILVER)
    P += box(-HL, HL, -HW, HW, Z_SKIRT, Z_BELT, C_NAVY)
    cab = [(2.25, Z_BELT), (1.82, Z_ROOF), (-2.22, Z_ROOF), (-2.26, Z_BELT)]
    P += prism_y(cab, -SIDE, SIDE, C_NAVY)
    # Techo alto Dehler: frente inclinado sobre el parabrisas, liso hasta atrás
    hitop = [(1.86, Z_ROOF), (1.35, Z_HITOP), (-2.05, Z_HITOP), (-2.22, Z_ROOF + 0.12), (-2.22, Z_ROOF)]
    roof = prism_y(hitop, -0.86, 0.86, C_ROOF, side_color=C_ROOF)
    P += roof
    for s in (1, -1):  # junta techo-carrocería
        P.append(quad_on_side(0.86 * s, -2.2, 1.8, Z_ROOF, Z_ROOF + 0.06, C_ROOF_SEAM, s))
    # Claraboya en la parte inclinada y aireador en el techo
    n = (0.49, 0, 0.51)
    def on_slope(t0, t1, y0, y1):
        (xa, za), (xb, zb) = hitop[0], hitop[1]
        p = lambda t: (xa + (xb - xa) * t, za + (zb - za) * t)
        (x0, z0), (x1, z1) = p(t0), p(t1)
        return [(x0, y0, z0), (x0, y1, z0), (x1, y1, z1), (x1, y0, z1)]
    P.append(Poly(on_slope(0.3, 0.85, -0.5, 0.5), C_SKYLIGHT, normal=n, bias=DECAL_BIAS))
    zt = Z_HITOP + 0.001
    P.append(Poly([(-0.5, -0.15, zt), (-0.2, -0.15, zt), (-0.2, 0.15, zt), (-0.5, 0.15, zt)],
                  C_ROOF_SEAM, normal=(0, 0, 1), bias=DECAL_BIAS))
    # Toldo enrollado en el lado izquierdo
    P += box(-1.7, 1.05, 0.84, 0.98, Z_ROOF + 0.18, Z_ROOF + 0.32, C_AWNING)

    # Lunas tintadas, banda gris bajo ventanas, rejilla trasera (pilar C)
    P.append(windshield_poly(-0.8, 0.8, 1.08, 1.78, C_GLASS))
    P.append(windshield_poly(0.3, 0.5, 1.5, 1.72, C_GLASS_HI, bias=DECAL_BIAS * 2))
    for s in (1, -1):
        y = SIDE * s
        for x0, x1 in ((1.15, 1.8), (0.05, 1.0), (-1.2, -0.1)):
            P.append(quad_on_side(y, x0, x1, 1.14, 1.74, C_GLASS, s))
        for z in (1.2, 1.32, 1.44, 1.56):
            P.append(quad_on_side(y, -2.1, -1.4, z, z + 0.06, T.C_BLACK, s))
        P.append(quad_on_side(HW * s, -HL, HL, 0.88, 0.98, C_TRIM, s))      # banda bajo ventanas
        P.append(quad_on_side(HW * s, -HL, HL, Z_SKIRT - 0.02, Z_SKIRT + 0.05, C_TRIM, s))  # moldura
        for wx in (1.23, -1.23):
            P.append(Poly([(wx + 0.38, HW * s, Z_FLOOR)]
                          + [(x, HW * s, z) for x, z in octagon(wx, Z_FLOOR, 0.38, math.pi / 8)
                             if z > Z_FLOOR] + [(wx - 0.38, HW * s, Z_FLOOR)],
                          T.C_BLACK, normal=(0, s, 0), bias=DECAL_BIAS))
    P.append(Poly([(rear_x_at(1.15), 0.7, 1.15), (rear_x_at(1.15), -0.7, 1.15),
                   (rear_x_at(1.7), -0.7, 1.7), (rear_x_at(1.7), 0.7, 1.7)], C_GLASS,
                  normal=(-1, 0, 0.05), bias=DECAL_BIAS))

    # Frontal: faros dobles rectangulares, rejilla negra con logo, intermitentes, rejilla baja
    head = T.C_HEAD_ON if lights else T.C_HEAD
    P.append(quad_on_front(HL, -0.5, 0.5, 0.78, 0.92, T.C_BLACK, 1))
    P.append(quad_on_front(HL, -0.06, 0.06, 0.8, 0.9, C_SPOKES, 1, bias=DECAL_BIAS * 2))
    P.append(quad_on_front(HL, -0.75, 0.75, 0.6, 0.7, T.C_BLACK, 1))
    for s in (1, -1):
        y0, y1 = sorted((0.52 * s, 0.86 * s))
        broken = damage >= 2 and s == -1
        P.append(quad_on_front(HL, y0, y1, 0.78, 0.92, T.C_BLACK if broken else head, 1,
                               bias=DECAL_BIAS * 2, emissive=lights and not broken))
        iy0, iy1 = sorted((0.74 * s, 0.88 * s))
        P.append(quad_on_front(HL, iy0, iy1, 0.6, 0.7, T.C_INDICATOR, 1, bias=DECAL_BIAS * 2))
        tail_ok = not (damage >= 3 and s == 1)
        P.append(quad_on_front(-HL, y0, y1, 0.6, 0.92, (T.C_TAIL_ON if lights else T.C_TAIL)
                               if tail_ok else T.C_BLACK, -1, emissive=lights and tail_ok))
    for z in (0.66, 0.74):
        P.append(quad_on_front(-HL, -0.45, 0.45, z, z + 0.04, T.C_BLACK, -1))
    # Parachoques grandes envolventes
    fb = box(HL, HL + 0.14, -0.95, 0.95, 0.3, 0.56, C_BUMPER)
    if damage >= 3:
        rotate(fb, (1, 0, 0), math.radians(-14), (HL, 0.95, 0.56))
    P += fb
    rb = box(-HL - 0.12, -HL, -0.95, 0.95, 0.3, 0.54, C_BUMPER)
    if damage >= 2:
        rotate(rb, (0, 0, 1), math.radians(6), (-HL, -0.95, 0.4))
    P += rb
    for s in (1, -1):
        y0, y1 = sorted((0.92 * s, 1.06 * s))
        P += box(1.85, 1.95, y0, y1, 1.12, 1.3, T.C_BLACK)
    for wx, st in ((1.23, steer), (-1.23, 0.0)):
        for s in (1, -1):
            P += wire_wheel(wx, 0.83 * s, s, spin, st, hubcap=not (damage >= 3 and wx < 0 and s == 1))

    # Daños (0 bien · 1 desgastado · 2 averiado · 3 crítico)
    if damage >= 1:
        for s in (1, -1):
            for x0, z0, w, h in ((1.55, 0.6, 0.22, 0.12), (-0.85, 0.62, 0.3, 0.1),
                                 (-1.65, 0.7, 0.16, 0.14)):
                P.append(quad_on_side(HW * s, x0, x0 + w, z0, z0 + h, T.C_RUST, s, bias=DECAL_BIAS * 2))
    if damage >= 2:
        P.append(quad_on_side(-HW, 0.2, 0.75, 0.6, 0.86, darken(C_NAVY, 0.6), -1, bias=DECAL_BIAS * 2))
        P.append(quad_on_side(HW, -1.2, -0.6, 0.62, 0.86, darken(C_NAVY, 0.6), 1, bias=DECAL_BIAS * 2))
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


T.BUILDER[0] = build_dehler
