class_name CityBuilder
extends RefCounted
## Levanta los edificios del mapa con la cámara inclinada de la T3: el tejado sube en
## pantalla la `altura` del tile y se ve la fachada sur. Cada fila de tiles es un nodo con
## Y-sort, así la furgo pasa por delante o por detrás según dónde esté.
## Los tiles con volumen llevan en Tiled: altura, tejado, fachada, detalle, patron y,
## opcionales, zocalo, remate + remate_px y aguja (ver scripts/gen-sevilla-map.mjs).

const TREE_PATTERN := "arbol"
const MERLON_PATTERN := "almenas"


## Nodo con Y-sort que contiene todas las filas de edificios.
static func build(map: TiledMap) -> Node2D:
	var root := Node2D.new()
	root.name = "Buildings"
	root.y_sort_enabled = true
	var textures := {}
	var tile := GameConfig.TILE_SIZE
	var chunk := GameConfig.CITY_CHUNK_TILES
	for ty in map.height:
		for x0 in range(0, map.width, chunk):
			var row := BuildingRow.new()
			# El nodo está en el borde inferior de la fila: ahí toca el suelo.
			row.position = Vector2(0, (ty + 1) * tile)
			row.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			_fill_row(row, map, ty, x0, mini(x0 + chunk, map.width), textures)
			if row.commands.is_empty():
				row.free()
			else:
				root.add_child(row)
	_add_spires(root, map)
	return root


static func _altura(map: TiledMap, x: int, y: int) -> int:
	return int(map.tile_props.get(map.cell(x, y), {}).get("altura", 0))


static func _fill_row(row: BuildingRow, map: TiledMap, ty: int, x_from: int, x_to: int, textures: Dictionary) -> void:
	var tile := float(GameConfig.TILE_SIZE)
	var tx := x_from
	while tx < x_to:
		var id := map.cell(tx, ty)
		var props: Dictionary = map.tile_props.get(id, {})
		var h := float(props.get("altura", 0))
		if h <= 0.0:
			tx += 1
			continue
		var facade := _altura(map, tx, ty + 1) < h
		var sunlit := _altura(map, tx, ty - 1) < h
		if props.patron == TREE_PATTERN:
			_add_tree(row, props, tx * tile + tile / 2, h)
			tx += 1
			continue
		# Tramo de tiles iguales: un rectángulo por pieza en vez de uno por tile.
		var end := tx + 1
		while end < x_to and map.cell(end, ty) == id and (_altura(map, end, ty + 1) < h) == facade and (_altura(map, end, ty - 1) < h) == sunlit:
			end += 1
		_add_block(row, props, Rect2(tx * tile, -tile, (end - tx) * tile, tile), h, facade, sunlit, textures)
		tx = end


## Tramo de edificio. `foot` = huella en el suelo (coordenadas locales de la fila).
static func _add_block(row: BuildingRow, props: Dictionary, foot: Rect2, h: float, facade: bool, sunlit: bool, textures: Dictionary) -> void:
	var roof_color: Color = props.tejado
	var roof := Rect2(foot.position - Vector2(0, h), foot.size)
	row.rect(roof, roof_color)
	if sunlit:
		row.rect(Rect2(roof.position, Vector2(roof.size.x, 1)), roof_color.lightened(GameConfig.CITY_ROOF_EDGE_LIGHTEN))
	if not facade:
		return
	var wall := Rect2(foot.position.x, foot.end.y - h, foot.size.x, h)
	row.rect(wall, props.fachada)
	var top := wall.position.y
	var bottom := wall.end.y
	if props.has("remate"):
		var band := minf(float(props.remate_px), h)
		row.rect(Rect2(wall.position.x, top, wall.size.x, band), props.remate)
		top += band
	if props.has("zocalo"):
		row.rect(Rect2(wall.position.x, bottom - GameConfig.CITY_ZOCALO_PX, wall.size.x, GameConfig.CITY_ZOCALO_PX), props.zocalo)
		bottom -= GameConfig.CITY_ZOCALO_PX
	if bottom > top:
		row.pattern(Rect2(wall.position.x, top, wall.size.x, bottom - top), _pattern_texture(GameConfig.CITY_PATTERNS[props.patron], props.detalle, textures))
	row.rect(Rect2(wall.position, Vector2(wall.size.x, 1)), roof_color.darkened(GameConfig.CITY_EAVE_DARKEN))
	if props.patron == MERLON_PATTERN:
		var m: Vector2i = GameConfig.CITY_MERLON.cell
		row.pattern(Rect2(wall.position - Vector2(0, m.y), Vector2(wall.size.x, m.y)), _pattern_texture(GameConfig.CITY_MERLON, props.detalle, textures))


