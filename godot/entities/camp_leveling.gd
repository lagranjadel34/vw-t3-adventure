class_name CampLeveling
extends RefCounted
## Puzzle de calzos del spot: cada rueda tiene su pila de piezas apilables (GameConfig.CAMP_PIECES_CM).
## Nivelada = las cuatro ruedas a la misma altura, con la tolerancia GameConfig.CAMP_LEVEL_TOL_CM.

const WHEELS := [&"fl", &"fr", &"rl", &"rr"]

## Piezas que quedan en la furgo, por altura (cm).
var stock := {}
## Pila de cada rueda: altura de cada pieza, de abajo arriba.
var stacks := {}


func _init() -> void:
	for size: int in GameConfig.CAMP_PIECES_CM:
		stock[size] = GameConfig.CAMP_PIECES_PER_SIZE
	for wheel: StringName in WHEELS:
		stacks[wheel] = []


## Altura de una rueda sobre el suelo base (terreno + pila), en cm.
func height(wheel: StringName) -> float:
	var total: float = GameConfig.CAMP_GROUND_CM[wheel]
	for piece: int in stacks[wheel]:
		total += piece
	return total


## Inclinación lateral (+ = cae a la derecha), en cm.
func roll() -> float:
	return (height(&"fr") + height(&"rr") - height(&"fl") - height(&"rl")) / 2.0


## Inclinación longitudinal (+ = morro abajo), en cm.
func pitch() -> float:
	return (height(&"rl") + height(&"rr") - height(&"fl") - height(&"fr")) / 2.0


func is_level() -> bool:
	var low := INF
	var high := -INF
	for wheel: StringName in WHEELS:
		low = minf(low, height(wheel))
		high = maxf(high, height(wheel))
	return high - low <= GameConfig.CAMP_LEVEL_TOL_CM


## Apila una pieza de esa altura bajo la rueda. Falso si no quedan piezas de ese tamaño.
func put(wheel: StringName, size: int) -> bool:
	if stock.get(size, 0) <= 0:
		return false
	stock[size] -= 1
	stacks[wheel].append(size)
	return true


## Retira la pieza de arriba de la pila de esa rueda y la devuelve al stock.
func take(wheel: StringName) -> bool:
	if stacks[wheel].is_empty():
		return false
	var size: int = stacks[wheel].pop_back()
	stock[size] += 1
	return true
