class_name GameConfig
## Constantes del juego, portadas de src/config (versión Phaser). Sin números mágicos fuera de aquí.
## Medidas en píxeles internos (320x180); velocidades en px/s y aceleraciones en px/s².

# --- Pantalla y tiles ---
const GAME_WIDTH := 320
const GAME_HEIGHT := 180
const TILE_SIZE := 16
# El juego se dibuja a la resolución de la pantalla (stretch canvas_items): la lógica sigue en
# 320x180 y los tiles se amplían pixelados, pero la T3 y los polígonos salen nítidos. Las
# líneas llevan grosor en px de juego (sin él serían de 1 px de pantalla, un pelo).
const LINE_WIDTH := 1.0

# --- Conducción de la T3 ---
# Velocidad en pantalla: la furgo mide 64 px y a 100 km/h solo hacía 2 furgos por segundo (una T3
# real hace ~6), así que las tres primeras marchas parecían ir arrastrándose. Esta escala multiplica
# velocidades y aceleraciones sin tocar los km/h (METERS_PER_PIXEL se deriva de VAN_MAX_SPEED).
# 1.0 = la de antes; ~3.0 = escala real de la T3.
const VAN_SPEED_SCALE := 2.0
# Empuje del motor en 1ª a bajas vueltas (px/s²). Cada marcha lo reduce mucho (GEAR_ACCEL_RATIO).
const VAN_ACCELERATION := 75.0 * VAN_SPEED_SCALE
const VAN_MAX_SPEED := 130.0 * VAN_SPEED_SCALE
# Inercia: sin pedales, la furgo pierde esta velocidad por segundo hasta parar.
const VAN_DRAG := 30.0 * VAN_SPEED_SCALE
# Freno y marcha atrás. Por debajo de VAN_STOP_SPEED se considera parada.
const VAN_BRAKE_DECELERATION := 150.0 * VAN_SPEED_SCALE
const VAN_REVERSE_ACCELERATION := 120.0 * VAN_SPEED_SCALE
const VAN_MAX_REVERSE_SPEED := 30.0 * VAN_SPEED_SCALE
const VAN_STOP_SPEED := 2.0
# Dirección tipo coche: giran las ruedas delanteras y la trasera sigue la trazada.
# Ejes como fracción del alto del sprite medida desde el centro (batalla T3 ≈ 54% del largo).
const VAN_FRONT_AXLE_RATIO := 0.3
const VAN_REAR_AXLE_RATIO := 0.24
# Ángulo máximo de las ruedas delanteras (grados). Más ángulo = giro más cerrado.
const VAN_MAX_STEER_DEG := 35.0
# Colisión: círculo centrado (gira con la furgo sin cambiar de forma).
const VAN_BODY_RADIUS := 14.0
# Largo de la furgo para las físicas (ejes, batalla). Antes salía del alto del sprite cenital.
const VAN_LENGTH_PX := 64.0

# --- Sprite de la T3 (texturas generadas con tools/sprites/top_hd.py) ---
# Vista superior en alta resolución, una por estado: top_d<daño>.png y top_d<daño>_luces.png,
# morro a la derecha. Se gira con la furgo, con filtro lineal y mipmaps: sin escalones.
const VAN_SPRITE_LIGHTS_SUFFIX := "_luces"
# Px de textura por px de juego (HD_SCALE en top_hd.py).
const VAN_TOP_HD_SCALE := 4.0
# Sombra: la silueta desplazada en el suelo (px) y semitransparente.
const VAN_SHADOW_OFFSET := Vector2(2, 3)
const VAN_SHADOW_COLOR := Color(0, 0, 0, 0.3)
# Escala y cámara del escape (cenital, como el mapa).
const VAN_SPRITE_PX_PER_M := 13.0
const VAN_SPRITE_CAMERA_DEG := 90.0
# Estados de daño de la carrocería (0 bien · 1 desgastado · 2 averiado · 3 crítico).
const VAN_DAMAGE_LEVELS := 4

