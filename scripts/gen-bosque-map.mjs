// Genera el mapa Tiled del bosque (la extensión fuera de Sevilla) y su tileset placeholder.
// Uso: npm run map:bosque
// Salida: godot/assets/maps/bosque.json + tiles-bosque.png (editables luego en Tiled).
// Guion: desde Sevilla se llega por una carretera convencional (dos carriles, arcén y línea
// central) que no se pierde: rodea el pinar en circunvalación (recta al este, baja, vuelve al
// oeste) y regresa a la ciudad por otra salida. En un cruce de la recta norte sale una pista de
// tierra que abandona el asfalto y se mete en el pinar, dentro del circuito, hasta el claro.
// Los árboles y rocas llevan volumen (godot/scripts/city_view.gd, mismo formato que Sevilla).
import { writeFileSync } from 'node:fs';
import { deflateSync } from 'node:zlib';
import { shade } from './tile-texture.mjs';

const OUT_DIR = 'godot/assets/maps';
const TILE = 16;
const W = 160;
const H = 100;
const ARC_STEP_DEG = 15;

// ---------- Tiles (gid = índice + 1) ----------
const T = { HIERBA: 1, ASFALTO: 2, ARCEN: 3, TIERRA: 4, CLARO: 5, AGUA: 6, OLIVO: 7, PINO: 8, ROCA: 9, PINO_OCRE: 10,
  // Variantes para romper la repetición del suelo (mismas propiedades que la base).
  HIERBA2: 11, HIERBA3: 12, TIERRA2: 13, RODADA_H: 14, RODADA_V: 15, TIERRA_HIERBA: 16, CHARCO: 17,
  ASFALTO2: 18, ARCEN2: 19, CLARO2: 20 };
const vol = (altura, tejado, fachada, detalle, patron) => ({ altura, tejado, fachada, detalle, patron });
const TILE_DEFS = [
  { name: 'hierba', tex: 'grass', color: [142, 140, 72], speck: [128, 128, 62] },
  { name: 'asfalto', tex: 'asfalto', color: [96, 80, 70] },
  { name: 'arcen', tex: 'grava', color: [196, 164, 122], speck: [172, 140, 100] },
  { name: 'tierra', tex: 'tierra', color: [180, 124, 72], speck: [160, 106, 60] },
  { name: 'claro', tex: 'flores', color: [190, 156, 84], speck: [208, 176, 104] },
  { name: 'agua', color: [70, 112, 116], wave: [128, 168, 160], collides: true },
  { name: 'olivo', tex: 'grass', color: [142, 140, 72], tree: [104, 120, 70], collides: true, vol: vol(18, '#8a9a5c', '#5a4632', '#b4bd82', 'arbol') },
  { name: 'pino', tex: 'grass', color: [120, 112, 58], tree: [176, 84, 44], collides: true, vol: vol(34, '#b5532e', '#5a3a28', '#d9743a', 'arbol') },
  { name: 'roca', color: [140, 122, 104], border: [112, 96, 80], collides: true, vol: vol(10, '#a89478', '#7a6652', '#5e4e40', 'ladrillo') },
  { name: 'pino_ocre', tex: 'grass', color: [120, 112, 58], tree: [218, 164, 64], collides: true, vol: vol(34, '#d9a040', '#5a3a28', '#f0c060', 'arbol') },
  { name: 'hierba2', tex: 'hojas', color: [138, 132, 66] },
  { name: 'hierba3', tex: 'grass', color: [150, 146, 76], noise: 9 },
  { name: 'tierra2', tex: 'tierra', color: [172, 118, 68] },
  { name: 'rodada_h', tex: 'rodada_h', color: [180, 124, 72] },
  { name: 'rodada_v', tex: 'rodada_v', color: [180, 124, 72] },
  { name: 'tierra_hierba', tex: 'tierra_hierba', color: [176, 124, 70] },
  { name: 'charco', tex: 'charco', color: [160, 112, 66] },
  { name: 'asfalto2', tex: 'asfalto_grietas', color: [96, 80, 70] },
  { name: 'arcen2', tex: 'grava', color: [188, 156, 116], noise: 9 },
  { name: 'claro2', tex: 'flores', color: [196, 160, 86] },
];

