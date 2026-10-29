class_name TransitionConfig
## Pantalla de paso de la ciudad al campo: la imagen de Ara (carretera de montaña al atardecer)
## y la furgo alejándose por la carretera mientras el motor rompe el silencio.
## Posiciones en píxeles de la imagen (1195x896); `tools/sprites/transition_road.py` saca
## el fondo sin la furgo y la furgo recortada.

const BACKGROUND := "res://assets/backgrounds/transicion_campo.png"
const VAN_TEXTURE := "res://assets/sprites/transicion_furgo.png"
const LAYER := 11 # por encima del HUD y del fundido de mapa

# La imagen cubre la pantalla; de lo que sobra en vertical se recorta según este punto (0 arriba, 1 abajo).
const FOCUS_Y := 0.55

# Perspectiva de la carretera: punto de fuga y apoyo de la furgo pintada (su tamaño = escala 1).
# La furgo va por el centro de su carril; la escala es 1/profundidad.
const VANISH := Vector2(665, 632)
const VAN_REF_FOOT := Vector2(674, 710)
const VAN_DEPTH_FROM := 0.4 # cerca de la cámara, saliendo por abajo
const VAN_DEPTH_TO := 3.1 # en el cambio de rasante del fondo (apoyo en CREST_Y)
# Curva a la derecha: desde YAW_FROM_DEPTH la furgo gira y se le ve el costado derecho.
const YAW_FROM_DEPTH := 0.9
const YAW_AT_CREST := 0.5 # rad
const YAW_END := 0.75 # rad, ya tras el rasante
const TURN_SHIFT_PX := 14.0 # se abre a la derecha al llegar al rasante (px de imagen)
# Tras el rasante la carretera baja: la furgo se hunde detrás y sigue a la derecha.
const CREST_Y := 656.0
const CREST_RECT := Rect2(540, 656, 260, 60) # asfalto que tapa la furgo al pasar el rasante
const SINK_S := 1.6
const SINK_DRIFT_PX := 18.0 # px de imagen
# Costado de la furgo (px del sprite, la trasera mide 103x121). El largo de una T3 es
# unas 2,5 veces su ancho; se acorta por la perspectiva.
const SIDE_LENGTH := 150.0
const SIDE_FAR_SHRINK := 0.8 # el extremo lejano se ve más pequeño
const SIDE_FAR_RISE := 0.1 # y algo más arriba (hacia el horizonte), fracción del alto
const SIDE_BOTTOM_Y := -6.0
const SIDE_TOP_Y := -98.0 # debajo del techo redondeado
const SIDE_WINDOW := Vector2(0.45, 0.75) # franja de ventanas, de abajo (0) a arriba (1)
const SIDE_BODY_COLOR := Color("d9dde6")
const SIDE_SHADE := 0.82 # el costado recibe menos luz que la trasera
const SIDE_WINDOW_COLOR := Color("27304a")
const SIDE_SKIRT_COLOR := Color("141821") # bajos y rueda
const SIDE_SKIRT_H := 14.0
const VAN_BOB_PX := 1.2 # traqueteo vertical (px de imagen a escala 1)
const VAN_BOB_HZ := 6.0

# Pilotos traseros encendidos (atardecer): centro en px del sprite recortado de la furgo.
const TAIL_LIGHTS: Array[Vector2] = [Vector2(19, 86), Vector2(85, 86)]
const TAIL_LIGHT_RADIUS := 7
const TAIL_LIGHT_COLOR := Color(1.0, 0.25, 0.15, 0.55)
const TAIL_LIGHT_PULSE := 0.15 # parpadeo suave del brillo (fracción)
const TAIL_LIGHT_PULSE_HZ := 1.5

# Humo del escape: en px de imagen a escala 1 (se encoge con la furgo).
const SMOKE_TEXTURE_RADIUS := 8
const SMOKE_TINTS: Array[Color] = [Color("e8e2da"), Color("c9c1b6"), Color("a39a8e")]
const SMOKE_FREQUENCY_S := 0.06
const SMOKE_LIFE_S := Vector2(0.8, 1.4)
const SMOKE_DIRECTION := Vector2(-0.4, -1) # sube y se queda atrás
const SMOKE_SPREAD_DEG := 20.0
const SMOKE_SPEED := Vector2(14, 30)
const SMOKE_SCALE := Vector2(0.5, 1.8)
const SMOKE_ALPHA := 0.55

# Cámara que sube del suelo: empieza cerca del asfalto (más zoom, mirando abajo) y se eleva
# hasta el plano completo.
const CRANE_ZOOM_FROM := 1.35
const CRANE_FOCUS_FROM := Vector2(640, 790) # px de imagen en el centro de la pantalla al empezar
const CRANE_S := 4.5

# Tiempos (s)
const FADE_S := 0.35
const GAME_FADE_OUT_S := 0.5 # el juego se va a negro antes de la imagen
const REVEAL_S := 0.8 # al acabar, la imagen se funde y deja ver el campo
const SILENCE_S := 1.2 # silencio de montaña antes de arrancar
const DRIVE_S := 5.0
const HOLD_S := 1.2 # carretera vacía, solo pájaros
const DRIVE_TRANS := Tween.TRANS_QUAD
const DRIVE_EASE := Tween.EASE_IN # arranca despacio y coge velocidad

# Motor: vueltas al arrancar y en marcha; el volumen baja con la distancia.
const ENGINE_START_RPM := 2600.0 # acelerón al arrancar
const ENGINE_CRUISE_RPM := 3400.0
const ENGINE_REV_S := 0.5
const ENGINE_DB := 0.0 # pegado a la cámara
const ENGINE_SILENT_DB := -60.0
const WIND_DB := -22.0
const BIRD_DELAY_S := Vector2(0.6, 2.0)
const BIRD_DB := -14.0

# Onomatopeyas: salen del tubo de escape hacia la izquierda (px de imagen a escala 1 desde el apoyo) y suben.
const EXHAUST_OFFSET := Vector2(-40, -8)
const SMOKE_OFFSET := Vector2(-30, -6) # tubo de escape, desde el apoyo de la furgo
const ENGINE_WORDS: Array[String] = ["BRRRUM!", "BRRRR...", "RRRUM!", "BRUM BRUM", "brrrm..."]
const START_WORD := "BRRRRUMMM!"
const WORD_EVERY_S := 0.7
const WORD_FONT_SIZE := 14 # con la furgo a escala 1 en pantalla de 320
const WORD_MIN_FONT_SIZE := 6
const WORD_MAX_FONT_SIZE := 18
const WORD_OUTLINE := 3
const WORD_COLOR := Color("ffd24d")
const WORD_RISE_PX := 14.0
const WORD_DRIFT_PX := 10.0 # hacia un lado, al azar
const WORD_LIFE_S := 1.1
const BIRD_WORDS: Array[String] = ["pío pío", "pío", "fiu fiu", "pi-pío"]
const BIRD_WORD_COLOR := Color("ffffff")
const BIRD_WORD_FONT_SIZE := 8
const BIRD_ZONE := Rect2(80, 300, 1050, 300) # monte y matorral, px de imagen

const SKIP_TEXT_TOUCH := "SALTAR »"
const SKIP_TEXT_KEYS := "SALTAR (ESC) »"
const SKIP_FONT_SIZE := 10
const SKIP_ALPHA := 0.7
const SKIP_PADDING_X := 8.0
