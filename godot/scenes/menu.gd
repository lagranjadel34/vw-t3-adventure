extends Node2D
## Pantalla de título: fondo de acampada, hoguera, estrellas fugaces y menú (portada de MenuScene.ts).

const INTRO_SCENE := "res://scenes/intro.tscn"
const OPTIONS_SCENE := "res://scenes/options.tscn"
const GARAGE_SCENE := "res://scenes/garage.tscn"

var _press_text: Label
var _options: Array[Label] = []
var _selected := 0
var _showing_options := false
var _star_texture: Texture2D

@onready var _ui: CanvasLayer = $UI


func _ready() -> void:
	var screen := get_viewport().get_visible_rect().size
	var bg := Sprite2D.new()
	bg.texture = load(MenuConfig.BACKGROUND)
	var bg_size := bg.texture.get_size()
	bg.scale = Vector2.ONE * maxf(screen.x / bg_size.x, screen.y / bg_size.y)
	bg.position = screen / 2
	add_child(bg)

	_create_fire(bg, bg_size)
	_star_texture = UiKit.streak_texture(MenuConfig.STAR_SIZE)
	_schedule_star(randf_range(MenuConfig.STAR_FIRST_DELAY_S.x, MenuConfig.STAR_FIRST_DELAY_S.y))

	_ui.add_child(UiKit.label(MenuConfig.TITLE, UiKit.POPPINS_BOLD_ITALIC, MenuConfig.TITLE_FONT_SIZE, Color.WHITE,
		MenuConfig.TITLE_OUTLINE, Vector2(MenuConfig.MENU_X, MenuConfig.TITLE_Y), Vector2(0, 0.5)))

	var press := MenuConfig.PRESS_TEXT_TOUCH if DisplayServer.is_touchscreen_available() else MenuConfig.PRESS_TEXT_KEYS
	_press_text = UiKit.label(press, UiKit.fredoka(), MenuConfig.PRESS_FONT_SIZE, Color.WHITE, MenuConfig.PRESS_OUTLINE,
		Vector2(MenuConfig.MENU_X, screen.y - MenuConfig.PRESS_BOTTOM_OFFSET), Vector2(0, 0.5))
	_ui.add_child(_press_text)
	var blink := _press_text.create_tween().set_loops()
	blink.tween_property(_press_text, "modulate:a", 0.0, MenuConfig.PRESS_BLINK_S)
	blink.tween_property(_press_text, "modulate:a", 1.0, MenuConfig.PRESS_BLINK_S)


func _notification(what: int) -> void:
	# Botón "atrás" de Android: desde el título se sale del juego.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if not _showing_options:
			_show_options()
		elif event.physical_keycode in [KEY_UP, KEY_W]:
			_move_selection(-1)
		elif event.physical_keycode in [KEY_DOWN, KEY_S]:
			_move_selection(1)
		elif event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_confirm()
	elif event is InputEventScreenTouch and event.pressed:
		if not _showing_options:
			_show_options()
			return
		for i in _options.size():
			if _hit_rect(_options[i]).has_point(event.position):
				_set_selected(i)
				_confirm()
	elif event is InputEventMouseMotion and _showing_options:
		for i in _options.size():
			if _hit_rect(_options[i]).has_point(event.position):
				_set_selected(i)


## Hoguera sobre el fondo: el punto de diseño (320x180) se lleva a coordenadas de la imagen.
func _create_fire(bg: Sprite2D, bg_size: Vector2) -> void:
	var design := Vector2(GameConfig.GAME_WIDTH, GameConfig.GAME_HEIGHT)
	var design_scale := maxf(design.x / bg_size.x, design.y / bg_size.y)
	var on_image := (MenuConfig.FIRE_POS - design / 2) / design_scale
	var fire := UiKit.particles(UiKit.circle_texture(MenuConfig.FIRE_PARTICLE_RADIUS), MenuConfig.FIRE_FREQUENCY_S,
		MenuConfig.FIRE_LIFE_S, MenuConfig.FIRE_DIRECTION, MenuConfig.FIRE_SPREAD_DEG, MenuConfig.FIRE_SPEED,
		MenuConfig.FIRE_SCALE, MenuConfig.FIRE_ALPHA, MenuConfig.FIRE_TINTS)
	fire.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fire.emission_rect_extents = Vector2(MenuConfig.FIRE_SPREAD_X, 0)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fire.material = add
	fire.position = bg.position + on_image * bg.scale
	add_child(fire)


