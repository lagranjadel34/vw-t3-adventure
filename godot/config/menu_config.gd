class_name MenuConfig
## Pantalla de título (portada de src/scenes/MenuScene.ts). Medidas en píxeles internos (320x180).

const BACKGROUND := "res://assets/backgrounds/campamento_nocturno_v1.jpg"
const OPTIONS: Array[String] = ["Empezar", "Elegir camperizador", "Configuración"]
const START_OPTION := 0

const MENU_X := 14.0
const TITLE := "VW T3 ADVENTURE"
const TITLE_Y := 36.0
const TITLE_FONT_SIZE := 20
const TITLE_OUTLINE := 4
const PRESS_TEXT_TOUCH := "TOCA LA PANTALLA"
const PRESS_TEXT_KEYS := "PULSA UNA TECLA"
const PRESS_BOTTOM_OFFSET := 30.0 # desde abajo
const PRESS_FONT_SIZE := 12
const PRESS_OUTLINE := 3
const PRESS_BLINK_S := 0.6
const OPTIONS_Y := 96.0
const OPTION_FONT_SIZE := 14
const OPTION_OUTLINE := 3
const OPTION_COLOR := Color.WHITE
const OPTION_SELECTED_COLOR := Color("ffd24d")
const OPTION_SELECTED_SCALE := 1.1
const TAP_PADDING_X := 8.0

# Hoguera: posición sobre el fondo diseñado a 320x180 (se recoloca si la pantalla es más ancha).
const FIRE_POS := Vector2(179, 156)
const FIRE_SPREAD_X := 4.0
const FIRE_DIRECTION := Vector2(0, -1)
const FIRE_SPREAD_DEG := 11.0
const FIRE_SPEED := Vector2(14, 26) # mín, máx (px/s)
const FIRE_SCALE := Vector2(0.9, 0.0) # inicio, fin
const FIRE_ALPHA := 0.9
const FIRE_LIFE_S := Vector2(0.35, 0.6) # mín, máx
const FIRE_FREQUENCY_S := 0.045
const FIRE_PARTICLE_RADIUS := 4
const FIRE_TINTS: Array[Color] = [Color("fff3b0"), Color("ffb347"), Color("ff6a1a"), Color("ff3d00")]

# Estrellas fugaces.
const STAR_SIZE := Vector2i(22, 3)
const STAR_START_X := Vector2i(40, 260)
const STAR_START_Y := Vector2i(8, 30)
const STAR_DX := Vector2i(50, 80)
const STAR_DY := Vector2i(20, 35)
const STAR_FLY_S := 0.18
const STAR_FADE_S := 0.22
const STAR_FIRST_DELAY_S := Vector2(0.1, 0.3)
const STAR_DELAY_S := Vector2(3.0, 8.0)