// ---------- RNG con semilla (mapa reproducible) ----------
let seed = 1984;
const rnd = () => {
  seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};

// ---------- Rejilla ----------
const g = new Array(W * H).fill(T.HIERBA);
const inside = (x, y) => x >= 0 && y >= 0 && x < W && y < H;
const get = (x, y) => g[y * W + x];
const set = (x, y, t) => inside(x, y) && (g[y * W + x] = t);
const rect = (x0, y0, x1, y1, t) => {
  for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) set(x, y, t);
};
// Distancia de la celda (x, y) a una polilínea.
const segDist = (x, y, [ax, ay], [bx, by]) => {
  const dx = bx - ax, dy = by - ay;
  const t = Math.max(0, Math.min(1, ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy)));
  return Math.hypot(x - ax - t * dx, y - ay - t * dy);
};
const pathDist = (x, y, pts) => Math.min(...pts.slice(1).map((p, i) => segDist(x, y, pts[i], p)));

// 1) Carretera comarcal: asfalto de 4 tiles (dos carriles de 2, como la salida de Sevilla) con
// 1 tile de arcén a cada lado. Circuito: entra por el oeste (salida norte de Sevilla), recta al
// este, esquina redondeada, baja por el este, otra esquina y vuelve recta al oeste (salida sur).
const A4 = { y0: 20, y1: 25 }; // franja de la entrada norte (objetos `vuelta_sevilla` y `entrada_a4`)
const A4_MID = (A4.y0 + A4.y1 + 1) / 2;
const SUR = { y0: 90, y1: 95 }; // franja de la entrada sur (`vuelta_sevilla_sur` y `entrada_sur`)
const SUR_MID = (SUR.y0 + SUR.y1 + 1) / 2;
const RIGHT_X = 130;
const CORNER_R = 8;
const arc = (cx, cy, from, to) => {
  const pts = [];
  for (let a = from; a <= to; a += ARC_STEP_DEG) pts.push([cx + CORNER_R * Math.cos(a * Math.PI / 180), cy + CORNER_R * Math.sin(a * Math.PI / 180)]);
  return pts;
};
const COMARCAL = [
  [0, A4_MID],
  ...arc(RIGHT_X - CORNER_R, A4_MID + CORNER_R, -90, 0),
  ...arc(RIGHT_X - CORNER_R, SUR_MID - CORNER_R, 0, 90),
  [0, SUR_MID],
];
const ROAD_HALF = 2.0; // semianchura del asfalto (tiles)
const ARCEN_HALF = 3.0;

