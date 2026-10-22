class_name Van
extends CharacterBody2D
## La T3. Modelo bicicleta portado de src/entities/Van.ts (versión Phaser):
## giran las ruedas delanteras y la trasera sigue la trazada mientras hay agarre.
## Si la curva pide más de lo que aguantan las ruedas (o con el freno de mano),
## la cola se va hacia fuera: motor y tracción traseros.

# Mandos que fija la escena cada frame: volante en [-1, 1] (joystick) y pedales.
var steer_input := 0.0
var gas_input := false
var brake_input := false
var handbrake_input := false

## Carga de la camperización (kg): ver GameConfig.VAN_LOAD_PRESETS_KG.
var load_kg := GameConfig.VAN_DEFAULT_LOAD_KG
## La furgo va de lado (para HUD, humo, sonido...).
var drifting := false

## Caja de cambios: la potencia depende de la marcha metida.
var gearbox := Gearbox.new()

var _trip_meters := 0.0
# Marcha atrás: solo si se pisa el freno con la furgo parada; dura mientras siga pisado.
var _reversing := false
var _brake_was_down := false
# Velocidad de lado (px/s, + = hacia la izquierda del morro). Solo existe derrapando.
var _slip := 0.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _shape: CollisionShape2D = $Shape


func _ready() -> void:
	(_shape.shape as CircleShape2D).radius = GameConfig.VAN_BODY_RADIUS


## Distancia recorrida en esta partida (km). Fuente única para cuentakilómetros, averías, etc.
var trip_km: float:
	get:
		return _trip_meters / GameConfig.METERS_PER_KM

## Velocidad con signo en el sentido del morro (px/s; negativa = marcha atrás).
var speed: float:
	get:
		return velocity.dot(_heading())

## Acelerador por teclado (W/↑).
var gas_key: bool:
	get:
		return Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)

## Freno por teclado (S/↓).
var brake_key: bool:
	get:
		return Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)

## Freno de mano por teclado (Espacio).
var handbrake_key: bool:
	get:
		return Input.is_physical_key_pressed(KEY_SPACE)

## Más carga, menos alegría: 1 con la carga por defecto.
var weight_factor: float:
	get:
		return (GameConfig.VAN_EMPTY_MASS_KG + GameConfig.VAN_DEFAULT_LOAD_KG) / (GameConfig.VAN_EMPTY_MASS_KG + load_kg)

## Teclado: E sube marcha, Q baja, M alterna automático/manual.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_E:
			gearbox.manual_shift(true)
		KEY_Q:
			gearbox.manual_shift(false)
		KEY_M:
			gearbox.set_automatic(not gearbox.automatic)


## Eje delantero en coordenadas de mundo (la cámara mira hacia donde va el morro).
var front: Vector2:
	get:
		return global_position + Vector2(0, -_length() * GameConfig.VAN_FRONT_AXLE_RATIO).rotated(rotation)


