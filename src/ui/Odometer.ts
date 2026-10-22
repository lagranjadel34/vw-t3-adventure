import Phaser from 'phaser';
import { GAME_WIDTH } from '../config/constants';
import {
  ODOMETER_CARRY_ZONE,
  ODOMETER_CELL_H,
  ODOMETER_CELL_W,
  ODOMETER_COLORS,
  ODOMETER_DEPTH,
  ODOMETER_GLYPH_H,
  ODOMETER_GLYPH_W,
  ODOMETER_INT_DIGITS,
  ODOMETER_LABEL_GAP,
  ODOMETER_MARGIN,
  ODOMETER_PADDING,
  ODOMETER_SHADE_ALPHA,
  ODOMETER_SHADE_ROWS,
  ODOMETER_TENTHS_DIGITS,
  ODOMETER_WHEEL_GAP,
} from '../config/odometer';

// Fuente 3x5: cada dígito son 5 filas de 3 bits.
const GLYPHS: Record<number, string[]> = {
  0: ['111', '101', '101', '101', '111'],
  1: ['010', '110', '010', '010', '111'],
  2: ['111', '001', '111', '100', '111'],
  3: ['111', '001', '011', '001', '111'],
  4: ['101', '101', '111', '001', '001'],
  5: ['111', '100', '111', '001', '111'],
  6: ['111', '100', '111', '101', '111'],
  7: ['111', '001', '010', '010', '010'],
  8: ['111', '101', '111', '101', '111'],
  9: ['111', '101', '111', '001', '111'],
};
// "km" en 3x5 (k y m), para la etiqueta.
const LABEL_KM = [
  ['100', '101', '110', '101', '101'],
  ['000', '000', '111', '111', '101'],
];

const DIGITS = 10;
const STRIP_INT = 'odo_strip_int';
const STRIP_TENTHS = 'odo_strip_tenths';

/** Cuentakilómetros mecánico: rodillos 0-9 que giran y arrastran al de su izquierda. */
export class Odometer {
  private wheels: Phaser.GameObjects.TileSprite[] = [];
  private readonly total = ODOMETER_INT_DIGITS + ODOMETER_TENTHS_DIGITS;

  constructor(scene: Phaser.Scene) {
    this.makeStrip(scene, STRIP_INT, ODOMETER_COLORS.wheel, ODOMETER_COLORS.digit);
    this.makeStrip(scene, STRIP_TENTHS, ODOMETER_COLORS.tenthsWheel, ODOMETER_COLORS.tenthsDigit);

    const wheelsW = this.total * ODOMETER_CELL_W + (this.total - 1) * ODOMETER_WHEEL_GAP;
    const labelW = LABEL_KM.length * (ODOMETER_GLYPH_W + 1);
    const innerW = wheelsW + ODOMETER_LABEL_GAP + labelW;
    const w = innerW + ODOMETER_PADDING * 2;
    const h = ODOMETER_CELL_H + ODOMETER_PADDING * 2;
    const x0 = GAME_WIDTH - ODOMETER_MARGIN - w;
    const y0 = ODOMETER_MARGIN;

    const g = scene.add.graphics();
    // Marco: borde claro arriba/izquierda, oscuro abajo/derecha (relieve de plástico).
    g.fillStyle(ODOMETER_COLORS.frameDark).fillRect(x0 - 1, y0 - 1, w + 2, h + 2);
    g.fillStyle(ODOMETER_COLORS.frame).fillRect(x0 - 1, y0 - 1, w + 1, h + 1);
    g.fillStyle(ODOMETER_COLORS.bezel).fillRect(x0, y0, w, h);

    const wx = x0 + ODOMETER_PADDING;
    const wy = y0 + ODOMETER_PADDING;
    for (let i = 0; i < this.total; i++) {
      const isTenths = i >= ODOMETER_INT_DIGITS;
      const x = wx + i * (ODOMETER_CELL_W + ODOMETER_WHEEL_GAP);
      const wheel = scene.add
        .tileSprite(x, wy, ODOMETER_CELL_W, ODOMETER_CELL_H, isTenths ? STRIP_TENTHS : STRIP_INT)
        .setOrigin(0, 0);
      this.wheels.push(wheel);
    }

    // Sombra de curvatura sobre los rodillos.
    const shade = scene.add.graphics();
    for (let r = 0; r < ODOMETER_SHADE_ROWS; r++) {
      const a = ODOMETER_SHADE_ALPHA * (1 - r / ODOMETER_SHADE_ROWS);
      shade.fillStyle(ODOMETER_COLORS.shade, a);
      shade.fillRect(wx, wy + r, wheelsW, 1);
      shade.fillRect(wx, wy + ODOMETER_CELL_H - 1 - r, wheelsW, 1);
    }

    // Etiqueta "km".
    const lx = wx + wheelsW + ODOMETER_LABEL_GAP;
    const ly = wy + Math.floor((ODOMETER_CELL_H - ODOMETER_GLYPH_H) / 2);
    shade.fillStyle(ODOMETER_COLORS.label);
    LABEL_KM.forEach((glyph, n) => this.drawGlyph(shade, glyph, lx + n * (ODOMETER_GLYPH_W + 1), ly));

    for (const o of [g, ...this.wheels, shade]) o.setScrollFactor(0).setDepth(ODOMETER_DEPTH);
  }

  /** Muestra un kilometraje (con decimales). Los rodillos giran de forma continua. */
  setKm(km: number): void {
    // Valor en la unidad del rodillo más a la derecha (décimas).
    let value = km * 10 ** ODOMETER_TENTHS_DIGITS;
    let pos = value % DIGITS; // posición continua del rodillo de las unidades más bajas
    for (let i = this.total - 1; i >= 0; i--) {
      this.wheels[i].tilePositionY = pos * ODOMETER_CELL_H;
      // Siguiente rodillo: su dígito entero, más el arrastre cuando el actual pasa de 9 a 0.
      const frac = pos - Math.floor(pos);
      const carrying = pos >= DIGITS - 1 && frac > 1 - ODOMETER_CARRY_ZONE;
      const carry = carrying ? (frac - (1 - ODOMETER_CARRY_ZONE)) / ODOMETER_CARRY_ZONE : 0;
      value = Math.floor(value / DIGITS);
      pos = (value % DIGITS) + carry;
    }
  }

  /** Genera una tira vertical 0..9 que la TileSprite repite (9 vuelve a 0). */
  private makeStrip(scene: Phaser.Scene, key: string, bg: number, fg: number): void {
    if (scene.textures.exists(key)) return;
    const g = scene.make.graphics({}, false);
    g.fillStyle(bg).fillRect(0, 0, ODOMETER_CELL_W, ODOMETER_CELL_H * DIGITS);
    g.fillStyle(fg);
    const gx = Math.floor((ODOMETER_CELL_W - ODOMETER_GLYPH_W) / 2);
    const gy = Math.floor((ODOMETER_CELL_H - ODOMETER_GLYPH_H) / 2);
    for (let d = 0; d < DIGITS; d++) this.drawGlyph(g, GLYPHS[d], gx, d * ODOMETER_CELL_H + gy);
    g.generateTexture(key, ODOMETER_CELL_W, ODOMETER_CELL_H * DIGITS);
    g.destroy();
  }

  private drawGlyph(g: Phaser.GameObjects.Graphics, rows: string[], x: number, y: number): void {
    rows.forEach((row, ry) => {
      for (let rx = 0; rx < row.length; rx++) if (row[rx] === '1') g.fillRect(x + rx, y + ry, 1, 1);
    });
  }
}
