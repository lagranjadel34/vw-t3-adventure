"""Generador de sprites de la VW T3 en vista cenital-isométrica.

Modelo 3D low-poly (cajas y prismas) -> rasterizado con z-buffer a 1 px sin
antialiasing -> píxel art coherente en cualquier ángulo. Cambiar el modelo y
re-ejecutar regenera todas las fichas.

Ejes del modelo (metros): x adelante, y izquierda, z arriba. Origen: centro en el suelo.
"""
import math
import numpy as np
from PIL import Image

# --- Cámara / escala ---
PX_PER_M = 13.0          # 4.57 m de T3 ≈ 59 px (el sprite actual mide 64)
# Cámara del mapa (estilo GTA 1): cenital y con perspectiva, a CAM_HEIGHT_PX sobre el suelo
# (= CITY_CAMERA_HEIGHT en godot/config/game_config.gd). En el juego sigue al eje
# delantero de la furgo, CAM_AHEAD_PX por delante de su centro.
ELEVATION_DEG = 90.0     # 90 = cenital puro; 60 = la vista "ligeramente isométrica" anterior
CAM_HEIGHT_PX = 300.0    # None = proyección paralela (sin perspectiva)
CAM_AHEAD_PX = 19.0      # VAN_FRONT_AXLE_RATIO · VAN_LENGTH_PX
CANVAS = 80
PIVOT = (40, 40)         # dónde cae el centro de la furgo (suelo) en el lienzo
DECAL_BIAS = 0.03
OUTLINE = (26, 24, 36)

# --- Paleta (bitono clásico T3) ---
C_LOWER = (104, 150, 62)
C_UPPER = (232, 222, 186)
C_POPTOP = (246, 244, 236)
C_POPTOP_SEAL = (120, 112, 98)
C_GLASS = (58, 72, 112)
C_GLASS_HI = (120, 140, 188)
C_BLACK = (34, 34, 40)
C_BUMPER = (70, 72, 78)
C_TIRE_A = (30, 30, 34)
C_TIRE_B = (52, 52, 58)
C_HUB = (176, 180, 186)
C_HEAD = (196, 196, 170)
C_HEAD_ON = (255, 250, 200)
C_TAIL = (130, 30, 30)
C_TAIL_ON = (255, 60, 50)
C_INDICATOR = (210, 130, 40)
C_RUST = (128, 70, 36)
C_RUST_DARK = (92, 48, 28)
C_PRIMER = (150, 150, 146)
C_CRACK = (200, 210, 230)

# Media T3 (m)
HL = 2.285   # medio largo
HW = 0.92    # medio ancho
Z_FLOOR = 0.32
Z_BELT = 1.0
Z_ROOF = 1.84

LIGHT = np.array([-0.35, 0.45, 0.82])
LIGHT /= np.linalg.norm(LIGHT)
SHADE_LEVELS = np.array([0.62, 0.76, 0.9, 1.0])


class Poly:
    def __init__(self, verts, color, normal=None, bias=0.0, emissive=False):
        self.v = np.array(verts, dtype=float)
        self.color = color
        if normal is None:
            n = np.cross(self.v[1] - self.v[0], self.v[2] - self.v[0])
            normal = n / (np.linalg.norm(n) + 1e-12)
        self.n = np.array(normal, dtype=float)
        self.bias = bias
        self.emissive = emissive


def orient(polys, center):
    for p in polys:
        if np.dot(p.n, p.v.mean(axis=0) - center) < 0:
            p.n = -p.n
    return polys


def prism_y(profile_xz, y0, y1, color, side_color=None, edge_colors=None):
    """Prisma convexo: perfil en XZ extruido en Y."""
    polys = []
    side_color = side_color or color
    a = [(x, y0, z) for x, z in profile_xz]
    b = [(x, y1, z) for x, z in profile_xz]
    polys.append(Poly(a, side_color))
    polys.append(Poly(b, side_color))
    n = len(profile_xz)
    for i in range(n):
        j = (i + 1) % n
        c = edge_colors[i] if edge_colors else color
        polys.append(Poly([a[i], a[j], b[j], b[i]], c))
    center = np.array([np.mean([p[0] for p in profile_xz]), (y0 + y1) / 2,
                       np.mean([p[1] for p in profile_xz])])
    return orient(polys, center)


