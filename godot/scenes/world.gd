extends Node2D
## Escena de juego: mapa (Sevilla o el bosque, se pasa por la A-4), la T3, cámara y HUD.

const MENU_SCENE := "res://scenes/menu.tscn"

@onready var _van: Van = $Van
@onready var _camera: Camera2D = $Camera
@onready var _hud: Hud = $Hud
@onready var _map_root: Node2D = $Map

var _van_sound := VanSound.new()
var _soundscape := Soundscape.new()
## Mapa en el que está la furgo (clave de GameConfig.MAPS).
var map_id: StringName
var _map_def: Dictionary
var _map: TiledMap
var _city: CityView
var _street: StreetProps
var _traffic: Traffic
# Salida de la ciudad: cuanto más cerca, más campo suena.
var _exit: Variant
# Zonas que llevan a otro mapa: [{rect: Rect2, link: Dictionary}].
var _exits: Array = []
var _fade := ColorRect.new()
# Cabeceo de la cámara al cambiar de marcha (px de mundo), decae solo.
var _shift_kick := Vector2.ZERO


func _ready() -> void:
	_hud.add_gear_lever(_van.gearbox)
	_van.gearbox.shifted.connect(_on_shifted)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = GameConfig.MAP_FADE_LAYER
	_fade.color = GameConfig.MAP_FADE_COLOR
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	fade_layer.add_child(_fade)
	add_child(fade_layer)

	_load_map(GameConfig.MAP_START)
	var start: Variant = _map_def.get("start_tile")
	if start != null:
		_van.global_position = (start as Vector2) * GameConfig.TILE_SIZE
		_van.rotation = deg_to_rad(_map_def.start_rot_deg)
	else:
		var spawn: Variant = _map.find_object(GameConfig.MAP_SPAWN)
		if spawn:
			_van.global_position = Vector2(spawn.x, spawn.y)
	_hud.odometer.set_km(GameConfig.ODOMETER_START_KM + _van.trip_km)
	_camera.zoom = Vector2.ONE * GameConfig.CAMERA_ZOOM_STOPPED
	_snap_camera()

	_soundscape.countryside = _countryside()
	add_child(_soundscape)
	add_child(_van_sound)
	_van_sound.setup(_van)



## Cambia el mapa cargado (suelo, edificios/árboles, sombras, rótulos, salidas).
func _load_map(id: StringName) -> void:
	map_id = id
	_map_def = GameConfig.MAPS[id]
	for child in _map_root.get_children():
		child.queue_free()
	for node: Node in [_city, _street, _traffic]:
		if node:
			node.queue_free()
	_map = TiledMap.load_json(
		_map_def.json,
		load(_map_def.tileset),
		GameConfig.MAP_GROUND_LAYER,
		GameConfig.MAP_OBJECTS_LAYER,
		GameConfig.MAP_COLLIDES_PROPERTY,
	)
	_map_root.add_child(_map.ground)
	# Edificios y árboles con perspectiva de cámara cenital (estilo GTA 1).
	_city = CityView.create(_map)
	_city.z_index = GameConfig.CITY_Z
	add_child(_city)
	# Sombras sobre el suelo y bajo la furgo.
	_map_root.add_child(_city.shadows)
	# Vida en la calle: peatones (bajo la furgo), semáforos y farolas (altos) y tráfico.
	_map_root.add_child(Pedestrians.create(_map, _van))
	_street = StreetProps.create(_map)
	_street.z_index = GameConfig.STREET_Z
	add_child(_street)
	_traffic = Traffic.create(_map, _van, _street)
	add_child(_traffic)
	for o: Dictionary in _map.objects:
		if o.type == GameConfig.MAP_LABEL_TYPE:
			_map_root.add_child(_make_label(o.name, Vector2(o.x, o.y)))

	_exit = _map.find_object(_map_def.ambient_exit) if _map_def.ambient_exit != "" else null
	_exits.clear()
	for exit_name: String in _map_def.exits:
		var o: Variant = _map.find_object(exit_name)
		if o:
			_exits.append({"rect": Rect2(o.x, o.y, o.width, o.height), "link": _map_def.exits[exit_name]})

	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(_map.size_px.x)
	_camera.limit_bottom = int(_map.size_px.y)


## Al entrar en una salida, la furgo aparece en el otro mapa con la misma velocidad.
func _travel(link: Dictionary) -> void:
	var spd := _van.speed
	_load_map(link.to)
	var at: Variant = _map.find_object(link.at)
	var pos := Vector2(at.x + at.width / 2.0, at.y + at.height / 2.0) if at else _map.size_px / 2
	_van.global_position = pos + (link.offset_tiles as Vector2) * GameConfig.TILE_SIZE
	_van.rotation = deg_to_rad(link.rot_deg)
	_van.velocity = Vector2.from_angle(_van.rotation - PI / 2) * spd
	_snap_camera()
	_fade.modulate.a = 1.0
	create_tween().tween_property(_fade, "modulate:a", 0.0, GameConfig.MAP_FADE_S)


func _snap_camera() -> void:
	_camera.global_position = _van.front
	_camera.reset_smoothing()


func _notification(what: int) -> void:
	# Botón "atrás" de Android: vuelve al menú.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().change_scene_to_file(MENU_SCENE)


## Cada cambio da un cabeceo a la cámara y una vibración corta en el móvil.
func _on_shifted(from_gear: int, to_gear: int) -> void:
	var dir := -1.0 if to_gear > from_gear else 1.0
	_shift_kick = _van.heading * dir * GameConfig.GEAR_KICK_PX
	Input.vibrate_handheld(GameConfig.GEAR_VIBRATE_MS)


func _physics_process(_delta: float) -> void:
	# Joystick = volante; la potencia sale solo de los pedales (pantalla o W/S).
	_hud.update_pedals(_van.gas_key, _van.brake_key)
	_van.steer_input = _hud.steer
	_van.gas_input = _hud.gas.pressed
	_van.brake_input = _hud.brake.pressed


func _process(delta: float) -> void:
	_shift_kick = _shift_kick.lerp(Vector2.ZERO, 1.0 - exp(-GameConfig.GEAR_KICK_DECAY * delta))
	_camera.offset = _shift_kick
	# La cámara sigue al eje delantero, así en pantalla se ve el giro sobre el morro.
	_camera.global_position = _van.front
	_hud.odometer.set_km(GameConfig.ODOMETER_START_KM + _van.trip_km)

	# Más velocidad, más visión: la cámara se aleja suavemente.
	var t := minf(absf(_van.speed) / GameConfig.VAN_MAX_SPEED, 1.0)
	var target := lerpf(GameConfig.CAMERA_ZOOM_STOPPED, GameConfig.CAMERA_ZOOM_MIN, t)
	var weight := 1.0 - pow(1.0 - GameConfig.CAMERA_ZOOM_LERP, delta * GameConfig.CAMERA_ZOOM_LERP_FPS)
	_camera.zoom = Vector2.ONE * lerpf(_camera.zoom.x, target, weight)
	_soundscape.countryside = _countryside()

	for e: Dictionary in _exits:
		if (e.rect as Rect2).has_point(_van.global_position):
			_travel(e.link)
			break


## 0 en plena ciudad, 1 al llegar a la salida (el ruido se va quedando atrás).
func _countryside() -> float:
	if _map_def.campo != null:
		return _map_def.campo
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
	label.z_index = GameConfig.MAP_LABEL_Z
	label.size = label.get_minimum_size()
	label.position = pos - label.size / 2
	return label
