extends SceneTree
## Atropellos sin pantalla: godot --headless --path godot -s res://tests/pedestrian_test.gd
## Un peatón delante de la furgo lanzada queda tendido; con la furgo parada, no.

var frame := 0
var peds: Pedestrians
var van: Van


func _initialize() -> void:
	var world: Node = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	world.ready.connect(func() -> void:
		world.set_physics_process(false)
		van = world.get_node("Van")
		for n in world.find_children("*", "Pedestrians", true, false):
			peds = n
	)


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 5:
		peds._peds.clear()
		peds._peds.append(_walker(van.global_position))
	elif frame == 10:
		if not peds._bodies.is_empty():
			push_error("Atropellado con la furgo parada")
		peds._peds.clear()
		peds._peds.append(_walker(van.global_position))
		van.velocity = Vector2.from_angle(van.rotation - PI / 2) * GameConfig.VAN_MAX_SPEED
	elif frame == 15:
		if peds._bodies.size() != 1:
			push_error("La furgo lanzada no atropella (%d cuerpos)" % peds._bodies.size())
		else:
			print("atropello OK")
		return true
	return false


func _walker(pos: Vector2) -> Dictionary:
	return {"pos": pos, "target": pos, "dir": Vector2i.RIGHT, "shirt": Color.RED, "hair": Color.BLACK, "clock": 0.0}
