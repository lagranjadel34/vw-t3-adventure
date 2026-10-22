class_name TouchJoystick
extends Node2D
## Joystick virtual flotante (volante). x/y en [-1, 1] (y negativo = arriba).

var x := 0.0
var y := 0.0

var _touch_index := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO


func _ready() -> void:
	get_viewport().size_changed.connect(_reset)
	_reset()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and event.position.x <= _screen().x * GameConfig.JOYSTICK_ZONE_WIDTH_RATIO:
			_touch_index = event.index
			_origin = event.position
			modulate.a = GameConfig.JOYSTICK_ACTIVE_ALPHA
			_move(event.position)
		elif not event.pressed and event.index == _touch_index:
			_reset()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_move(event.position)


func _draw() -> void:
	draw_circle(_origin, GameConfig.JOYSTICK_RADIUS, GameConfig.JOYSTICK_BASE_COLOR)
	draw_circle(_origin, GameConfig.JOYSTICK_RADIUS, GameConfig.JOYSTICK_RING_COLOR, false, 1.0)
	draw_circle(_origin + _knob, GameConfig.JOYSTICK_KNOB_RADIUS, GameConfig.JOYSTICK_KNOB_COLOR)


func _move(pos: Vector2) -> void:
	_knob = (pos - _origin).limit_length(GameConfig.JOYSTICK_RADIUS)
	var n := _knob / GameConfig.JOYSTICK_RADIUS
	x = 0.0 if absf(n.x) < GameConfig.JOYSTICK_DEAD_ZONE else n.x
	y = 0.0 if absf(n.y) < GameConfig.JOYSTICK_DEAD_ZONE else n.y
	queue_redraw()


func _reset() -> void:
	_touch_index = -1
	x = 0.0
	y = 0.0
	_origin = Vector2(0, _screen().y) + GameConfig.JOYSTICK_IDLE_OFFSET
	_knob = Vector2.ZERO
	modulate.a = GameConfig.JOYSTICK_IDLE_ALPHA
	queue_redraw()


func _screen() -> Vector2:
	return get_viewport().get_visible_rect().size
