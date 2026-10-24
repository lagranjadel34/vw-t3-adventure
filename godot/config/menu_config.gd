class_name MenuConfig
## Pantalla de título (portada de src/scenes/MenuScene.ts). Medidas en píxeles internos (320x180).

const BACKGROUND := "res://assets/backgrounds/campamento_nocturno_v1.jpg"
const OPTIONS: Array[String] = ["Empezar", "Elegir camperizador", "Configuración", "Salir"]
const START_OPTION := 0
const QUIT_OPTION := 3

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

# --- Configuración (opción 3 del menú). De momento, solo el apartado Sonido ---
const SETTINGS_OPTION := 2
const CFG_TITLE := "CONFIGURACIÓN"
const CFG_TITLE_Y := 22.0
const CFG_SECTION := "Sonido"
const CFG_SECTION_Y := 50.0
const CFG_SECTION_COLOR := Color("c9bf9f")
const CFG_ROWS_Y := 78.0 # una fila por TAP_MIN_HEIGHT
const CFG_VOLUME := "Volumen"
const CFG_MUTE := "Silencio"
const CFG_CREDITS := "Créditos"
const CFG_BACK := "Volver"
const CFG_YES := "Sí"
const CFG_NO := "No"
const CFG_VALUE_X := 150.0 # columna de los valores
const CFG_MINUS := "-"
const CFG_PLUS := "+"
const CFG_BAR_X := 170.0 # barra de volumen, entre - y +
const CFG_BAR_STEP_W := 6.0
const CFG_BAR_H := 8.0
const CFG_BAR_GAP := 1.0
const CFG_BAR_ON := Color("ffd24d")
const CFG_BAR_OFF := Color(1, 1, 1, 0.25)
const CFG_DIM := Color(0, 0, 0, 0.55) # velo sobre el fondo

# --- Elegir camperizador (opción 2 del menú) ---
const GARAGE_OPTION := 1
const GARAGE_TITLE := "CAMPERIZADOR"
const GARAGE_NAME_Y := 50.0
const GARAGE_NAME_FONT_SIZE := 12
const GARAGE_DETAIL_Y := 66.0
const GARAGE_DETAIL_LINE := 10.0
const GARAGE_DETAIL_FONT_SIZE := 9
const GARAGE_ROWS_Y := 130.0 # una fila por TAP_MIN_HEIGHT
const GARAGE_CHOOSE := "Elegir"
const GARAGE_CHOSEN := "Elegida"
const GARAGE_PREV := "<"
const GARAGE_NEXT := ">"
const GARAGE_ARROW_Y := 96.0
const GARAGE_PREVIEW_RIGHT := 70.0 # centro de la furgo, desde el borde derecho
const GARAGE_PREVIEW_Y := 92.0
const GARAGE_PREVIEW_SCALE := 1.5 # hojas de tools/sprites/export_garage.py (vista de frente)
const GARAGE_TURN_S := 0.15 # tiempo por rumbo al girar en el escaparate
# --- Créditos (desde Configuración) ---
const CREDITS_TITLE := "CRÉDITOS"
const CREDITS_Y := 50.0
const CREDITS_LINE_H := 14.0
const CREDITS_FONT_SIZE := 10
const CREDITS_OUTLINE := 2
# Pares [papel, nombre]; el papel va en CFG_SECTION_COLOR y el nombre en blanco.
const CREDITS_LINES: Array = [
	["Idea, guion y arte", "La Granja del 34"],
	["Programación", "Ara con Claude (Anthropic)"],
	["Motor", "Godot Engine (MIT)"],
	["Letras", "Fredoka y Poppins (SIL OFL)"],
	["Furgoneta", "VW T3 · 1979-1992"],
]
const CREDITS_NAME_X := 120.0
const CREDITS_BACK_Y := 150.0

# Icono y panel de la ficha técnica (dentro de Elegir camperizador)
const SHEET_ICON_SIZE := 14.0
const SHEET_ICON_POS := Vector2(18, 22) # centro del icono, desde la esquina superior derecha
const SHEET_ICON_COLOR := Color("ffd24d")
const SHEET_ICON_TEXT := "i"
const SHEET_ICON_LABEL := "Ficha"
const SHEET_CARD_MARGIN := 8.0
const SHEET_CARD_COLOR := Color("d9e3e5") # fondo de las fichas de Ara
const SHEET_TEXT_COLOR := Color("1d2430")
const SHEET_LABEL_COLOR := Color("5a6672")
const SHEET_TITLE_FONT_SIZE := 12
const SHEET_TITLE_Y := 18.0
const SHEET_IMAGE_POS := Vector2(14, 34)
const SHEET_ROWS_X := 160.0
const SHEET_VALUES_X := 222.0
const SHEET_ROWS_Y := 36.0
const SHEET_ROW_H := 11.0
const SHEET_FONT_SIZE := 8
const SHEET_CLOSE := "Cerrar"
const SHEET_CLOSE_BOTTOM := 18.0 # desde abajo
