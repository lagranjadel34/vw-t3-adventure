class_name ObjectiveBox
extends CanvasLayer
## Recuadro con el objetivo al empezar la partida. No pausa el juego: se va al tocar la
## pantalla, al pulsar una tecla o solo al cabo de unos segundos.

signal closed

var _panel := PanelContainer.new()
var _closing := false


static func create() -> ObjectiveBox:
	var box := ObjectiveBox.new()
	box.layer = GameConfig.OBJECTIVE_LAYER
	return box


func _ready() -> void:
	var cx := get_viewport().get_visible_rect().size.x / 2
	var style := StyleBoxFlat.new()
	style.bg_color = GameConfig.OBJECTIVE_BG
	style.border_color = GameConfig.OBJECTIVE_BORDER
	style.set_border_width_all(GameConfig.OBJECTIVE_BORDER_W)
	style.set_corner_radius_all(GameConfig.OBJECTIVE_RADIUS)
	style.set_content_margin_all(GameConfig.OBJECTIVE_PADDING)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", int(GameConfig.OBJECTIVE_GAP))
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(column)

	var title := _text(GameConfig.OBJECTIVE_TITLE, UiKit.fredoka(true), GameConfig.OBJECTIVE_TITLE_SIZE, GameConfig.OBJECTIVE_BORDER)
	column.add_child(title)
	var who := Settings.player_name
	var goal := GameConfig.OBJECTIVE_TEXT_NAMED % who if who != "" else GameConfig.OBJECTIVE_TEXT
	var text := _text(goal, UiKit.fredoka(), GameConfig.OBJECTIVE_TEXT_SIZE, Color.WHITE)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = GameConfig.OBJECTIVE_WIDTH - GameConfig.OBJECTIVE_PADDING * 2
	column.add_child(text)
	var hint_text := GameConfig.OBJECTIVE_HINT_TOUCH if DisplayServer.is_touchscreen_available() else GameConfig.OBJECTIVE_HINT_KEYS
	var hint := _text(hint_text, UiKit.fredoka(), GameConfig.OBJECTIVE_HINT_SIZE, Color.WHITE)
	hint.modulate.a = GameConfig.OBJECTIVE_HINT_ALPHA
	column.add_child(hint)

	add_child(_panel)
	_panel.reset_size()
	_panel.position = Vector2(cx - _panel.size.x / 2, GameConfig.OBJECTIVE_Y)
	_panel.modulate.a = 0.0
	# El primer fotograma tras cargar el mapa trae un delta enorme: se espera a que pase.
	await get_tree().process_frame
	await get_tree().process_frame
	var t := create_tween()
	t.tween_interval(GameConfig.OBJECTIVE_DELAY_S)
	t.tween_property(_panel, "modulate:a", 1.0, GameConfig.OBJECTIVE_FADE_S)
	t.tween_interval(GameConfig.OBJECTIVE_SHOW_S)
	t.tween_callback(close)


func _text(s: String, font: Font, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Cualquier toque o tecla lo cierra, sin quitarle la pulsación al juego (pedales, volante).
func _input(event: InputEvent) -> void:
	if _panel.modulate.a <= 0.0:
		return
	if (event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey) and event.pressed:
		close()


func close() -> void:
	if _closing:
		return
	_closing = true
	var t := create_tween()
	t.tween_property(_panel, "modulate:a", 0.0, GameConfig.OBJECTIVE_FADE_S)
	t.tween_callback(func() -> void:
		closed.emit()
		queue_free())
