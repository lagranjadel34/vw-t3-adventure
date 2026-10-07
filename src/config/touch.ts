// Controles táctiles. Medidas en píxeles internos (320x180);
// en un móvil apaisado la escala suele ser x2-x3, así que 22 px internos ≈ 44-66 px reales.

export const TOUCH_ACTIVE_POINTERS = 3;

// Joystick flotante: aparece donde se apoya el pulgar en la mitad izquierda.
export const JOYSTICK_ZONE_WIDTH_RATIO = 0.5;
export const JOYSTICK_RADIUS = 22;
export const JOYSTICK_KNOB_RADIUS = 10;
export const JOYSTICK_DEAD_ZONE = 0.2;
export const JOYSTICK_IDLE_X = 44;
export const JOYSTICK_IDLE_Y = 132;
export const JOYSTICK_IDLE_ALPHA = 0.35;
export const JOYSTICK_ACTIVE_ALPHA = 0.7;
export const JOYSTICK_DEPTH = 1000;

// Zona mínima de toque para botones y opciones de menú.
export const TAP_MIN_HEIGHT = 22;
export const TAP_PADDING_X = 8;
