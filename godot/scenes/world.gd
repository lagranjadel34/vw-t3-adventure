extends Node2D
## Escena de juego: mapa de Sevilla, la T3, cámara y HUD.

@onready var _van: Van = $Van
@onready var _camera: Camera2D = $Camera
@onready var _hud: Hud = $Hud
@onready var _map_root: Node2D = $Map

var _van_sound := VanSound.new()
var _soundscape := Soundscape.new()
# Salida de la ciudad: cuanto más cerca, más campo suena.
var _exit: Variant


func _ready() -> void:
	var map := TiledMap.load_json(
		GameConfig.MAP_JSON,
		load(GameConfig.MAP_TILESET_IMAGE),
		GameConfig.MAP_GROUND_LAYER,
		GameConfig.MAP_OBJECTS_LAYER,
		GameConfig.MAP_COLLIDES_PROPERTY,
	)
	_map_root.add_child(map.ground)
	for o: Dictionary in map.objects:
		if o.type == GameConfig.MAP_LABEL_TYPE:
			_map_root.add_child(_make_label(o.name, Vector2(o.x, o.y)))

	_hud.add_gear_lever(_van.gearbox)

	_exit = map.find_object(GameConfig.MAP_EXIT)

	var spawn: Variant = map.find_object(GameConfig.MAP_SPAWN)
	if spawn:
		_van.global_position = Vector2(spawn.x, spawn.y)

	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(map.size_px.x)
	_camera.limit_bottom = int(map.size_px.y)
	_camera.global_position = _van.front
	_hud.odometer.set_km(GameConfig.ODOMETER_START_KM + _van.trip_km)
	_camera.zoom = Vector2.ONE * GameConfig.CAMERA_ZOOM_STOPPED
	_camera.reset_smoothing()

	_soundscape.countryside = _countryside()
	add_child(_soundscape)
	add_child(_van_sound)
	_van_sound.setup(_van)


func _physics_process(_delta: float) -> void:
	# Joystick = volante; la potencia sale solo de los pedales (pantalla o W/S).
	_hud.update_pedals(_van.gas_key, _van.brake_key)
	_van.steer_input = _hud.steer
	_van.gas_input = _hud.gas.pressed
	_van.brake_input = _hud.brake.pressed


func _process(delta: float) -> void:
	# La cámara sigue al eje delantero, así en pantalla se ve el giro sobre el morro.
	_camera.global_position = _van.front
	_hud.odometer.set_km(GameConfig.ODOMETER_START_KM + _van.trip_km)

	# Más velocidad, más visión: la cámara se aleja suavemente.
	var t := minf(absf(_van.speed) / GameConfig.VAN_MAX_SPEED, 1.0)
	var target := lerpf(GameConfig.CAMERA_ZOOM_STOPPED, GameConfig.CAMERA_ZOOM_MIN, t)
	var weight := 1.0 - pow(1.0 - GameConfig.CAMERA_ZOOM_LERP, delta * GameConfig.CAMERA_ZOOM_LERP_FPS)
	_camera.zoom = Vector2.ONE * lerpf(_camera.zoom.x, target, weight)
	_soundscape.countryside = _countryside()


## 0 en plena ciudad, 1 al llegar a la salida (el ruido se va quedando atrás).
func _countryside() -> float:
	if _exit == null:
		return 0.0
	var center := Vector2(_exit.x + _exit.width / 2.0, _exit.y + _exit.height / 2.0)
	return 1.0 - clampf(_van.global_position.distance_to(center) / AudioConfig.COUNTRY_FADE_PX, 0.0, 1.0)


func _make_label(text: String, pos: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", GameConfig.MAP_LABEL_FONT_SIZE)
	label.add_theme_color_override("font_color", GameConfig.MAP_LABEL_COLOR)
	label.add_theme_color_override("font_outline_color", GameConfig.MAP_LABEL_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", GameConfig.MAP_LABEL_OUTLINE_SIZE)
	label.modulate.a = GameConfig.MAP_LABEL_ALPHA
	label.size = label.get_minimum_size()
	label.position = pos - label.size / 2
	return label