# --- Humo del escape (según el daño) ---
# Escape en metros del modelo: x adelante, y izquierda, z altura.
const VAN_EXHAUST_M := Vector3(-2.39, 0.5, 0.25)
const VAN_SMOKE_AMOUNT: Array[int] = [6, 10, 18, 28]
const VAN_SMOKE_COLORS: Array[Color] = [Color(0.8, 0.8, 0.8, 0.35), Color(0.7, 0.7, 0.7, 0.5), Color(0.47, 0.47, 0.48, 0.7), Color(0.16, 0.16, 0.17, 0.85)]
const VAN_SMOKE_LIFETIME := 0.9
const VAN_SMOKE_SPEED := Vector2(4, 10)
const VAN_SMOKE_RISE := -10.0
const VAN_SMOKE_SPREAD_DEG := 30.0
const VAN_SMOKE_SIZE := Vector2(1, 3)


# --- Peso: según la camperización la T3 pesa más o menos ---
# Masa en vacío y carga por defecto (camperización media). Con la carga por defecto el
# factor de peso es 1; más carga = acelera, frena y agarra menos (y al revés).
const VAN_EMPTY_MASS_KG := 1400.0
const VAN_DEFAULT_LOAD_KG := 300.0
const VAN_LOAD_PRESETS_KG := {"furgon": 0.0, "camper": 300.0, "westfalia": 450.0}

# --- Agarre y derrape (motor y tracción traseros: se va de atrás) ---
# Aceleración lateral (v · giro, px/s²) que aguantan las ruedas antes de derrapar.
const VAN_GRIP_LIMIT := 140.0 * VAN_SPEED_SCALE * VAN_SPEED_SCALE # v · giro: crece con la escala al cuadrado
# Agarre lateral durante el derrape: la velocidad de lado se pierde a este ritmo (1/s).
const VAN_DRIFT_GRIP := 3.0
# Con gas en pleno derrape las ruedas traseras patinan: agarre multiplicado por esto.
const VAN_DRIFT_GAS_GRIP_RATIO := 0.6
# Tracción trasera: con gas, las ruedas de atrás gastan agarre en empujar y la cola se
# suelta antes en curva (sobreviraje de potencia). Límite de agarre restado con empuje máximo.
const VAN_REAR_DRIVE_GRIP_LOSS := 0.6
# Motor trasero: el peso de atrás empuja la cola hacia fuera (rad/s por px/s de deslizamiento).
const VAN_DRIFT_TAIL_YAW := 0.012 / VAN_SPEED_SCALE
const VAN_DRIFT_MAX_TAIL_YAW := 1.5
# El derrape acaba cuando la velocidad de lado baja de esto (px/s).
const VAN_DRIFT_END_SLIP := 6.0 * VAN_SPEED_SCALE
# Freno de mano (Espacio): bloquea las traseras, casi sin agarre lateral.
const VAN_HANDBRAKE_GRIP := 1.2
const VAN_HANDBRAKE_DECELERATION := 110.0 * VAN_SPEED_SCALE

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

# --- Cuentakilómetros de rodillos (arriba a la derecha), portado de src/config/odometer.ts ---
# Rodillos: enteros + 1 de décimas (colores invertidos, como en el VW original).
const ODOMETER_INT_DIGITS := 6
const ODOMETER_TENTHS_DIGITS := 1
const ODOMETER_CELL := Vector2(5, 9)
const ODOMETER_WHEEL_GAP := 1.0
const ODOMETER_PADDING := 2.0
const ODOMETER_MARGIN := 4.0
const ODOMETER_LABEL_GAP := 2.0
# Fracción final del giro en la que el rodillo de la izquierda arrastra (acarreo mecánico).
const ODOMETER_CARRY_ZONE := 0.15
# Sombreado de curvatura del cilindro (filas de arriba y de abajo).
const ODOMETER_SHADE_ROWS := 2
const ODOMETER_SHADE_ALPHA := 0.45
const ODOMETER_COLORS := {
	"frame": Color("6b6150"),
	"frame_dark": Color("2a2620"),
	"bezel": Color("0c0c0c"),
	"wheel": Color("161616"),
	"digit": Color("e8e2cf"),
	"tenths_wheel": Color("e8e2cf"),
	"tenths_digit": Color("b3261e"),
	"shade": Color("000000"),
	"label": Color("c9bf9f"),
}

