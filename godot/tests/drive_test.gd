extends SceneTree
## Prueba de conducción sin pantalla: godot --headless -s res://tests/drive_test.gd

var van: Van
var frame := 0
var log_lines := []
var drifted := false
var spawn: Vector2

func _initialize() -> void:
	var world: Node = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	van = world.get_node("Van")
	world.ready.connect(func() -> void: spawn = van.global_position)
	# Quitamos el mando de la escena para controlar la furgo desde aquí.
	world.ready.connect(func() -> void: world.set_physics_process(false))

func _physics_process(_delta: float) -> bool:
	frame += 1
	var t := frame / 60.0
	# Derrape en recta despejada: vuelve al punto de salida.
	if frame == 600:
		van.global_position = spawn
		van.rotation = 0.0
		van.velocity = Vector2.ZERO
	van.gas_input = t < 2.0 or (t > 5.0 and t < 7.0) or (t > 10.0 and t < 13.0)
	van.brake_input = (t > 3.0 and t < 4.5) or (t > 8.0 and t < 9.5)
	van.steer_input = 1.0 if (t > 5.0 and t < 7.0) or (t > 13.0 and t < 14.0) else 0.0
	# Freno de mano en curva: la cola se va.
	van.handbrake_input = t > 13.0 and t < 13.5
	if van.drifting:
		drifted = true
	if frame % 30 == 0:
		print("t=%.1f gear=%d speed=%.1f rot=%.1f pos=%s km=%.4f drift=%s" % [t, van.gearbox.gear, van.speed, rad_to_deg(van.rotation), van.global_position.round(), van.trip_km, van.drifting])
	if t > 15.0:
		if not drifted:
			push_error("La furgo no ha derrapado con freno de mano en curva")
		return true
	return false
