class_name GameConfig
## Constantes del juego, portadas de src/config (versión Phaser). Sin números mágicos fuera de aquí.
## Medidas en píxeles internos (320x180); velocidades en px/s y aceleraciones en px/s².

# --- Pantalla y tiles ---
const GAME_WIDTH := 320
const GAME_HEIGHT := 180
const TILE_SIZE := 16

# --- Conducción de la T3 ---
const VAN_ACCELERATION := 220.0
const VAN_MAX_SPEED := 90.0
# Inercia: sin pedales, la furgo pierde esta velocidad por segundo hasta parar.
const VAN_DRAG := 160.0
# Freno y marcha atrás. Por debajo de VAN_STOP_SPEED se considera parada.
const VAN_BRAKE_DECELERATION := 260.0
const VAN_REVERSE_ACCELERATION := 120.0
const VAN_MAX_REVERSE_SPEED := 30.0
const VAN_STOP_SPEED := 2.0
# Dirección tipo coche: giran las ruedas delanteras y la trasera sigue la trazada.
# Ejes como fracción del alto del sprite medida desde el centro (batalla T3 ≈ 54% del largo).
const VAN_FRONT_AXLE_RATIO := 0.3
const VAN_REAR_AXLE_RATIO := 0.24
# Ángulo máximo de las ruedas delanteras (grados). Más ángulo = giro más cerrado.
const VAN_MAX_STEER_DEG := 35.0
# Colisión: círculo centrado (gira con la furgo sin cambiar de forma).
const VAN_BODY_RADIUS := 14.0

# --- Cámara: se aleja con la velocidad para ver más mapa (zoom 1 parada -> MIN a tope) ---
const CAMERA_ZOOM_STOPPED := 1.0
const CAMERA_ZOOM_MIN := 0.75
# Suavizado por frame a 60 fps (0-1); se corrige con el delta real.
const CAMERA_ZOOM_LERP := 0.03
const CAMERA_ZOOM_LERP_FPS := 60.0

# --- Escala del mundo y cuentakilómetros ---
# Con VAN_MAX_SPEED = 90 px/s, 0.28 m/px ≈ 90 km/h.
const METERS_PER_PIXEL := 0.28
const METERS_PER_KM := 1000.0
# Kilometraje con el que sale la T3 (una furgo de 1980 ya tiene sus km).
const ODOMETER_START_KM := 184263.0

# --- Mapa de Sevilla (Tiled). Generado con scripts/gen-sevilla-map.mjs ---
const MAP_JSON := "res://assets/maps/sevilla.json"
const MAP_TILESET_IMAGE := "res://assets/maps/tiles-sevilla.png"
const MAP_GROUND_LAYER := "suelo"
const MAP_OBJECTS_LAYER := "objetos"
const MAP_SPAWN := "spawn"
const MAP_LABEL_TYPE := "rotulo"
const MAP_COLLIDES_PROPERTY := "collides"
# Rótulos de barrios y monumentos sobre el mapa.
const MAP_LABEL_FONT_SIZE := 8
const MAP_LABEL_COLOR := Color.WHITE
const MAP_LABEL_OUTLINE_COLOR := Color.BLACK
const MAP_LABEL_OUTLINE_SIZE := 2
const MAP_LABEL_ALPHA := 0.75

# --- Controles táctiles ---
# Joystick flotante: aparece donde se apoya el pulgar en la mitad izquierda.
const JOYSTICK_ZONE_WIDTH_RATIO := 0.5
const JOYSTICK_RADIUS := 22.0
const JOYSTICK_KNOB_RADIUS := 10.0
const JOYSTICK_DEAD_ZONE := 0.2
# Posición en reposo: desde la esquina inferior izquierda.
const JOYSTICK_IDLE_OFFSET := Vector2(44, -48)
const JOYSTICK_IDLE_ALPHA := 0.35
const JOYSTICK_ACTIVE_ALPHA := 0.7
const JOYSTICK_BASE_COLOR := Color(1, 1, 1, 0.15)
const JOYSTICK_RING_COLOR := Color(1, 1, 1, 0.8)
const JOYSTICK_KNOB_COLOR := Color(1, 1, 1, 0.6)
# Zona mínima de toque para botones y opciones de menú.
const TAP_MIN_HEIGHT := 22

# --- Pedales (acelerador y freno), abajo a la derecha, lejos del joystick ---
# Rectángulos relativos a la esquina inferior derecha de la pantalla.
# Como en una T3: freno ancho a la izquierda, acelerador alto y estrecho a la derecha.
const PEDAL_GAS := Rect2(-24, -38, 16, 32)
const PEDAL_BRAKE := Rect2(-58, -26, 26, 20)
# Zona de toque más generosa que el dibujo (alto final >= TAP_MIN_HEIGHT).
const PEDAL_HIT_PADDING := 4.0
# Forma de pedal de T3: goma con esquinas romas y estrías, colgada de un brazo metálico.
const PEDAL_ARM_WIDTH := 2.0
const PEDAL_ARM_LENGTH := 10.0
const PEDAL_CORNER := 2.0 # píxeles recortados en cada esquina (redondeo pixel art)
const PEDAL_RIB_SPACING := 3.0 # separación de las estrías de goma
const PEDAL_RIB_INSET := 3.0 # margen lateral de las estrías
const PEDAL_PRESS_OFFSET := 1.0 # el pedal "baja" al pisarlo
const PEDAL_IDLE_ALPHA := 0.8
const PEDAL_PRESSED_ALPHA := 1.0
const PEDAL_COLORS := {
	"arm": Color("8d8778"),
	"arm_shadow": Color("3b372f"),
	"outline": Color("080808"),
	"rubber": Color("262626"),
	"rubber_pressed": Color("1a1a1a"),
	"highlight": Color("4a4a4a"),
	"rib": Color("0f0f0f"),
	"rib_light": Color("3e3e3e"),
}
