export const GAME_WIDTH = 320;
export const GAME_HEIGHT = 180;
export const TILE_SIZE = 16;

export const VAN_ACCELERATION = 220;
export const VAN_MAX_SPEED = 90;
export const VAN_DRAG = 160;
// Freno y marcha atrás (px/s²; px/s). Por debajo de VAN_STOP_SPEED se considera parada.
export const VAN_BRAKE_DECELERATION = 260;
export const VAN_REVERSE_ACCELERATION = 120;
export const VAN_MAX_REVERSE_SPEED = 30;
export const VAN_STOP_SPEED = 2;
// Dirección tipo coche: giran las ruedas delanteras y la trasera sigue la trazada.
// Ejes como fracción del alto del sprite medida desde el centro (batalla T3 ≈ 54% del largo).
export const VAN_FRONT_AXLE_RATIO = 0.3;
export const VAN_REAR_AXLE_RATIO = 0.24;
// Ángulo máximo de las ruedas delanteras (grados). Más ángulo = giro más cerrado.
export const VAN_MAX_STEER_DEG = 35;

// Colisión de la T3: círculo centrado (el cuerpo Arcade no rota con el sprite).
export const VAN_BODY_RADIUS = 14;

// Cámara: se aleja con la velocidad para ver más mapa (zoom 1 parada -> MIN a tope).
export const CAMERA_ZOOM_STOPPED = 1;
export const CAMERA_ZOOM_MIN = 0.75;
export const CAMERA_ZOOM_LERP = 0.03; // suavizado por frame (0-1)