// 2) Pista de tierra (3 tiles): sale del asfalto en el cruce de la recta norte, con una explanada
// de grava en la boca, y baja dentro del circuito hasta el claro (que queda escondido).
const CRUCE_X = 70;
const LAGUNA = { x: 94, y: 58, rx: 8, ry: 5 };
const CAMINO_BASE = [[CRUCE_X, A4_MID], [CRUCE_X + 2, 34], [CRUCE_X - 3, 44], [CRUCE_X - 7, 54], [62, 62]];
// Pista sinuosa: la polilínea se remuestrea cada tile y se desplaza de lado con una onda que se
// anula en los extremos (cruce y claro quedan donde están).
const wiggle = (pts, amp, wavelength) => {
  const out = [];
  const total = pts.slice(1).reduce((n, p, k) => n + Math.hypot(p[0] - pts[k][0], p[1] - pts[k][1]), 0);
  let run = 0;
  for (let k = 1; k < pts.length; k++) {
    const [ax, ay] = pts[k - 1], [bx, by] = pts[k];
    const len = Math.hypot(bx - ax, by - ay);
    const nx = -(by - ay) / len, ny = (bx - ax) / len;
    for (let t = 0; t < len; t++) {
      const f = (run + t) / total;
      const off = amp * Math.sin(f * Math.PI) * Math.sin((run + t) * 2 * Math.PI / wavelength);
      out.push([ax + (bx - ax) * t / len + nx * off, ay + (by - ay) * t / len + ny * off]);
    }
    run += len;
  }
  out.push(pts[pts.length - 1]);
  return out;
};
const CAMINO = wiggle(CAMINO_BASE, 2.2, 17);
// Senda estrecha que se desgaja de la pista hacia la laguna y acaba en un embarcadero de tierra.
const SENDA_BASE = [CAMINO_BASE[2], [78, 46], [LAGUNA.x - LAGUNA.rx - 3, LAGUNA.y - 1]];
const SENDA = wiggle(SENDA_BASE, 1.6, 13);
const SENDA_HALF = 1.15;
const CAMINO_HALF = 1.6;
const EXPLANADA = { x: CRUCE_X + 0.5, y: A4_MID + 3.5, r: 2.6 };
const CLARO = { x: 62, y: 62, r: 8 };
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
  const c = x + 0.5, r = y + 0.5;
  if (Math.hypot(c - CLARO.x, r - CLARO.y) <= CLARO.r) set(x, y, T.CLARO);
  else if (pathDist(c, r, COMARCAL) <= ROAD_HALF) set(x, y, T.ASFALTO);
  else if (pathDist(c, r, CAMINO) <= CAMINO_HALF + 0.3 * Math.sin(c * 0.45) || pathDist(c, r, SENDA) <= SENDA_HALF
    || Math.hypot(c - EXPLANADA.x, r - EXPLANADA.y) <= EXPLANADA.r
    || Math.hypot(c - SENDA[SENDA.length - 1][0], r - SENDA[SENDA.length - 1][1]) <= 2.4) set(x, y, T.TIERRA);
  else if (pathDist(c, r, COMARCAL) <= ARCEN_HALF) set(x, y, T.ARCEN);
  if (((c - LAGUNA.x) / LAGUNA.rx) ** 2 + ((r - LAGUNA.y) / LAGUNA.ry) ** 2 <= 1) set(x, y, T.AGUA);
}

// Lo que se pisa: árboles y rocas dejan un tile de margen para que la T3 pase holgada.
const DRIVE = new Set([T.ASFALTO, T.ARCEN, T.TIERRA, T.CLARO]);
const nearDrive = (x, y, m) => {
  for (let dy = -m; dy <= m; dy++) for (let dx = -m; dx <= m; dx++) if (inside(x + dx, y + dy) && DRIVE.has(get(x + dx, y + dy))) return true;
  return false;
};

// 3) Olivares en hileras junto a la A-4 (campo abierto: el ruido de Sevilla ya quedó atrás).
const FOREST_X0 = 40; // a partir de aquí empieza el pinar
for (let y = 2; y < H - 2; y += 3) for (let x = 3; x < FOREST_X0 - 6; x += 3) {
  if (get(x, y) === T.HIERBA && !nearDrive(x, y, 2) && rnd() < 0.85) set(x, y, T.OLIVO);
}

// 4) Pinar: cada vez más espeso hacia el este; rocas sueltas.
for (let y = 0; y < H; y++) for (let x = FOREST_X0 - 10; x < W; x++) {
  if (get(x, y) !== T.HIERBA || nearDrive(x, y, 1)) continue;
  const density = Math.min(1, (x - FOREST_X0 + 10) / 40) * 0.5;
  const r = rnd();
  if (r < density) set(x, y, rnd() < 0.45 ? T.PINO_OCRE : T.PINO);
  else if (r < density + 0.01 && x > FOREST_X0) set(x, y, T.ROCA);
}

// 5) Borde: pinos en todo el contorno salvo donde entra la A-4.
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
  const edge = x === 0 || y === 0 || x === W - 1 || y === H - 1;
  if (edge && !DRIVE.has(get(x, y))) set(x, y, x < FOREST_X0 ? T.OLIVO : T.PINO);
}