# --- Mapas (Tiled). Sevilla: scripts/gen-sevilla-map.mjs; bosque: scripts/gen-bosque-map.mjs ---
const MAP_GROUND_LAYER := "suelo"
const MAP_OBJECTS_LAYER := "objetos"
const MAP_SPAWN := "spawn"
const MAP_START := &"sevilla"
# Cada mapa: json, tileset, `campo` (null = el ambiente pasa a campo al acercarse a `ambient_exit`;
# número = mezcla fija) y `exits`: zona del mapa -> {to: mapa, at: objeto de llegada,
# offset_tiles: desplazamiento desde su centro, rot_deg: rumbo (0 = norte, 90 = este)}.
const MAPS := {
	&"sevilla": {
		"json": "res://assets/maps/sevilla.json",
		"tileset": "res://assets/maps/tiles-sevilla.png",
		"ambient_exit": "salida_a4",
		"campo": null,
		# La T3 sale en el objeto `spawn` (al pie del Puente de Triana, orilla del Arenal).
		# Dos puertas a la circunvalación del bosque: se entra por una y se vuelve por la otra.
		"exits": {
			"salida_a4": {"to": &"bosque", "at": "entrada_a4", "offset_tiles": Vector2.ZERO, "rot_deg": 90.0},
			"salida_sur": {"to": &"bosque", "at": "entrada_sur", "offset_tiles": Vector2.ZERO, "rot_deg": 90.0},
		},
	},
	&"bosque": {
		"json": "res://assets/maps/bosque.json",
		"tileset": "res://assets/maps/tiles-bosque.png",
		"ambient_exit": "",
		"campo": 1.0,
		"exits": {
			"vuelta_sevilla": {"to": &"sevilla", "at": "salida_a4", "offset_tiles": Vector2(-8, 0), "rot_deg": -90.0},
			"vuelta_sevilla_sur": {"to": &"sevilla", "at": "salida_sur", "offset_tiles": Vector2(-8, 0), "rot_deg": -90.0},
		},
	},
}
# Fundido a negro al cambiar de mapa.
const MAP_FADE_S := 0.35
const MAP_FADE_COLOR := Color.BLACK
const MAP_FADE_LAYER := 10

# --- Talleres: zona del mapa (objeto de tipo `taller`) dentro del portón ---
# Al entrar la furgo se para el juego y sale el menú del taller; al salir, la furgo aparece
# en el objeto <nombre>_salida mirando hacia fuera (WORKSHOP_EXIT_ROT_DEG).
const MAP_WORKSHOP_TYPE := "taller"
const MAP_WORKSHOP_EXIT_SUFFIX := "_salida"
const WORKSHOP_EXIT_ROT_DEG := 0.0
const WORKSHOP_NAMES := {"taller_karvans": "Taller Karvans"}
# Menú del taller (provisional, hasta hacer el de verdad).
const WORKSHOP_LAYER := 20
const WORKSHOP_DIM := Color(0, 0, 0, 0.75)
const WORKSHOP_TITLE_SIZE := 18
const WORKSHOP_TEXT_SIZE := 9
const WORKSHOP_BUTTON_SIZE := 12
const WORKSHOP_OUTLINE := 3
const WORKSHOP_TITLE_Y := 40.0
const WORKSHOP_TEXT_Y := 78.0
const WORKSHOP_BUTTON_Y := 130.0
const WORKSHOP_ACCENT := Color("d8742a")
const WORKSHOP_TEXT := "Próximamente:\nreparaciones, piezas y camperización."
const WORKSHOP_BUTTON := "Salir del taller"

