class_name Traffic
extends Node2D
## Pocos coches, cada uno en su ruta del mapa (objetos "ruta" con la propiedad `coches`).


static func create(map: TiledMap, van: Node2D, street: StreetProps) -> Traffic:
	var traffic := Traffic.new()
	traffic.name = "Traffic"
	var texture: Texture2D = load(GameConfig.CAR_SPRITES)
	var rng := RandomNumberGenerator.new()
	var obstacles: Array[Node2D] = [van]
	var cars: Array[Car] = []
	var n := 0
	for o: Dictionary in map.objects_of_type(GameConfig.MAP_ROUTE_TYPE):
		var points := PackedVector2Array()
		for p: Dictionary in o.polyline:
			points.append(Vector2(o.x + p.x, o.y + p.y))
		var count := int(TiledMap.object_property(o, "coches", 1))
		var total := Car.route_length(points)
		for i in count:
			var car := Car.new()
			car.setup(points, total * i / count + rng.randf() * GameConfig.CAR_STOP_DISTANCE, n % GameConfig.CAR_MODELS, texture)
			car.street = street
			cars.append(car)
			obstacles.append(car)
			traffic.add_child(car)
			n += 1
	for car in cars:
		car.obstacles = obstacles
	return traffic
