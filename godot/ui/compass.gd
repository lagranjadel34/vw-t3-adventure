class_name Compass
extends Node2D
## Rosa de los vientos con el Norte arriba. Dentro, un punto que parpadea: la furgo, en el
## sitio de la rosa que le corresponde en el mapa (arriba = norte del mapa, centro = centro).

## Ancho / alto del mapa, para que encaje en la rosa sin deformarse.
var aspect := 1.0
var _where := Vector2(0.5, 0.5)
var _clock := 0.0
var _font := UiKit.fredoka(true)


## Posición de la furgo en el mapa, de (0, 0) arriba-izquierda a (1, 1) abajo-derecha.
func set_van(where: Vector2) -> void:
	_where = where.clamp(Vector2.ZERO, Vector2.ONE)


func _process(delta: float) -> void:
	_clock += delta
	var r := GameConfig.COMPASS_RADIUS
	position = Vector2.ONE * (GameConfig.COMPASS_MARGIN + r)
	queue_redraw()


func _draw() -> void:
	var c := GameConfig.COMPASS_COLORS
	var r := GameConfig.COMPASS_RADIUS
	draw_circle(Vector2.ZERO, r, c.disc)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, c.rim, GameConfig.LINE_WIDTH)
	var half := _map_half()
	draw_rect(Rect2(-half, half * 2), c.map, false, GameConfig.LINE_WIDTH)
	# Diagonales cortas debajo; las cuatro puntas largas encima, el Norte en rojo.
	for i in 4:
		_draw_point(Vector2.from_angle(PI / 4 + i * PI / 2), GameConfig.COMPASS_POINT_SHORT * r, c.point_dark, c.point_dark)
	for letter: String in GameConfig.COMPASS_LETTERS:
		var dir: Vector2 = GameConfig.COMPASS_LETTERS[letter]
		var north := letter == "N"
		_draw_point(dir, GameConfig.COMPASS_POINT_LONG * r, c.north if north else c.point, c.point_dark)
	for letter: String in GameConfig.COMPASS_LETTERS:
		var dir: Vector2 = GameConfig.COMPASS_LETTERS[letter]
		var size := GameConfig.COMPASS_LETTER_SIZE
		var w := _font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
		var at := dir * r * GameConfig.COMPASS_LETTER_RADIUS + Vector2(-w.x / 2, _font.get_ascent(size) / 2 - 1)
		draw_string_outline(_font, at, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 2, c.dot_edge)
		draw_string(_font, at, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c.north if letter == "N" else c.letter)
	# La furgo.
	var dot := dot_position()
	var blink := 0.5 + 0.5 * cos(_clock * TAU * GameConfig.COMPASS_BLINK_HZ)
	var dr := GameConfig.COMPASS_DOT_RADIUS
	draw_circle(dot, dr + 1.0, c.dot_edge)
	draw_circle(dot, dr, c.dot.lerp(Color.WHITE, blink * 0.5))


## Dónde va el punto de la furgo, respecto al centro de la rosa.
func dot_position() -> Vector2:
	return (_where * 2.0 - Vector2.ONE) * _map_half()


## Medio tamaño del rectángulo del mapa dentro de la rosa, con su proporción.
func _map_half() -> Vector2:
	var a := atan2(1.0, aspect)
	return Vector2(cos(a), sin(a)) * GameConfig.COMPASS_RADIUS * GameConfig.COMPASS_MAP_FIT


## Punta en rombo: mitad clara y mitad oscura, como una rosa de carta náutica.
func _draw_point(dir: Vector2, length: float, light: Color, dark: Color) -> void:
	var tip := dir * length
	var side := dir.orthogonal() * length * GameConfig.COMPASS_POINT_WIDTH
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO, tip, side]), light)
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO, -side, tip]), dark)
