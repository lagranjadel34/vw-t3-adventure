// Genera el mapa Tiled de Sevilla (esquemático) y su tileset placeholder.
// Uso: npm run map
// Salida: godot/assets/maps/sevilla.json + tiles-sevilla.png (editables luego en Tiled).
// Los tiles de edificio llevan propiedades de volumen (altura, colores, patrón de fachada):
// el juego los levanta con perspectiva de cámara cenital, estilo GTA 1 (godot/scripts/city_view.gd).
// La versión Phaser (congelada) conserva su copia en public/assets/maps.
import { writeFileSync } from 'node:fs';
import { deflateSync } from 'node:zlib';

const OUT_DIR = 'godot/assets/maps';
const TILE = 16;
const W = 200;
const H = 150;

// ---------- Tiles (gid = índice + 1) ----------
const T = {
  ASFALTO: 1, ACERA: 2, TEJADO: 3, PARQUE: 4, AGUA: 5, PUENTE: 6,
  MONUMENTO: 7, ALBERO: 8, ARBOL: 9, CAL: 10, OCRE: 11, GIRALDA: 12,
  CATEDRAL: 13, TORRE_ORO: 14, MAESTRANZA: 15, PLAZA_ESPANA: 16, TORRE_PE: 17,
  ALCAZAR: 18, ARCHIVO: 19, SETAS: 20, TORRE_SEVILLA: 21, PABELLON: 22, BLOQUE: 23,
  PUENTE_TRIANA: 24, BARANDILLA: 25, CAPILLITA: 26, NARANJO: 27,
  NAVE: 28, TALLER_SUELO: 29, ENTRADA: 30,
};
// Volumen: altura en px de mundo (≈ 18 px por planta; debe quedar por debajo de CITY_CAMERA_HEIGHT); patrón de fachada; remate = franja
// alta de otro color (campanario) que ocupa remate_frac de la altura; aguja = chapitel.
const vol = (altura, tejado, fachada, detalle, patron, extra = {}) => ({ altura, tejado, fachada, detalle, patron, ...extra });
const TILE_DEFS = [
  { name: 'asfalto', color: [58, 58, 64] },
  { name: 'acera', color: [150, 142, 132], grid: [170, 162, 152] },
  { name: 'tejado', color: [178, 98, 70], border: [140, 72, 50], collides: true },
  { name: 'parque', color: [86, 140, 62] },
  { name: 'agua', color: [44, 92, 138], wave: [90, 140, 186], collides: true },
  { name: 'puente', color: [110, 106, 112], border: [190, 186, 180] },
  { name: 'monumento', color: [214, 192, 136], border: [170, 146, 96], collides: true },
  { name: 'albero', color: [218, 166, 74] },
  { name: 'arbol', color: [86, 140, 62], tree: [40, 92, 36], collides: true, vol: vol(24, '#2e6b2a', '#6b4a2e', '#3f8a38', 'arbol') },
  // Casas de cal con azotea y zócalo de albero; casas ocres y rosadas con teja.
  { name: 'cal', color: [232, 226, 210], border: [190, 180, 160], collides: true, vol: vol(55, '#d6d0c2', '#f2eee2', '#4a3f3a', 'ventanas', { zocalo: '#d6a53c' }) },
  { name: 'ocre', color: [212, 160, 60], border: [170, 120, 40], collides: true, vol: vol(65, '#c6603f', '#e0a83c', '#4a3328', 'ventanas', { zocalo: '#f2eee2' }) },
  { name: 'giralda', color: [201, 143, 90], border: [120, 84, 50], collides: true, vol: vol(170, '#b77b4a', '#c98f5a', '#8a5a36', 'ladrillo', { remate: '#efe6d0', remate_frac: 0.2, aguja: '#d9b44a' }) },
  { name: 'catedral', color: [205, 181, 138], border: [154, 129, 96], collides: true, vol: vol(95, '#a8936d', '#cdb58a', '#9a8160', 'contrafuertes') },
  { name: 'torre_oro', color: [217, 176, 98], border: [170, 130, 60], collides: true, vol: vol(70, '#c9a050', '#d9b062', '#a88440', 'almenas', { remate: '#e9cf8a', remate_frac: 0.25 }) },
  { name: 'maestranza', color: [244, 239, 228], border: [214, 165, 60], collides: true, vol: vol(30, '#c6603f', '#f4efe4', '#d6a53c', 'arcos') },
  { name: 'plaza_espana', color: [181, 87, 58], border: [239, 224, 192], collides: true, vol: vol(65, '#9a4630', '#b5573a', '#efe0c0', 'arcos') },
  { name: 'torre_pe', color: [181, 87, 58], border: [239, 224, 192], collides: true, vol: vol(130, '#9a4630', '#b5573a', '#efe0c0', 'ventanas', { remate: '#efe0c0', remate_frac: 0.15, aguja: '#7aa6b8' }) },
  { name: 'alcazar', color: [216, 183, 122], border: [170, 140, 90], collides: true, vol: vol(45, '#c9a96a', '#d8b77a', '#a8874a', 'almenas') },
  { name: 'archivo', color: [201, 143, 90], border: [239, 230, 208], collides: true, vol: vol(55, '#b0a090', '#c98f5a', '#efe6d0', 'ventanas') },
  { name: 'setas', color: [232, 210, 166], border: [184, 154, 104], collides: true, vol: vol(60, '#e8d2a6', '#e8d2a6', '#b89a68', 'rejilla') },
  { name: 'torre_sevilla', color: [143, 179, 201], border: [109, 143, 166], collides: true, vol: vol(200, '#6d8fa6', '#8fb3c9', '#c8dce8', 'cristal') },
  { name: 'pabellon', color: [232, 232, 232], border: [176, 184, 192], collides: true, vol: vol(35, '#b0b8c0', '#e8e8e8', '#7f9bb0', 'cristal') },
  { name: 'bloque', color: [201, 194, 181], border: [143, 138, 130], collides: true, vol: vol(110, '#8f8a82', '#c9c2b5', '#4f5d6b', 'ventanas') },
  // Puente de Triana (Isabel II): calzada, barandilla de hierro y la Capillita del Carmen.
  { name: 'puente_triana', color: [72, 70, 74] },
  // Barandilla: acera con la reja en medio (el juego la levanta en perspectiva).
  { name: 'barandilla', color: [150, 142, 132], grid: [170, 162, 152], rail: [61, 72, 80], collides: true },
  { name: 'capillita', color: [180, 85, 58], border: [239, 230, 208], collides: true, vol: vol(48, '#2f7f8a', '#b4553a', '#efe6d0', 'ladrillo', { remate: '#efe6d0', remate_frac: 0.2, aguja: '#2f8f9a' }) },
  // Naranjos de las aceras: copa verde con naranjas.
  { name: 'naranjo', color: [150, 142, 132], tree: [40, 92, 36], collides: true, vol: vol(20, '#2f6b2a', '#6b4a2e', '#e8892a', 'arbol') },
  // Taller Karvans: nave de chapa en el polígono junto a la A-4, con portón abierto.
  { name: 'nave', color: [200, 204, 208], border: [125, 134, 140], collides: true, vol: vol(40, '#9aa3a8', '#c8ccd0', '#7d868c', 'chapa', { remate: '#d8742a', remate_frac: 0.25 }) },
  { name: 'taller_suelo', color: [70, 72, 76], grid: [84, 86, 90] },
  // Entrada del taller: franjas amarillas y negras en el suelo.
  { name: 'entrada', color: [40, 40, 44], hatch: [226, 186, 40] },
];
// La casa rosada con teja usa el tile 'tejado'.
TILE_DEFS[T.TEJADO - 1].vol = vol(45, '#b85a3c', '#e7b9a0', '#4a3328', 'ventanas', { zocalo: '#f2eee2' });
const BUILDING = new Set([T.TEJADO, T.CAL, T.OCRE]);