// 6) Texturas: variantes del suelo para que no se repita el mismo tile, surcos de rueda y
// hierba comiéndose los bordes de la pista, charcos de barro y grietas en el asfalto.
const base = g.slice();
const cellAt = (x, y) => (inside(x, y) ? base[y * W + x] : T.HIERBA);
const GREEN = new Set([T.HIERBA, T.OLIVO, T.PINO, T.PINO_OCRE]);
const heading = (x, y, pts) => {
  let best = Infinity, dir = [1, 0];
  for (let k = 1; k < pts.length; k++) {
    const d = segDist(x + 0.5, y + 0.5, pts[k - 1], pts[k]);
    if (d < best) { best = d; dir = [pts[k][0] - pts[k - 1][0], pts[k][1] - pts[k - 1][1]]; }
  }
  return { dist: best, horizontal: Math.abs(dir[0]) >= Math.abs(dir[1]) };
};
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
  const t = base[y * W + x], r = rnd();
  if (t === T.HIERBA) set(x, y, r < 0.55 ? T.HIERBA : r < 0.8 ? T.HIERBA2 : T.HIERBA3);
  else if (t === T.ASFALTO && r < 0.08) set(x, y, T.ASFALTO2);
  else if (t === T.ARCEN && r < 0.4) set(x, y, T.ARCEN2);
  else if (t === T.CLARO && r < 0.3) set(x, y, T.CLARO2);
  else if (t === T.TIERRA) {
    const edge = [[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dx, dy]) => GREEN.has(cellAt(x + dx, y + dy)));
    const h = heading(x, y, CAMINO);
    const onTrack = h.dist <= CAMINO_HALF;
    if (edge && r < 0.7) set(x, y, T.TIERRA_HIERBA);
    else if (onTrack && Math.abs(h.dist - 0.6) < 0.5 && h.dist > 0.1) set(x, y, h.horizontal ? T.RODADA_H : T.RODADA_V);
    else if (r < 0.04) set(x, y, T.CHARCO);
    else if (r < 0.2) set(x, y, T.TIERRA2);
  }
}

// ---------- Objetos: llegada, vuelta a Sevilla, spot y rótulos ----------
const px = (t) => t * TILE;
let oid = 1;
const point = (name, type, tx, ty) => ({ id: oid++, name, type, x: px(tx), y: px(ty), width: 0, height: 0, rotation: 0, visible: true, point: true });
const area = (name, type, tx, ty, tw, th) => ({ id: oid++, name, type, x: px(tx), y: px(ty), width: px(tw), height: px(th), rotation: 0, visible: true });
// Marcas viales: polilíneas (puntos en tiles) que el juego dibuja sobre el asfalto.
const polyline = (name, pts, estilo) => ({
  id: oid++, name, type: 'linea', x: 0, y: 0, width: 0, height: 0, rotation: 0, visible: true,
  polyline: pts.map(([tx, ty]) => ({ x: px(tx), y: px(ty) })),
  properties: [{ name: 'estilo', type: 'string', value: estilo }],
});
const objects = [
  polyline('eje_carretera', COMARCAL, 'discontinua'),
  // Solo línea central: en las curvas el asfalto sigue la rejilla de tiles y una raya de borde
  // se saldría de él; el arcén ya marca el borde.
  // La furgo llega desde Sevilla aquí, mirando al este; volviendo al borde oeste regresa a la ciudad.
  point('entrada_a4', 'spawn', 8, A4_MID),
  area('vuelta_sevilla', 'salida', 0, A4.y0, 2, A4.y1 - A4.y0 + 1),
  // Segunda puerta: el circuito sale por el sur y la furgo regresa a Sevilla por otra carretera.
  point('entrada_sur', 'spawn', 8, SUR_MID),
  area('vuelta_sevilla_sur', 'salida', 0, SUR.y0, 2, SUR.y1 - SUR.y0 + 1),
  area('spot_acampada', 'spot', CLARO.x - 4, CLARO.y - 4, 8, 8),
  point('Carretera comarcal (a Sevilla norte)', 'rotulo', 16, A4.y0 - 3),
  point('Carretera comarcal (a Sevilla sur)', 'rotulo', 16, SUR.y1 + 3),
  point('Desvío a pista forestal', 'rotulo', CRUCE_X + 1, A4_MID + 8),
  point('Olivares', 'rotulo', 20, 58),
  point('Pinar', 'rotulo', 110, 58),
  point('Laguna', 'rotulo', LAGUNA.x, LAGUNA.y - LAGUNA.ry - 2),
  point('Spot de acampada', 'rotulo', CLARO.x, CLARO.y - CLARO.r - 1),
];

