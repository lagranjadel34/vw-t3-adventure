class_name IntroConfig
## Intro con viñetas (portada de src/config/intro.ts). Placeholders hasta tener arte.
## Medidas en píxeles internos, diseñadas para 320x180 (en pantallas más anchas se centran).

const TYPE_DELAY_S := 0.045
const AUTO_ADVANCE_S := 2.5
const FADE_S := 0.4

const TEXT_BOX_HEIGHT := 40.0
const TEXT_PADDING := 8.0
const TEXT_FONT_SIZE := 12
const LABEL_FONT_SIZE := 8
const LABEL_OUTLINE := 2
const SKIP_TEXT_TOUCH := "SALTAR »"
const SKIP_TEXT_KEYS := "SALTAR (ESC) »"
const SKIP_FONT_SIZE := 10
const SKIP_OUTLINE := 2
const SKIP_ALPHA := 0.7
const SKIP_PADDING_X := 8.0
const IMAGE_EASE := Tween.EASE_IN_OUT
const IMAGE_TRANS := Tween.TRANS_SINE

const HORN_WORDS: Array[String] = ["PIII!", "¡PI PI!", "BIP!", "PÍIIII!"]
const HORN_INTERVAL_S := 0.65
const HORN_RISE_PX := 10.0
const HORN_LIFE_S := 0.7
const HORN_FONT_SIZE := 10
const HORN_OUTLINE := 3
const HORN_COLOR := Color("ffd24d")
const HORN_SHAKE_S := 0.12
const HORN_SHAKE_INTENSITY := 0.002 # fracción del tamaño de pantalla

const SMOKE_TEXTURE_RADIUS := 8
const SMOKE_TINTS: Array[Color] = [Color("e0e0e0"), Color("b5b5b5"), Color("8f8f8f")]
const SMOKE_FREQUENCY_S := 0.11
const SMOKE_LIFE_S := Vector2(1.1, 1.8) # mín, máx
# Velocidad en píxeles de la imagen original: hacia arriba y algo a la derecha.
const SMOKE_DIRECTION := Vector2(13, -52)
const SMOKE_SPREAD_DEG := 12.0
const SMOKE_SPEED := Vector2(36, 72) # mín, máx
const SMOKE_SCALE := Vector2(0.7, 2.2) # inicio, fin
const SMOKE_ALPHA := 0.75

const HAZE_COLOR := Color("c9a66b")
const HAZE_MAX_ALPHA := 0.4
const HAZE_DEFAULT_S := 4.0

# Cada viñeta: fondo, formas placeholder (con rótulo opcional), imagen con pan/zoom
# (posición del centro y escala, inicio -> fin), tubos de escape en píxeles de la imagen,
# zona de bocinas, neblina y texto.
const PANELS := [
	{
		# Sevilla, Torre del Oro: plano general con pan hacia la torre
		"bg": Color("000000"),
		"shapes": [],
		"image": {
			"file": "res://assets/backgrounds/intro_sevilla_torre_oro_v1.jpg",
			"from_scale": 0.26, "to_scale": 0.26,
			"from": Vector2(193, 75), "to": Vector2(127, 65),
			"duration": 4.5,
		},
		"horns": Rect2(150, 75, 140, 40),
		"haze": true,
		"text": "Otra semana igual.",
	},
	{
		# Sevilla, avenida atascada: zoom hacia el tráfico
		"bg": Color("000000"),
		"shapes": [],
		"image": {
			"file": "res://assets/backgrounds/intro_sevilla_atasco_v1.jpg",
			"from_scale": 0.22, "to_scale": 0.4,
			"from": Vector2(160, 70), "to": Vector2(298, 14),
			"duration": 4.5,
		},
		"horns": Rect2(40, 45, 100, 65),
		"haze": true,
		"text": "Ruido, prisas, humo.",
	},
	{
		# Ara dentro de la T3, en mitad del atasco (humo de tubos de escape)
		"bg": Color("000000"),
		"shapes": [],
		"image": {
			"file": "res://assets/backgrounds/intro_interior_furgo_v2.jpg",
			"from_scale": 0.25, "to_scale": 0.27,
			"from": Vector2(175, 72), "to": Vector2(165, 70),
			"duration": 4.5,
			"exhausts": [Vector2(540, 452), Vector2(610, 425), Vector2(700, 492), Vector2(820, 448), Vector2(985, 418)],
		},
		"horns": Rect2(120, 55, 160, 45),
		"text": "Necesito salir de aquí.",
	},
	{
		# La T3 aparcada en la calle
		"bg": Color("22303c"),
		"shapes": [
			{"rect": Rect2(0, 110, 320, 30), "color": Color("3a3a3a")},
			{"rect": Rect2(110, 70, 100, 50), "color": Color("f2efe6"), "label": "VW T3"},
			{"rect": Rect2(125, 115, 16, 10), "color": Color("111111")},
			{"rect": Rect2(179, 115, 16, 10), "color": Color("111111")},
		],
		"text": "Ella siempre está lista.",
	},
	{
		# Carretera alejándose de la ciudad, hacia el bosque
		"bg": Color("3d5a80"),
		"shapes": [
			{"rect": Rect2(0, 90, 320, 50), "color": Color("2d6a4f")},
			{"rect": Rect2(140, 90, 40, 50), "color": Color("555555"), "label": "carretera"},
			{"rect": Rect2(20, 60, 20, 30), "color": Color("1b4332"), "label": "bosque"},
			{"rect": Rect2(260, 55, 24, 35), "color": Color("1b4332")},
			{"rect": Rect2(150, 120, 20, 12), "color": Color("f2efe6")},
		],
		"text": "Rumbo al bosque. Sin plan. Solo un buen spot.",
	},
]