// ---------- RNG con semilla (mapa reproducible) ----------
let seed = 1992;
const rnd = () => {
  seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
const rint = (a, b) => a + Math.floor(rnd() * (b - a + 1));

// ---------- Rejilla ----------
const g = new Array(W * H).fill(T.TEJADO);
const inside = (x, y) => x >= 0 && y >= 0 && x < W && y < H;
const get = (x, y) => g[y * W + x];
const set = (x, y, t) => inside(x, y) && (g[y * W + x] = t);
const rect = (x0, y0, x1, y1, t) => {
  for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) set(x, y, t);
};

// Río Guadalquivir: eje con meandro suave.
const RIVER_W = 12;
const riverX = (y) => Math.round(62 + 6 * Math.sin(y / 25));
// Casco antiguo: elipse de la Ronda histórica.
const CASCO = { cx: 110, cy: 62, rx: 38, ry: 44 };
const ellipse = (x, y) => ((x - CASCO.cx) / CASCO.rx) ** 2 + ((y - CASCO.cy) / CASCO.ry) ** 2;

// 1) Triana / Los Remedios (orilla oeste): cuadrícula con algo de desorden.
for (let x = 6; x < 60; x += rint(13, 17)) rect(x, 0, x + 3, H - 1, T.ASFALTO);
for (let y = 6; y < H; y += rint(12, 15)) rect(0, y, 60, y + 3, T.ASFALTO);

