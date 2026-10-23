extends SceneTree
## Tracción trasera: godot --headless -s res://tests/rear_drive_test.gd
## Misma curva cerrada en 2ª dos veces: con gas la cola se suelta; sin gas, no.

var van: Van
var frame := 0
var with_gas := true
var drifted := {true: false, false: false}

func _initialize() -> void:
	var world: Node = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	van = world.get_node("Van")
	world.ready.connect(func() -> void: world.set_physics_process(false))

func _physics_process(_delta: float) -> bool:
	frame += 1
	# Recta hasta ~70 px/s en 2ª y luego volante a tope 1 s.
	var phase := frame % 300
	if phase == 1:
		van.rotation = 0.0
		van.velocity = Vector2.ZERO
		van.gearbox.set_automatic(true)
	var turning := phase > 200
	van.steer_input = 1.0 if turning else 0.0
	van.gas_input = (not turning and van.speed < 72.0) or (turning and with_gas)
	if turning and van.drifting:
		drifted[with_gas] = true
	if phase == 299:
		print("%s gas: marcha %d, derrapa=%s" % ["con" if with_gas else "sin", van.gearbox.gear, drifted[with_gas]])
		if not with_gas:
			if not drifted[true] or drifted[false]:
				push_error("La tracción trasera no se nota")
			return true
		with_gas = false
	return false
