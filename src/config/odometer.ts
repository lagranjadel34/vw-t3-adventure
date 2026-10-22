// Cuentakilómetros HUD (contador mecánico de rodillos, estilo años 80).
// Medidas en píxeles internos (320x180).

// Escala del mundo: con VAN_MAX_SPEED = 90 px/s, 0.28 m/px ≈ 90 km/h.
export const METERS_PER_PIXEL = 0.28;
export const METERS_PER_KM = 1000;

// Kilometraje con el que sale la T3 (una furgo de 1980 ya tiene sus km).
export const ODOMETER_START_KM = 184263;

// Rodillos: enteros + 1 de décimas (colores invertidos, como en el VW original).
export const ODOMETER_INT_DIGITS = 6;
export const ODOMETER_TENTHS_DIGITS = 1;

// Fuente de píxeles 3x5 escalada; cada celda del rodillo tiene margen arriba/abajo.
export const ODOMETER_GLYPH_W = 3;
export const ODOMETER_GLYPH_H = 5;
export const ODOMETER_CELL_W = 5;
export const ODOMETER_CELL_H = 9;
export const ODOMETER_WHEEL_GAP = 1;
export const ODOMETER_PADDING = 2;
export const ODOMETER_MARGIN = 4;
export const ODOMETER_LABEL_GAP = 2;
export const ODOMETER_DEPTH = 900;

// Fracción final del giro en la que los rodillos superiores arrastran (acarreo mecánico).
export const ODOMETER_CARRY_ZONE = 0.15;

// Sombreado de curvatura del cilindro (filas superior e inferior).
export const ODOMETER_SHADE_ROWS = 2;
export const ODOMETER_SHADE_ALPHA = 0.45;

export const ODOMETER_COLORS = {
  frame: 0x6b6150,
  frameDark: 0x2a2620,
  bezel: 0x0c0c0c,
  wheel: 0x161616,
  digit: 0xe8e2cf,
  tenthsWheel: 0xe8e2cf,
  tenthsDigit: 0xb3261e,
  shade: 0x000000,
  label: 0xc9bf9f,
};