const MAP_LABEL_TYPE := "rotulo"
const MAP_COLLIDES_PROPERTY := "collides"
# Rótulos de barrios y monumentos sobre el mapa.
const MAP_LABEL_FONT_SIZE := 8
const MAP_LABEL_COLOR := Color.WHITE
const MAP_LABEL_OUTLINE_COLOR := Color.BLACK
const MAP_LABEL_OUTLINE_SIZE := 2
const MAP_LABEL_ALPHA := 0.75

# --- Marcas viales (scripts/road_markings.gd): objetos `linea` de Tiled ---
const MAP_LINE_TYPE := "linea"
const ROAD_LINE_COLOR := Color(0.92, 0.9, 0.82)
const ROAD_CENTER_WIDTH := 2.0
const ROAD_EDGE_WIDTH := 1.0
# Largo de raya y de hueco en el eje discontinuo (px).
const ROAD_DASH_PX := 10.0
# Por encima de los edificios.
const MAP_LABEL_Z := 2

# --- Edificios con perspectiva estilo GTA 1 (scripts/city_view.gd) ---
# Cámara cenital a esta altura (px de mundo) sobre el suelo: más baja = los edificios se
# abren más hacia los bordes de la pantalla. Las alturas de los tiles van en la misma unidad.
const CITY_CAMERA_HEIGHT := 300.0
# Celda de culling (tiles): solo se pinta lo que cae cerca de la pantalla.
const CITY_CULL_CELL_TILES := 16
const CITY_Z := 1 # por encima de la furgo: los edificios se abren hacia fuera y no la tapan
# Orden a igual altura: fachadas, luego tejados, árboles y chapiteles.
const CITY_DRAW_ORDER := {&"wall": 0, &"roof": 1, &"edge": 2, &"tree": 3, &"spire": 4}
# Sombras en el suelo: dirección, largo (fracción de la altura) y color con su transparencia.
const CITY_SHADOW_DIR := Vector2(0.8, -0.6)
const CITY_SHADOW_LENGTH := 0.35
const CITY_SHADOW_COLOR := Color(0, 0, 0, 0.3)
# Oscurecido de cada fachada según hacia dónde mira (luz de mediodía desde el sur).
const CITY_WALL_SHADE := {Vector2i.DOWN: 0.0, Vector2i.LEFT: 0.15, Vector2i.RIGHT: 0.25, Vector2i.UP: 0.35}
const CITY_EAVE_DARKEN := 0.35 # alero: línea oscura entre tejado y fachada
# Fachada casi de canto (px): no se pinta, su polígono degenera y Godot no lo triangula.
const CITY_WALL_MIN_FACING := 0.5
const CITY_ZOCALO_HEIGHT := 6.0
# Ventanas: px de patrón por px de altura (una fila de ventanas ≈ una planta).
const CITY_PATTERN_SCALE := 0.45
const CITY_SPIRE_HEIGHT := 30.0
const CITY_SPIRE_BASE_RATIO := 0.5
const CITY_TREE_CANOPY_RADIUS := 7.0
const CITY_TREE_HIGHLIGHT_RADIUS := 3.0
const CITY_TREE_HIGHLIGHT_OFFSET := Vector2(-2, -2)
const CITY_TREE_TRUNK_WIDTH := 2.0
# Patrones de fachada: celda que se repite y rectángulos pintados con el color `detalle`.
const CITY_PATTERNS := {
	"ventanas": {"cell": Vector2i(6, 8), "rects": [Rect2i(2, 2, 2, 3)]},
	"contrafuertes": {"cell": Vector2i(6, 8), "rects": [Rect2i(0, 0, 1, 8), Rect2i(3, 2, 1, 4)]},
	"arcos": {"cell": Vector2i(6, 8), "rects": [Rect2i(2, 3, 2, 5), Rect2i(1, 4, 4, 4)]},
	"ladrillo": {"cell": Vector2i(8, 8), "rects": [Rect2i(3, 1, 2, 1), Rect2i(2, 2, 1, 1), Rect2i(5, 2, 1, 1), Rect2i(1, 3, 1, 2), Rect2i(6, 3, 1, 2), Rect2i(2, 5, 1, 1), Rect2i(5, 5, 1, 1), Rect2i(3, 6, 2, 1)]},
	"almenas": {"cell": Vector2i(8, 8), "rects": [Rect2i(4, 3, 1, 3)]},
	"cristal": {"cell": Vector2i(8, 4), "rects": [Rect2i(0, 0, 8, 1), Rect2i(0, 0, 1, 4)]},
	"rejilla": {"cell": Vector2i(4, 4), "rects": [Rect2i(0, 0, 4, 1), Rect2i(0, 0, 1, 4)]},
	"chapa": {"cell": Vector2i(4, 8), "rects": [Rect2i(0, 0, 1, 8)]},
}

