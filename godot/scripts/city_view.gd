class_name CityView
extends Node2D
## Edificios con perspectiva de cámara cenital, como GTA 1: la cámara está a
## CITY_CAMERA_HEIGHT sobre el suelo y cada punto a altura z se aleja del centro de la
## pantalla en proporción H / (H - z). Así los edificios "se abren" hacia fuera, se ven
## las fachadas que miran a la cámara y la calle por la que va la furgo nunca queda tapada.
## Los tiles con volumen llevan en Tiled: altura, tejado, fachada, detalle, patron y,
## opcionales, zocalo, remate + remate_frac y aguja (ver scripts/gen-sevilla-map.mjs).

const TREE_PATTERN := "arbol"

## Piezas por celda de culling: Vector2i -> Array de piezas (Dictionary).
var _buckets := {}
var _textures := {}
var _last_center := Vector2.INF
var _last_zoom := Vector2.ZERO
var _next_id := 0
## Sombras en el suelo (estáticas). Se añade bajo la furgo; el grupo las aplana para que
## dos sombras que se pisan no oscurezcan el doble.
var shadows := CanvasGroup.new()
var _shadow_drawer := ShadowDrawer.new()


static func create(map: TiledMap) -> CityView:
	var view := CityView.new()
	view.name = "City"
	view.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	view.shadows.name = "CityShadows"
	view.shadows.self_modulate = GameConfig.CITY_SHADOW_COLOR
	view.shadows.add_child(view._shadow_drawer)
	view._build(map)
	return view


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var center := cam.get_screen_center_position()
	if center != _last_center or cam.zoom != _last_zoom:
		_last_center = center
		_last_zoom = cam.zoom
		queue_redraw()


func _draw() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var center := cam.get_screen_center_position()
	var half := get_viewport_rect().size / cam.zoom / 2
	var view := Rect2(center - half, half * 2).grow(GameConfig.TILE_SIZE)
	var cell := GameConfig.CITY_CULL_CELL_TILES * GameConfig.TILE_SIZE
	var c0 := Vector2i((view.position / cell).floor())
	var c1 := Vector2i((view.end / cell).floor())
	var pieces: Array = []
	var seen := {}
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			for p: Dictionary in _buckets.get(Vector2i(cx, cy), []):
				if not seen.has(p.id) and p.bounds.grow(1).intersects(view):
					seen[p.id] = true
					pieces.append(p)
	# Lo bajo primero: lo alto se pinta encima. A igual altura, fachadas antes que tejados.
	pieces.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.order < b.order)
	for p: Dictionary in pieces:
		match p.kind:
			&"wall":
				_draw_wall(p, center)
			&"roof":
				_draw_roof(p, center)
			&"tree":
				_draw_tree(p, center)
			&"spire":
				_draw_spire(p, center)
			&"edge":
				draw_line(project(p.a, p.h, center), project(p.b, p.h, center), (p.props.tejado as Color).darkened(GameConfig.CITY_EAVE_DARKEN))


## Punto del mundo a altura z, tal como lo ve la cámara.
static func project(p: Vector2, z: float, center: Vector2) -> Vector2:
	return center + (p - center) * (GameConfig.CITY_CAMERA_HEIGHT / (GameConfig.CITY_CAMERA_HEIGHT - z))


func _draw_roof(p: Dictionary, center: Vector2) -> void:
	var r: Rect2 = p.rect
	var a := project(r.position, p.h, center)
	var b := project(r.end, p.h, center)
	draw_rect(Rect2(a, b - a), p.props.tejado)


func _draw_wall(p: Dictionary, center: Vector2) -> void:
	var a: Vector2 = p.a
	var b: Vector2 = p.b
	# Solo se ve si la cámara está del lado hacia el que mira la fachada.
	if (center - a).dot(p.normal) <= GameConfig.CITY_WALL_MIN_FACING:
		return
	var props: Dictionary = p.props
	var h: float = p.h
	var shade: float = p.shade
	_quad(a, b, 0.0, h, center, (props.fachada as Color).darkened(shade))
	var top := h
	var bottom := 0.0
	if props.has("remate"):
		var band := h * float(props.remate_frac)
		_quad(a, b, h - band, h, center, (props.remate as Color).darkened(shade))
		top -= band
	if props.has("zocalo"):
		bottom = minf(GameConfig.CITY_ZOCALO_HEIGHT, top)
		_quad(a, b, 0.0, bottom, center, (props.zocalo as Color).darkened(shade))
	if top > bottom:
		var pattern: Dictionary = GameConfig.CITY_PATTERNS[props.patron]
		var tex := _pattern_texture(pattern, props.detalle)
		var cell: Vector2 = Vector2(pattern.cell)
		var length := a.distance_to(b)
		var scale := GameConfig.CITY_PATTERN_SCALE
		var pts := PackedVector2Array([project(a, bottom, center), project(b, bottom, center), project(b, top, center), project(a, top, center)])
		var uvs := PackedVector2Array([
			Vector2(0, (top - bottom) * scale / cell.y), Vector2(length / cell.x, (top - bottom) * scale / cell.y),
			Vector2(length / cell.x, 0), Vector2.ZERO,
		])
		var tint := Color.WHITE.darkened(shade)
		draw_polygon(pts, PackedColorArray([tint, tint, tint, tint]), uvs, tex)


