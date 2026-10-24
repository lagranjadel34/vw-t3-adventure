extends SceneTree
## Aceleración a fondo en automático: godot --headless -s res://tests/accel_test.gd
## Imprime cuándo entra cada marcha, su aceleración media (km/h/s) y cuánto tarda en llegar a 100 km/h.
## Falla si una marcha no empuja menos que la anterior o si un cambio no sube el tope de velocidad.

var van: Van
var frame := 0
var last_gear := 1
var gear_start_t := 0.0
var gear_start_kmh := 0.0
var gear_accels: Array[float] = []

func _initialize() -> void:
	var world: Node = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	van = world.get_node("Van")
	# Prueba de motor, no de mapa: sin colisiones para que ningún edificio pare la aceleración.
	van.collision_mask = 0
	world.ready.connect(func() -> void: world.set_physics_process(false))

func _physics_process(_delta: float) -> bool:
	frame += 1
	var t := frame / 60.0
	van.gas_input = true
	var kmh := van.speed * GameConfig.METERS_PER_PIXEL * GameConfig.KMH_PER_MPS
	if van.gearbox.gear != last_gear:
		_close_gear(t, kmh)
		print("t=%.1f %dª -> %dª a %.0f km/h" % [t, last_gear, van.gearbox.gear, kmh])
		last_gear = van.gearbox.gear
	if kmh >= GameConfig.VAN_TOP_SPEED_KMH * 0.97:
		_close_gear(t, kmh)
		print("t=%.1f a %.0f km/h" % [t, kmh])
		for i in range(1, gear_accels.size()):
			if gear_accels[i] >= gear_accels[i - 1]:
				push_error("La %dª empuja igual o más que la %dª" % [i + 1, i])
		return true
	if t > 30.0:
		push_error("No llega a 100 km/h en 30 s (%.0f km/h)" % kmh)
		return true
	return false


func _close_gear(t: float, kmh: float) -> void:
	var accel := (kmh - gear_start_kmh) / maxf(t - gear_start_t, 0.001)
	print("  %dª: %.0f km/h/s" % [last_gear, accel])
	gear_accels.append(accel)
	gear_start_t = t
	gear_start_kmh = kmh
