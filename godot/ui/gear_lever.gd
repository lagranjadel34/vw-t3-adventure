class_name GearLever
extends Node2D
## Palanca de cambios de la T3 en el HUD: placa con la rejilla en H y la bola que la recorre.
## Deslizar hacia arriba sube marcha y hacia abajo baja (pasa a manual);
## un toque sin deslizar alterna automático/manual.

var gearbox: Gearbox

var _rect: Rect2
var _hit: Rect2
var _knob := Vector2.ZERO
var _touch_index := -1
var _touch_start := Vector2.ZERO
var _swiped := false
var _tween: Tween


func _init(box: Gearbox) -> void:
	gearbox = box
	gearbox.shifted.connect(_on_shifted)
	gearbox.mode_changed.connect(func(_auto: bool) -> void: queue_redraw())


func _ready() -> void:
	modulate.a = GameConfig.LEVER_IDLE_ALPHA
	get_viewport().size_changed.connect(_place)
	_place()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and _hit.has_point(event.position):
			_touch_index = event.index
			_touch_start = event.position
			_swiped = false
		elif not event.pressed and event.index == _touch_index:
			if not _swiped:
				gearbox.set_automatic(not gearbox.automatic)
			_touch_index = -1
	elif event is InputEventScreenDrag and event.index == _touch_index and not _swiped:
		var dy: float = event.position.y - _touch_start.y
		if absf(dy) >= GameConfig.LEVER_SWIPE_MIN:
			_swiped = true
			gearbox.manual_shift(dy < 0)


## Posición de la bola en una marcha, o en el pasillo central (fila 0) de su columna.
func _slot(gear: int, row_override := -2) -> Vector2:
	var gate: Vector2i = GameConfig.GEAR_GATE[gear - 1]
	var row := gate.y if row_override == -2 else row_override
	var inset := GameConfig.LEVER_SLOT_INSET
	var center := _rect.get_center()
	var half := _rect.size / 2 - inset
	return center + Vector2(gate.x * half.x, row * half.y)


func _on_shifted(from_gear: int, to_gear: int) -> void:
	# Recorrido real por la H: baja/sube al pasillo central, cruza y entra en la nueva marcha.
	var path: Array[Vector2] = [_knob, _slot(from_gear, 0), _slot(to_gear, 0), _slot(to_gear)]
	if _tween:
		_tween.kill()
	_tween = create_tween()
	var leg := GameConfig.LEVER_SHIFT_S / (path.size() - 1)
	for i in range(1, path.size()):
		_tween.tween_method(_set_knob, path[i - 1], path[i], leg)


func _set_knob(pos: Vector2) -> void:
	_knob = pos
	queue_redraw()


func _place() -> void:
	var r := GameConfig.LEVER_RECT
	_rect = Rect2(get_viewport().get_visible_rect().size + r.position, r.size)
	_hit = _rect.grow(GameConfig.LEVER_HIT_PADDING)
	_knob = _slot(gearbox.gear)
	queue_redraw()


func _draw() -> void:
	var colors := GameConfig.LEVER_COLORS
	# Placa con relieve.
	draw_rect(_rect.grow(1), colors.plate_edge)
	draw_rect(_rect, colors.plate)

	# Rejilla en H: dos ranuras verticales y el pasillo central.
	var inset := GameConfig.LEVER_SLOT_INSET
	var left := _rect.position.x + inset.x
	var right := _rect.end.x - inset.x
	var top := _rect.position.y + inset.y
	var bottom := _rect.end.y - inset.y
	var mid := _rect.get_center().y
	draw_rect(Rect2(left - 1, top, 2, bottom - top), colors.slot)
	draw_rect(Rect2(right - 1, top, 2, bottom - top), colors.slot)
	draw_rect(Rect2(left, mid - 1, right - left, 2), colors.slot)

	# Número de cada marcha por fuera de su ranura, a la altura del final.
	var gap := GameConfig.LEVER_KNOB_RADIUS
	for g in range(1, Gearbox.count() + 1):
		var gate: Vector2i = GameConfig.GEAR_GATE[g - 1]
		var p := _slot(g)
		var x := p.x - gap - PixelFont.WIDTH if gate.x < 0 else p.x + gap
		PixelFont.draw_char(self, str(g), Vector2(x, p.y - PixelFont.HEIGHT / 2.0).floor(), colors.number)

	# Modo: A (automático) o M (manual), arriba en el centro.
	var mode := "A" if gearbox.automatic else "M"
	var mode_color: Color = colors.mode_auto if gearbox.automatic else colors.mode_manual
	var mode_pos := Vector2(_rect.get_center().x - PixelFont.WIDTH / 2.0, _rect.position.y + GameConfig.LEVER_MODE_TOP)
	PixelFont.draw_char(self, mode, mode_pos.floor(), mode_color)

	# Bola de la palanca con brillo.
	draw_circle(_knob, GameConfig.LEVER_KNOB_RADIUS, colors.knob)
	draw_rect(Rect2(_knob + Vector2(-2, -2), Vector2(2, 1)), colors.knob_shine)
