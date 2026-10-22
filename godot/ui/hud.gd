class_name Hud
extends CanvasLayer
## Capa del HUD encima del mapa, con su propia transformación: así el zoom de la cámara
## (más visión a más velocidad) no escala los mandos.

var joystick: TouchJoystick
var gas: Pedal
var brake: Pedal
var lever: GearLever

# Dedos apoyados ahora mismo: índice -> posición en pantalla.
var _touches := {}


func _ready() -> void:
	if DisplayServer.is_touchscreen_available():
		joystick = TouchJoystick.new()
		add_child(joystick)
	gas = Pedal.new(GameConfig.PEDAL_GAS)
	brake = Pedal.new(GameConfig.PEDAL_BRAKE)
	add_child(gas)
	add_child(brake)


## La palanca necesita la caja de cambios de la furgo (la pone la escena).
func add_gear_lever(gearbox: Gearbox) -> void:
	lever = GearLever.new(gearbox)
	add_child(lever)


## Volante actual (joystick o 0 si no hay pantalla táctil).
var steer: float:
	get:
		return joystick.x if joystick else 0.0


## El teclado también "pisa" los pedales para que se vea en pantalla.
func update_pedals(gas_key: bool, brake_key: bool) -> void:
	var points := _touches.values()
	gas.update_press(points, gas_key)
	brake.update_press(points, brake_key)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