func _draw_tree(p: Dictionary, center: Vector2) -> void:
	var base: Vector2 = p.pos
	var crown := project(base, p.h, center)
	var s: float = GameConfig.CITY_CAMERA_HEIGHT / (GameConfig.CITY_CAMERA_HEIGHT - p.h)
	draw_line(base, crown, p.props.fachada, GameConfig.CITY_TREE_TRUNK_WIDTH)
	draw_circle(crown, GameConfig.CITY_TREE_CANOPY_RADIUS * s, p.props.tejado)
	draw_circle(crown + GameConfig.CITY_TREE_HIGHLIGHT_OFFSET * s, GameConfig.CITY_TREE_HIGHLIGHT_RADIUS * s, p.props.detalle)


func _draw_spire(p: Dictionary, center: Vector2) -> void:
	var r: Rect2 = p.rect
	var h: float = p.h
	var pts := PackedVector2Array()
	for corner: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		pts.append(project(corner, h, center))
	pts.append(project(r.get_center(), h + p.spire_h, center))
	var hull := Geometry2D.convex_hull(pts)
	draw_colored_polygon(hull, p.props.aguja)


func _quad(a: Vector2, b: Vector2, z0: float, z1: float, center: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([project(a, z0, center), project(b, z0, center), project(b, z1, center), project(a, z1, center)]), color)


func _pattern_texture(pattern: Dictionary, color: Color) -> Texture2D:
	var key := [pattern, color]
	if not _textures.has(key):
		var cell: Vector2i = pattern.cell
		var img := Image.create(cell.x, cell.y, false, Image.FORMAT_RGBA8)
		for r: Rect2i in pattern.rects:
			img.fill_rect(r, color)
		_textures[key] = ImageTexture.create_from_image(img)
	return _textures[key]


# --- Construcción: tejados, fachadas exteriores, árboles y chapiteles ---

func _build(map: TiledMap) -> void:
	var tile := float(GameConfig.TILE_SIZE)
	# Tejados: tramos horizontales de tiles iguales, unidos en vertical si coinciden.
	var open_runs := {}
	for ty in map.height:
		var next_open := {}
		var tx := 0
		while tx < map.width:
			var id := map.cell(tx, ty)
			var props: Dictionary = map.tile_props.get(id, {})
			if float(props.get("altura", 0)) <= 0.0:
				tx += 1
				continue
			if props.patron == TREE_PATTERN:
				_add(&"tree", Rect2(tx * tile, ty * tile, tile, tile), props, {"pos": Vector2(tx + 0.5, ty + 0.5) * tile})
				tx += 1
				continue
			var end := tx + 1
			while end < map.width and map.cell(end, ty) == id:
				end += 1
			var key := Vector3i(tx, end, id)
			var rect := Rect2(tx * tile, ty * tile, (end - tx) * tile, tile)
			if open_runs.has(key):
				rect = (open_runs[key] as Rect2).merge(rect)
			next_open[key] = rect
			tx = end
		for key: Vector3i in open_runs:
			if not next_open.has(key):
				_add(&"roof", open_runs[key], map.tile_props[key.z])
		open_runs = next_open
	for key: Vector3i in open_runs:
		_add(&"roof", open_runs[key], map.tile_props[key.z])

	# Fachadas: bordes de tile que dan a algo más bajo, unidos si siguen en línea.
	for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var along := Vector2i(absi(side.y), absi(side.x))
		var lines := map.width if side.x != 0 else map.height
		var steps := map.height if side.x != 0 else map.width
		for line in lines:
			var run_start := -1
			var run_id := -1
			for step in steps + 1:
				var t := Vector2i(line, step) if side.x != 0 else Vector2i(step, line)
				var id := map.cell(t.x, t.y) if step < steps else -1
				var props: Dictionary = map.tile_props.get(id, {})
				var h := float(props.get("altura", 0))
				var exposed: bool = h > 0.0 and props.patron != TREE_PATTERN and _altura(map, t + side) < h
				if run_start >= 0 and (not exposed or id != run_id):
					_add_wall(map, side, along, line, run_start, step, run_id)
					run_start = -1
				if exposed and run_start < 0:
					run_start = step
					run_id = id

	_add_spires(map)


