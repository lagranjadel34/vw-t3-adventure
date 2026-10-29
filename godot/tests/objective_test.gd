extends SceneTree
## Objetivo al empezar: sale el recuadro sin pausar el juego y se va solo.
## godot --headless --path godot -s res://tests/objective_test.gd

var world: Node
var box: Node
var elapsed := 0.0
var closed := false


func _initialize() -> void:
	world = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)


func _process(delta: float) -> bool:
	elapsed += delta
	if closed:
		print("Objetivo mostrado y cerrado solo a los %.1f s" % elapsed)
		return true
	if not box:
		for c in world.get_children():
			if c.has_method("close") and c.has_signal("closed"):
				box = c
				box.closed.connect(func() -> void: closed = true)
		if not box:
			push_error("No sale el recuadro del objetivo")
			return true
	if paused:
		push_error("El objetivo no debe pausar el juego")
		return true
	if elapsed > GameConfig.OBJECTIVE_DELAY_S + GameConfig.OBJECTIVE_SHOW_S + GameConfig.OBJECTIVE_FADE_S * 2 + 2.0:
		push_error("El recuadro del objetivo no se va solo")
		return true
	return false