// 2) Cartuja (norte de la orilla oeste): parque con pabellones de la Expo.
rect(0, 0, 60, 34, T.PARQUE);
for (let i = 0; i < 6; i++) {
  const x = rint(4, 44), y = rint(4, 26);
  rect(x, y, x + rint(4, 8), y + rint(3, 5), T.PABELLON);
}

// 3) Nervión y ensanche (este y alrededores del casco): avenidas anchas.
for (let x = 152; x < W; x += 18) rect(x, 0, x + 5, H - 1, T.ASFALTO);
for (let y = 4; y < H; y += 18) rect(70, y, W - 1, y + 5, T.ASFALTO);

// 4) Casco antiguo: calles quebradas de 4 tiles (la T3 cabe justa).
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (ellipse(x, y) < 1) set(x, y, T.TEJADO);
for (let y0 = CASCO.cy - CASCO.ry + 10; y0 < CASCO.cy + CASCO.ry; y0 += rint(14, 17)) {
  let y = y0;
  for (let x = CASCO.cx - CASCO.rx; x < CASCO.cx + CASCO.rx; ) {
    const len = rint(7, 13);
    for (let i = 0; i <= len; i++) for (let k = 0; k < 4; k++) if (ellipse(x + i, y + k) < 1.05) set(x + i, y + k, T.ASFALTO);
    x += len;
    const dy = rint(-2, 2);
    for (let k = 0; k < 4 + Math.abs(dy); k++) for (let j = 0; j < 4; j++) if (ellipse(x + j, Math.min(y, y + dy) + k) < 1.05) set(x + j, Math.min(y, y + dy) + k, T.ASFALTO);
    y += dy;
  }
}
for (let x0 = CASCO.cx - CASCO.rx + 10; x0 < CASCO.cx + CASCO.rx; x0 += rint(15, 19)) {
  let x = x0;
  for (let y = CASCO.cy - CASCO.ry; y < CASCO.cy + CASCO.ry; ) {
    const len = rint(6, 12);
    // Algunas calles se cortan: callejones sin salida, muy de casco antiguo.
    if (rnd() < 0.2) { y += len; continue; }
    for (let i = 0; i <= len; i++) for (let k = 0; k < 4; k++) if (ellipse(x + k, y + i) < 1.05) set(x + k, y + i, T.ASFALTO);
    y += len;
    const dx = rint(-2, 2);
    for (let k = 0; k < 4 + Math.abs(dx); k++) for (let j = 0; j < 4; j++) if (ellipse(Math.min(x, x + dx) + k, y + j) < 1.05) set(Math.min(x, x + dx) + k, y + j, T.ASFALTO);
    x += dx;
  }
}

// 5) Ronda histórica: anillo de 6 tiles alrededor del casco.
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
  const e = ellipse(x, y);
  if (e >= 1.0 && e < 1.32) set(x, y, T.ASFALTO);
}

// 6) Catedral y Giralda (con plaza alrededor) y Avenida de la Constitución.
rect(102, 78, 124, 94, T.ACERA);
rect(105, 81, 121, 91, T.CATEDRAL);
rect(119, 79, 122, 82, T.GIRALDA);
rect(108, 94, 112, 112, T.ASFALTO);

// 6b) Archivo de Indias (al oeste de la avenida) y Reales Alcázares (murallas con jardín).
rect(101, 95, 107, 101, T.ACERA);
rect(102, 96, 106, 100, T.ARCHIVO);
const ALC = { x0: 114, y0: 96, x1: 130, y1: 103 };
for (let y = ALC.y0; y <= ALC.y1; y++) for (let x = ALC.x0; x <= ALC.x1; x++) {
  if (ellipse(x, y) >= 1) continue;
  const wall = x <= ALC.x0 + 1 || y <= ALC.y0 + 1 || x >= ALC.x1 - 1 || y >= ALC.y1 - 1 || ellipse(x + 2, y + 2) >= 1;
  set(x, y, wall ? T.ALCAZAR : (x * 7 + y * 3) % 5 === 0 ? T.ARBOL : T.PARQUE);
}

