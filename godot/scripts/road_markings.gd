class_name RoadMarkings
extends Node2D
## Marcas viales de las carreteras: polilíneas de Tiled (objetos de tipo `linea`) pintadas
## sobre el asfalto. Propiedad `estilo`: "discontinua" (eje) o "continua" (bordes).

const STYLE_DASHED := "discontinua"


static func create(map: TiledMap) -> RoadMarkings:
	var marks := RoadMarkings.new()
	marks.name = "RoadMarkings"
	for o: Dictionary in map.objects:
		if o.type == GameConfig.MAP_LINE_TYPE:
			marks._lines.append(_line_of(o))
	return marks


var _lines: Array[Dictionary] = []


static func _line_of(o: Dictionary) -> Dictionary:
	var pts := PackedVector2Array()
	for p: Dictionary in o.polyline:
		pts.append(Vector2(o.x + p.x, o.y + p.y))
	var style := ""
	for p: Dictionary in o.get("properties", []):
		if p.name == "estilo":
			style = p.value
	return {"points": pts, "dashed": style == STYLE_DASHED}


func _draw() -> void:
	for line in _lines:
		var pts: PackedVector2Array = line.points
		for i in pts.size() - 1:
			if line.dashed:
				draw_dashed_line(pts[i], pts[i + 1], GameConfig.ROAD_LINE_COLOR, GameConfig.ROAD_CENTER_WIDTH, GameConfig.ROAD_DASH_PX)
			else:
				draw_line(pts[i], pts[i + 1], GameConfig.ROAD_LINE_COLOR, GameConfig.ROAD_EDGE_WIDTH)
