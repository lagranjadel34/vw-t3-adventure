extends SceneTree
## Paso al campo: al cruzar la salida de Sevilla se pausa el juego, sale la pantalla de la
## carretera de montaña con la furgo alejándose, el mapa cambia al bosque y al acabar se reanuda.
## godot --headless --path godot -s res://tests/transition_test.gd

var world: Node
var van: Van
var frame := 0
var start_scale := 0.0
var finished := false
var reported := false
var elapsed := 0.0


func _initialize() -> void:
	world = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	van = world.get_node("Van")
	world.ready.connect(_place)


func _place() -> void:
	var a4: Dictionary = world._exits.filter(func(e: Dictionary) -> bool: return e.link.at == "entrada_a4")[0]
	van.global_position = (a4.rect as Rect2).get_center()


func _process(delta: float) -> bool:
	frame += 1
	elapsed += delta
	var t: MapTransition = world._transition
	if finished:
		if paused or world.map_id != &"bosque":
			push_error("Tras la pantalla el juego no sigue en el bosque (pausa: %s, mapa: %s)" % [paused, world.map_id])
		else:
			print("Pantalla de paso terminada en el frame %d: bosque y juego en marcha" % frame)
		return true
	if t:
		if not paused:
			push_error("El juego no se ha pausado durante la pantalla de paso")
			return true
		if start_scale == 0.0:
			start_scale = t.van_scale()
			t.finished.connect(func() -> void: finished = true)
		elif t._gone and not reported:
			reported = true
			if t.van_scale() >= start_scale:
				push_error("La furgo no se ha alejado (escala %.2f -> %.2f)" % [start_scale, t.van_scale()])
				return true
			if world.map_id != &"bosque":
				push_error("El mapa no ha cambiado al bosque durante la pantalla")
				return true
			print("La furgo se aleja: escala %.2f -> %.2f; mapa %s" % [start_scale, t.van_scale(), world.map_id])
	# Dura unos 8 s de reloj; con margen.
	if elapsed > 15.0:
		push_error("La pantalla de paso no sale o no termina (%.1f s)" % elapsed)
		return true
	return false