// 6c) Las Setas en la plaza de la Encarnación.
rect(103, 32, 121, 44, T.ACERA);
rect(106, 35, 118, 40, T.SETAS);

// 7) Maestranza: coso de albero junto al río.
const MAE = { x: 84, y: 76, r: 6 };
for (let y = MAE.y - MAE.r - 2; y <= MAE.y + MAE.r + 2; y++) for (let x = MAE.x - MAE.r - 2; x <= MAE.x + MAE.r + 2; x++) {
  const d = Math.hypot(x - MAE.x, y - MAE.y);
  if (d <= MAE.r - 2) set(x, y, T.ALBERO);
  else if (d <= MAE.r + 0.5) set(x, y, T.MAESTRANZA);
}

// 8) Río, avenidas de ribera (Torneo/Colón y Betis) y puentes.
for (let y = 0; y < H; y++) {
  const c = riverX(y);
  rect(c - 17, y, c - 12, y, T.ASFALTO);
  rect(c - 11, y, c - 7, y, T.ACERA);
  rect(c - 6, y, c + 5, y, T.AGUA);
  rect(c + 6, y, c + 8, y, T.ACERA);
  rect(c + 9, y, c + 14, y, T.ASFALTO);
}
const BRIDGES = [
  { y: 22, name: 'Puente de la Barqueta' },
  { y: 98, name: 'Puente de San Telmo' },
  { y: 132, name: 'Puente de Los Remedios' },
];
for (const b of BRIDGES) {
  for (let y = b.y; y < b.y + 5; y++) {
    const c = riverX(y);
    rect(c - 12, y, c + 9, y, T.PUENTE);
  }
}
// Puente de Triana (Isabel II, 1852): recto de orilla a orilla, con barandilla de hierro,
// aceras y dos carriles; debajo, tres arcos de hierro con anillos (los pinta el juego).
// Filas: barandilla, acera, 4 de calzada, acera, barandilla.
const TRIANA = { y0: 59, y1: 66 };
const trianaRows = [];
for (let y = TRIANA.y0; y <= TRIANA.y1; y++) trianaRows.push(riverX(y));
TRIANA.x0 = Math.min(...trianaRows) - 12; // empieza en la calle Betis
TRIANA.x1 = Math.max(...trianaRows) + 9; // y acaba en Reyes Católicos / Paseo de Colón
TRIANA.rail0 = Math.max(...trianaRows) - 11;
TRIANA.rail1 = Math.min(...trianaRows) + 8;
TRIANA.road0 = TRIANA.y0 + 2;
TRIANA.road1 = TRIANA.y1 - 2;
rect(TRIANA.x0, TRIANA.road0, TRIANA.x1, TRIANA.road1, T.PUENTE_TRIANA);
rect(TRIANA.rail0, TRIANA.y0 + 1, TRIANA.rail1, TRIANA.y0 + 1, T.ACERA);
rect(TRIANA.rail0, TRIANA.y1 - 1, TRIANA.rail1, TRIANA.y1 - 1, T.ACERA);
rect(TRIANA.rail0, TRIANA.y0, TRIANA.rail1, TRIANA.y0, T.BARANDILLA);
rect(TRIANA.rail0, TRIANA.y1, TRIANA.rail1, TRIANA.y1, T.BARANDILLA);
// Arcos sobre el agua: de la orilla de Triana a la del Arenal.
TRIANA.arch0 = Math.min(...trianaRows) - 6;
TRIANA.arch1 = Math.max(...trianaRows) + 6;
// Capillita del Carmen (Aníbal González) en la cabeza del puente, lado Triana, junto a Betis.
const CAPILLA = { x: TRIANA.rail0 + 1, y: TRIANA.y1 + 1 };
rect(CAPILLA.x, CAPILLA.y, CAPILLA.x + 1, CAPILLA.y + 1, T.CAPILLITA);

