extends SceneTree
## Carreteras y enlaces entre mapas. godot --headless --path godot -s res://tests/road_test.gd
##
## - Cada eje de carretera (objetos `eje_carretera*`) se recorre entero: ningún punto de su eje,
##   ni 1,5 tiles a cada lado, cae en un tile con colisión.
## - Cada salida de GameConfig.MAPS lleva a un objeto de llegada que existe y donde la T3 cabe.
## - En el bosque hay camino con holgura para la T3 desde cada entrada hasta el spot de
##   acampada, y la circunvalación lleva de la entrada norte a la puerta sur (y al revés).

const STEP_PX := 4.0
const SIDE_TILES := 1.5
const CLEARANCE := 1

var _maps := {}


func _initialize() -> void:
	for id: StringName in GameConfig.MAPS:
		var def: Dictionary = GameConfig.MAPS[id]
		_maps[id] = TiledMap.load_json(def.json, load(def.tileset), GameConfig.MAP_GROUND_LAYER,
			GameConfig.MAP_OBJECTS_LAYER, GameConfig.MAP_COLLIDES_PROPERTY)
	for id: StringName in _maps:
		_check_axes(id, _maps[id])
		_check_links(id)
	var forest: TiledMap = _maps[&"bosque"]
	_check_reach(forest, "entrada_a4", "spot_acampada")
	_check_reach(forest, "entrada_sur", "spot_acampada")
	_check_reach(forest, "entrada_a4", "vuelta_sevilla_sur")
	_check_reach(forest, "entrada_sur", "vuelta_sevilla")
	for id: StringName in _maps:
		(_maps[id] as TiledMap).ground.free()
	quit()


func _check_axes(id: StringName, map: TiledMap) -> void:
	var axes := 0
	for o: Dictionary in map.objects:
		if not (o.type == GameConfig.MAP_LINE_TYPE and String(o.name).begins_with("eje_carretera")):
			continue
		axes += 1
		var pts: Array = (o.polyline as Array).map(func(p: Dictionary) -> Vector2: return Vector2(o.x + p.x, o.y + p.y))
		var checked := 0
		for i in pts.size() - 1:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var normal := (b - a).normalized().orthogonal()
			for k in int(a.distance_to(b) / STEP_PX):
				var p := a.lerp(b, k * STEP_PX / a.distance_to(b))
				for side in [-SIDE_TILES, 0.0, SIDE_TILES]:
					var q: Vector2 = p + normal * side * GameConfig.TILE_SIZE
					if _blocked(map, Vector2i((q / GameConfig.TILE_SIZE).floor())):
						push_error("%s/%s: la carretera choca con algo en %s" % [id, o.name, q.round()])
						return
				checked += 1
		print("%s/%s: carretera libre (%d puntos)" % [id, o.name, checked])
	if axes == 0:
		push_error("%s: falta algún objeto eje_carretera" % id)


## Cada salida: el objeto de llegada existe y, 8 tiles hacia dentro, la T3 cabe.
func _check_links(id: StringName) -> void:
	var map: TiledMap = _maps[id]
	for exit_name: String in GameConfig.MAPS[id].exits:
		var link: Dictionary = GameConfig.MAPS[id].exits[exit_name]
		if map.find_object(exit_name) == null:
			push_error("%s: no existe la salida %s" % [id, exit_name])
			continue
		var target: TiledMap = _maps[link.to]
		var at: Variant = target.find_object(link.at)
		if at == null:
			push_error("%s: la salida %s apunta a %s/%s, que no existe" % [id, exit_name, link.to, link.at])
			continue
		var pos := Vector2(at.x + at.width / 2.0, at.y + at.height / 2.0) + (link.offset_tiles as Vector2) * GameConfig.TILE_SIZE
		if not _clear(target, Vector2i((pos / GameConfig.TILE_SIZE).floor())):
			push_error("%s: tras %s la furgo aparece en %s/%s sin hueco (%s)" % [id, exit_name, link.to, link.at, pos.round()])
		else:
			print("%s: %s -> %s/%s ok" % [id, exit_name, link.to, link.at])


## Búsqueda en anchura por tiles sin colisión a menos de CLEARANCE tiles (la T3 mide ~1,75).
func _check_reach(map: TiledMap, from_name: String, to_name: String) -> void:
	var tile := float(GameConfig.TILE_SIZE)
	var start_o: Variant = map.find_object(from_name)
	var goal_o: Variant = map.find_object(to_name)
	if start_o == null or goal_o == null:
		push_error("bosque: falta %s o %s" % [from_name, to_name])
		return
	var goal := Rect2(goal_o.x, goal_o.y, goal_o.width, goal_o.height)
	var start := Vector2i(int(start_o.x / tile), int(start_o.y / tile))
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		if goal.has_point((Vector2(c) + Vector2(0.5, 0.5)) * tile):
			print("bosque: de %s a %s hay camino (%d tiles explorados)" % [from_name, to_name, seen.size()])
			return
		for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var n := c + d
			if seen.has(n) or not _clear(map, n):
				continue
			seen[n] = true
			queue.append(n)
	push_error("bosque: la furgo no llega de %s a %s con holgura" % [from_name, to_name])


func _blocked(map: TiledMap, c: Vector2i) -> bool:
	var id := map.cell(c.x, c.y)
	return id < 0 or map.tile_props.get(id, {}).get(GameConfig.MAP_COLLIDES_PROPERTY, false)


func _clear(map: TiledMap, c: Vector2i) -> bool:
	for dy in range(-CLEARANCE, CLEARANCE + 1):
		for dx in range(-CLEARANCE, CLEARANCE + 1):
			if _blocked(map, c + Vector2i(dx, dy)):
				return false
	return true
