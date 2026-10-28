extends SceneTree
## Escribe tu nombre: sin nombre no deja pasar; con nombre lo guarda (sin espacios de más)
## y sigue a la intro. godot --headless --path godot -s res://tests/name_entry_test.gd

var screen: Node
var saved_name: String
var frame := 0


func _initialize() -> void:
	screen = load("res://scenes/name_entry.tscn").instantiate()
	root.add_child(screen)


func _process(_delta: float) -> bool:
	frame += 1
	var settings: Node = root.get_node("Settings")
	if frame == 1:
		saved_name = settings.player_name
		screen._field.text = "   "
		screen._confirm()
		if current_scene != screen and screen.is_inside_tree() == false:
			push_error("Sin nombre ha pasado de pantalla")
		screen._field.text = "  Ara  "
		screen._confirm()
	elif frame == 3:
		if settings.player_name != "Ara":
			push_error("No guarda el nombre: '%s'" % settings.player_name)
		elif not current_scene or current_scene.scene_file_path != "res://scenes/intro.tscn":
			push_error("No sigue a la intro (%s)" % [current_scene.scene_file_path if current_scene else "nada"])
		else:
			print("Nombre guardado y a la intro")
		settings.set_player_name(saved_name)
		return true
	return false
