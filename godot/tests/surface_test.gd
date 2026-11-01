extends SceneTree
## Superficies: godot --headless -s res://tests/surface_test.gd
## Comprueba que cada mapa lee bien el tipo de tile bajo la furgo y que tierra y hierba agarran menos que el asfalto.

func _initialize() -> void:
	var failed := false
	for id: StringName in GameConfig.MAPS:
		var def: Dictionary = GameConfig.MAPS[id]
		var map := TiledMap.load_json(def.json, load(def.tileset), GameConfig.MAP_GROUND_LAYER, GameConfig.MAP_OBJECTS_LAYER, GameConfig.MAP_COLLIDES_PROPERTY)
		var road := _first_cell_of(map, "asfalto")
		if road == Vector2.INF:
			push_error("%s: no hay asfalto para probar type_at" % id)
			failed = true
		elif map.type_at(road) != "asfalto":
			push_error("%s: type_at no lee el asfalto (%s)" % [id, map.type_at(road)])
			failed = true
		if map.type_at(Vector2(-1, -1)) != "" or map.type_at(map.size_px + Vector2(16, 16)) != "":
			push_error("%s: type_at fuera del mapa debe ser vacío" % id)
			failed = true
	for name: String in GameConfig.SURFACES:
		var s: Dictionary = GameConfig.SURFACES[name]
		if s.grip <= 0.0 or s.grip >= 1.0 or s.speed <= 0.0 or s.speed > 1.0 or s.drag < 1.0:
			push_error("%s: valores fuera de rango %s" % [name, s])
			failed = true
	if GameConfig.SURFACES.tierra.grip >= GameConfig.SURFACE_ROAD.grip:
		push_error("La tierra debe agarrar menos que el asfalto")
		failed = true
	if GameConfig.SURFACES.hierba.grip >= GameConfig.SURFACES.tierra.grip:
		push_error("La hierba debe agarrar menos que la tierra")
		failed = true
	print("superficies: %d tipos con entrada; %s" % [GameConfig.SURFACES.size(), "FALLO" if failed else "OK"])
	quit(1 if failed else 0)


## Centro de la primera celda con ese tipo, o Vector2.INF si no hay.
func _first_cell_of(map: TiledMap, type: String) -> Vector2:
	for i in map.cells.size():
		if map.cells[i] >= 0 and map.tile_types.get(map.cells[i], "") == type:
			return Vector2(i % map.width, i / map.width) * map.tile_px + Vector2.ONE * map.tile_px / 2.0
	return Vector2.INF
