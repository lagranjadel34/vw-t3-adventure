class_name RoadMarkings
extends Node2D
## Marcas viales de las carreteras: polilíneas de Tiled (objetos de tipo `linea`) pintadas
## sobre el asfalto. Propiedad `estilo`: "discontinua" (eje) o "continua" (bordes).
## También los pasos de peatones (objetos `paso`): cebra y línea de detención.

const STYLE_DASHED := "discontinua"


static func create(map: TiledMap) -> RoadMarkings:
	var marks := RoadMarkings.new()
	marks.name = "RoadMarkings"
	for o: Dictionary in map.objects:
		if o.type == GameConfig.MAP_LINE_TYPE:
			marks._lines.append(_line_of(o))
		elif o.type == GameConfig.MAP_CROSSING_TYPE:
			marks._crossings.append(StreetProps.crossing_of(o))
	return marks


var _lines: Array[Dictionary] = []
var _crossings: Array[Dictionary] = []


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
	for c in _crossings:
		_draw_crossing(c)


## Franjas paralelas a la calle, de acera a acera, y la línea de detención de quien llega.
func _draw_crossing(c: Dictionary) -> void:
	var r: Rect2 = c.rect
	var dir: Vector2 = c.dir
	var along := dir.abs() # sentido de los coches
	var across := Vector2(along.y, along.x) # de acera a acera
	var length := r.size.dot(across)
	var depth := r.size.dot(along)
	var m := GameConfig.ZEBRA_MARGIN
	var stripe := along * (depth - m * 2) + across * GameConfig.ZEBRA_STRIPE
	var t := m
	while t + GameConfig.ZEBRA_STRIPE <= length - m:
		draw_rect(Rect2(r.position + along * m + across * t, stripe), GameConfig.ZEBRA_COLOR)
		t += GameConfig.ZEBRA_PERIOD
	# Línea de detención: en el carril de la derecha de quien llega, antes del paso.
	var right := Vector2(-dir.y, dir.x)
	var near := r.get_center() - dir * (depth / 2 + GameConfig.STOP_LINE_GAP)
	draw_line(near, near + right * (length / 2), GameConfig.ZEBRA_COLOR, GameConfig.ROAD_EDGE_WIDTH)

