extends SceneTree
## Puzzle de calzos: una solución nivela la furgo y quitar una pieza la desnivela.
## godot --headless --path godot -s res://tests/camp_test.gd

var _fails := 0


func _check(cond: bool, what: String) -> void:
	if not cond:
		_fails += 1
		push_error("FALLA: " + what)


func _initialize() -> void:
	var camp := CampLeveling.new()
	_check(not camp.is_level(), "sin piezas no está nivelada")
	# Solución con el terreno de GameConfig: fl 13 · fr 7 · rl 7+10 · rr 10 (cm).
	_check(camp.put(&"fl", 13), "pone un 13 en la delantera izquierda")
	_check(camp.put(&"fr", 7), "pone un 7 en la delantera derecha")
	_check(camp.put(&"rl", 7), "pone un 7 en la trasera izquierda")
	_check(camp.put(&"rl", 10), "pone un 10 encima en la trasera izquierda")
	_check(camp.put(&"rr", 10), "pone un 10 en la trasera derecha")
	_check(camp.is_level(), "la solución deja la furgo nivelada")
	_check(not camp.put(&"fl", 7), "no quedan piezas de 7 y no se puede poner")
	_check(camp.take(&"rl"), "retira la pieza de arriba de la trasera izquierda")
	_check(camp.stock[10] == 1, "la pieza de 10 vuelve al stock")
	_check(not camp.is_level(), "quitar una pieza desnivela la furgo")
	print("camp_test: %d fallos" % _fails)
	quit(1 if _fails > 0 else 0)