static func _add_tree(row: BuildingRow, props: Dictionary, x: float, h: float) -> void:
	var ground_y := -float(GameConfig.TILE_SIZE) / 2
	var w := GameConfig.CITY_TREE_TRUNK_WIDTH
	row.rect(Rect2(x - w / 2, ground_y - h, w, h), props.fachada)
	var crown := Vector2(x, ground_y - h)
	row.circle(crown, GameConfig.CITY_TREE_CANOPY_RADIUS, props.tejado)
	row.circle(crown + GameConfig.CITY_TREE_HIGHLIGHT_OFFSET, GameConfig.CITY_TREE_HIGHLIGHT_RADIUS, props.detalle)


## Chapitel sobre cada torre con `aguja`, dibujado justo después de su última fila.
static func _add_spires(root: Node2D, map: TiledMap) -> void:
	var tile := float(GameConfig.TILE_SIZE)
	var seen := {}
	for i in map.cells.size():
		var id := map.cells[i]
		var props: Dictionary = map.tile_props.get(id, {})
		if seen.has(i) or not props.has("aguja"):
			continue
		# Huella de la torre (tiles contiguos del mismo tipo).
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
		var spire := BuildingRow.new()
		spire.position = Vector2(0, box.end.y * tile)
		var h := float(props.altura)
		var roof_center := Vector2((box.position.x + box.size.x / 2.0) * tile, (box.position.y - box.end.y + box.size.y / 2.0) * tile - h)
		var half := box.size.x * tile * GameConfig.CITY_SPIRE_BASE_RATIO / 2
		spire.polygon(PackedVector2Array([roof_center + Vector2(-half, 0), roof_center + Vector2(half, 0), roof_center - Vector2(0, GameConfig.CITY_SPIRE_HEIGHT)]), props.aguja)
		root.add_child(spire)


static func _pattern_texture(pattern: Dictionary, color: Color, cache: Dictionary) -> Texture2D:
	var key := [pattern, color]
	if not cache.has(key):
		var cell: Vector2i = pattern.cell
		var img := Image.create(cell.x, cell.y, false, Image.FORMAT_RGBA8)
		for r: Rect2i in pattern.rects:
			img.fill_rect(r, color)
		cache[key] = ImageTexture.create_from_image(img)
	return cache[key]


## Fila (o trozo de fila) de edificios: guarda lo que hay que pintar y lo pinta una vez.
class BuildingRow:
	extends Node2D

	var commands: Array = []

	func rect(r: Rect2, color: Color) -> void:
		commands.append(func() -> void: draw_rect(r, color))

	func pattern(r: Rect2, texture: Texture2D) -> void:
		commands.append(func() -> void: draw_texture_rect(texture, r, true))

	func circle(center: Vector2, radius: float, color: Color) -> void:
		commands.append(func() -> void: draw_circle(center, radius, color))

	func polygon(points: PackedVector2Array, color: Color) -> void:
		commands.append(func() -> void: draw_colored_polygon(points, color))

	func _draw() -> void:
		for c: Callable in commands:
			c.call()
