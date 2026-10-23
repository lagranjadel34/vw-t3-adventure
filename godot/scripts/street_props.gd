class_name StreetProps
extends Node2D
## Detalles de la calle con la misma perspectiva que los edificios (CityView.project):
## semáforos que cambian de color, farolas y los arcos de hierro del puente de Triana.

## Semáforos: [{pos: Vector2, eje: "h" | "v"}]. Los coches los consultan.
var lights: Array[Dictionary] = []
var _lamps: PackedVector2Array = []
var _bridges: Array[Rect2] = []
## Barandillas: pares de puntos (de, a) a nivel de calle.
var _rails: Array[PackedVector2Array] = []
var _bridge_texture: Texture2D
var _clock := 0.0


static func create(map: TiledMap) -> StreetProps:
	var props := StreetProps.new()
	props.name = "StreetProps"
	for o: Dictionary in map.objects_of_type(GameConfig.MAP_LIGHT_TYPE):
		props.lights.append({"pos": Vector2(o.x, o.y), "eje": TiledMap.object_property(o, "eje", "h")})
	for o: Dictionary in map.objects_of_type(GameConfig.MAP_LAMP_TYPE):
		props._lamps.append(Vector2(o.x, o.y))
	for o: Dictionary in map.objects_of_type(GameConfig.MAP_BRIDGE_ARCHES_TYPE):
		var rect := Rect2(o.x, o.y, o.width, o.height)
		props._bridges.append(rect)
		props._bridge_texture = _arches_texture(int(rect.size.x), int(TiledMap.object_property(o, "arcos", 3)))
		var x0: float = TiledMap.object_property(o, "reja_x0", rect.position.x)
		var x1: float = TiledMap.object_property(o, "reja_x1", rect.end.x)
		for key in ["reja_y0", "reja_y1"]:
			var y: float = TiledMap.object_property(o, key, rect.position.y)
			props._rails.append(PackedVector2Array([Vector2(x0, y), Vector2(x1, y)]))
	return props


## Color de un semáforo de ese eje ahora: "green", "amber" o "red".
func light_state(eje: String) -> String:
	var phase := GameConfig.LIGHT_GREEN_S + GameConfig.LIGHT_AMBER_S
	var t := fmod(_clock + (phase if eje == "v" else 0.0), phase * 2)
	if t < GameConfig.LIGHT_GREEN_S:
		return "green"
	if t < phase:
		return "amber"
	return "red"


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _draw() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var center := cam.get_screen_center_position()
	var half := get_viewport_rect().size / cam.zoom / 2
	var view := Rect2(center - half, half * 2).grow(GameConfig.TILE_SIZE * 2)

	for r in _bridges:
		if r.intersects(view):
			_draw_bridge_side(r.position, Vector2(r.end.x, r.position.y), Vector2.UP, center)
			_draw_bridge_side(Vector2(r.position.x, r.end.y), r.end, Vector2.DOWN, center)

	for rail in _rails:
		if Rect2(rail[0], Vector2.ZERO).expand(rail[1]).intersects(view):
			_draw_rail(rail[0], rail[1], center)

	for p in _lamps:
		if not view.has_point(p):
			continue
		var top := CityView.project(p, GameConfig.LAMP_HEIGHT, center)
		draw_line(p, top, GameConfig.LAMP_POLE)
		draw_circle(top, GameConfig.LAMP_RADIUS, GameConfig.LAMP_GLASS)
		draw_rect(Rect2(top - Vector2(GameConfig.LAMP_RADIUS, GameConfig.LAMP_RADIUS + 1), Vector2(GameConfig.LAMP_RADIUS * 2, 1)), GameConfig.LAMP_POLE)

	var c := GameConfig.LIGHT_COLORS
	for l in lights:
		var p: Vector2 = l.pos
		if not view.has_point(p):
			continue
		var top := CityView.project(p, GameConfig.LIGHT_POLE_HEIGHT, center)
		draw_line(p, top, c.pole)
		var box := Rect2(top - GameConfig.LIGHT_BOX / 2, GameConfig.LIGHT_BOX)
		draw_rect(box, c.box)
		var state := light_state(l.eje)
		var x := box.position.x + 1
		draw_rect(Rect2(x, box.position.y + 1, 1, 1), c.red if state == "red" else c.off)
		draw_rect(Rect2(x, box.position.y + 3, 1, 1), c.amber if state == "amber" else c.off)
		draw_rect(Rect2(x, box.position.y + 5, 1, 1), c.green if state == "green" else c.off)