def box(x0, x1, y0, y1, z0, z1, color):
    return prism_y([(x0, z0), (x1, z0), (x1, z1), (x0, z1)], y0, y1, color)


def rot_matrix(axis, ang):
    axis = np.array(axis, float) / np.linalg.norm(axis)
    x, y, z = axis
    c, s = math.cos(ang), math.sin(ang)
    C = 1 - c
    return np.array([[c + x*x*C, x*y*C - z*s, x*z*C + y*s],
                     [y*x*C + z*s, c + y*y*C, y*z*C - x*s],
                     [z*x*C - y*s, z*y*C + x*s, c + z*z*C]])


def rotate(polys, axis, ang, pivot):
    R = rot_matrix(axis, ang)
    pv = np.array(pivot, float)
    for p in polys:
        p.v = (p.v - pv) @ R.T + pv
        p.n = R @ p.n
    return polys


def quad_on_side(y, x0, x1, z0, z1, color, sign, bias=DECAL_BIAS, emissive=False):
    return Poly([(x0, y, z0), (x1, y, z0), (x1, y, z1), (x0, y, z1)], color,
                normal=(0, sign, 0), bias=bias, emissive=emissive)


def quad_on_front(x, y0, y1, z0, z1, color, sign, bias=DECAL_BIAS, emissive=False):
    return Poly([(x, y0, z0), (x, y1, z0), (x, y1, z1), (x, y0, z1)], color,
                normal=(sign, 0, 0), bias=bias, emissive=emissive)


def octagon(cx, cz, r, phase):
    return [(cx + r * math.cos(phase + k * math.pi / 4),
             cz + r * math.sin(phase + k * math.pi / 4)) for k in range(8)]


def wheel(cx, cy_center, side, spin, steer, hubcap=True):
    r, w = 0.32, 0.22
    y0, y1 = cy_center - w / 2, cy_center + w / 2
    edge_cols = [C_TIRE_A if k % 2 == 0 else C_TIRE_B for k in range(8)]
    polys = prism_y(octagon(cx, Z_FLOOR, r, spin), y0, y1, C_TIRE_A,
                    side_color=C_TIRE_A, edge_colors=edge_cols)
    outer_y = y1 if side > 0 else y0
    if hubcap:
        polys.append(Poly([(x, outer_y, z) for x, z in octagon(cx, Z_FLOOR, 0.17, spin)],
                          C_HUB, normal=(0, side, 0), bias=DECAL_BIAS))
        bx = cx + 0.08 * math.cos(spin)
        bz = Z_FLOOR + 0.08 * math.sin(spin)
        polys.append(quad_on_side(outer_y, bx - 0.04, bx + 0.04, bz - 0.04, bz + 0.04,
                                  C_BLACK, side, bias=DECAL_BIAS * 2))
    if steer:
        rotate(polys, (0, 0, 1), steer, (cx, cy_center, 0))
    return polys


def cabin_x_at(z):
    """x del parabrisas inclinado a la altura z."""
    return 2.25 - (z - Z_BELT) * (0.43 / (Z_ROOF - Z_BELT))


def rear_x_at(z):
    return -2.26 + (z - Z_BELT) * (0.04 / (Z_ROOF - Z_BELT))


def windshield_poly(y0, y1, z0, z1, color, bias=DECAL_BIAS):
    n = np.array([0.84, 0, 0.43])
    n /= np.linalg.norm(n)
    return Poly([(cabin_x_at(z0), y0, z0), (cabin_x_at(z0), y1, z0),
                 (cabin_x_at(z1), y1, z1), (cabin_x_at(z1), y0, z1)], color, normal=n, bias=bias)


