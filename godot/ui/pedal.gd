class_name Pedal
extends Node2D
## Pedal de goma con estrías; se pisa con cualquier dedo (o ratón) que esté encima.
## `layout` es relativo a la esquina inferior derecha de la pantalla.

var pressed := false
var layout: Rect2

var _rect: Rect2
var _hit: Rect2


func _init(pedal_layout: Rect2) -> void:
	layout = pedal_layout


func _ready() -> void:
	get_viewport().size_changed.connect(_place)
	_place()


func update_press(touches: Array, key_down: bool) -> void:
	var now := key_down or touches.any(func(p: Vector2) -> bool: return _hit.has_point(p))
	if now == pressed:
		return
	pressed = now
	queue_redraw()


func _place() -> void:
	_rect = Rect2(get_viewport().get_visible_rect().size + layout.position, layout.size)
	_hit = _rect.grow(GameConfig.PEDAL_HIT_PADDING)
	queue_redraw()


func _draw() -> void:
	var colors := GameConfig.PEDAL_COLORS
	var x := _rect.position.x
	var y := _rect.position.y + (GameConfig.PEDAL_PRESS_OFFSET if pressed else 0.0)
	var w := _rect.size.x
	var h := _rect.size.y
	var c := GameConfig.PEDAL_CORNER
	modulate.a = GameConfig.PEDAL_PRESSED_ALPHA if pressed else GameConfig.PEDAL_IDLE_ALPHA

	# Brazo metálico del que cuelga el pedal (sale por arriba, centrado).
	var arm_w := GameConfig.PEDAL_ARM_WIDTH
	var arm_l := GameConfig.PEDAL_ARM_LENGTH
	var ax := x + floorf((w - arm_w) / 2)
	draw_rect(Rect2(ax, y - arm_l, arm_w + 1, arm_l), colors.arm_shadow)
	draw_rect(Rect2(ax, y - arm_l, arm_w, arm_l), colors.arm)

	# Goma con esquinas romas: contorno y relleno como rectángulos en cruz.
	var rounded := func(inset: float, color: Color) -> void:
		var cc := maxf(c - inset, 0)
		draw_rect(Rect2(x + inset + cc, y + inset, w - (inset + cc) * 2, h - inset * 2), color)
		draw_rect(Rect2(x + inset, y + inset + cc, w - inset * 2, h - (inset + cc) * 2), color)
		if cc > 1:
			draw_rect(Rect2(x + inset + 1, y + inset + 1, w - (inset + 1) * 2, h - (inset + 1) * 2), color)
	rounded.call(0.0, colors.outline)
	rounded.call(1.0, colors.rubber_pressed if pressed else colors.rubber)
	# Brillo arriba de la goma.
	draw_rect(Rect2(x + c + 1, y + 1, w - (c + 1) * 2, 1), colors.highlight)

	# Estrías horizontales en relieve (surco oscuro + filo claro).
	var inset := GameConfig.PEDAL_RIB_INSET
	var ry := y + GameConfig.PEDAL_RIB_SPACING
	while ry < y + h - GameConfig.PEDAL_RIB_SPACING:
		draw_rect(Rect2(x + inset, ry, w - inset * 2, 1), colors.rib)
		draw_rect(Rect2(x + inset, ry + 1, w - inset * 2, 1), colors.rib_light)
		ry += GameConfig.PEDAL_RIB_SPACING
