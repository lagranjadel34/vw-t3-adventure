extends SceneTree
## Caja de cambios sin pantalla: godot --headless -s res://tests/gearbox_test.gd
## Arranca en 3ª a mano (cuesta), reduce a 1ª en marcha (retiene) y vuelve a automático.

var van: Van
var frame := 0

func _initialize() -> void:
	var world: Node = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	van = world.get_node("Van")
	world.ready.connect(func() -> void: world.set_physics_process(false))

func _physics_process(_delta: float) -> bool:
	frame += 1
	var t := frame / 60.0
	if frame == 1:
		van.gearbox.manual_shift(true)
		van.gearbox.manual_shift(true) # 3ª
	if frame == 240:
		van.gearbox.manual_shift(false)
		van.gearbox.manual_shift(false) # 1ª a toda velocidad: freno motor
	if frame == 360:
		van.gearbox.set_automatic(true)
	van.gas_input = true
	if frame % 30 == 0:
		print("t=%.1f gear=%d %s speed=%.1f" % [t, van.gearbox.gear, "A" if van.gearbox.automatic else "M", van.speed])
	return t > 7.0