## Reja de hierro: barrotes y pasamanos con la perspectiva de los edificios.
func _draw_rail(a: Vector2, b: Vector2, center: Vector2) -> void:
	var h := GameConfig.BRIDGE_RAIL_HEIGHT
	var color := GameConfig.BRIDGE_RAIL_COLOR
	var n := int(a.distance_to(b) / GameConfig.BRIDGE_RAIL_POST_SPACING)
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		draw_line(p, CityView.project(p, h, center), color)
	draw_line(CityView.project(a, h, center), CityView.project(b, h, center), color, 2.0)


## Costado del puente desde la calzada hasta el agua: solo se ve si la cámara está de ese lado.
func _draw_bridge_side(a: Vector2, b: Vector2, normal: Vector2, center: Vector2) -> void:
	if (center - a).dot(normal) <= GameConfig.CITY_WALL_EDGE_ON:
		return
	var d := -GameConfig.BRIDGE_DEPTH
	var pts := PackedVector2Array([CityView.project(a, 0, center), CityView.project(b, 0, center), CityView.project(b, d, center), CityView.project(a, d, center)])
	var uvs := PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN])
	draw_polygon(pts, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]), uvs, _bridge_texture)


## Costado del puente de Triana: tablero de hierro, pilas de piedra y arcos con la hilera
## de anillos entre el arco y la calzada, que se hacen más pequeños hacia la clave.
static func _arches_texture(width: int, arches: int) -> Texture2D:
	var h := GameConfig.BRIDGE_TEXTURE_HEIGHT
	var col := GameConfig.BRIDGE_COLORS
	var img := Image.create(width, h, false, Image.FORMAT_RGBA8)
	var deck := GameConfig.BRIDGE_DECK_ROWS
	var pier := GameConfig.BRIDGE_PIER_WIDTH
	img.fill_rect(Rect2i(0, 0, width, deck), col.iron)
	img.fill_rect(Rect2i(0, deck - 1, width, 1), col.iron_light)
	# Estribos en las orillas y pilas en el río.
	var supports: Array[int] = []
	for i in arches + 1:
		supports.append(int(round(float(i) * (width - pier) / arches)))
	for x in supports:
		img.fill_rect(Rect2i(x, deck, pier, h - deck), col.stone)
		img.fill_rect(Rect2i(x + pier - 1, deck, 1, h - deck), col.stone_dark)
	for i in arches:
		var x0 := supports[i] + pier
		var x1 := supports[i + 1]
		var mid := (x0 + x1) / 2.0
		var half_span := (x1 - x0) / 2.0
		var crown := deck + 2
		var arch_y := func(x: float) -> float:
			var u := clampf((x - mid) / half_span, -1.0, 1.0)
			return crown + (h - crown) * (1.0 - sqrt(1.0 - u * u))
		for x in range(x0, x1):
			var y := int(arch_y.call(x + 0.5))
			img.fill_rect(Rect2i(x, y, 1, mini(GameConfig.BRIDGE_ARCH_THICKNESS, h - y)), col.iron)
		# Anillos en las enjutas.
		var spacing := GameConfig.BRIDGE_RING_SPACING
		var xc := x0 + spacing / 2.0
		while xc < x1:
			var gap: float = arch_y.call(xc) - deck
			var r := minf(gap / 2.0 - 0.5, spacing / 2.0 - 1.0)
			if r >= 1.5:
				_ring(img, Vector2(xc, deck + gap / 2.0), r, col.iron_light)
			xc += spacing
	return ImageTexture.create_from_image(img)


static func _ring(img: Image, c: Vector2, r: float, color: Color) -> void:
	var steps := int(ceil(r * 8))
	for i in steps:
		var a := TAU * i / steps
		var p := Vector2i((c + Vector2(cos(a), sin(a)) * r).round())
		if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
			img.set_pixelv(p, color)
