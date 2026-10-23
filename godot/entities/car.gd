class_name Car
extends AnimatableBody2D
## Coche del tráfico: recorre su ruta (circuito cerrado por el centro del carril) y frena
## si tiene algo delante (la T3, otro coche) o un semáforo en rojo de su eje.
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
	var eje := "h" if absf(heading.x) > absf(heading.y) else "v"
	if street.light_state(eje) == "green":
		return false
	for l in street.lights:
		if l.eje != eje:
			continue
		var d: Vector2 = l.pos - global_position
		var ahead := d.dot(heading)
		if ahead > GameConfig.LIGHT_STOP_AHEAD.x and ahead < GameConfig.LIGHT_STOP_AHEAD.y and absf(d.cross(heading)) < GameConfig.LIGHT_STOP_SIDE:
			return true
	return false
