class_name Pedestrians
extends Node2D
## Algún transeúnte por las aceras, solo cerca de la cámara. Andan de tile en tile de
## acera (siguen recto y giran en las esquinas) y se apartan de un salto si llega la T3.
## Si la T3 los pilla, quedan tendidos en el suelo con un charco de sangre.

var _map: TiledMap
var _van: Van
var _walkable := {}
var _peds: Array[Dictionary] = []
var _bodies: Array[Dictionary] = []
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
		if _run_over(p):
			_peds.remove_at(i)
			_add_body(p)
			continue
		_walk(p, delta)
	for i in range(_bodies.size() - 1, -1, -1):
		_bodies[i].clock += delta
		if _bodies[i].pos.distance_to(center) > GameConfig.PED_DESPAWN_DISTANCE:
			_bodies.remove_at(i)
	queue_redraw()


## ¿Está dentro de la caja de la furgo, que va lanzada?
func _run_over(p: Dictionary) -> bool:
	if absf(_van.speed) < GameConfig.PED_HIT_SPEED:
		return false
	var local: Vector2 = (p.pos - _van.global_position).rotated(-_van.rotation)
	return absf(local.x) < GameConfig.PED_HIT_HALF.x and absf(local.y) < GameConfig.PED_HIT_HALF.y


func _add_body(p: Dictionary) -> void:
	var blobs: Array[Vector3] = []
	for b in GameConfig.PED_BLOOD_BLOBS:
		var off := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf() * GameConfig.PED_BLOOD_SPREAD
		blobs.append(Vector3(off.x, off.y, _rng.randf_range(GameConfig.PED_BLOOD_RADIUS.x, GameConfig.PED_BLOOD_RADIUS.y)))
	# Cae en el sentido en que iba la furgo, con algo de giro.
	var angle := _van.rotation - PI / 2 + _rng.randf_range(-PI / 2, PI / 2)
	_bodies.append({"pos": p.pos, "angle": angle, "shirt": p.shirt, "hair": p.hair, "blobs": blobs, "clock": 0.0})
	if _bodies.size() > GameConfig.PED_MAX_BODIES:
		_bodies.pop_front()


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
	for b in _bodies:
		_draw_body(b)
	for p in _peds:
		_draw_walker(p)


## De pie, con la vista oblicua de la T3: sombra, piernas, camiseta, brazos y cabeza.
func _draw_walker(p: Dictionary) -> void:
	var feet: Vector2 = (p.pos as Vector2).round()
	var step := 1.0 if int(p.clock / GameConfig.PED_STEP_S) % 2 == 0 else -1.0
	var dir: Vector2i = p.dir
	var skin := GameConfig.PED_SKIN
	draw_set_transform(feet)
	draw_rect(GameConfig.PED_SHADOW, GameConfig.PED_SHADOW_COLOR)
	# Al andar, una pierna se levanta y los brazos se balancean al revés.
	draw_rect(_lift(GameConfig.PED_LEG_L, maxf(step, 0)), GameConfig.PED_LEGS)
	draw_rect(_lift(GameConfig.PED_LEG_R, maxf(-step, 0)), GameConfig.PED_LEGS)
	draw_rect(GameConfig.PED_TORSO, p.shirt)
	draw_rect(GameConfig.PED_ARM_L.grow_side(SIDE_TOP, -step), skin)
	draw_rect(GameConfig.PED_ARM_R.grow_side(SIDE_TOP, step), skin)
	var head := GameConfig.PED_HEAD
	draw_rect(head, skin)
	# Pelo: arriba si mira hacia la cámara, toda la cabeza de espaldas, la nuca de lado.
	var hair := Rect2(head.position, Vector2(head.size.x, GameConfig.PED_HAIR_ROWS))
	if dir == Vector2i.UP:
		hair = head
	elif dir.x != 0:
		hair = Rect2(head.position, Vector2(head.size.x, head.size.y - 1))
		hair = hair.grow_side(SIDE_RIGHT if dir.x > 0 else SIDE_LEFT, -2)
	draw_rect(hair, p.hair)
	draw_set_transform(Vector2.ZERO)


func _lift(r: Rect2, amount: float) -> Rect2:
	return r.grow_side(SIDE_BOTTOM, -amount)


## Tendido en el suelo, sobre el charco de sangre que se va extendiendo.
func _draw_body(b: Dictionary) -> void:
	var grow := clampf(b.clock / GameConfig.PED_BLOOD_GROW_S, 0.5, 1.0)
	draw_set_transform((b.pos as Vector2).round(), b.angle)
	for blob: Vector3 in b.blobs:
		draw_circle(Vector2(blob.x, blob.y) * grow, blob.z * grow + 1, GameConfig.PED_BLOOD_DARK, true, -1.0, false)
	for blob: Vector3 in b.blobs:
		draw_circle(Vector2(blob.x, blob.y) * grow, blob.z * grow, GameConfig.PED_BLOOD, true, -1.0, false)
	var legs := GameConfig.PED_BODY_LEGS
	draw_rect(legs, GameConfig.PED_LEGS)
	draw_rect(Rect2(legs.position + Vector2(0, GameConfig.PED_BODY_LEG_GAP), legs.size), GameConfig.PED_LEGS)
	draw_rect(GameConfig.PED_BODY_ARMS, GameConfig.PED_SKIN)
	draw_rect(GameConfig.PED_BODY_TORSO, b.shirt)
	draw_rect(GameConfig.PED_BODY_HEAD, b.hair)
	draw_set_transform(Vector2.ZERO)


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