// 8b) Torre del Oro en la orilla del Paseo de Colón y Torre Sevilla en la Cartuja.
const ORO = { x: riverX(89) + 6, y: 89, r: 2.6 }; // en la orilla, sin pisar el carril del Paseo de Colón
for (let y = ORO.y - 3; y <= ORO.y + 3; y++) for (let x = ORO.x - 3; x <= ORO.x + 3; x++) {
  if (Math.hypot(x - ORO.x, y - ORO.y) <= ORO.r) set(x, y, T.TORRE_ORO);
}
rect(41, 26, 47, 31, T.ACERA);
rect(42, 27, 46, 30, T.TORRE_SEVILLA);

// 9) Parque de María Luisa y Plaza de España.
const PARK = { x0: 92, y0: 112, x1: 150, y1: 146 };
rect(PARK.x0, PARK.y0, PARK.x1, PARK.y1, T.PARQUE);
for (let y = PARK.y0; y <= PARK.y1; y++) for (let x = PARK.x0; x <= PARK.x1; x++) if (rnd() < 0.09) set(x, y, T.ARBOL);
rect(PARK.x0, 126, PARK.x1, 129, T.ALBERO); // paseo central
rect(118, PARK.y0, 121, PARK.y1, T.ALBERO);
const PE = { x: 150, y: 128, r: 16 };
for (let y = PE.y - PE.r - 4; y <= PE.y + PE.r + 4; y++) for (let x = PE.x - PE.r - 4; x <= PE.x; x++) {
  const d = Math.hypot(x - PE.x, y - PE.y);
  if (d <= PE.r) set(x, y, T.ALBERO);
  else if (d <= PE.r + 3) set(x, y, T.PLAZA_ESPANA);
}
rect(PE.x - PE.r - 4, PE.y - 2, PE.x - PE.r + 1, PE.y + 1, T.ALBERO); // entrada a la plaza
// Las dos torres en los extremos del semicírculo.
rect(PE.x - 3, PE.y - PE.r - 3, PE.x, PE.y - PE.r - 1, T.TORRE_PE);
rect(PE.x - 3, PE.y + PE.r + 1, PE.x, PE.y + PE.r + 3, T.TORRE_PE);

// 10) Salida hacia el bosque: Autovía A-4 al este.
const EXIT_Y = 58;
rect(CASCO.cx + CASCO.rx, EXIT_Y, W - 1, EXIT_Y + 5, T.ASFALTO);

// 11) Aceras: todo edificio que toca asfalto pasa a ser acera.
const isRoad = (t) => t === T.ASFALTO;
const toSidewalk = [];
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
  if (!BUILDING.has(get(x, y))) continue;
  const n = [[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dx, dy]) => inside(x + dx, y + dy) && isRoad(get(x + dx, y + dy)));
  if (n) toSidewalk.push([x, y]);
}
for (const [x, y] of toSidewalk) set(x, y, T.ACERA);

// 12) Manzanas: cada una con su color (teja, cal o albero ocre).
const NERVION_X0 = 150;
const seen = new Uint8Array(W * H);
for (let i = 0; i < W * H; i++) {
  if (seen[i] || !BUILDING.has(g[i])) continue;
  const r = rnd();
  // Nervión: bloques de pisos; el resto, casas de cal, teja u ocre.
  const color = i % W >= NERVION_X0 ? T.BLOQUE : r < 0.5 ? T.CAL : r < 0.8 ? T.TEJADO : T.OCRE;
  const stack = [i];
  seen[i] = 1;
  while (stack.length) {
    const j = stack.pop();
    g[j] = color;
    const x = j % W, y = (j / W) | 0;
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      const k = (y + dy) * W + x + dx;
      if (inside(x + dx, y + dy) && !seen[k] && BUILDING.has(g[k])) { seen[k] = 1; stack.push(k); }
    }
  }
}

