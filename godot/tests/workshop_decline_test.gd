extends SceneTree
## Taller Karvans: con "Seguir de largo" el juego sigue sin volver a preguntar mientras la
## furgo esté en el portón; al salir y volver a entrar, vuelve a preguntar.
## godot --headless --path godot -s res://tests/workshop_decline_test.gd

var world: Node
var van: Van
var frame := 0
var phase := 0
var phase_frame := 0
var gate: Rect2
var outside: Vector2


func _initialize() -> void:
	world = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	van = world.get_node("Van")
	world.ready.connect(_place)


func _place() -> void:
	world.set_physics_process(false)
	gate = world._workshops[0].rect
	outside = world._workshops[0].exit
	van.global_position = gate.get_center()
	van.velocity = Vector2.ZERO


func _physics_process(_delta: float) -> bool:
	frame += 1
	world._check_workshops()
	match phase:
		0:
			if world._workshop_entry:
				if not paused:
					push_error("El juego no se ha pausado en el portón")
				print("Popup en el frame %d: seguir de largo" % frame)
				world._workshop_entry.choose(false)
				phase = 1
				phase_frame = frame
		1:
			if world._workshop_entry or paused:
				push_error("Vuelve a preguntar dentro del portón o el juego no se reanuda")
				return true
			if frame - phase_frame >= 10:
				van.global_position = outside
				phase = 2
		2:
			# Fuera del portón se olvida la negativa; la furgo vuelve a entrar.
			if world._workshop_skipped != "":
				push_error("La negativa no se ha olvidado al salir del portón")
				return true
			van.global_position = gate.get_center()
			phase = 3
		3:
			if world._workshop_entry:
				print("Vuelve a preguntar al volver a entrar, frame %d" % frame)
				return true
	if frame > 600:
		push_error("No llega a preguntar en el taller (fase %d)" % phase)
		return true
	return false
