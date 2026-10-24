extends SceneTree
## Taller Karvans: la furgo baja por el carril, entra por el portón, sale el menú y al
## salir espera en el carril. godot --headless --path godot -s res://tests/workshop_test.gd

var world: Node
var van: Van
var frame := 0
var entered_at := -1
var exit_pos: Vector2


func _initialize() -> void:
	world = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	van = world.get_node("Van")
	world.ready.connect(_place)


func _place() -> void:
	world.set_physics_process(false)
	var out: Dictionary = world._map.find_object("taller_karvans" + GameConfig.MAP_WORKSHOP_EXIT_SUFFIX)
	exit_pos = Vector2(out.x, out.y)
	# Desde el carril, mirando al sur (hacia el portón).
	van.global_position = exit_pos
	van.rotation = PI
	van.velocity = Vector2.ZERO


func _physics_process(_delta: float) -> bool:
	frame += 1
	# El mando de la escena está apagado (lo lleva la prueba): comprobamos el taller a mano.
	world._check_workshops()
	if world._workshop_menu == null:
		van.gas_input = entered_at < 0
	elif entered_at < 0:
		entered_at = frame
		if not paused:
			push_error("El juego no se ha pausado en el taller")
		print("Taller abierto en el frame %d, furgo en %s" % [frame, van.global_position.round()])
	if entered_at > 0 and frame == entered_at + 10:
		world._workshop_menu.close()
	if entered_at > 0 and frame == entered_at + 12:
		if paused or world._workshop_menu != null:
			push_error("El taller no se ha cerrado")
		if van.global_position.distance_to(exit_pos) > 1.0:
			push_error("La furgo no ha vuelto al carril: %s" % van.global_position)
		print("Fuera del taller en %s" % van.global_position.round())
		return true
	if frame > 600:
		push_error("La furgo no ha llegado al taller (está en %s)" % van.global_position.round())
		return true
	return false
