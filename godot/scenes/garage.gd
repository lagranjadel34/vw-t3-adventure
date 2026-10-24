extends Node2D
## Elegir camperizador: escaparate de las furgonetas de VehicleConfig, girando sobre sí
## mismas con las ruedas rodando. La elegida se guarda en Settings y es la que conduces.

const MENU_SCENE := "res://scenes/menu.tscn"
enum Row { CHOOSE, BACK }

var _index := 0
var _rows: Array[Label] = []
var _selected := Row.CHOOSE
var _name: Label
var _details: Array[Label] = []
var _prev: Label
var _next: Label
var _preview := Sprite2D.new()
var _turn_t := 0.0
var _frame := 0
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

	_ui.add_child(UiKit.label(MenuConfig.GARAGE_TITLE, UiKit.POPPINS_BOLD_ITALIC, MenuConfig.TITLE_FONT_SIZE, Color.WHITE,
		MenuConfig.TITLE_OUTLINE, Vector2(MenuConfig.MENU_X, MenuConfig.CFG_TITLE_Y), Vector2(0, 0.5)))
	_name = UiKit.label("", UiKit.fredoka(true), MenuConfig.GARAGE_NAME_FONT_SIZE, MenuConfig.OPTION_SELECTED_COLOR,
		MenuConfig.OPTION_OUTLINE, Vector2(MenuConfig.MENU_X, MenuConfig.GARAGE_NAME_Y), Vector2(0, 0.5))
	_ui.add_child(_name)

	_preview.position = Vector2(screen.x - MenuConfig.GARAGE_PREVIEW_RIGHT, MenuConfig.GARAGE_PREVIEW_Y)
	_preview.scale = Vector2.ONE * MenuConfig.GARAGE_PREVIEW_SCALE
	_preview.hframes = GameConfig.VAN_SPRITE_DIRECTIONS
	_preview.vframes = GameConfig.VAN_SPRITE_STEER_ROWS * GameConfig.VAN_SPRITE_WHEEL_FRAMES
	_ui.add_child(_preview)
	var arrow_dx := GameConfig.VAN_LENGTH_PX * MenuConfig.GARAGE_PREVIEW_SCALE / 2
	_prev = _option_label(MenuConfig.GARAGE_PREV, Vector2(_preview.position.x - arrow_dx, MenuConfig.GARAGE_ARROW_Y))
	_next = _option_label(MenuConfig.GARAGE_NEXT, Vector2(_preview.position.x + arrow_dx, MenuConfig.GARAGE_ARROW_Y))
	var several := VehicleConfig.VEHICLES.size() > 1
	_prev.visible = several
	_next.visible = several
	_ui.add_child(_prev)
	_ui.add_child(_next)

	for text in [MenuConfig.GARAGE_CHOOSE, MenuConfig.CFG_BACK]:
		var row := _option_label(text, Vector2(MenuConfig.MENU_X, _row_y(_rows.size())))
		_rows.append(row)
		_ui.add_child(row)

	for i in VehicleConfig.VEHICLES.size():
		if VehicleConfig.VEHICLES[i].id == Settings.vehicle_id:
			_index = i
	_beep.stream = Synth.clack(0.0)
	add_child(_beep)
	_show_vehicle()


func _process(delta: float) -> void:
	_turn_t += delta
	if _turn_t >= MenuConfig.GARAGE_TURN_S:
		_turn_t -= MenuConfig.GARAGE_TURN_S
		_frame += 1
		var wheel := _frame % GameConfig.VAN_SPRITE_WHEEL_FRAMES
		# Fila del volante recto (1) y el frame de rueda; columna = rumbo.
		_preview.frame_coords = Vector2i(_frame % GameConfig.VAN_SPRITE_DIRECTIONS,
			GameConfig.VAN_SPRITE_WHEEL_FRAMES + wheel)


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
				_cycle(-1)
			KEY_RIGHT, KEY_D:
				_cycle(1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_activate(_selected)
			KEY_ESCAPE, KEY_BACKSPACE:
				_back()
	elif event is InputEventScreenTouch and event.pressed:
		if _prev.visible and _hit_rect(_prev).has_point(event.position):
			_cycle(-1)
		elif _next.visible and _hit_rect(_next).has_point(event.position):
			_cycle(1)
		else:
			for i in _rows.size():
				if _row_rect(i).has_point(event.position):
					_select(i)
					_activate(i)


func _activate(row: int) -> void:
	match row:
		Row.CHOOSE:
			Settings.set_vehicle(VehicleConfig.VEHICLES[_index].id)
			_beep.play()
			_show_vehicle()
		Row.BACK:
			_back()


func _cycle(delta: int) -> void:
	if VehicleConfig.VEHICLES.size() < 2:
		return
	_index = posmod(_index + delta, VehicleConfig.VEHICLES.size())
	_beep.play()
	_show_vehicle()


func _show_vehicle() -> void:
	var v: Dictionary = VehicleConfig.VEHICLES[_index]
	_name.text = "%s (%d)" % [v.nombre, v.anio] if v.has("anio") else v.nombre
	_name.size = _name.get_minimum_size()
	for d in _details:
		d.queue_free()
	_details.clear()
	for i in v.detalle.size():
		var line := UiKit.label(v.detalle[i], UiKit.fredoka(false), MenuConfig.GARAGE_DETAIL_FONT_SIZE, MenuConfig.CFG_SECTION_COLOR,
			MenuConfig.OPTION_OUTLINE, Vector2(MenuConfig.MENU_X, MenuConfig.GARAGE_DETAIL_Y + i * MenuConfig.GARAGE_DETAIL_LINE),
			Vector2(0, 0.5))
		_details.append(line)
		_ui.add_child(line)
	_preview.texture = load(v.sprites % [0, ""])
	var chosen: bool = v.id == Settings.vehicle_id
	_rows[Row.CHOOSE].text = MenuConfig.GARAGE_CHOSEN if chosen else MenuConfig.GARAGE_CHOOSE
	_rows[Row.CHOOSE].size = _rows[Row.CHOOSE].get_minimum_size()
	_refresh()


func _back() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)


func _select(row: int) -> void:
	_selected = row as Row
	_refresh()


func _refresh() -> void:
	for i in _rows.size():
		var on := i == _selected
		_rows[i].add_theme_color_override("font_color", MenuConfig.OPTION_SELECTED_COLOR if on else MenuConfig.OPTION_COLOR)


func _row_y(i: int) -> float:
	return MenuConfig.GARAGE_ROWS_Y + i * GameConfig.TAP_MIN_HEIGHT


func _option_label(text: String, pos: Vector2) -> Label:
	return UiKit.label(text, UiKit.fredoka(true), MenuConfig.OPTION_FONT_SIZE, MenuConfig.OPTION_COLOR,
		MenuConfig.OPTION_OUTLINE, pos, Vector2(0, 0.5))


## Fila entera hasta el escaparate: para tocar Elegir o Volver.
func _row_rect(i: int) -> Rect2:
	return Rect2(0, _row_y(i) - GameConfig.TAP_MIN_HEIGHT / 2.0, _prev.position.x, GameConfig.TAP_MIN_HEIGHT)


func _hit_rect(l: Label) -> Rect2:
	var center := l.position + l.size / 2
	var side := maxf(GameConfig.TAP_MIN_HEIGHT, l.size.x + MenuConfig.TAP_PADDING_X * 2)
	return Rect2(center - Vector2(side, GameConfig.TAP_MIN_HEIGHT) / 2, Vector2(side, GameConfig.TAP_MIN_HEIGHT))
