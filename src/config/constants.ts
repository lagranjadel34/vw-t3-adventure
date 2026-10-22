export const GAME_WIDTH = 320;
export const GAME_HEIGHT = 180;
export const TILE_SIZE = 16;

export const VAN_ACCELERATION = 220;
export const VAN_MAX_SPEED = 90;
export const VAN_DRAG = 160;
// Dirección tipo coche: giran las ruedas delanteras y la trasera sigue la trazada.
// Ejes como fracción del alto del sprite medida desde el centro (batalla T3 ≈ 54% del largo).
export const VAN_FRONT_AXLE_RATIO = 0.3;
export const VAN_REAR_AXLE_RATIO = 0.24;
// Ángulo máximo de las ruedas delanteras (grados). Más ángulo = giro más cerrado.
export const VAN_MAX_STEER_DEG = 35;

// Colisión de la T3: círculo centrado (el cuerpo Arcade no rota con el sprite).
export const VAN_BODY_RADIUS = 14;
