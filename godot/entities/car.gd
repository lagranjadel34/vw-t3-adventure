class_name Car
extends AnimatableBody2D
## Coche del tráfico: recorre su ruta (circuito cerrado por el centro del carril) y frena
## si tiene algo delante (la T3, otro coche), un paso de peatones con su semáforo en rojo
## o alguien cruzando.
## No gira el cuerpo: el sprite elige el frame según el rumbo, como la T3.

var route: PackedVector2Array
var model := 0
## Distancia recorrida sobre la ruta (px).
var s := 0.0
var speed := 0.0
var heading := Vector2.RIGHT
## Lo que puede cortarle el paso: la furgo y los demás coches (los pone Traffic).
var obstacles: Array[Node2D] = []
var street: StreetProps

var _lengths := PackedFloat32Array()
var _total := 0.0
var _sprite := Sprite2D.new()


func setup(points: PackedVector2Array, start: float, car_model: int, texture: Texture2D) -> void:
	route = points
	model = car_model
	_lengths.append(0.0)
	for i in route.size():
		_total += route[i].distance_to(route[(i + 1) % route.size()])
		_lengths.append(_total)
	s = start
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = GameConfig.CAR_RADIUS
	shape.shape = circle
	add_child(shape)
	_sprite.texture = texture
	_sprite.hframes = GameConfig.CAR_SPRITE_DIRECTIONS
	_sprite.vframes = GameConfig.CAR_MODELS
	_sprite.offset = GameConfig.CAR_SPRITE_OFFSET
	add_child(_sprite)
	position = point_at(s)
	_update_heading()


## Largo del circuito cerrado (px).
static func route_length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in points.size():
		total += points[i].distance_to(points[(i + 1) % points.size()])
	return total


## Punto de la ruta a esa distancia (da la vuelta al circuito).
func point_at(dist: float) -> Vector2:
	var d := fposmod(dist, _total)
	var i := _lengths.bsearch(d, false) - 1
	i = clampi(i, 0, route.size() - 1)
	var a := route[i]
	var b := route[(i + 1) % route.size()]
	var seg := _lengths[i + 1] - _lengths[i]
	return a.lerp(b, (d - _lengths[i]) / seg) if seg > 0.0 else a


func _physics_process(delta: float) -> void:
	var target := 0.0 if _blocked() else GameConfig.CAR_SPEED
	var rate := GameConfig.CAR_ACCEL if target > speed else GameConfig.CAR_BRAKE
	speed = move_toward(speed, target, rate * delta)
	s += speed * delta
	position = point_at(s)
	_update_heading()


func _update_heading() -> void:
	var ahead := point_at(s + GameConfig.CAR_STEER_LOOKAHEAD) - position
	if ahead.length_squared() > 0.01:
		heading = ahead.normalized()
	var step := TAU / GameConfig.CAR_SPRITE_DIRECTIONS
	var column := int(round(wrapf(heading.angle(), 0.0, TAU) / step)) % GameConfig.CAR_SPRITE_DIRECTIONS
	_sprite.frame = model * GameConfig.CAR_SPRITE_DIRECTIONS + column


func _blocked() -> bool:
	for o in obstacles:
		if o == self:
			continue
		var d := o.global_position - global_position
		var ahead := d.dot(heading)
		if ahead > 0.0 and ahead < GameConfig.CAR_STOP_DISTANCE and absf(d.cross(heading)) < GameConfig.CAR_STOP_HALF_WIDTH:
			return true
	if street == null:
		return false
	for c in street.crossings:
		if _stops_at(c):
			return true
	return false


## ¿Tiene que parar antes de este paso? Mide, a lo largo de la calle (no del rumbo, que
## baila en las curvas de la ruta), lo que le falta al morro para llegar a la línea.
func _stops_at(c: Dictionary) -> bool:
	var toward := heading.dot(c.dir)
	if absf(toward) < GameConfig.CROSSING_INCOMING_DOT:
		return false
	var axis: Vector2 = c.dir if toward > 0.0 else -c.dir
	var r: Rect2 = c.rect
	var d := r.get_center() - global_position
	if absf(d.cross(axis)) > absf(r.size.dot(axis.orthogonal())) / 2.0:
		return false
	var depth := absf(r.size.dot(axis)) / 2.0
	var gap := d.dot(axis) - depth - GameConfig.CROSSING_FRONT
	# Alguien cruzando delante: se espera aunque el semáforo esté en verde.
	if c.busy and gap > -depth * 2.0 - GameConfig.CROSSING_FRONT and gap < GameConfig.CAR_STOP_DISTANCE:
		return true
	# El semáforo es de quien llega al cruce, no de quien sale de él.
	if toward < 0.0:
		return false
	var stop_d := speed * speed / (2.0 * GameConfig.CAR_BRAKE)
	if gap < -GameConfig.CROSSING_STOP_MARGIN or gap > stop_d + GameConfig.CROSSING_STOP_MARGIN:
		return false
	match street.light_state(c.eje):
		"green":
			return false
		"amber":
			return gap > stop_d * GameConfig.CROSSING_AMBER_COMMIT
	return true
