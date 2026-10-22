class_name TiledMap
extends RefCounted
## Carga un mapa de Tiled (JSON, un tileset) en un TileMapLayer.
## Los tiles con la propiedad `collides` reciben un cuadrado de colisión completo.

# Bits altos del gid de Tiled: volteos/rotación (no se usan, se descartan).
const GID_MASK := 0x1FFFFFFF
const ATLAS_SOURCE_ID := 0
const PHYSICS_LAYER := 0

var ground: TileMapLayer
var objects: Array = []
var size_px: Vector2


static func load_json(json_path: String, tileset_image: Texture2D, ground_layer: String, objects_layer: String, collides_property: String) -> TiledMap:
	var data: Dictionary = (load(json_path) as JSON).data
	var map := TiledMap.new()
	var tile := Vector2i(int(data.tilewidth), int(data.tileheight))
	var width := int(data.width)
	map.size_px = Vector2(width * tile.x, int(data.height) * tile.y)

	var ts: Dictionary = data.tilesets[0]
	var columns := int(ts.columns)
	var first_gid := int(ts.firstgid)
	var tile_set := TileSet.new()
	tile_set.tile_size = tile
	tile_set.add_physics_layer()
	var source := TileSetAtlasSource.new()
	source.texture = tileset_image
	source.texture_region_size = tile
	tile_set.add_source(source, ATLAS_SOURCE_ID)
	for id in int(ts.tilecount):
		source.create_tile(_atlas_coords(id, columns))

	var half := Vector2(tile) / 2
	var square := PackedVector2Array([-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)])
	for t: Dictionary in ts.get("tiles", []):
		if not _bool_property(t, collides_property):
			continue
		var tile_data := source.get_tile_data(_atlas_coords(int(t.id), columns), 0)
		tile_data.add_collision_polygon(PHYSICS_LAYER)
		tile_data.set_collision_polygon_points(PHYSICS_LAYER, 0, square)

	map.ground = TileMapLayer.new()
	map.ground.name = "Ground"
	map.ground.tile_set = tile_set
	for layer: Dictionary in data.layers:
		if layer.type == "tilelayer" and layer.name == ground_layer:
			var cells: Array = layer.data
			for i in cells.size():
				var gid := int(cells[i]) & GID_MASK
				if gid == 0:
					continue
				map.ground.set_cell(Vector2i(i % width, i / width), ATLAS_SOURCE_ID, _atlas_coords(gid - first_gid, columns))
		elif layer.type == "objectgroup" and layer.name == objects_layer:
			map.objects = layer.objects
	return map


## Primer objeto con ese nombre, o null.
func find_object(object_name: String) -> Variant:
	for o: Dictionary in objects:
		if o.name == object_name:
			return o
	return null


static func _atlas_coords(id: int, columns: int) -> Vector2i:
	return Vector2i(id % columns, id / columns)


static func _bool_property(tile: Dictionary, property: String) -> bool:
	for p: Dictionary in tile.get("properties", []):
		if p.name == property:
			return bool(p.value)
	return false
