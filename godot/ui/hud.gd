class_name Hud
extends CanvasLayer
## Capa del HUD encima del mapa, con su propia transformación: así el zoom de la cámara
## (más visión a más velocidad) no escala los mandos.

var joystick: TouchJoystick
var gas: Pedal
var brake: Pedal
var lever: GearLever

# Borde izquierdo del último botón de prueba colocado.
var _buttons_left := 0.0
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


## Botones de prueba en la esquina superior derecha, de derecha a izquierda.
func add_test_button(text: String, on_press: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", GameConfig.TEST_BUTTON_FONT_SIZE)
	b.custom_minimum_size = GameConfig.TEST_BUTTON_SIZE
	b.pressed.connect(on_press)
	add_child(b)
	b.size = b.get_combined_minimum_size()
	if _buttons_left == 0.0:
		_buttons_left = get_viewport().get_visible_rect().size.x
	_buttons_left -= b.size.x + GameConfig.TEST_BUTTON_MARGIN
	b.position = Vector2(_buttons_left, GameConfig.TEST_BUTTON_MARGIN)


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