def build_t3(spin=0.0, steer=0.0, lights=False, damage=0):
    P = []
    # Carrocería inferior (verde) y cabina superior (crema)
    P += box(-HL, HL, -HW, HW, Z_FLOOR, Z_BELT, C_LOWER)
    cab = [(2.25, Z_BELT), (1.82, Z_ROOF), (-2.22, Z_ROOF), (-2.26, Z_BELT)]
    P += prism_y(cab, -0.89, 0.89, C_UPPER)
    # Techo elevable Westfalia
    poptop = box(-1.95, 1.2, -0.8, 0.8, Z_ROOF, Z_ROOF + 0.12, C_POPTOP_SEAL)
    for p in poptop:
        if p.n[2] > 0.5:
            p.color = C_POPTOP
    P += poptop

    # Lunas
    P.append(windshield_poly(-0.8, 0.8, 1.08, 1.78, C_GLASS))
    P.append(windshield_poly(0.3, 0.5, 1.5, 1.72, C_GLASS_HI, bias=DECAL_BIAS * 2))
    for s in (1, -1):
        y = 0.89 * s
        for x0, x1 in ((1.15, 1.8), (0.05, 1.0), (-1.05, -0.1), (-2.05, -1.2)):
            P.append(quad_on_side(y, x0, x1, 1.12, 1.72, C_GLASS, s))
        # Rejilla de admisión del motor (trasera, costado)
        P.append(quad_on_side(HW * s, -2.0, -1.45, 0.82, 0.92, C_BLACK, s))
        # Paso de rueda
        for wx in (1.23, -1.23):
            P.append(Poly([(wx + 0.38, HW * s, Z_FLOOR)]
                          + [(x, HW * s, z) for x, z in octagon(wx, Z_FLOOR, 0.38, math.pi / 8)
                             if z > Z_FLOOR] + [(wx - 0.38, HW * s, Z_FLOOR)],
                          C_BLACK, normal=(0, s, 0), bias=DECAL_BIAS))
    # Luneta trasera
    P.append(Poly([(rear_x_at(1.15), 0.7, 1.15), (rear_x_at(1.15), -0.7, 1.15),
                   (rear_x_at(1.7), -0.7, 1.7), (rear_x_at(1.7), 0.7, 1.7)], C_GLASS,
                  normal=(-1, 0, 0.05), bias=DECAL_BIAS))
    # Frontal: faros, intermitentes, rejilla
    head = C_HEAD_ON if lights else C_HEAD
    for s in (1, -1):
        y0, y1 = sorted((0.55 * s, 0.86 * s))
        broken = damage >= 2 and s == -1
        P.append(quad_on_front(HL, y0, y1, 0.66, 0.9, C_BLACK if broken else head, 1,
                               emissive=lights and not broken))
        P.append(quad_on_front(HL, y0, y1, 0.56, 0.64, C_INDICATOR, 1))
        tail_ok = not (damage >= 3 and s == 1)
        P.append(quad_on_front(-HL, y0, y1, 0.6, 0.92, (C_TAIL_ON if lights else C_TAIL)
                               if tail_ok else C_BLACK, -1, emissive=lights and tail_ok))
    P.append(quad_on_front(HL, -0.5, 0.5, 0.8, 0.88, C_BLACK, 1))
    # Tapa del motor (trasera)
    for z in (0.42, 0.5):
        P.append(quad_on_front(-HL, -0.45, 0.45, z, z + 0.04, C_BLACK, -1))
    # Parachoques
    front_bumper = box(HL, HL + 0.08, -0.95, 0.95, 0.34, 0.5, C_BUMPER)
    if damage >= 3:
        rotate(front_bumper, (1, 0, 0), math.radians(-14), (HL, 0.95, 0.5))
    P += front_bumper
    rear_bumper = box(-HL - 0.08, -HL, -0.95, 0.95, 0.34, 0.5, C_BUMPER)
    if damage >= 2:
        rotate(rear_bumper, (0, 0, 1), math.radians(6), (-HL, -0.95, 0.4))
    P += rear_bumper
    # Retrovisores
    for s in (1, -1):
        y0, y1 = sorted((0.92 * s, 1.06 * s))
        P += box(1.85, 1.95, y0, y1, 1.12, 1.26, C_BLACK)
    # Ruedas (exterior 2 cm por fuera del costado: se ven por el paso de rueda)
    for wx, st in ((1.23, steer), (-1.23, 0.0)):
        for s in (1, -1):
            P += wheel(wx, 0.83 * s, s, spin, st, hubcap=not (damage >= 3 and wx < 0 and s == 1))

    # Daños según estado del motor (0 bien · 1 desgastado · 2 averiado · 3 crítico)
    if damage >= 1:
        for s in (1, -1):
            for x0, z0, w, h in ((1.55, 0.36, 0.22, 0.12), (-0.85, 0.36, 0.3, 0.1),
                                 (-1.65, 0.62, 0.16, 0.14)):
                P.append(quad_on_side(HW * s, x0, x0 + w, z0, z0 + h, C_RUST, s, bias=DECAL_BIAS * 2))
    if damage >= 2:
        P.append(quad_on_side(-HW, 0.2, 0.75, 0.45, 0.8, darken(C_LOWER, 0.7), -1, bias=DECAL_BIAS * 2))
        P.append(quad_on_side(HW, -1.2, -0.6, 0.5, 0.75, darken(C_LOWER, 0.7), 1, bias=DECAL_BIAS * 2))
        # Grieta en el parabrisas (zigzag de 1 px)
        pts = [(-0.6, 1.2), (-0.35, 1.38), (-0.45, 1.5), (-0.1, 1.68)]
        for (y0, z0), (y1, z1) in zip(pts, pts[1:]):
            P.append(windshield_poly(min(y0, y1), max(y0, y1) + 0.06, min(z0, z1),
                                     max(z0, z1), C_CRACK, bias=DECAL_BIAS * 2))
    if damage >= 3:
        for s in (1, -1):
            P.append(quad_on_side(HW * s, -2.2, -1.0, 0.32, 0.5, C_RUST_DARK, s, bias=DECAL_BIAS * 3))
            P.append(quad_on_side(HW * s, 1.0, 2.2, 0.32, 0.46, C_RUST_DARK, s, bias=DECAL_BIAS * 3))
        P.append(quad_on_side(HW, 0.1, 1.0, 0.45, 0.95, C_PRIMER, 1, bias=DECAL_BIAS * 3))  # puerta de desguace
        zt = Z_ROOF + 0.121
        for x0, y0, w, h in ((-1.4, -0.45, 0.3, 0.2), (-1.2, -0.3, 0.18, 0.28), (0.4, 0.3, 0.16, 0.14)):
            P.append(Poly([(x0, y0, zt), (x0 + w, y0, zt), (x0 + w, y0 + h, zt), (x0, y0 + h, zt)],
                          C_RUST, normal=(0, 0, 1), bias=DECAL_BIAS))
    return P


