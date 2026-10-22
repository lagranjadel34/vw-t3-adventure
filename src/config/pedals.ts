// Pedales en pantalla (acelerador y freno), en la capa del HUD.
// Medidas en píxeles internos (320x180). Abajo a la derecha, lejos del joystick.

export interface PedalRect {
  x: number;
  y: number;
  w: number;
  h: number;
}

// Como en una T3: freno ancho a la izquierda, acelerador alto y estrecho a la derecha.
export const PEDAL_GAS: PedalRect = { x: 296, y: 142, w: 16, h: 32 };
export const PEDAL_BRAKE: PedalRect = { x: 262, y: 154, w: 26, h: 20 };

// Zona de toque más generosa que el dibujo (alto final >= TAP_MIN_HEIGHT).
export const PEDAL_HIT_PADDING = 4;
export const PEDAL_DEPTH = 900;

// Forma de pedal de T3: goma con esquinas romas y estrías, colgada de un brazo metálico.
export const PEDAL_ARM_WIDTH = 2;
export const PEDAL_ARM_LENGTH = 10;
export const PEDAL_CORNER = 2; // píxeles recortados en cada esquina (redondeo pixel art)
export const PEDAL_RIB_SPACING = 3; // separación de las estrías de goma
export const PEDAL_RIB_INSET = 3; // margen lateral de las estrías
export const PEDAL_PRESS_OFFSET = 1; // el pedal "baja" al pisarlo
export const PEDAL_IDLE_ALPHA = 0.8;
export const PEDAL_PRESSED_ALPHA = 1;

export const PEDAL_COLORS = {
  arm: 0x8d8778,
  armShadow: 0x3b372f,
  outline: 0x080808,
  rubber: 0x262626,
  rubberPressed: 0x1a1a1a,
  highlight: 0x4a4a4a,
  rib: 0x0f0f0f,
  ribLight: 0x3e3e3e,
};

