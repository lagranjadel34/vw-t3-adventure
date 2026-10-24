class_name WorkshopMenu
extends CanvasLayer
## Menú del taller (provisional): nombre, lo que habrá y "Salir del taller".
## Se muestra con el juego en pausa; avisa con `closed` al salir (toque, Enter o atrás).

signal closed

var _button: Label


static func create(title: String) -> WorkshopMenu:
	var menu := WorkshopMenu.new()
	menu.layer = GameConfig.WORKSHOP_LAYER
	menu.process_mode = Node.PROCESS_MODE_ALWAYS
	menu._title = title
	return menu


var _title := ""


func _ready() -> void:
	_build(_title)


func _build(title: String) -> void:
	var dim := ColorRect.new()
	dim.color = GameConfig.WORKSHOP_DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	# Centrado en lo que se ve (en móviles anchos la pantalla mide más de 320).
	var cx := get_viewport().get_visible_rect().size.x / 2
	add_child(UiKit.label(title, UiKit.POPPINS_BOLD_ITALIC, GameConfig.WORKSHOP_TITLE_SIZE, GameConfig.WORKSHOP_ACCENT,
		GameConfig.WORKSHOP_OUTLINE, Vector2(cx, GameConfig.WORKSHOP_TITLE_Y), Vector2(0.5, 0.5)))
	var text := UiKit.label(GameConfig.WORKSHOP_TEXT, UiKit.fredoka(), GameConfig.WORKSHOP_TEXT_SIZE, Color.WHITE,
		GameConfig.WORKSHOP_OUTLINE, Vector2(cx, GameConfig.WORKSHOP_TEXT_Y), Vector2(0.5, 0.5))
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(text)
	_button = UiKit.label(GameConfig.WORKSHOP_BUTTON, UiKit.fredoka(true), GameConfig.WORKSHOP_BUTTON_SIZE, Color.WHITE,
		GameConfig.WORKSHOP_OUTLINE, Vector2(cx, GameConfig.WORKSHOP_BUTTON_Y), Vector2(0.5, 0.5))
	# Zona de toque cómoda aunque el texto sea pequeño.
	var grow := maxf(0.0, (GameConfig.TAP_MIN_HEIGHT - _button.size.y) / 2)
	_button.position.y -= grow
	_button.size.y += grow * 2
	_button.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_button.gui_input.connect(_on_button_input)
	add_child(_button)


func _on_button_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		close()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		close()


func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	queue_free()
