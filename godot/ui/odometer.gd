class_name Odometer
extends Node2D
## Cuentakilómetros mecánico (portado de src/ui/Odometer.ts): rodillos 0-9 que giran
## de forma continua y arrastran al de su izquierda al pasar de 9 a 0.

const DIGITS := 10

var _km := 0.0
var _total := GameConfig.ODOMETER_INT_DIGITS + GameConfig.ODOMETER_TENTHS_DIGITS


## Muestra un kilometraje (con decimales).
func set_km(km: float) -> void:
	if km == _km:
		return
	_km = km
	queue_redraw()


func _process(_delta: float) -> void:
	# Arriba a la derecha aunque cambie el ancho visible (pantallas más alargadas).
	var w := get_viewport().get_visible_rect().size.x
	var pos := Vector2(w - GameConfig.ODOMETER_MARGIN - _size().x, GameConfig.ODOMETER_MARGIN)
	if position != pos:
		position = pos


func _size() -> Vector2:
	var cell := GameConfig.ODOMETER_CELL
	var wheels_w := _total * cell.x + (_total - 1) * GameConfig.ODOMETER_WHEEL_GAP
	var label_w := 2 * (PixelFont.WIDTH + 1)
	return Vector2(wheels_w + GameConfig.ODOMETER_LABEL_GAP + label_w, cell.y) + Vector2.ONE * GameConfig.ODOMETER_PADDING * 2


func _draw() -> void:
	var c := GameConfig.ODOMETER_COLORS
	var cell := GameConfig.ODOMETER_CELL
	var size := _size()
	# Marco: borde claro arriba/izquierda, oscuro abajo/derecha (relieve de plástico).
	draw_rect(Rect2(-Vector2.ONE, size + Vector2(2, 2)), c.frame_dark)
	draw_rect(Rect2(-Vector2.ONE, size + Vector2.ONE), c.frame)
	draw_rect(Rect2(Vector2.ZERO, size), c.bezel)

	var origin := Vector2.ONE * GameConfig.ODOMETER_PADDING
	var glyph_off := ((cell - Vector2(PixelFont.WIDTH, PixelFont.HEIGHT)) / 2).floor()
	# Valor en la unidad del rodillo de más a la derecha (décimas).
	var value := floorf(_km * pow(10, GameConfig.ODOMETER_TENTHS_DIGITS))
	var pos := fmod(_km * pow(10, GameConfig.ODOMETER_TENTHS_DIGITS), DIGITS)
	for i in range(_total - 1, -1, -1):
		var tenths := i >= GameConfig.ODOMETER_INT_DIGITS
		var rect := Rect2(origin + Vector2(i * (cell.x + GameConfig.ODOMETER_WHEEL_GAP), 0), cell)
		draw_rect(rect, c.tenths_wheel if tenths else c.wheel)
		# Dígito actual subiendo y el siguiente entrando por abajo.
		var digit := int(floorf(pos)) % DIGITS
		var frac := pos - floorf(pos)
		var y := rect.position.y + glyph_off.y - roundf(frac * cell.y)
		var color: Color = c.tenths_digit if tenths else c.digit
		PixelFont.draw_char(self, str(digit), Vector2(rect.position.x + glyph_off.x, y), color, rect)
		PixelFont.draw_char(self, str((digit + 1) % DIGITS), Vector2(rect.position.x + glyph_off.x, y + cell.y), color, rect)
		# Siguiente rodillo: su dígito, más el arrastre cuando el actual pasa de 9 a 0.
		var carrying := pos >= DIGITS - 1 and frac > 1 - GameConfig.ODOMETER_CARRY_ZONE
		var carry := (frac - (1 - GameConfig.ODOMETER_CARRY_ZONE)) / GameConfig.ODOMETER_CARRY_ZONE if carrying else 0.0
		value = floorf(value / DIGITS)
		pos = fmod(value, DIGITS) + carry

	# Sombra de curvatura sobre los rodillos.
	var wheels_w := _total * cell.x + (_total - 1) * GameConfig.ODOMETER_WHEEL_GAP
	for r in GameConfig.ODOMETER_SHADE_ROWS:
		var shade: Color = c.shade
		shade.a = GameConfig.ODOMETER_SHADE_ALPHA * (1.0 - float(r) / GameConfig.ODOMETER_SHADE_ROWS)
		draw_rect(Rect2(origin + Vector2(0, r), Vector2(wheels_w, 1)), shade)
		draw_rect(Rect2(origin + Vector2(0, cell.y - 1 - r), Vector2(wheels_w, 1)), shade)

	# Etiqueta "km".
	var label := origin + Vector2(wheels_w + GameConfig.ODOMETER_LABEL_GAP, glyph_off.y)
	PixelFont.draw_char(self, "k", label, c.label)
	PixelFont.draw_char(self, "m", label + Vector2(PixelFont.WIDTH + 1, 0), c.label)