// 13) Naranjos en las aceras (semilla aparte: no cambia el resto del mapa).
let treeSeed = 777;
const trnd = () => {
  treeSeed = (treeSeed + 0x6d2b79f5) | 0;
  let t = Math.imul(treeSeed ^ (treeSeed >>> 15), 1 | treeSeed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
const N4 = [[1, 0], [-1, 0], [0, 1], [0, -1]];
const nearTriana = (x, y) => x >= TRIANA.x0 - 3 && x <= TRIANA.x1 + 3 && y >= TRIANA.y0 - 3 && y <= TRIANA.y1 + 3;
const isCorner = (x, y) => [[1, 1], [1, -1], [-1, 1], [-1, -1]].some(([dx, dy]) =>
  inside(x + dx, y + dy) && isRoad(get(x + dx, y) ?? 0) && isRoad(get(x, y + dy) ?? 0) && isRoad(get(x + dx, y + dy)));
for (let y = 1; y < H - 1; y++) for (let x = 1; x < W - 1; x++) {
  if (get(x, y) !== T.ACERA || nearTriana(x, y) || isCorner(x, y)) continue;
  if (!N4.some(([dx, dy]) => isRoad(get(x + dx, y + dy)))) continue;
  const crowded = [[-1, 0], [-2, 0], [0, -1], [0, -2], [-1, -1], [1, -1]].some(([dx, dy]) => get(x + dx, y + dy) === T.NARANJO);
  if (!crowded && trnd() < 0.18) set(x, y, T.NARANJO);
}

// 14) Semáforos en esquinas de manzana. `eje`: h = regula a quien va de este a oeste
// (o al revés), v = de norte a sur. Los coches paran en rojo.
const lights = [];
for (let y = 1; y < H - 1; y++) for (let x = 1; x < W - 1; x++) {
  if (get(x, y) !== T.ACERA || nearTriana(x, y)) continue;
  for (const [dx, dy] of [[1, 1], [1, -1], [-1, 1], [-1, -1]]) {
    if (!(isRoad(get(x + dx, y)) && isRoad(get(x, y + dy)) && isRoad(get(x + dx, y + dy)))) continue;
    if (lights.some((l) => Math.abs(l.x - x) + Math.abs(l.y - y) < 14) || trnd() > 0.3) continue;
    lights.push({ x: x + 0.5 + dx * 0.35, y: y + 0.5 + dy * 0.35, eje: trnd() < 0.5 ? 'h' : 'v' });
  }
}
// Los del puente de Triana: cruce con Betis y con Reyes Católicos.
for (const [x, y] of [[TRIANA.rail0, TRIANA.y0 - 0.2], [TRIANA.rail0, TRIANA.y1 + 1.2], [TRIANA.rail1 + 1, TRIANA.y0 - 0.2], [TRIANA.rail1 + 1, TRIANA.y1 + 1.2]]) {
  lights.push({ x, y, eje: 'h' });
  lights.push({ x: x + 0.01, y, eje: 'v' });
}

// 15) Rutas de los coches (circulan por la derecha). Cada ruta es un circuito cerrado
// por el centro de su carril; se descarta si algún tramo pisa algo que no es calzada.
const drivable = new Set([T.ASFALTO, T.PUENTE, T.PUENTE_TRIANA]);
const along = (yFrom, yTo, xAt) => {
  const pts = [];
  const step = yTo > yFrom ? 2 : -2;
  for (let y = yFrom; step > 0 ? y < yTo : y > yTo; y += step) pts.push([xAt(y), y]);
  pts.push([xAt(yTo), yTo]);
  return pts;
};
const betisS = (y) => riverX(Math.floor(y)) - 15.5;
const betisN = (y) => riverX(Math.floor(y)) - 12.5;
const colonS = (y) => riverX(Math.floor(y)) + 10.5;
const colonN = (y) => riverX(Math.floor(y)) + 13.5;
const lane = (b, east) => b.y + (east ? 3.5 : 1.5);
const telmo = BRIDGES[1], remedios = BRIDGES[2];
const triE = TRIANA.road0 + 3, triW = TRIANA.road0 + 1;
const rectLoop = (x0, y0, x1, y1, cw) => cw
  ? [[x0 + 4.5, y0 + 4.5], [x1 + 1.5, y0 + 4.5], [x1 + 1.5, y1 + 1.5], [x0 + 4.5, y1 + 1.5]]
  : [[x0 + 1.5, y0 + 1.5], [x0 + 1.5, y1 + 4.5], [x1 + 4.5, y1 + 4.5], [x1 + 4.5, y0 + 1.5]];
const ROUTES = [
  // Triana -> Paseo de Colón -> San Telmo -> Betis -> Triana (sentido horario).
  { name: 'triana_san_telmo', coches: 3, pts: [
    ...along(triE, lane(telmo, false), colonS), ...along(lane(telmo, false), triE, betisN)] },
  // Triana -> Betis -> Los Remedios -> Colón -> Triana (antihorario).
  { name: 'triana_remedios', coches: 3, pts: [
    ...along(triW, lane(remedios, true), betisS), ...along(lane(remedios, true), triW, colonN)] },
  { name: 'nervion_1', coches: 2, pts: rectLoop(152, 76, 170, 94, true) },
  { name: 'nervion_2', coches: 2, pts: rectLoop(170, 40, 188, 58, false) },
];
const routes = [];
for (const r of ROUTES) {
  const closed = [...r.pts, r.pts[0]];
  let ok = true;
  for (let i = 0; i + 1 < closed.length && ok; i++) {
    const [ax, ay] = closed[i], [bx, by] = closed[i + 1];
    const n = Math.ceil(Math.hypot(bx - ax, by - ay) * 4);
    for (let k = 0; k <= n; k++) {
      const x = Math.floor(ax + (bx - ax) * k / n), y = Math.floor(ay + (by - ay) * k / n);
      if (!drivable.has(get(x, y))) { ok = false; console.warn(`ruta ${r.name} descartada: (${x}, ${y}) no es calzada`); break; }
    }
  }
  if (ok) routes.push(r);
}

// 13) Taller Karvans, en la manzana del polígono al sur de la A-4 (entre avenidas de Nervión).
// Un carril sale de la A-4 hacia el portón; la furgo entra en la nave y se abre el taller.
const KAR = { x0: 176, y0: 64, x1: 187, y1: 75, door0: 180, door1: 183 };
rect(KAR.x0, KAR.y0, KAR.x1, KAR.y1, T.ACERA);
rect(KAR.x0 + 1, KAR.y0 + 3, KAR.x1 - 1, KAR.y1 - 1, T.NAVE);
rect(KAR.door0, KAR.y0, KAR.door1, KAR.y0 + 1, T.ASFALTO); // carril desde la A-4
rect(KAR.door0, KAR.y0 + 2, KAR.door1, KAR.y0 + 2, T.ENTRADA);
rect(KAR.door0, KAR.y0 + 3, KAR.door1, KAR.y0 + 6, T.TALLER_SUELO); // portón abierto

// ---------- Objetos: spawn, salida y rótulos ----------
const px = (t) => t * TILE;
let oid = 1;
const point = (name, type, tx, ty) => ({ id: oid++, name, type, x: px(tx), y: px(ty), width: 0, height: 0, rotation: 0, visible: true, point: true });
const objects = [
  // La T3 sale al pie del Puente de Triana, en la orilla del Arenal (Paseo de Colón), mirando al norte.
  point('spawn', 'spawn', riverX(62) + 12, 63),
  { id: oid++, name: 'salida_a4', type: 'salida', x: px(W - 4), y: px(EXIT_Y), width: px(4), height: px(6), rotation: 0, visible: true },
  // Dentro del portón: al entrar, el taller. Al salir, la furgo vuelve al carril mirando a la A-4.
  { id: oid++, name: 'taller_karvans', type: 'taller', x: px(KAR.door0), y: px(KAR.y0 + 4), width: px(KAR.door1 - KAR.door0 + 1), height: px(3), rotation: 0, visible: true },
  point('taller_karvans_salida', 'taller_salida', (KAR.door0 + KAR.door1 + 1) / 2, KAR.y0),
  point('Taller Karvans', 'rotulo', (KAR.x0 + KAR.x1 + 1) / 2, KAR.y1 - 2),
  point('Triana', 'rotulo', 30, 64),
  point('La Cartuja', 'rotulo', 30, 16),
  point('Guadalquivir', 'rotulo', riverX(40), 40),
  point('Casco Antiguo', 'rotulo', 112, 46),
  point('Catedral', 'rotulo', 113, 76),
  point('Maestranza', 'rotulo', MAE.x, MAE.y - MAE.r - 2),
  point('Parque de María Luisa', 'rotulo', 112, 120),
  point('Plaza de España', 'rotulo', 142, 128),
  point('Nervión', 'rotulo', 172, 92),
  point('Salida A-4', 'rotulo', W - 12, EXIT_Y - 2),
  point('Torre del Oro', 'rotulo', ORO.x, ORO.y + 4),
  point('Reales Alcázares', 'rotulo', (ALC.x0 + ALC.x1) / 2, ALC.y1 + 2),
  point('Las Setas', 'rotulo', 112, 45),
  point('Torre Sevilla', 'rotulo', 44, 33),
  ...BRIDGES.map((b) => point(b.name, 'rotulo', riverX(b.y), b.y - 1)),
  point('Puente de Triana', 'rotulo', (TRIANA.arch0 + TRIANA.arch1) / 2, TRIANA.y0 - 1.5),
  point('Capillita del Carmen', 'rotulo', CAPILLA.x + 1, CAPILLA.y + 3),
  point('Altozano', 'rotulo', TRIANA.x0 - 4, TRIANA.y0 - 2),
  // Arcos del puente de Triana: el juego pinta los costados bajo la calzada.
  { id: oid++, name: 'puente_triana', type: 'puente_arcos', x: px(TRIANA.arch0), y: px(TRIANA.y0), width: px(TRIANA.arch1 - TRIANA.arch0), height: px(TRIANA.y1 - TRIANA.y0 + 1), rotation: 0, visible: true,
    properties: [
      { name: 'arcos', type: 'int', value: 3 },
      // Barandillas: de dónde a dónde (x) y a qué altura del mapa (y), en px.
      { name: 'reja_x0', type: 'float', value: px(TRIANA.rail0) },
      { name: 'reja_x1', type: 'float', value: px(TRIANA.rail1 + 1) },
      { name: 'reja_y0', type: 'float', value: px(TRIANA.y0 + 0.5) },
      { name: 'reja_y1', type: 'float', value: px(TRIANA.y1 + 0.5) },
    ] },
  // Farolas sobre la barandilla, a ambos lados.
  ...Array.from({ length: Math.floor((TRIANA.rail1 - TRIANA.rail0) / 3) + 1 }, (_, i) => TRIANA.rail0 + 0.5 + i * 3).flatMap((x) => [
    point('farola', 'farola', x, TRIANA.y0 + 0.5), point('farola', 'farola', x, TRIANA.y1 + 0.5)]),
  ...lights.map((l) => ({ ...point('semaforo', 'semaforo', l.x, l.y), properties: [{ name: 'eje', type: 'string', value: l.eje }] })),
  ...routes.map((r) => ({
    id: oid++, name: r.name, type: 'ruta', x: 0, y: 0, rotation: 0, visible: true,
    polyline: r.pts.map(([x, y]) => ({ x: px(x), y: px(y) })),
    properties: [{ name: 'coches', type: 'int', value: r.coches }],
  })),
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
    firstgid: 1, name: 'placeholder', image: 'tiles-sevilla.png',
    imagewidth: TILE * TILE_DEFS.length, imageheight: TILE, tilewidth: TILE, tileheight: TILE,
    tilecount: TILE_DEFS.length, columns: TILE_DEFS.length, margin: 0, spacing: 0,
    tiles: TILE_DEFS.map((d, id) => ({ id, type: d.name, properties: [{ name: 'collides', type: 'bool', value: !!d.collides }, ...volProps(d.vol)] })),
  }],
};
writeFileSync(`${OUT_DIR}/sevilla.json`, JSON.stringify(map));