# --- Vida en la calle: tráfico, semáforos, farolas y peatones (objetos del mapa) ---
const MAP_ROUTE_TYPE := "ruta"
const MAP_LIGHT_TYPE := "semaforo"
const MAP_CROSSING_TYPE := "paso"
const MAP_LAMP_TYPE := "farola"
const MAP_BRIDGE_ARCHES_TYPE := "puente_arcos"
const STREET_Z := 1 # postes y arcos, a la altura de los edificios

# Coches: hoja de tools/sprites/cars.py (24 rumbos x un modelo por fila).
const CAR_SPRITES := "res://assets/sprites/coches/coches.png"
const CAR_SPRITE_DIRECTIONS := 24
const CAR_MODELS := 4
const CAR_SPRITE_OFFSET := Vector2.ZERO # celda 64x64 con el centro del coche en (32, 32)
const CAR_RADIUS := 10.0
const CAR_SPEED := 48.0 * VAN_SPEED_SCALE # px/s, bastante menos que la T3 a tope
const CAR_ACCEL := 40.0
const CAR_BRAKE := 120.0
# Mira esto por delante para girar suave en las esquinas (px de ruta).
const CAR_STEER_LOOKAHEAD := 14.0
# Frena si hay algo delante: distancia y anchura del carril que vigila.
const CAR_STOP_DISTANCE := 40.0
const CAR_STOP_HALF_WIDTH := 16.0

# Semáforos: verde, ámbar y rojo por eje (h = este-oeste, v = norte-sur), desfasados.
const LIGHT_GREEN_S := 6.0
const LIGHT_AMBER_S := 1.5
const LIGHT_POLE_HEIGHT := 22.0
const LIGHT_BOX := Vector2(3, 7)
# Pasos de peatones (objetos `paso`): cebra y línea de detención antes del paso.
const ZEBRA_PERIOD := 4.0 # px entre el inicio de una franja y la siguiente
const ZEBRA_STRIPE := 2.0
const ZEBRA_MARGIN := 2.0 # px libres a cada lado de las franjas
const ZEBRA_COLOR := Color(0.92, 0.9, 0.82)
const STOP_LINE_GAP := 3.0 # px entre la línea de detención y el paso
# Los coches que llegan al paso paran en rojo (en ámbar, solo si les da para frenar)
# con el morro a CROSSING_STOP_MARGIN px de la línea; ceden a quien esté cruzando.
const CROSSING_STOP_MARGIN := 6.0
const CROSSING_FRONT := 12.0 # del centro del coche al morro (px)
const CROSSING_AMBER_COMMIT := 0.6 # en ámbar sigue si ya está a menos de esta parte de su frenada
const CROSSING_INCOMING_DOT := 0.3 # va hacia el cruce (también en diagonal): el semáforo es suyo
# Los peatones solo empiezan a cruzar al principio de su verde (rojo de los coches).
const PED_CROSS_WINDOW_S := 3.0
const LIGHT_COLORS := {
	"pole": Color("2a2e33"),
	"box": Color("15171a"),
	"off": Color("3a3a3a"),
	"red": Color("ff3b30"),
	"amber": Color("ffb000"),
	"green": Color("3ddc6a"),
}

