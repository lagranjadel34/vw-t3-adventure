extends SceneTree
## Paso entre mapas por la A-4: godot --headless -s res://tests/map_test.gd

var world: Node
var van: Van
var frame := 0
var start: Vector2
var step := 0
var step_frame := 0
const DRIVE_FRAMES := 120
const WAIT_FRAMES := 60


func _initialize() -> void:
	world = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	van = world.get_node("Van")
	world.ready.connect(func() -> void: world.set_physics_process(false))


func _rect(o: Dictionary) -> Rect2:
	return Rect2(o.x, o.y, o.width, o.height)


func _object(map_json: String, object_name: String) -> Dictionary:
	var data: Dictionary = (load(map_json) as JSON).data
	for layer: Dictionary in data.layers:
		if layer.type == "objectgroup":
			for o: Dictionary in layer.objects:
				if o.name == object_name:
					return o
	return {}


func _physics_process(_delta: float) -> bool:
	frame += 1
	match step:
		0:
			if world.map_id != GameConfig.MAP_START:
				push_error("No arranca en Sevilla")
			van.global_position = _rect(_object(GameConfig.MAPS[&"sevilla"].json, "salida_a4")).get_center()
			_next()
		1:
			if world.map_id == &"bosque":
				start = van.global_position
				print("bosque: llegada en %s" % start)
				_next()
		2:
			# Por la A-4 hacia el este: no debe chocar con nada.
			van.gas_input = frame - step_frame < DRIVE_FRAMES
			if frame - step_frame >= DRIVE_FRAMES:
				print("bosque: tras 2 s en %s (speed %.1f)" % [van.global_position.round(), van.speed])
				if van.global_position.x - start.x < GameConfig.TILE_SIZE * 4 or absf(van.global_position.y - start.y) > GameConfig.TILE_SIZE:
					push_error("La furgo no avanza recta por la A-4 del bosque")
				van.global_position = _rect(_object(GameConfig.MAPS[&"bosque"].json, "vuelta_sevilla")).get_center()
				_next()
		3:
			if world.map_id == &"sevilla":
				print("sevilla: de vuelta en %s" % van.global_position.round())
				return true
	if step != 2 and frame - step_frame > WAIT_FRAMES:
		push_error("Paso %d: no cambia de mapa (sigue en %s)" % [step, world.map_id])
		return true
	return false


func _next() -> void:
	step += 1
	step_frame = frame