func _physics_process(delta: float) -> void:
	var left := Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
	var right := Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
	# Teclado manda; si no hay teclas pulsadas, se usa el joystick.
	var steer := -1.0 if left else (1.0 if right else steer_input)

	var spd := maxf(speed, -GameConfig.VAN_MAX_REVERSE_SPEED)
	var handbrake := handbrake_input or handbrake_key
	var weight := weight_factor

	# Modelo bicicleta: parada no gira; marcha atrás invierte el giro.
	var wheelbase := _length() * (GameConfig.VAN_FRONT_AXLE_RATIO + GameConfig.VAN_REAR_AXLE_RATIO)
	var yaw_rate := (spd / wheelbase) * tan(deg_to_rad(GameConfig.VAN_MAX_STEER_DEG) * steer)

	# Pedales: sin acelerador no hay potencia (solo rueda por inercia).
	# Freno: con la furgo parada, pisarlo mete marcha atrás (mientras siga pisado);
	# en marcha (adelante o atrás) frena hasta parar.
	var stopped := absf(spd) <= GameConfig.VAN_STOP_SPEED
	var brake_pressed := brake_input and not _brake_was_down
	_brake_was_down = brake_input
	if not brake_input:
		_reversing = false
	elif brake_pressed and stopped:
		_reversing = true

	if _reversing:
		spd -= GameConfig.VAN_REVERSE_ACCELERATION * weight * delta
	elif brake_input:
		spd = _toward_zero(spd, GameConfig.VAN_BRAKE_DECELERATION * weight * delta)
	elif handbrake:
		spd = _toward_zero(spd, GameConfig.VAN_HANDBRAKE_DECELERATION * weight * delta)
	elif gas_input and spd < Gearbox.max_speed(gearbox.gear):
		spd = minf(spd + gearbox.acceleration(spd) * weight * delta, Gearbox.max_speed(gearbox.gear))
	elif not gas_input:
		spd = _toward_zero(spd, GameConfig.VAN_DRAG * delta)
	# Pasado de vueltas (tras reducir): el motor retiene hasta el tope de la marcha.
	if not _reversing and spd > Gearbox.max_speed(gearbox.gear):
		spd = move_toward(spd, Gearbox.max_speed(gearbox.gear), GameConfig.GEAR_ENGINE_BRAKE * delta)
	gearbox.update(spd, delta)
	spd = clampf(spd, -GameConfig.VAN_MAX_REVERSE_SPEED, GameConfig.VAN_MAX_SPEED)

	# Agarre: más carga, antes se suelta la cola.
	var lateral_accel := absf(spd * yaw_rate)
	var moving := absf(spd) > GameConfig.VAN_STOP_SPEED
	var over_limit := lateral_accel > GameConfig.VAN_GRIP_LIMIT * weight
	if moving and (handbrake or over_limit):
		drifting = true
	if drifting:
		_slip = _side_speed()
		var grip := GameConfig.VAN_HANDBRAKE_GRIP if handbrake else GameConfig.VAN_DRIFT_GRIP
		if gas_input and not handbrake:
			grip *= GameConfig.VAN_DRIFT_GAS_GRIP_RATIO
		_slip *= exp(-grip * delta)
		# El peso del motor trasero sigue empujando la cola hacia fuera (hay que contravolantear).
		yaw_rate += clampf(_slip * GameConfig.VAN_DRIFT_TAIL_YAW, -GameConfig.VAN_DRIFT_MAX_TAIL_YAW, GameConfig.VAN_DRIFT_MAX_TAIL_YAW)
		# Se recupera el agarre cuando la curva ya no pide más y casi no queda velocidad de lado.
		var settled := not over_limit and absf(_slip) < GameConfig.VAN_DRIFT_END_SLIP
		if not handbrake and (settled or not moving):
			drifting = false
	if not drifting:
		# Con agarre la velocidad sigue siempre el morro (la parte que va de lado se pierde).
		_slip = 0.0

	var prev_position := global_position
	var prev_rotation := rotation
	velocity = _heading() * spd + _side() * _slip
	rotation += yaw_rate * delta
	move_and_slide()
	# Contra un muro solo queda la velocidad que de verdad se ha movido.
	velocity = get_real_velocity()
	# Derrapando la furgo gira sobre su centro: la trasera ya no va pegada a la trazada.
	if not drifting:
		_pivot_on_rear_axle(prev_rotation)

	# Distancia real recorrida (no la velocidad), así choques y paradas no suman.
	_trip_meters += global_position.distance_to(prev_position) * GameConfig.METERS_PER_PIXEL


## El cuerpo gira sobre su centro; aquí se desplaza para que el eje trasero
## no se mueva de lado: el morro marca la curva y la trasera la sigue.
func _pivot_on_rear_axle(prev_rotation: float) -> void:
	if rotation == prev_rotation:
		return
	# La trasera queda "abajo" del sprite: offset local (0, +r).
	var rear := Vector2(0, _length() * GameConfig.VAN_REAR_AXLE_RATIO)
	move_and_collide(rear.rotated(prev_rotation) - rear.rotated(rotation))


func _heading() -> Vector2:
	return Vector2.from_angle(rotation - PI / 2)


## Izquierda del morro.
func _side() -> Vector2:
	return _heading().orthogonal()


func _side_speed() -> float:
	return velocity.dot(_side())


func _length() -> float:
	return _sprite.texture.get_height() * _sprite.scale.y


static func _toward_zero(value: float, amount: float) -> float:
	return 0.0 if absf(value) <= amount else value - signf(value) * amount