# Farolas del puente de Triana.
const LAMP_HEIGHT := 24.0
const LAMP_POLE := Color("2f3a40")
const LAMP_GLASS := Color("f4e7b8")
const LAMP_RADIUS := 2.0

# Arcos de hierro del puente de Triana (costados bajo la calzada, hasta el agua).
const BRIDGE_DEPTH := 80.0
const BRIDGE_TEXTURE_HEIGHT := 24
const BRIDGE_PIER_WIDTH := 8
const BRIDGE_DECK_ROWS := 2
const BRIDGE_ARCH_THICKNESS := 2
const BRIDGE_RING_SPACING := 7
const BRIDGE_COLORS := {
	"iron": Color("55636d"),
	"iron_light": Color("a9b6bf"),
	"stone": Color("d8cfbd"),
	"stone_dark": Color("a89f8e"),
}
# Barandilla de hierro: pasamanos a esta altura y barrotes cada tantos px.
const BRIDGE_RAIL_HEIGHT := 8.0
const BRIDGE_RAIL_POST_SPACING := 4.0
const BRIDGE_RAIL_COLOR := Color("3d4850")

# Peatones por las aceras: pocos y solo cerca de la furgo.
const PED_COUNT := 24
const PED_SPAWN_RANGE := Vector2(140, 280) # distancia a la cámara al aparecer (px)
const PED_DESPAWN_DISTANCE := 360.0
const PED_SPEED := 14.0
const PED_FLEE_SPEED := 60.0
const PED_FLEE_DISTANCE := 48.0 # desde el centro de la furgo (mide 64 px de largo)
const PED_STEP_S := 0.25 # cada cuánto alternan las piernas
const PED_TURN_CHANCE := 0.15 # en cada tile, probabilidad de girar aunque pueda seguir recto
const PED_JITTER := 4.0 # px: no van todos en fila por el centro de la acera
# Figura de pie con la misma vista oblicua que la T3 (algo exagerada, estilo GTA 1):
# rectángulos relativos a los pies, y hacia arriba en negativo. Mide 16 px de alto.
const PED_SHADOW := Rect2(-3, -1, 8, 2)
const PED_LEG_L := Rect2(-3, -5, 2, 5)
const PED_LEG_R := Rect2(2, -5, 2, 5)
const PED_TORSO := Rect2(-3, -11, 7, 6)
const PED_ARM_L := Rect2(-4, -10, 1, 4)
const PED_ARM_R := Rect2(4, -10, 1, 4)
const PED_HEAD := Rect2(-2, -16, 5, 5)
const PED_HAIR_ROWS := 2
const PED_SHADOW_COLOR := Color(0, 0, 0, 0.3)
# Atropellos: dentro de la caja de la furgo (medio ancho, medio largo) y por encima de
# esta velocidad, el peatón queda tendido en el suelo con su charco de sangre.
const PED_HIT_HALF := Vector2(13, 34)
const PED_HIT_SPEED := 15.0 * VAN_SPEED_SCALE
const PED_MAX_BODIES := 12
# Tendido visto desde arriba, a lo largo de x desde el centro del cuerpo.
const PED_BODY_TORSO := Rect2(-4, -3, 7, 6)
const PED_BODY_HEAD := Rect2(3, -2, 4, 4)
const PED_BODY_LEGS := Rect2(-10, -3, 6, 2)
const PED_BODY_LEG_GAP := 4.0
const PED_BODY_ARMS := Rect2(-2, -6, 2, 12)
const PED_BLOOD_BLOBS := 8
const PED_BLOOD_RADIUS := Vector2(3, 8)
const PED_BLOOD_SPREAD := 10.0
const PED_BLOOD_GROW_S := 1.5 # el charco se extiende durante este tiempo
const PED_BLOOD := Color("7a0d0d")
const PED_BLOOD_DARK := Color("4f0606")
const PED_LEGS := Color("2b2b33")
const PED_WALKABLE := ["acera", "albero", "parque"]
const PED_SHIRTS: Array[Color] = [Color("c0392b"), Color("2e86c1"), Color("f1c40f"), Color("27ae60"), Color("ecf0f1"), Color("8e44ad"), Color("e67e22")]
const PED_HAIR: Array[Color] = [Color("2b1d14"), Color("4a3020"), Color("d9b36c"), Color("111111"), Color("8a8a8a")]
const PED_SKIN := Color("d9a27a")

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
# Topes por marcha: 1ª = 25, 2ª = 50, 3ª = 75, 4ª = 100 km/h (la 4ª va 4 veces más que la 1ª).
# Empuje: la 1ª es corta y muy fuerte (~40 km/h/s); cada marcha empuja bastante menos y llega
# más lejos (2ª ~13, 3ª ~8) y la 4ª es solo velocidad (~4,5 km/h/s). Con gas a fondo cada marcha
# dura lo bastante para notarla (~0,6 / 1,8 / 3 s) y 0-100 sale en ~11 s.
const GEAR_MAX_SPEED_RATIO: Array[float] = [0.25, 0.5, 0.75, 1.0]
const GEAR_ACCEL_RATIO: Array[float] = [1.0, 0.6, 0.36, 0.2]
# Dentro de cada marcha el empuje cae al subir de vueltas: al tope de la marcha queda
# (1 - GEAR_TORQUE_FALLOFF) del empuje. Así la T3 sale fuerte y va cogiendo velocidad poco a poco.
const GEAR_TORQUE_FALLOFF := 0.6
# Marcha larga a pocas vueltas: por debajo de esta fracción del tope de la marcha anterior,
# el motor se ahoga y apenas empuja (arrancar en 3ª cuesta).
const GEAR_LUG_SPEED_RATIO := 0.5
const GEAR_LUG_ACCEL_RATIO := 0.25
# Por encima del tope de la marcha (al reducir), el motor retiene hasta ese tope.
const GEAR_ENGINE_BRAKE := 60.0 * VAN_SPEED_SCALE
# Embrague pisado durante el cambio: ese tiempo no hay potencia (s) y la furgo pierde
# velocidad (GEAR_SHIFT_DRAG, px/s²): se nota el bache antes de que tire la marcha nueva.
const GEAR_SHIFT_TIME := 0.3
const GEAR_SHIFT_DRAG := 25.0 * VAN_SPEED_SCALE
# Retención del motor al soltar el gas (multiplica VAN_DRAG): fuerte en 1ª, casi nula en 4ª.
const GEAR_COAST_DRAG_RATIO: Array[float] = [1.6, 1.1, 0.7, 0.4]
# Al cambiar, la cámara cabecea hacia atrás (subir) o hacia delante (reducir) y el móvil vibra.
const GEAR_KICK_PX := 4.0
const GEAR_KICK_DECAY := 7.0
const GEAR_VIBRATE_MS := 35
# Automático: sube al llegar a esta fracción del tope; baja por debajo de esta fracción
# del tope de la marcha anterior.
const GEAR_AUTO_UP_RATIO := 0.95
const GEAR_AUTO_DOWN_RATIO := 0.6
# Holgura de la caja de serie (1 = gastada, como las T3 de verdad; el taller la deja en 0).
const GEARBOX_PLAY_STOCK := 1.0

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
