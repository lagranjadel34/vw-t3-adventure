class_name VanSprite
extends Sprite2D
## Sprite de la T3: la vista superior en alta resolución gira con la furgo (filtro lineal y
## mipmaps, sin escalones). Lleva su sombra en el suelo y echa humo por el escape.

var _van: Van
var _textures := {}
var _shadow := Sprite2D.new()
var _smoke: CPUParticles2D
var _smoke_level := -1


func _ready() -> void:
	_van = get_parent()
	var path: String = VehicleConfig.chosen(self).sprites
	for damage in GameConfig.VAN_DAMAGE_LEVELS:
		for lights: bool in [false, true]:
			var suffix := GameConfig.VAN_SPRITE_LIGHTS_SUFFIX if lights else ""
			_textures[[damage, lights]] = _with_mipmaps(load(path % [damage, suffix]))
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	scale = Vector2.ONE / GameConfig.VAN_TOP_HD_SCALE
	_shadow.texture_filter = texture_filter
	_shadow.scale = scale
	_shadow.modulate = GameConfig.VAN_SHADOW_COLOR
	_smoke = _make_smoke()
	# Sombra y humo, detrás de la carrocería.
	_van.add_child.call_deferred(_shadow)
	_van.move_child.call_deferred(_shadow, 0)
	_van.add_child.call_deferred(_smoke)
	_van.move_child.call_deferred(_smoke, 0)


static func _with_mipmaps(tex: Texture2D) -> Texture2D:
	var img := tex.get_image()
	img.decompress()
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _process(_delta: float) -> void:
	texture = _textures[[_van.damage_level, _van.lights_on]]
	# Morro de la textura a la derecha; el de la furgo, hacia -y local.
	rotation = -PI / 2
	_shadow.texture = texture
	_shadow.global_rotation = global_rotation
	_shadow.global_position = global_position + GameConfig.VAN_SHADOW_OFFSET
	_update_smoke(wrapf(_van.rotation - PI / 2, 0.0, TAU))


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
