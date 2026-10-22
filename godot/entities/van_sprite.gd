class_name VanSprite
extends Sprite2D
## Sprite isométrico de la T3: no gira con la furgo, elige el frame de la hoja según
## el rumbo, el volante y lo que han rodado las ruedas. Echa humo por el escape.

var _van: Van
var _textures := {}
var _wheel_px := 0.0
var _smoke: CPUParticles2D
var _smoke_level := -1


func _ready() -> void:
	_van = get_parent()
	for damage in GameConfig.VAN_DAMAGE_LEVELS:
		for lights: bool in [false, true]:
			var suffix := GameConfig.VAN_SPRITE_LIGHTS_SUFFIX if lights else ""
			_textures[[damage, lights]] = load(GameConfig.VAN_SPRITE_PATH % [damage, suffix])
	hframes = GameConfig.VAN_SPRITE_DIRECTIONS
	vframes = GameConfig.VAN_SPRITE_STEER_ROWS * GameConfig.VAN_SPRITE_WHEEL_FRAMES
	offset = GameConfig.VAN_SPRITE_OFFSET
	_smoke = _make_smoke()
	# Detrás de la carrocería.
	_van.add_child.call_deferred(_smoke)
	_van.move_child.call_deferred(_smoke, 0)


func _process(delta: float) -> void:
	global_rotation = 0.0
	texture = _textures[[_van.damage_level, _van.lights_on]]

	# Rumbo en pantalla (0 = derecha, horario) -> columna.
	var heading := wrapf(_van.rotation - PI / 2, 0.0, TAU)
	var step := TAU / GameConfig.VAN_SPRITE_DIRECTIONS
	var column := int(round(heading / step)) % GameConfig.VAN_SPRITE_DIRECTIONS

	var steer_row := 1
	if _van.steer < -GameConfig.VAN_SPRITE_STEER_THRESHOLD:
		steer_row = 0
	elif _van.steer > GameConfig.VAN_SPRITE_STEER_THRESHOLD:
		steer_row = 2
	_wheel_px += _van.speed * delta
	var wheel := posmod(int(_wheel_px / GameConfig.VAN_WHEEL_FRAME_PX), GameConfig.VAN_SPRITE_WHEEL_FRAMES)
	frame = (steer_row * GameConfig.VAN_SPRITE_WHEEL_FRAMES + wheel) * GameConfig.VAN_SPRITE_DIRECTIONS + column

	_update_smoke(heading)


func _update_smoke(heading: float) -> void:
	if _smoke_level != _van.damage_level:
		_smoke_level = _van.damage_level
		_smoke.amount = GameConfig.VAN_SMOKE_AMOUNT[_smoke_level]
		_smoke.color = GameConfig.VAN_SMOKE_COLORS[_smoke_level]
	# Escape (metros del modelo) proyectado como en las hojas: el suelo se aplasta
	# con la inclinación de la cámara y la altura sube en pantalla.
	var e := GameConfig.VAN_EXHAUST_M
	var fwd := Vector2.from_angle(heading)
	var left := Vector2(fwd.y, -fwd.x)
	var ground := (fwd * e.x + left * e.y) * GameConfig.VAN_SPRITE_PX_PER_M
	var cam := deg_to_rad(GameConfig.VAN_SPRITE_CAMERA_DEG)
	ground.y = ground.y * sin(cam) - e.z * cos(cam) * GameConfig.VAN_SPRITE_PX_PER_M
	_smoke.global_position = global_position + ground
	_smoke.global_rotation = 0.0


func _make_smoke() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.local_coords = false
	p.lifetime = GameConfig.VAN_SMOKE_LIFETIME
	p.direction = Vector2.UP
	p.spread = GameConfig.VAN_SMOKE_SPREAD_DEG
	p.gravity = Vector2(0, GameConfig.VAN_SMOKE_RISE)
	p.initial_velocity_min = GameConfig.VAN_SMOKE_SPEED.x
	p.initial_velocity_max = GameConfig.VAN_SMOKE_SPEED.y
	p.scale_amount_min = GameConfig.VAN_SMOKE_SIZE.x
	p.scale_amount_max = GameConfig.VAN_SMOKE_SIZE.y
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	return p
