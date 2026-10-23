extends SceneTree
## Tráfico sin pantalla: godot --headless --path godot -s res://tests/traffic_test.gd
## Con la furgo aparcada fuera de las rutas, todos los coches deben avanzar (semáforos
## incluidos) y ninguno quedarse bloqueado para siempre.

const SECONDS := 60.0
const MIN_PROGRESS := 400.0 # px recorridos como mínimo por cada coche

var frame := 0
var cars: Array[Car] = []
var start := {}


func _initialize() -> void:
	var world: Node = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	world.ready.connect(func() -> void:
		world.set_physics_process(false)
		# Furgo aparcada en mitad del Parque de María Luisa, lejos de todas las rutas.
		var van: Van = world.get_node("Van")
		van.global_position = Vector2(100, 120) * GameConfig.TILE_SIZE
		for c in world.get_node("Traffic").get_children():
			cars.append(c)
			start[c] = c.s
	)


func _physics_process(_delta: float) -> bool:
	frame += 1
	if frame / 60.0 < SECONDS:
		return false
	if cars.is_empty():
		push_error("No hay coches en el mapa")
	for c in cars:
		var progress: float = c.s - start[c]
		print("coche %d: %.0f px" % [c.get_index(), progress])
		if progress < MIN_PROGRESS:
			push_error("El coche %d apenas se ha movido (%.0f px)" % [c.get_index(), progress])
	return true
