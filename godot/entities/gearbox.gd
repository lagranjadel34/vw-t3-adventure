class_name Gearbox
extends RefCounted
## Caja de 4 marchas de la T3. Automática por defecto; cualquier cambio a mano la pasa a manual.

signal shifted(from_gear: int, to_gear: int)
signal mode_changed(automatic: bool)

var gear := 1
var automatic := true
## Holgura de la caja (1 = de serie, las T3 la traen gastada; 0 = arreglada en el taller).
## De momento solo cambia el sonido: con holgura la marcha cuesta entrar.
var play := GameConfig.GEARBOX_PLAY_STOCK
# Tiempo que queda de embrague pisado tras un cambio (sin potencia).
var _clutch := 0.0


## Embrague pisado: durante el cambio no hay potencia.
var shifting: bool:
	get:
		return _clutch > 0.0


func shift_up() -> void:
	_set_gear(gear + 1)


func shift_down() -> void:
	_set_gear(gear - 1)


## Cambio pedido por el jugador: pasa a manual.
func manual_shift(up: bool) -> void:
	set_automatic(false)
	if up:
		shift_up()
	else:
		shift_down()


func set_automatic(value: bool) -> void:
	if value == automatic:
		return
	automatic = value
	mode_changed.emit(automatic)


## Tope de velocidad de una marcha (px/s).
static func max_speed(g: int) -> float:
	return GameConfig.VAN_MAX_SPEED * GameConfig.GEAR_MAX_SPEED_RATIO[g - 1]


## Cuánto retiene el motor al soltar el gas en esta marcha (multiplica VAN_DRAG).
static func coast_drag_ratio(g: int) -> float:
	return GameConfig.GEAR_COAST_DRAG_RATIO[g - 1]


## Aceleración que da el motor a esta velocidad en la marcha actual (px/s²).
func acceleration(spd: float) -> float:
	if _clutch > 0.0 or spd >= max_speed(gear):
		return 0.0
	var accel := GameConfig.VAN_ACCELERATION * GameConfig.GEAR_ACCEL_RATIO[gear - 1]
	accel *= 1.0 - GameConfig.GEAR_TORQUE_FALLOFF * clampf(spd / max_speed(gear), 0.0, 1.0)
	if gear > 1 and spd < max_speed(gear - 1) * GameConfig.GEAR_LUG_SPEED_RATIO:
		accel *= GameConfig.GEAR_LUG_ACCEL_RATIO
	return accel


## Avanza el embrague y, en automático, elige marcha según la velocidad (hacia delante).
func update(spd: float, delta: float) -> void:
	_clutch = maxf(_clutch - delta, 0.0)
	if not automatic or _clutch > 0.0:
		return
	if gear < count() and spd >= max_speed(gear) * GameConfig.GEAR_AUTO_UP_RATIO:
		shift_up()
	elif gear > 1 and spd < max_speed(gear - 1) * GameConfig.GEAR_AUTO_DOWN_RATIO:
		shift_down()


static func count() -> int:
	return GameConfig.GEAR_GATE.size()


func _set_gear(g: int) -> void:
	g = clampi(g, 1, count())
	if g == gear:
		return
	var from := gear
	gear = g
	_clutch = GameConfig.GEAR_SHIFT_TIME
	shifted.emit(from, gear)