func _schedule_star(delay: float) -> void:
	get_tree().create_timer(delay).timeout.connect(_spawn_star)


func _spawn_star() -> void:
	var start := Vector2(randi_range(MenuConfig.STAR_START_X.x, MenuConfig.STAR_START_X.y),
		randi_range(MenuConfig.STAR_START_Y.x, MenuConfig.STAR_START_Y.y))
	var going_right := randf() < 0.5
	var dx := randi_range(MenuConfig.STAR_DX.x, MenuConfig.STAR_DX.y) * (1 if going_right else -1)
	var dy := randi_range(MenuConfig.STAR_DY.x, MenuConfig.STAR_DY.y)

	var star := Sprite2D.new()
	star.texture = _star_texture
	star.centered = false
	# Origen en la cabeza (extremo brillante); la cola queda detrás, en el sentido de la marcha.
	star.offset = Vector2(-MenuConfig.STAR_SIZE.x, -MenuConfig.STAR_SIZE.y / 2.0)
	star.rotation = atan2(dy, dx)
	star.position = start
	star.modulate.a = 0
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	star.material = add
	add_child(star)

	var t := create_tween()
	t.set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_property(star, "position", start + Vector2(dx, dy), MenuConfig.STAR_FLY_S)
	t.tween_property(star, "modulate:a", 1.0, MenuConfig.STAR_FLY_S)
	t.chain().tween_property(star, "modulate:a", 0.0, MenuConfig.STAR_FADE_S)
	t.chain().tween_callback(star.queue_free)

	_schedule_star(randf_range(MenuConfig.STAR_DELAY_S.x, MenuConfig.STAR_DELAY_S.y))


func _show_options() -> void:
	_showing_options = true
	_press_text.queue_free()
	for i in MenuConfig.OPTIONS.size():
		var y := MenuConfig.OPTIONS_Y + i * GameConfig.TAP_MIN_HEIGHT
		var option := UiKit.label(MenuConfig.OPTIONS[i], UiKit.fredoka(true), MenuConfig.OPTION_FONT_SIZE, MenuConfig.OPTION_COLOR,
			MenuConfig.OPTION_OUTLINE, Vector2(MenuConfig.MENU_X, y), Vector2(0, 0.5))
		_ui.add_child(option)
		_options.append(option)
	_set_selected(0)


## Zona de toque más grande que el texto, para dedos.
func _hit_rect(option: Label) -> Rect2:
	var center_y := option.position.y + option.size.y / 2
	return Rect2(option.position.x - MenuConfig.TAP_PADDING_X, center_y - GameConfig.TAP_MIN_HEIGHT / 2.0,
		option.size.x + MenuConfig.TAP_PADDING_X * 2, GameConfig.TAP_MIN_HEIGHT)


func _set_selected(index: int) -> void:
	_selected = index
	for i in _options.size():
		var on := i == index
		_options[i].add_theme_color_override("font_color", MenuConfig.OPTION_SELECTED_COLOR if on else MenuConfig.OPTION_COLOR)
		_options[i].scale = Vector2.ONE * (MenuConfig.OPTION_SELECTED_SCALE if on else 1.0)


func _move_selection(delta: int) -> void:
	_set_selected(posmod(_selected + delta, _options.size()))


func _confirm() -> void:
	if _selected == MenuConfig.START_OPTION:
		get_tree().change_scene_to_file(INTRO_SCENE)
	elif _selected == MenuConfig.SETTINGS_OPTION:
		get_tree().change_scene_to_file(OPTIONS_SCENE)
	elif _selected == MenuConfig.GARAGE_OPTION:
		get_tree().change_scene_to_file(GARAGE_SCENE)
	elif _selected == MenuConfig.QUIT_OPTION:
		get_tree().quit()