// ---------- Tiled JSON ----------
const volProps = (v) => !v ? [] : Object.entries(v).map(([name, value]) => (
  typeof value === 'number' ? { name, type: Number.isInteger(value) ? 'int' : 'float', value }
    : value.startsWith('#') ? { name, type: 'color', value: `#ff${value.slice(1)}` }
    : { name, type: 'string', value }));
const map = {
  type: 'map', version: '1.10', tiledversion: '1.10.2', orientation: 'orthogonal', renderorder: 'right-down',
  width: W, height: H, tilewidth: TILE, tileheight: TILE, infinite: false,
  nextlayerid: 3, nextobjectid: oid,
  layers: [
    { id: 1, name: 'suelo', type: 'tilelayer', width: W, height: H, x: 0, y: 0, opacity: 1, visible: true, data: g },
    { id: 2, name: 'objetos', type: 'objectgroup', draworder: 'topdown', x: 0, y: 0, opacity: 1, visible: true, objects },
  ],
  tilesets: [{
    firstgid: 1, name: 'placeholder', image: 'tiles-bosque.png',
    imagewidth: TILE * TILE_DEFS.length, imageheight: TILE, tilewidth: TILE, tileheight: TILE,
    tilecount: TILE_DEFS.length, columns: TILE_DEFS.length, margin: 0, spacing: 0,
    tiles: TILE_DEFS.map((d, id) => ({ id, type: d.name, properties: [{ name: 'collides', type: 'bool', value: !!d.collides }, ...volProps(d.vol)] })),
  }],
};
writeFileSync(`${OUT_DIR}/bosque.json`, JSON.stringify(map));

// ---------- Tileset PNG (rectángulos placeholder) ----------
const IW = TILE * TILE_DEFS.length;
const pix = Buffer.alloc(IW * TILE * 4);
const put = (x, y, [r, gg, b]) => { const o = (y * IW + x) * 4; pix[o] = r; pix[o + 1] = gg; pix[o + 2] = b; pix[o + 3] = 255; };
TILE_DEFS.forEach((d, i) => {
  for (let y = 0; y < TILE; y++) for (let x = 0; x < TILE; x++) {
    let c = d.color;
    if (d.border && (x === 0 || y === 0 || x === TILE - 1 || y === TILE - 1)) c = d.border;
    if (d.speck && (x * 7 + y * 13) % 11 === 0) c = d.speck;
    if (d.wave && (y % 6 === 2) && ((x + y) % 8 < 3)) c = d.wave;
    if (d.tree && Math.hypot(x - 7.5, y - 7.5) < 6) c = d.tree;
    put(i * TILE + x, y, shade(c, d, i, x, y));
  }
});
const crcTable = Array.from({ length: 256 }, (_, n) => { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; return c >>> 0; });
const crc = (buf) => { let c = 0xffffffff; for (const b of buf) c = crcTable[(c ^ b) & 0xff] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
const chunk = (type, data) => {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type), data]);
  const c = Buffer.alloc(4); c.writeUInt32BE(crc(td));
  return Buffer.concat([len, td, c]);
};
const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(IW, 0); ihdr.writeUInt32BE(TILE, 4); ihdr[8] = 8; ihdr[9] = 6;
const raw = Buffer.alloc((IW * 4 + 1) * TILE);
for (let y = 0; y < TILE; y++) pix.copy(raw, y * (IW * 4 + 1) + 1, y * IW * 4, (y + 1) * IW * 4);
writeFileSync(`${OUT_DIR}/tiles-bosque.png`, Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  chunk('IHDR', ihdr), chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0)),
]));
console.log(`bosque.json ${W}x${H} tiles, ${objects.length} objetos`);
