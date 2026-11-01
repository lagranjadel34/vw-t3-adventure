// Texturas procedurales para los tiles placeholder (compartido por los generadores de mapas).
// `shade` recibe el color plano de un píxel del tile y devuelve el color con grano y detalles
// según el estilo (`tex`) del tile: hierba, tierra, grava, asfalto... Es determinista: el mismo
// tile da siempre los mismos píxeles, y el ruido de cada píxel es independiente, así que los
// tiles vecinos siguen encajando sin costuras.

const TILE = 16;
const DEFAULT_NOISE = 7; // amplitud del grano fino (0-255)
const BLOTCH_RATIO = 0.7; // manchas de 2x2 respecto al grano

const hash = (x, y, s) => {
  let h = (Math.imul(x + 1013, 374761393) + Math.imul(y + 2027, 668265263) + Math.imul(s + 31, 1274126177)) | 0;
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  return ((h ^ (h >>> 16)) >>> 0) / 4294967296;
};
const clamp = (v) => Math.max(0, Math.min(255, Math.round(v)));
const add = (c, d) => [clamp(c[0] + d), clamp(c[1] + d), clamp(c[2] + d)];
const mix = (a, b, t) => [clamp(a[0] + (b[0] - a[0]) * t), clamp(a[1] + (b[1] - a[1]) * t), clamp(a[2] + (b[2] - a[2]) * t)];

const FLOWERS = [[236, 226, 200], [226, 150, 52], [196, 96, 70]];
const LEAF = [196, 104, 48];
const GRASS_EDGE = [128, 134, 66];

export const shade = (c, d, i, x, y) => {
  const amp = d.noise ?? DEFAULT_NOISE;
  const n = hash(x, y, i) - 0.5;
  const blotch = hash(x >> 1, y >> 1, i + 101) - 0.5;
  let out = add(c, n * 2 * amp + blotch * 2 * amp * BLOTCH_RATIO);
  switch (d.tex) {
    case 'grass': {
      // Briznas de 1x2 px: punta clara y base oscura.
      if (hash(x, y, i + 7) < 0.07) out = add(out, 18);
      else if (hash(x, y - 1, i + 7) < 0.07) out = add(out, -14);
      break;
    }
    case 'hojas': {
      if (hash(x, y, i + 7) < 0.07) out = add(out, 16);
      if (hash(x, y, i + 9) < 0.05) out = mix(out, LEAF, 0.85);
      break;
    }
    case 'flores': {
      if (hash(x, y, i + 7) < 0.05) out = add(out, 14);
      if (hash(x, y, i + 9) < 0.025) out = FLOWERS[Math.floor(hash(x, y, i + 11) * FLOWERS.length)];
      break;
    }
    case 'tierra': {
      if (hash(x >> 1, y >> 1, i + 13) < 0.05) out = add(out, 22); // piedrecillas
      else if (hash(x, y, i + 17) < 0.03) out = add(out, -20); // grietas
      break;
    }
    case 'rodada_h':
    case 'rodada_v': {
      const along = d.tex === 'rodada_h' ? x : y;
      const across = d.tex === 'rodada_h' ? y : x;
      // Dos surcos de rueda de 2 px, discontinuos, con el centro algo más claro.
      const rut = (across >= 3 && across <= 4) || (across >= 11 && across <= 12);
      if (rut && hash(along >> 2, across, i + 19) > 0.18) out = add(out, -24);
      else if (across >= 7 && across <= 8 && hash(x, y, i + 21) < 0.3) out = add(out, 10);
      if (hash(x >> 1, y >> 1, i + 13) < 0.04) out = add(out, 20);
      break;
    }
    case 'tierra_hierba': {
      // Borde del camino: matas de hierba que se comen la tierra, más densas hacia los bordes.
      const edge = Math.min(x, y, TILE - 1 - x, TILE - 1 - y);
      if (hash(x, y, i + 25) < 0.5 - 0.12 * edge) out = mix(out, GRASS_EDGE, 0.85);
      if (hash(x >> 1, y >> 1, i + 13) < 0.04) out = add(out, 20);
      break;
    }
    case 'charco': {
      // Barro con un charco brillante en el centro.
      const e = ((x - 7.5) / 6) ** 2 + ((y - 8) / 3.6) ** 2;
      if (e <= 1) out = mix(out, [134, 150, 138], 0.7 - 0.25 * e);
      else if (e <= 1.45) out = add(out, -22);
      break;
    }
    case 'grava': {
      if (hash(x, y, i + 23) < 0.12) out = add(out, 24);
      else if (hash(x, y, i + 27) < 0.06) out = add(out, -22);
      break;
    }
    case 'asfalto': {
      if (hash(x, y, i + 29) < 0.03) out = add(out, 10);
      break;
    }
    case 'asfalto_grietas': {
      if (hash(x, y, i + 29) < 0.03) out = add(out, 10);
      // Grieta que cruza el tile en diagonal irregular.
      const cx = Math.round(2 + (y * 0.8) + (hash(y, 0, i + 31) - 0.5) * 3);
      if (x === cx) out = add(out, -26);
      break;
    }
    default:
  }
  return out;
};
