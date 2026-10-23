// Genera el mapa Tiled del bosque (la extensión fuera de Sevilla) y su tileset placeholder.
// Uso: npm run map:bosque
// Salida: godot/assets/maps/bosque.json + tiles-bosque.png (editables luego en Tiled).
// Guion: la A-4 entra por el oeste desde Sevilla, cruza olivares, se vuelve carretera
// comarcal y luego camino de tierra que se mete en el pinar hasta el claro de acampada.
// Los árboles y rocas llevan volumen (godot/scripts/city_view.gd, mismo formato que Sevilla).
import { writeFileSync } from 'node:fs';
import { deflateSync } from 'node:zlib';

const OUT_DIR = 'godot/assets/maps';
const TILE = 16;
const W = 160;
const H = 100;

// ---------- Tiles (gid = índice + 1) ----------
const T = { HIERBA: 1, ASFALTO: 2, ARCEN: 3, TIERRA: 4, CLARO: 5, AGUA: 6, OLIVO: 7, PINO: 8, ROCA: 9 };
const vol = (altura, tejado, fachada, detalle, patron) => ({ altura, tejado, fachada, detalle, patron });
const TILE_DEFS = [
  { name: 'hierba', color: [104, 150, 64], speck: [92, 136, 56] },
  { name: 'asfalto', color: [58, 58, 64] },
  { name: 'arcen', color: [150, 142, 132], speck: [128, 120, 110] },
  { name: 'tierra', color: [168, 128, 82], speck: [150, 112, 70] },
  { name: 'claro', color: [128, 170, 80], speck: [150, 186, 96] },
  { name: 'agua', color: [44, 92, 138], wave: [90, 140, 186], collides: true },
  { name: 'olivo', color: [104, 150, 64], tree: [84, 104, 64], collides: true, vol: vol(18, '#7d8f5a', '#5a4632', '#a3b57a', 'arbol') },
  { name: 'pino', color: [70, 110, 50], tree: [30, 70, 35], collides: true, vol: vol(34, '#25562b', '#4a3524', '#3d7a3a', 'arbol') },
  { name: 'roca', color: [120, 118, 110], border: [96, 94, 88], collides: true, vol: vol(10, '#9a958a', '#6e6a62', '#58554e', 'ladrillo') },
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

// 1) A-4: autovía de 6 tiles que entra por el oeste (misma anchura que en Sevilla), con arcén.
const A4 = { x1: 46, y0: 20, y1: 25 };
rect(0, A4.y0 - 1, A4.x1, A4.y1 + 1, T.ARCEN);
rect(0, A4.y0, A4.x1, A4.y1, T.ASFALTO);
const A4_MID = (A4.y0 + A4.y1 + 1) / 2;

// 2) Carretera comarcal (asfalto, 4 tiles) y camino de tierra (3 tiles) hasta el claro.
const COMARCAL = [[A4.x1, A4_MID], [62, 26], [76, 36], [86, 48], [94, 56]];
const CAMINO = [[94, 56], [106, 60], [114, 70], [126, 78], [138, 82]];
const CLARO = { x: 140, y: 82, r: 8 };
const LAGUNA = { x: 146, y: 64, rx: 7, ry: 5 };
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
  const c = x + 0.5, r = y + 0.5;
  if (Math.hypot(c - CLARO.x, r - CLARO.y) <= CLARO.r) set(x, y, T.CLARO);
  else if (pathDist(c, r, CAMINO) <= 1.6) set(x, y, T.TIERRA);
  else if (pathDist(c, r, COMARCAL) <= 2.1) set(x, y, T.ASFALTO);
  else if (pathDist(c, r, COMARCAL) <= 3.1 && x > A4.x1) set(x, y, T.ARCEN);
  if (((c - LAGUNA.x) / LAGUNA.rx) ** 2 + ((r - LAGUNA.y) / LAGUNA.ry) ** 2 <= 1) set(x, y, T.AGUA);
}

// Lo que se pisa: árboles y rocas dejan un tile de margen para que la T3 pase holgada.
const DRIVE = new Set([T.ASFALTO, T.ARCEN, T.TIERRA, T.CLARO]);
const nearDrive = (x, y, m) => {
  for (let dy = -m; dy <= m; dy++) for (let dx = -m; dx <= m; dx++) if (inside(x + dx, y + dy) && DRIVE.has(get(x + dx, y + dy))) return true;
  return false;
};

// 3) Olivares en hileras junto a la A-4 (campo abierto: el ruido de Sevilla ya quedó atrás).
const FOREST_X0 = 70; // a partir de aquí empieza el pinar
for (let y = 2; y < H - 2; y += 3) for (let x = 3; x < FOREST_X0 - 6; x += 3) {
  if (get(x, y) === T.HIERBA && !nearDrive(x, y, 2) && rnd() < 0.85) set(x, y, T.OLIVO);
}

// 4) Pinar: cada vez más espeso hacia el este; rocas sueltas.
for (let y = 0; y < H; y++) for (let x = FOREST_X0 - 10; x < W; x++) {
  if (get(x, y) !== T.HIERBA || nearDrive(x, y, 1)) continue;
  const density = Math.min(1, (x - FOREST_X0 + 10) / 40) * 0.5;
  const r = rnd();
  if (r < density) set(x, y, T.PINO);
  else if (r < density + 0.01 && x > FOREST_X0) set(x, y, T.ROCA);
}

// 5) Borde: pinos en todo el contorno salvo donde entra la A-4.
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
  const edge = x === 0 || y === 0 || x === W - 1 || y === H - 1;
  if (edge && !DRIVE.has(get(x, y))) set(x, y, x < FOREST_X0 ? T.OLIVO : T.PINO);
}

// ---------- Objetos: llegada, vuelta a Sevilla, spot y rótulos ----------
const px = (t) => t * TILE;
let oid = 1;
const point = (name, type, tx, ty) => ({ id: oid++, name, type, x: px(tx), y: px(ty), width: 0, height: 0, rotation: 0, visible: true, point: true });
const area = (name, type, tx, ty, tw, th) => ({ id: oid++, name, type, x: px(tx), y: px(ty), width: px(tw), height: px(th), rotation: 0, visible: true });
const objects = [
  // La furgo llega desde Sevilla aquí, mirando al este; volviendo al borde oeste regresa a la ciudad.
  point('entrada_a4', 'spawn', 8, A4_MID),
  area('vuelta_sevilla', 'salida', 0, A4.y0, 2, A4.y1 - A4.y0 + 1),
  area('spot_acampada', 'spot', CLARO.x - 4, CLARO.y - 4, 8, 8),
  point('A-4 (a Sevilla)', 'rotulo', 10, A4.y0 - 3),
  point('Olivares', 'rotulo', 30, 40),
  point('Pinar', 'rotulo', 110, 40),
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
    put(i * TILE + x, y, c);
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
