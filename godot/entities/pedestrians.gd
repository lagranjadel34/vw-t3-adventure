class_name Pedestrians
extends Node2D
## Algún transeúnte por las aceras, solo cerca de la cámara. Andan de tile en tile de
## acera (siguen recto y giran en las esquinas) y se apartan de un salto si llega la T3.

var _map: TiledMap
var _van: Van
var _walkable := {}
var _peds: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


static func create(map: TiledMap, van: Van) -> Pedestrians:
	var peds := Pedestrians.new()
	peds.name = "Pedestrians"
	peds._map = map
	peds._van = van
	for id: int in map.tile_types:
		if map.tile_types[id] in GameConfig.PED_WALKABLE:
			peds._walkable[id] = true
	return peds


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var center := cam.get_screen_center_position()
	while _peds.size() < GameConfig.PED_COUNT:
		var p := _spawn(center)
		if p.is_empty():
			break
		_peds.append(p)
	for i in range(_peds.size() - 1, -1, -1):
		var p := _peds[i]
		if p.pos.distance_to(center) > GameConfig.PED_DESPAWN_DISTANCE:
			_peds.remove_at(i)
			continue
		_walk(p, delta)
	queue_redraw()


func _walk(p: Dictionary, delta: float) -> void:
	p.clock += delta
	var away: Vector2 = p.pos - _van.global_position
	if absf(_van.speed) > GameConfig.VAN_STOP_SPEED and away.length() < GameConfig.PED_FLEE_DISTANCE:
		# ¡Que viene la furgo! Salto hacia fuera y luego, a la acera más cercana.
		p.pos += away.normalized() * GameConfig.PED_FLEE_SPEED * delta
		p.target = _nearest_walkable(p.pos)
		return
	var to: Vector2 = p.target - p.pos
	var step := GameConfig.PED_SPEED * delta
	if to.length() > step:
		p.pos += to.normalized() * step
		return
	p.pos = p.target
	var tile := _tile(p.pos)
	var dirs: Array[Vector2i] = []
	for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		if d != -p.dir and _is_walkable(tile + d):
			dirs.append(d)
	var straight := _is_walkable(tile + p.dir) and _rng.randf() > GameConfig.PED_TURN_CHANCE
	if not straight:
		p.dir = dirs[_rng.randi() % dirs.size()] if not dirs.is_empty() else -p.dir
	var j := GameConfig.PED_JITTER
	p.target = _center(tile + p.dir) + Vector2(_rng.randf_range(-j, j), _rng.randf_range(-j, j))


func _draw() -> void:
	for p in _peds:
		var pos: Vector2 = (p.pos as Vector2).round()
		# Vistos desde arriba: piernas que se alternan, hombros con la camiseta y la cabeza.
		var leg := 1.0 if int(p.clock / GameConfig.PED_STEP_S) % 2 == 0 else -1.0
		var side := Vector2(p.dir).orthogonal()
		var fwd := Vector2(p.dir)
		var legs := GameConfig.PED_LEGS
		draw_rect(Rect2(pos + side * 1.5 + fwd * leg * 2 - Vector2.ONE, Vector2.ONE * 2), legs)
		draw_rect(Rect2(pos - side * 1.5 - fwd * leg * 2 - Vector2.ONE, Vector2.ONE * 2), legs)
		var s := GameConfig.PED_SHOULDERS
		var shoulders := s if p.dir.x == 0 else Vector2(s.y, s.x)
		draw_rect(Rect2(pos - shoulders / 2, shoulders), p.shirt)
		var head := Vector2.ONE * GameConfig.PED_HEAD
		draw_rect(Rect2(pos - head / 2, head), p.hair)


func _spawn(center: Vector2) -> Dictionary:
	for attempt in 20:
		var dist := _rng.randf_range(GameConfig.PED_SPAWN_RANGE.x, GameConfig.PED_SPAWN_RANGE.y)
		var pos := center + Vector2.from_angle(_rng.randf() * TAU) * dist
		var tile := _tile(pos)
		if not _is_walkable(tile):
			continue
		var dirs: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
		var start := _center(tile)
		return {
			"pos": start,
			"target": start,
			"dir": dirs[_rng.randi() % dirs.size()],
			"shirt": GameConfig.PED_SHIRTS[_rng.randi() % GameConfig.PED_SHIRTS.size()],
			"hair": GameConfig.PED_HAIR[_rng.randi() % GameConfig.PED_HAIR.size()],
			"clock": _rng.randf(),
		}
	return {}


func _nearest_walkable(pos: Vector2) -> Vector2:
	var tile := _tile(pos)
	var best := pos
	var best_d := INF
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var t := tile + Vector2i(dx, dy)
			if _is_walkable(t) and _center(t).distance_to(pos) < best_d:
				best_d = _center(t).distance_to(pos)
				best = _center(t)
	return best


func _is_walkable(t: Vector2i) -> bool:
	return _walkable.has(_map.cell(t.x, t.y))


func _tile(pos: Vector2) -> Vector2i:
	return Vector2i((pos / GameConfig.TILE_SIZE).floor())


func _center(t: Vector2i) -> Vector2:
	return (Vector2(t) + Vector2.ONE / 2) * GameConfig.TILE_SIZE
