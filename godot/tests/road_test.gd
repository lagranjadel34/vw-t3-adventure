extends SceneTree
## La carretera convencional de cada mapa (objeto `eje_carretera`) se puede recorrer entera:
## ningún punto de su eje, ni 1,5 tiles a cada lado, cae en un tile con colisión.
## godot --headless --path godot -s res://tests/road_test.gd

const STEP_PX := 4.0
const SIDE_TILES := 1.5


func _initialize() -> void:
	for id: StringName in GameConfig.MAPS:
		var def: Dictionary = GameConfig.MAPS[id]
		var map := TiledMap.load_json(def.json, load(def.tileset), GameConfig.MAP_GROUND_LAYER,
			GameConfig.MAP_OBJECTS_LAYER, GameConfig.MAP_COLLIDES_PROPERTY)
		var axis: Variant = map.find_object("eje_carretera")
		if axis == null:
			push_error("%s: falta el objeto eje_carretera" % id)
			map.ground.free()
			continue
		var pts: Array = (axis.polyline as Array).map(func(p: Dictionary) -> Vector2: return Vector2(axis.x + p.x, axis.y + p.y))
		var checked := 0
		for i in pts.size() - 1:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var normal := (b - a).normalized().orthogonal()
			for k in int(a.distance_to(b) / STEP_PX):
				var p := a.lerp(b, k * STEP_PX / a.distance_to(b))
				for side in [-SIDE_TILES, 0.0, SIDE_TILES]:
					var q: Vector2 = p + normal * side * GameConfig.TILE_SIZE
					var props: Dictionary = map.tile_props.get(map.cell(int(q.x / GameConfig.TILE_SIZE), int(q.y / GameConfig.TILE_SIZE)), {})
					if props.get(GameConfig.MAP_COLLIDES_PROPERTY, false):
						push_error("%s: la carretera choca con algo en %s" % [id, q.round()])
						map.ground.free()
						quit()
						return
				checked += 1
		print("%s: carretera libre (%d puntos)" % [id, checked])
		map.ground.free()
	quit()
