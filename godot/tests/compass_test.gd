extends SceneTree
## Rosa de los vientos sin pantalla: godot --headless --path godot -s res://tests/compass_test.gd
## El punto de la furgo queda dentro de la rosa y en el lado que toca: arriba si está al
## norte del mapa, a la derecha si está al este.

var frame := 0
var world: Node
var van: Van
var compass: Compass
const CASES := [Vector2(0.02, 0.02), Vector2(0.98, 0.02), Vector2(0.02, 0.98), Vector2(0.98, 0.98), Vector2(0.5, 0.5)]
var case_i := 0


func _initialize() -> void:
	world = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	world.ready.connect(func() -> void:
		world.set_physics_process(false)
		van = world.get_node("Van")
		compass = world._hud.compass
	)


func _process(_delta: float) -> bool:
	frame += 1
	if compass == null or frame % 3 != 0:
		return false
	var map_size: Vector2 = world._map.size_px
	if frame % 6 == 3:
		van.global_position = CASES[case_i] * map_size
		return false
	var want: Vector2 = CASES[case_i] * 2.0 - Vector2.ONE
	var dot := compass.dot_position()
	if dot.length() > GameConfig.COMPASS_RADIUS:
		push_error("El punto se sale de la rosa: %s" % dot)
	var ok := true
	for axis in 2:
		ok = ok and (signf(dot[axis]) == signf(want[axis]) if absf(want[axis]) > 0.5 else absf(dot[axis]) < 1.0)
	if not ok:
		push_error("Furgo en %s del mapa pero el punto en %s" % [CASES[case_i], dot])
	case_i += 1
	if case_i == CASES.size():
		print("rosa OK")
		return true
	return false