// ---------- Tileset PNG (rectángulos placeholder) ----------
const IW = TILE * TILE_DEFS.length;
const pix = Buffer.alloc(IW * TILE * 4);
const put = (x, y, [r, gg, b]) => { const o = (y * IW + x) * 4; pix[o] = r; pix[o + 1] = gg; pix[o + 2] = b; pix[o + 3] = 255; };
TILE_DEFS.forEach((d, i) => {
  for (let y = 0; y < TILE; y++) for (let x = 0; x < TILE; x++) {
    let c = d.color;
    if (d.border && (x === 0 || y === 0 || x === TILE - 1 || y === TILE - 1)) c = d.border;
    if (d.grid && (x % 8 === 0 || y % 8 === 0)) c = d.grid;
    if (d.wave && (y % 6 === 2) && ((x + y) % 8 < 3)) c = d.wave;
    if (d.tree && Math.hypot(x - 7.5, y - 7.5) < 6) c = d.tree;
    if (d.rail && (y === 7 || y === 8)) c = d.rail;
    if (d.hatch && (x + y) % 8 < 4) c = d.hatch;
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
writeFileSync(`${OUT_DIR}/tiles-sevilla.png`, Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  chunk('IHDR', ihdr), chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0)),
]));
console.log(`sevilla.json ${W}x${H} tiles, ${objects.length} objetos`);
