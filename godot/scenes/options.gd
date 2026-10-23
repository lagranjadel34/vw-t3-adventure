extends Node2D
## Configuración > Sonido: volumen general (- / +) y silencio. Se guarda al cambiar.

const MENU_SCENE := "res://scenes/menu.tscn"
enum Row { VOLUME, MUTE, BACK }

var _rows: Array[Label] = []
var _selected := Row.VOLUME
var _mute_value: Label
var _minus: Label
var _plus: Label
var _bar: Array[ColorRect] = []
var _beep := AudioStreamPlayer.new()

@onready var _ui: CanvasLayer = $UI


func _ready() -> void:
	var screen := get_viewport().get_visible_rect().size
	var bg := Sprite2D.new()
	bg.texture = load(MenuConfig.BACKGROUND)
	var bg_size := bg.texture.get_size()
	bg.scale = Vector2.ONE * maxf(screen.x / bg_size.x, screen.y / bg_size.y)
	bg.position = screen / 2
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = MenuConfig.CFG_DIM
	dim.size = screen
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(dim)

	_ui.add_child(UiKit.label(MenuConfig.CFG_TITLE, UiKit.POPPINS_BOLD_ITALIC, MenuConfig.TITLE_FONT_SIZE, Color.WHITE,
		MenuConfig.TITLE_OUTLINE, Vector2(MenuConfig.MENU_X, MenuConfig.CFG_TITLE_Y), Vector2(0, 0.5)))
	_ui.add_child(UiKit.label(MenuConfig.CFG_SECTION, UiKit.fredoka(true), MenuConfig.OPTION_FONT_SIZE, MenuConfig.CFG_SECTION_COLOR,
		MenuConfig.OPTION_OUTLINE, Vector2(MenuConfig.MENU_X, MenuConfig.CFG_SECTION_Y), Vector2(0, 0.5)))

	for text in [MenuConfig.CFG_VOLUME, MenuConfig.CFG_MUTE, MenuConfig.CFG_BACK]:
		var row := _option_label(text, Vector2(MenuConfig.MENU_X, _row_y(_rows.size())))
		_rows.append(row)
		_ui.add_child(row)

	var vy := _row_y(Row.VOLUME)
	_minus = _option_label(MenuConfig.CFG_MINUS, Vector2(MenuConfig.CFG_VALUE_X, vy))
	_ui.add_child(_minus)
	for i in AudioConfig.VOLUME_STEPS:
		var step := ColorRect.new()
		step.size = Vector2(MenuConfig.CFG_BAR_STEP_W - MenuConfig.CFG_BAR_GAP, MenuConfig.CFG_BAR_H)
		step.position = Vector2(MenuConfig.CFG_BAR_X + i * MenuConfig.CFG_BAR_STEP_W, vy - MenuConfig.CFG_BAR_H / 2)
		step.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bar.append(step)
		_ui.add_child(step)
	var plus_x := MenuConfig.CFG_BAR_X + AudioConfig.VOLUME_STEPS * MenuConfig.CFG_BAR_STEP_W + MenuConfig.CFG_BAR_STEP_W
	_plus = _option_label(MenuConfig.CFG_PLUS, Vector2(plus_x, vy))
	_ui.add_child(_plus)
	_mute_value = _option_label("", Vector2(MenuConfig.CFG_VALUE_X, _row_y(Row.MUTE)))
	_ui.add_child(_mute_value)

	_beep.stream = Synth.clack(0.0)
	add_child(_beep)
	_refresh()


func _notification(what: int) -> void:
	# Botón "atrás" de Android.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_UP, KEY_W:
				_select(posmod(_selected - 1, _rows.size()))
			KEY_DOWN, KEY_S:
				_select(posmod(_selected + 1, _rows.size()))
			KEY_LEFT, KEY_A:
				if _selected == Row.VOLUME:
					_change_volume(-1)
			KEY_RIGHT, KEY_D:
				if _selected == Row.VOLUME:
					_change_volume(1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_activate(_selected)
			KEY_ESCAPE, KEY_BACKSPACE:
				_back()
	elif event is InputEventScreenTouch and event.pressed:
		if _hit_rect(_minus).has_point(event.position):
			_select(Row.VOLUME)
			_change_volume(-1)
		elif _hit_rect(_plus).has_point(event.position):
			_select(Row.VOLUME)
			_change_volume(1)
		else:
			for i in _rows.size():
				if _row_rect(i).has_point(event.position):
					_select(i)
					_activate(i)


func _activate(row: int) -> void:
	match row:
		Row.MUTE:
			Settings.set_muted(not Settings.muted)
			_refresh()
			_beep.play()
		Row.BACK:
			_back()


func _change_volume(delta: int) -> void:
	Settings.set_volume(Settings.volume + delta)
	_refresh()
	_beep.play()


func _back() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)


func _select(row: int) -> void:
	_selected = row as Row
	_refresh()


func _refresh() -> void:
	for i in _rows.size():
		var on := i == _selected
		_rows[i].add_theme_color_override("font_color", MenuConfig.OPTION_SELECTED_COLOR if on else MenuConfig.OPTION_COLOR)
	for i in _bar.size():
		_bar[i].color = MenuConfig.CFG_BAR_ON if i < Settings.volume and not Settings.muted else MenuConfig.CFG_BAR_OFF
	_mute_value.text = MenuConfig.CFG_YES if Settings.muted else MenuConfig.CFG_NO
	_mute_value.size = _mute_value.get_minimum_size()


func _row_y(i: int) -> float:
	return MenuConfig.CFG_ROWS_Y + i * GameConfig.TAP_MIN_HEIGHT


func _option_label(text: String, pos: Vector2) -> Label:
	return UiKit.label(text, UiKit.fredoka(true), MenuConfig.OPTION_FONT_SIZE, MenuConfig.OPTION_COLOR,
		MenuConfig.OPTION_OUTLINE, pos, Vector2(0, 0.5))


## Fila entera (de la izquierda hasta los valores): para tocar Silencio o Volver.
func _row_rect(i: int) -> Rect2:
	return Rect2(0, _row_y(i) - GameConfig.TAP_MIN_HEIGHT / 2.0, MenuConfig.CFG_BAR_X, GameConfig.TAP_MIN_HEIGHT)


func _hit_rect(l: Label) -> Rect2:
	var center := l.position + l.size / 2
	var side := maxf(GameConfig.TAP_MIN_HEIGHT, l.size.x + MenuConfig.TAP_PADDING_X * 2)
	return Rect2(center - Vector2(side, GameConfig.TAP_MIN_HEIGHT) / 2, Vector2(side, GameConfig.TAP_MIN_HEIGHT))