def darken(c, f):
    return tuple(int(v * f) for v in c)


def _edge(ax, ay, bx, by, px, py):
    return (bx - ax) * (py - ay) - (by - ay) * (px - ax)


def render(polys, heading, elevation_deg=ELEVATION_DEG, scale=PX_PER_M, size=CANVAS,
           pivot=PIVOT, outline=True, dull=0.0, cam_height_px=CAM_HEIGHT_PX, cam_ahead_px=CAM_AHEAD_PX):
    """heading: radianes, 0 = mirando a la derecha, positivo = antihorario (norte arriba).

    Con cam_height_px (y elevation_deg = 90) la cámara es un punto sobre el eje delantero:
    lo alto se aleja de ella como en el mapa, y solo se ven las caras que la miran."""
    e = math.radians(elevation_deg)
    se, ce = math.sin(e), math.cos(e)
    cam = np.array([0.0, -ce, se])
    Rz = rot_matrix((0, 0, 1), heading)
    persp = cam_height_px is not None and elevation_deg == 90.0
    if persp:
        cam_pos = Rz @ np.array([cam_ahead_px / scale, 0.0, cam_height_px / scale])
    rgb = np.zeros((size, size, 3), np.uint8)
    alpha = np.zeros((size, size), bool)
    zbuf = np.full((size, size), np.inf)
    ys, xs = np.mgrid[0:size, 0:size]
    pxc, pyc = xs + 0.5, ys + 0.5
    for p in polys:
        nw = Rz @ p.n
        vw = p.v @ Rz.T
        if persp:
            if np.dot(nw, cam_pos - vw.mean(axis=0)) <= 1e-6:
                continue
            f = cam_pos[2] / (cam_pos[2] - vw[:, 2])
            sx = pivot[0] + (cam_pos[0] + (vw[:, 0] - cam_pos[0]) * f) * scale
            sy = pivot[1] - (cam_pos[1] + (vw[:, 1] - cam_pos[1]) * f) * scale
            depth = -vw[:, 2]
        else:
            if np.dot(nw, cam) <= 1e-6:
                continue
            sx = pivot[0] + vw[:, 0] * scale
            sy = pivot[1] - (vw[:, 1] * se + vw[:, 2] * ce) * scale
            depth = vw[:, 1] * ce - vw[:, 2] * se
        if p.emissive:
            col = np.array(p.color, float)
        else:
            lam = max(0.0, float(np.dot(nw, LIGHT)))
            raw = 0.55 + 0.45 * lam
            shade = SHADE_LEVELS[np.argmin(np.abs(SHADE_LEVELS - raw))]
            col = np.array(p.color, float) * shade
            if dull:
                grey = col.mean()
                col = col * (1 - dull) + grey * dull
        col = np.clip(col, 0, 255).astype(np.uint8)
        for i in range(1, len(sx) - 1):
            tri = (0, i, i + 1)
            x0 = max(int(math.floor(min(sx[list(tri)]))), 0)
            x1 = min(int(math.ceil(max(sx[list(tri)]))), size - 1)
            y0 = max(int(math.floor(min(sy[list(tri)]))), 0)
            y1 = min(int(math.ceil(max(sy[list(tri)]))), size - 1)
            if x1 < x0 or y1 < y0:
                continue
            a, b, c = tri
            area = _edge(sx[a], sy[a], sx[b], sy[b], sx[c], sy[c])
            if abs(area) < 1e-9:
                continue
            PX = pxc[y0:y1 + 1, x0:x1 + 1]
            PY = pyc[y0:y1 + 1, x0:x1 + 1]
            w0 = _edge(sx[b], sy[b], sx[c], sy[c], PX, PY) / area
            w1 = _edge(sx[c], sy[c], sx[a], sy[a], PX, PY) / area
            w2 = 1 - w0 - w1
            inside = (w0 >= -1e-6) & (w1 >= -1e-6) & (w2 >= -1e-6)
            d = w0 * depth[a] + w1 * depth[b] + w2 * depth[c] - p.bias
            zb = zbuf[y0:y1 + 1, x0:x1 + 1]
            m = inside & (d < zb)
            zb[m] = d[m]
            rgb[y0:y1 + 1, x0:x1 + 1][m] = col
            alpha[y0:y1 + 1, x0:x1 + 1][m] = True
    out = np.zeros((size, size, 4), np.uint8)
    out[..., :3] = rgb
    out[..., 3] = np.where(alpha, 255, 0)
    if outline:
        a = alpha
        nb = np.zeros_like(a)
        nb[1:, :] |= a[:-1, :]
        nb[:-1, :] |= a[1:, :]
        nb[:, 1:] |= a[:, :-1]
        nb[:, :-1] |= a[:, 1:]
        edge = nb & ~a
        out[edge] = (*OUTLINE, 255)
    return Image.fromarray(out, "RGBA")


