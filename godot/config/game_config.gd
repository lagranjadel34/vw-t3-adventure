class_name GameConfig
## Constantes del juego, portadas de src/config (versión Phaser). Sin números mágicos fuera de aquí.
## Medidas en píxeles internos (320x180); velocidades en px/s y aceleraciones en px/s².

# --- Pantalla y tiles ---
const GAME_WIDTH := 320
const GAME_HEIGHT := 180
const TILE_SIZE := 16

# --- Conducción de la T3 ---
const VAN_ACCELERATION := 320.0
const VAN_MAX_SPEED := 130.0
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

# --- Peso: según la camperización la T3 pesa más o menos ---
# Masa en vacío y carga por defecto (camperización media). Con la carga por defecto el
# factor de peso es 1; más carga = acelera, frena y agarra menos (y al revés).
const VAN_EMPTY_MASS_KG := 1400.0
const VAN_DEFAULT_LOAD_KG := 300.0
const VAN_LOAD_PRESETS_KG := {"furgon": 0.0, "camper": 300.0, "westfalia": 450.0}

# --- Agarre y derrape (motor y tracción traseros: se va de atrás) ---
# Aceleración lateral (v · giro, px/s²) que aguantan las ruedas antes de derrapar.
const VAN_GRIP_LIMIT := 140.0
# Agarre lateral durante el derrape: la velocidad de lado se pierde a este ritmo (1/s).
const VAN_DRIFT_GRIP := 3.0
# Con gas en pleno derrape las ruedas traseras patinan: agarre multiplicado por esto.
const VAN_DRIFT_GAS_GRIP_RATIO := 0.6
# Motor trasero: el peso de atrás empuja la cola hacia fuera (rad/s por px/s de deslizamiento).
const VAN_DRIFT_TAIL_YAW := 0.012
const VAN_DRIFT_MAX_TAIL_YAW := 1.5
# El derrape acaba cuando la velocidad de lado baja de esto (px/s).
const VAN_DRIFT_END_SLIP := 6.0
# Freno de mano (Espacio): bloquea las traseras, casi sin agarre lateral.
const VAN_HANDBRAKE_GRIP := 1.2
const VAN_HANDBRAKE_DECELERATION := 110.0

# --- Cámara: se aleja con la velocidad para ver más mapa (STOPPED parada -> MIN a tope) ---
const CAMERA_ZOOM_STOPPED := 0.75
const CAMERA_ZOOM_MIN := 0.55
# Suavizado por frame a 60 fps (0-1); se corrige con el delta real.
const CAMERA_ZOOM_LERP := 0.03
const CAMERA_ZOOM_LERP_FPS := 60.0

# --- Escala del mundo y cuentakilómetros ---
# Escala elegida para que VAN_MAX_SPEED marque la punta real de la T3 (100 km/h).
const VAN_TOP_SPEED_KMH := 100.0
const KMH_PER_MPS := 3.6
const METERS_PER_PIXEL := VAN_TOP_SPEED_KMH / KMH_PER_MPS / VAN_MAX_SPEED
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

# --- Caja de cambios de la T3 (4 marchas) ---
# Rejilla de la T3 de 4 marchas (al revés que un coche normal): 1ª abajo-izquierda,
# 2ª arriba-izquierda, 3ª abajo-derecha, 4ª arriba-derecha.
# (columna, fila) con -1/+1 = izquierda/derecha, arriba/abajo.
const GEAR_GATE: Array[Vector2i] = [Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, 1), Vector2i(1, -1)]
# Por marcha: velocidad máxima (fracción de VAN_MAX_SPEED) y fuerza (fracción de VAN_ACCELERATION).
const GEAR_MAX_SPEED_RATIO: Array[float] = [0.3, 0.55, 0.8, 1.0]
const GEAR_ACCEL_RATIO: Array[float] = [1.0, 0.75, 0.5, 0.35]
# Marcha larga a pocas vueltas: por debajo de esta fracción del tope de la marcha anterior,
# el motor se ahoga y apenas empuja (arrancar en 3ª cuesta).
const GEAR_LUG_SPEED_RATIO := 0.5
const GEAR_LUG_ACCEL_RATIO := 0.25
# Por encima del tope de la marcha (al reducir), el motor retiene hasta ese tope.
const GEAR_ENGINE_BRAKE := 140.0
# Embrague pisado durante el cambio: ese tiempo no hay potencia (s).
const GEAR_SHIFT_TIME := 0.25
# Automático: sube al llegar a esta fracción del tope; baja por debajo de esta fracción
# del tope de la marcha anterior.
const GEAR_AUTO_UP_RATIO := 0.95
const GEAR_AUTO_DOWN_RATIO := 0.6

# --- Palanca de cambios en el HUD, encima de los pedales ---
# Así el mismo pulgar que acelera y frena tiene que soltar el pedal para cambiar.
# Rectángulo relativo a la esquina inferior derecha de la pantalla.
const LEVER_RECT := Rect2(-48, -94, 30, 40)
const LEVER_HIT_PADDING := 4.0
const LEVER_SWIPE_MIN := 6.0 # px de deslizamiento para cambiar de marcha
const LEVER_SHIFT_S := 0.15 # duración del recorrido de la bola por la H
const LEVER_SLOT_INSET := Vector2(8, 9) # de la ranura al borde de la placa
const LEVER_KNOB_RADIUS := 4.0
const LEVER_MODE_TOP := 2.0 # letra A/M desde el borde superior de la placa
const LEVER_IDLE_ALPHA := 0.8
const LEVER_COLORS := {
	"plate": Color("2a2620"),
	"plate_edge": Color("6b6150"),
	"slot": Color("080808"),
	"number": Color("c9bf9f"),
	"knob": Color("141414"),
	"knob_shine": Color("5a5a5a"),
	"mode_auto": Color("6fbf4a"),
	"mode_manual": Color("ffd24d"),
}
