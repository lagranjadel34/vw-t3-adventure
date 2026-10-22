extends SceneTree
## Aceleración a fondo en automático: godot --headless -s res://tests/accel_test.gd
## Imprime cuándo entra cada marcha y cuánto tarda en llegar a 100 km/h.

var van: Van
var frame := 0
var last_gear := 1

func _initialize() -> void:
	var world: Node = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	van = world.get_node("Van")
	world.ready.connect(func() -> void: world.set_physics_process(false))

func _physics_process(_delta: float) -> bool:
	frame += 1
	var t := frame / 60.0
	van.gas_input = true
	var kmh := van.speed * GameConfig.METERS_PER_PIXEL * GameConfig.KMH_PER_MPS
	if van.gearbox.gear != last_gear:
		print("t=%.1f %dª -> %dª a %.0f km/h" % [t, last_gear, van.gearbox.gear, kmh])
		last_gear = van.gearbox.gear
	if kmh >= GameConfig.VAN_TOP_SPEED_KMH * 0.97:
		print("t=%.1f a %.0f km/h" % [t, kmh])
		return true
	if t > 30.0:
		push_error("No llega a 100 km/h en 30 s (%.0f km/h)" % kmh)
		return true
	return false