def shadow(size=CANVAS, pivot=PIVOT, heading=0.0, elevation_deg=ELEVATION_DEG, scale=PX_PER_M):
    """Sombra (rectángulo redondeado en el suelo), semitransparente."""
    e = math.radians(elevation_deg)
    img = np.zeros((size, size, 4), np.uint8)
    ys, xs = np.mgrid[0:size, 0:size]
    gx = (xs + 0.5 - pivot[0]) / scale
    gy = -(ys + 0.5 - pivot[1] + 2) / (scale * math.sin(e))
    c, s = math.cos(-heading), math.sin(-heading)
    lx = gx * c - gy * s
    ly = gx * s + gy * c
    m = (np.abs(lx) < HL + 0.15) & (np.abs(ly) < HW + 0.12)
    img[m] = (0, 0, 0, 70)
    return Image.fromarray(img, "RGBA")


BUILDER = [build_t3]  # el modelo activo; dehler.py lo cambia


def sprite(heading, spin=0.0, steer=0.0, lights=False, damage=0, elevation_deg=ELEVATION_DEG,
           with_shadow=True):
    body = render(BUILDER[0](spin, steer, lights, damage), heading, elevation_deg,
                  dull=[0, 0.12, 0.2, 0.3][damage])
    if not with_shadow:
        return body
    base = shadow(heading=heading, elevation_deg=elevation_deg)
    base.alpha_composite(body)
    return base
