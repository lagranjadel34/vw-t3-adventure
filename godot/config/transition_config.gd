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
const VAN_DEPTH_TO := 3.6 # al fondo, donde la carretera se esconde tras el monte
const VAN_HIDE_FROM_DEPTH := 2.6 # desde aquí se va desvaneciendo tras la curva
const VAN_BOB_PX := 1.2 # traqueteo vertical (px de imagen a escala 1)
const VAN_BOB_HZ := 6.0

# Tiempos (s)
const FADE_S := 0.35
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
const WORD_MIN_VAN_ALPHA := 0.7 # tras la curva ya no suelta más
const BIRD_WORDS: Array[String] = ["pío pío", "pío", "fiu fiu", "pi-pío"]
const BIRD_WORD_COLOR := Color("ffffff")
const BIRD_WORD_FONT_SIZE := 8
const BIRD_ZONE := Rect2(80, 300, 1050, 300) # monte y matorral, px de imagen

const SKIP_TEXT_TOUCH := "SALTAR »"
const SKIP_TEXT_KEYS := "SALTAR (ESC) »"
const SKIP_FONT_SIZE := 10
const SKIP_ALPHA := 0.7
const SKIP_PADDING_X := 8.0