func _add_wall(map: TiledMap, side: Vector2i, along: Vector2i, line: int, from: int, to: int, id: int) -> void:
	var tile := float(GameConfig.TILE_SIZE)
	# Borde del tile que mira hacia `side`.
	var origin := Vector2(line, from) if side.x != 0 else Vector2(from, line)
	if side == Vector2i.RIGHT:
		origin.x += 1
	elif side == Vector2i.DOWN:
		origin.y += 1
	var a := origin * tile
	var b := a + Vector2(along) * (to - from) * tile
	var shade: float = GameConfig.CITY_WALL_SHADE[side]
	var bounds := Rect2(a, Vector2.ZERO).expand(b)
	_add(&"wall", bounds, map.tile_props[id], {"a": a, "b": b, "normal": Vector2(side), "shade": shade})
	# Borde del tejado (alero), también por detrás: dibuja el contorno de cada edificio.
	_add(&"edge", bounds, map.tile_props[id], {"a": a, "b": b})


func _altura(map: TiledMap, t: Vector2i) -> float:
	return float(map.tile_props.get(map.cell(t.x, t.y), {}).get("altura", 0))


## Chapitel sobre cada torre con `aguja`.
func _add_spires(map: TiledMap) -> void:
	var tile := float(GameConfig.TILE_SIZE)
	var seen := {}
	for i in map.cells.size():
		var id := map.cells[i]
		var props: Dictionary = map.tile_props.get(id, {})
		if seen.has(i) or not props.has("aguja"):
			continue
		var box := Rect2i(i % map.width, i / map.width, 1, 1)
		var stack := [i]
		seen[i] = true
		while not stack.is_empty():
			var j: int = stack.pop_back()
			var p := Vector2i(j % map.width, j / map.width)
			box = box.expand(p).expand(p + Vector2i.ONE)
			for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
				var n := p + d
				var k := n.y * map.width + n.x
				if map.cell(n.x, n.y) == id and not seen.has(k):
					seen[k] = true
					stack.append(k)
		var foot := Rect2(Vector2(box.position) * tile, Vector2(box.size) * tile)
		var base := Rect2(foot.get_center(), Vector2.ZERO).grow(foot.size.x * GameConfig.CITY_SPIRE_BASE_RATIO / 2)
		_add(&"spire", foot, props, {"rect": base, "spire_h": GameConfig.CITY_SPIRE_HEIGHT})


func _add(kind: StringName, bounds: Rect2, props: Dictionary, extra := {}) -> void:
	var h := float(props.altura)
	var kind_order: int = GameConfig.CITY_DRAW_ORDER[kind]
	_next_id += 1
	var piece := {"id": _next_id, "kind": kind, "bounds": bounds, "props": props, "h": h, "order": h * GameConfig.CITY_DRAW_ORDER.size() + kind_order}
	if kind == &"roof":
		piece.rect = bounds
	piece.merge(extra)
	if kind == &"roof" or kind == &"tree":
		_shadow_drawer.add(bounds, h)
	var cell := float(GameConfig.CITY_CULL_CELL_TILES * GameConfig.TILE_SIZE)
	var c0 := Vector2i((bounds.position / cell).floor())
	var c1 := Vector2i((bounds.end / cell).floor())
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var key := Vector2i(cx, cy)
			if not _buckets.has(key):
				_buckets[key] = []
			_buckets[key].append(piece)


## Sombra de cada edificio hacia el noreste (sol de tarde por el suroeste), en negro opaco:
## la transparencia la pone el CanvasGroup.
class ShadowDrawer:
	extends Node2D

	var polygons: Array[PackedVector2Array] = []

	func add(foot: Rect2, h: float) -> void:
		var off := GameConfig.CITY_SHADOW_DIR * h * GameConfig.CITY_SHADOW_LENGTH
		var pts := PackedVector2Array()
		for corner: Vector2 in [foot.position, Vector2(foot.end.x, foot.position.y), foot.end, Vector2(foot.position.x, foot.end.y)]:
			pts.append(corner)
			pts.append(corner + off)
		polygons.append(Geometry2D.convex_hull(pts))

	func _draw() -> void:
		for poly in polygons:
			draw_colored_polygon(poly, Color.BLACK)
