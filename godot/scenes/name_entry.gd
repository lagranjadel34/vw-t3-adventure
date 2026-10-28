extends Node2D
## Escribe tu nombre: el personaje no tiene nombre fijo. Sale al pulsar Empezar, antes de la
## intro; el nombre se guarda en Settings y se usa en toda la partida. Esc o "atrás" vuelven al menú.

const INTRO_SCENE := "res://scenes/intro.tscn"
const MENU_SCENE := "res://scenes/menu.tscn"

@onready var _ui: CanvasLayer = $UI

var _field := LineEdit.new()
var _field_x: float
var _start_rect: Rect2
var _back_rect: Rect2


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

	var cx := screen.x / 2
	_ui.add_child(UiKit.label(MenuConfig.NAME_TITLE, UiKit.POPPINS_BOLD_ITALIC, MenuConfig.TITLE_FONT_SIZE, Color.WHITE,
		MenuConfig.TITLE_OUTLINE, Vector2(cx, MenuConfig.NAME_TITLE_Y), Vector2(0.5, 0.5)))

	var box := StyleBoxFlat.new()
	box.bg_color = MenuConfig.NAME_FIELD_BG
	box.border_color = MenuConfig.NAME_FIELD_BORDER
	box.set_border_width_all(MenuConfig.NAME_FIELD_BORDER_W)
	box.set_content_margin_all(MenuConfig.NAME_FIELD_PADDING)
	for style in ["normal", "focus", "read_only"]:
		_field.add_theme_stylebox_override(style, box)
	_field.add_theme_font_override("font", UiKit.fredoka(true))
	_field.add_theme_font_size_override("font_size", MenuConfig.NAME_FONT_SIZE)
	_field.add_theme_color_override("font_color", Color.WHITE)
	_field.add_theme_color_override("font_placeholder_color", MenuConfig.CFG_SECTION_COLOR)
	_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_field.max_length = MenuConfig.NAME_MAX_LENGTH
	_field.placeholder_text = MenuConfig.NAME_HINT
	_field.text = Settings.player_name
	_field.size = MenuConfig.NAME_FIELD_SIZE
	_field_x = cx - MenuConfig.NAME_FIELD_SIZE.x / 2
	_field.position = Vector2(_field_x, MenuConfig.NAME_FIELD_Y)
	_field.text_submitted.connect(func(_t: String) -> void: _confirm())
	_ui.add_child(_field)

	_start_rect = _option(MenuConfig.NAME_START, MenuConfig.OPTION_SELECTED_COLOR, Vector2(cx, MenuConfig.NAME_START_Y))
	_back_rect = _option(MenuConfig.CFG_BACK, MenuConfig.OPTION_COLOR, Vector2(cx, MenuConfig.NAME_BACK_Y))
	_field.grab_focus()
	_field.caret_column = _field.text.length()


## Opción centrada con zona de toque de al menos TAP_MIN_HEIGHT de alto.
func _option(text: String, color: Color, pos: Vector2) -> Rect2:
	var l := UiKit.label(text, UiKit.fredoka(true), MenuConfig.OPTION_FONT_SIZE, color, MenuConfig.OPTION_OUTLINE, pos, Vector2(0.5, 0.5))
	_ui.add_child(l)
	return Rect2(l.position.x - MenuConfig.TAP_PADDING_X, pos.y - GameConfig.TAP_MIN_HEIGHT / 2.0,
		l.size.x + MenuConfig.TAP_PADDING_X * 2, GameConfig.TAP_MIN_HEIGHT)


func _notification(what: int) -> void:
	# Botón "atrás" de Android.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()


func _input(event: InputEvent) -> void:
	# En _input y no en _unhandled_input: con el campo enfocado, el teclado se lo queda él.
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_back()


func _unhandled_input(event: InputEvent) -> void:
	var at: Variant = null
	if event is InputEventScreenTouch and event.pressed:
		at = event.position
	elif event is InputEventMouseButton and event.pressed:
		at = event.position
	if at == null:
		return
	if _start_rect.has_point(at):
		_confirm()
	elif _back_rect.has_point(at):
		_back()


func _confirm() -> void:
	var typed := _field.text.strip_edges()
	if typed.is_empty():
		_shake()
		return
	Settings.set_player_name(typed)
	get_tree().change_scene_to_file(INTRO_SCENE)


func _shake() -> void:
	var t := _field.create_tween()
	for dx in [MenuConfig.NAME_SHAKE_PX, -MenuConfig.NAME_SHAKE_PX, 0.0]:
		t.tween_property(_field, "position:x", _field_x + dx, MenuConfig.NAME_SHAKE_S / 3)
	_field.grab_focus()


func _back() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
