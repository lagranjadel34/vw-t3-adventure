class_name OptionRows
extends RefCounted
## Filas de texto con contorno que se eligen con teclado o toque (menús del taller).
## Cada fila recuerda su posición para recolocarse cuando cambia su texto.

signal picked(index: int)

var selected := 0

var _labels: Array[Label] = []
var _anchors: Array[Vector2] = []
var _enabled: Array[bool] = []


## Añade una fila centrada en `pos` dentro de `parent`.
func add(parent: Node, text: String, pos: Vector2) -> void:
	var index := _labels.size()
	var label := UiKit.label(text, UiKit.fredoka(true), GameConfig.WORKSHOP_BUTTON_SIZE, Color.WHITE,
		GameConfig.WORKSHOP_OUTLINE, pos, Vector2(0.5, 0.5))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.gui_input.connect(_on_gui_input.bind(index))
	parent.add_child(label)
	_labels.append(label)
	_anchors.append(pos)
	_enabled.append(true)
	_layout(index)
	_refresh()


func set_text(index: int, text: String) -> void:
	_labels[index].text = text
	_layout(index)


func set_enabled(index: int, on: bool) -> void:
	_enabled[index] = on
	_refresh()


func move(delta: int) -> void:
	selected = posmod(selected + delta, _labels.size())
	_refresh()


func activate() -> void:
	if _enabled[selected]:
		picked.emit(selected)


## Zona de toque de al menos TAP_MIN_HEIGHT aunque el texto sea pequeño.
func _layout(index: int) -> void:
	var label := _labels[index]
	var min_size := label.get_minimum_size()
	label.size = Vector2(min_size.x + MenuConfig.TAP_PADDING_X * 2, maxf(min_size.y, GameConfig.TAP_MIN_HEIGHT))
	label.pivot_offset = label.size * Vector2(0.5, 0.5)
	label.position = _anchors[index] - label.pivot_offset


func _refresh() -> void:
	for i in _labels.size():
		var color := Color.WHITE
		if not _enabled[i]:
			color = GameConfig.WORKSHOP_DISABLED
		elif i == selected:
			color = MenuConfig.OPTION_SELECTED_COLOR
		_labels[i].add_theme_color_override("font_color", color)


func _on_gui_input(event: InputEvent, index: int) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		selected = index
		_refresh()
		activate()
