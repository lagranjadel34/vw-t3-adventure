extends SceneTree
## Pasos de peatones sin pantalla: godot --headless --path godot -s res://tests/crossing_test.gd
## Ningún coche entra en un paso con su semáforo en rojo (salvo el que ya estaba en él) y
## los peatones cruzan, pero solo cuando pueden.

const SECONDS := 90.0
# Cruce de Nervión con pasos en los cuatro brazos y una ruta de coches.
const VAN_TILE := Vector2(166.5, 55.5)

var frame := 0
var street: StreetProps
var peds: Pedestrians
var cars: Array[Car] = []
var inside := {}
var red_runs := 0
var stops := 0
var crossed := 0
var bad_steps := 0


func _initialize() -> void:
	var world: Node = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	world.ready.connect(func() -> void:
		world.set_physics_process(false)
		var van: Van = world.get_node("Van")
		van.global_position = VAN_TILE * GameConfig.TILE_SIZE
		street = world.get_node("StreetProps")
		for n in world.find_children("*", "Pedestrians", true, false):
			peds = n
		for c in world.get_node("Traffic").get_children():
			cars.append(c)
	)


func _physics_process(_delta: float) -> bool:
	frame += 1
	if street == null:
		return false
	for car in cars:
		for i in street.crossings.size():
			var c: Dictionary = street.crossings[i]
			var key := [car, i]
			var now: bool = (c.rect as Rect2).grow(-1).has_point(car.global_position + car.heading * GameConfig.CROSSING_FRONT)
			if now and not inside.get(key, false) and car.heading.dot(c.dir) > GameConfig.CROSSING_INCOMING_DOT:
				if street.light_state(c.eje) == "red":
					red_runs += 1
					push_error("Coche %d en rojo por el paso %d (%s, rumbo %s, vel %.0f)" % [car.get_index(), i, c.rect, car.heading, car.speed])
			inside[key] = now
			if car.speed < 1.0 and car._stops_at(c) and not c.busy:
				stops += 1
	for p in peds._peds:
		var tile := peds._tile(p.pos)
		var was: bool = p.get("test_on", false)
		var now := peds._crossing_tiles.has(tile)
		if now and not was:
			crossed += 1
			# Entra en el paso: tenía que poder cruzar hace un momento.
			var c: Dictionary = street.crossings[peds._crossing_tiles[tile]]
			if street.light_state(c.eje) == "green":
				bad_steps += 1
				push_error("Peatón cruzando con los coches en verde")
		p.test_on = now
	if frame / 60.0 < SECONDS:
		return false
	print("pasos %d · coches parados en rojo %d frames · saltos de rojo %d · peatones que cruzan %d" % [street.crossings.size(), stops, red_runs, crossed])
	if stops == 0:
		push_error("Ningún coche ha parado en un paso")
	if crossed == 0:
		push_error("Ningún peatón ha cruzado")
	return true
