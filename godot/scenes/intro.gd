extends Node2D
## Intro con viñetas: pan/zoom de imagen, texto a máquina, humo, bocinas y neblina (portada de IntroScene.ts).

const PLAY_SCENE := "res://scenes/world.tscn"

var _panel_index := 0
var _typing := false
var _finished := false
var _transitioning := false
var _shake_left := 0.0
var _smoke_texture: Texture2D
var _skip_rect: Rect2
var _content_origin: Vector2

@onready var _content: Node2D = $Content
@onready var _panel_layer: Node2D = $Content/Panel
@onready var _ui: CanvasLayer = $UI
@onready var _type_timer: Timer = $TypeTimer
@onready var _advance_timer: Timer = $AdvanceTimer
@onready var _horn_timer: Timer = $HornTimer

var _narration: Label
var _fade: ColorRect
var _fade_tween: Tween


func _ready() -> void:
	var screen := get_viewport().get_visible_rect().size
	# El diseño es de 320 de ancho: en pantallas más anchas se centra.
	_content.position.x = (screen.x - GameConfig.GAME_WIDTH) / 2
	_content_origin = _content.position

	var box_y := screen.y - IntroConfig.TEXT_BOX_HEIGHT
	var box := ColorRect.new()
	box.color = Color.BLACK
	box.position = Vector2(0, box_y)
	box.size = Vector2(screen.x, IntroConfig.TEXT_BOX_HEIGHT)
	_ui.add_child(box)

	_narration = UiKit.label("", UiKit.fredoka(), IntroConfig.TEXT_FONT_SIZE, Color.WHITE, 0,
		Vector2(_content.position.x + IntroConfig.TEXT_PADDING, box_y + IntroConfig.TEXT_PADDING))
	_narration.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_narration.size.x = GameConfig.GAME_WIDTH - IntroConfig.TEXT_PADDING * 2
	_ui.add_child(_narration)

	var skip_text := IntroConfig.SKIP_TEXT_TOUCH if DisplayServer.is_touchscreen_available() else IntroConfig.SKIP_TEXT_KEYS
	var skip := UiKit.label(skip_text, UiKit.fredoka(), IntroConfig.SKIP_FONT_SIZE, Color.WHITE, IntroConfig.SKIP_OUTLINE,
		Vector2(screen.x - IntroConfig.SKIP_PADDING_X, GameConfig.TAP_MIN_HEIGHT / 2.0), Vector2(1, 0.5))
	skip.modulate.a = IntroConfig.SKIP_ALPHA
	_ui.add_child(skip)
	# Zona de toque más grande que el texto, para dedos.
	_skip_rect = Rect2(skip.position.x - IntroConfig.SKIP_PADDING_X, 0,
		skip.size.x + IntroConfig.SKIP_PADDING_X * 2, GameConfig.TAP_MIN_HEIGHT)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.size = screen
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_fade)

	_smoke_texture = UiKit.circle_texture(IntroConfig.SMOKE_TEXTURE_RADIUS)
	_type_timer.wait_time = IntroConfig.TYPE_DELAY_S
	_type_timer.timeout.connect(_type_next)
	_advance_timer.wait_time = IntroConfig.AUTO_ADVANCE_S
	_advance_timer.timeout.connect(_next_panel)
	_horn_timer.wait_time = IntroConfig.HORN_INTERVAL_S
	_horn_timer.timeout.connect(_spawn_horn)

	_show_panel()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_finish()
		elif event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_handle_advance()
	elif event is InputEventScreenTouch and event.pressed:
		# Tocar en cualquier sitio (salvo el botón SALTAR) avanza.
		if _skip_rect.has_point(event.position):
			_finish()
		else:
			_handle_advance()


func _process(delta: float) -> void:
	if _shake_left <= 0:
		return
	_shake_left -= delta
	var amount := get_viewport().get_visible_rect().size * IntroConfig.HORN_SHAKE_INTENSITY
	var offset := Vector2(randf_range(-amount.x, amount.x), randf_range(-amount.y, amount.y))
	_content.position = _content_origin + (offset if _shake_left > 0 else Vector2.ZERO)


func _show_panel() -> void:
	_transitioning = false
	var panel: Dictionary = IntroConfig.PANELS[_panel_index]
	_horn_timer.stop()
	for child in _panel_layer.get_children():
		child.queue_free() # sus tweens mueren con ellos

	var panel_height := GameConfig.GAME_HEIGHT - IntroConfig.TEXT_BOX_HEIGHT
	_panel_layer.add_child(_rect(Rect2(0, 0, GameConfig.GAME_WIDTH, panel_height), panel.bg))
	for s: Dictionary in panel.shapes:
		_panel_layer.add_child(_rect(s.rect, s.color))
		if s.has("label"):
			_panel_layer.add_child(UiKit.label(s.label, UiKit.fredoka(), IntroConfig.LABEL_FONT_SIZE, Color.WHITE,
				IntroConfig.LABEL_OUTLINE, s.rect.get_center(), Vector2(0.5, 0.5)))

	if panel.has("image"):
		_add_panel_image(panel.image)
	if panel.get("haze", false):
		var haze := _rect(Rect2(0, 0, GameConfig.GAME_WIDTH, panel_height), Color(IntroConfig.HAZE_COLOR, 0))
		_panel_layer.add_child(haze)
		var duration: float = panel.image.duration if panel.has("image") else IntroConfig.HAZE_DEFAULT_S
		haze.create_tween().tween_property(haze, "color:a", IntroConfig.HAZE_MAX_ALPHA, duration)
	if panel.has("horns"):
		_horn_timer.start()

	_tween_fade(0.0)
	_type_text(panel.text)


## El escenario (imagen + humo) se mueve y escala como un solo bloque.
func _add_panel_image(img: Dictionary) -> void:
	var stage := Node2D.new()
	stage.position = img.from
	stage.scale = Vector2.ONE * img.from_scale
	var sprite := Sprite2D.new()
	sprite.texture = load(img.file)
	stage.add_child(sprite)
	_panel_layer.add_child(stage)

	var half: Vector2 = sprite.texture.get_size() / 2
	for exhaust: Vector2 in img.get("exhausts", []):
		var smoke := UiKit.particles(_smoke_texture, IntroConfig.SMOKE_FREQUENCY_S, IntroConfig.SMOKE_LIFE_S,
			IntroConfig.SMOKE_DIRECTION, IntroConfig.SMOKE_SPREAD_DEG, IntroConfig.SMOKE_SPEED,
			IntroConfig.SMOKE_SCALE, IntroConfig.SMOKE_ALPHA, IntroConfig.SMOKE_TINTS)
		smoke.position = exhaust - half
		stage.add_child(smoke)

	var t := stage.create_tween().set_parallel().set_ease(IntroConfig.IMAGE_EASE).set_trans(IntroConfig.IMAGE_TRANS)
	t.tween_property(stage, "position", img.to, img.duration)
	t.tween_property(stage, "scale", Vector2.ONE * img.to_scale, img.duration)


func _spawn_horn() -> void:
	var panel: Dictionary = IntroConfig.PANELS[_panel_index]
	if _transitioning or not panel.has("horns"):
		return
	var zone: Rect2 = panel.horns
	var pos := Vector2(randf_range(zone.position.x, zone.end.x), randf_range(zone.position.y, zone.end.y))
	var word: String = IntroConfig.HORN_WORDS.pick_random()
	var text := UiKit.label(word, UiKit.fredoka(true), IntroConfig.HORN_FONT_SIZE, IntroConfig.HORN_COLOR,
		IntroConfig.HORN_OUTLINE, pos, Vector2(0.5, 0.5))
	_panel_layer.add_child(text)
	var t := text.create_tween().set_parallel()
	t.tween_property(text, "position:y", text.position.y - IntroConfig.HORN_RISE_PX, IntroConfig.HORN_LIFE_S)
	t.tween_property(text, "modulate:a", 0.0, IntroConfig.HORN_LIFE_S)
	t.chain().tween_callback(text.queue_free)
	_shake_left = IntroConfig.HORN_SHAKE_S


func _type_text(full: String) -> void:
	_typing = true
	_advance_timer.stop()
	_narration.text = full
	_narration.visible_characters = 0
	_type_timer.start()


func _type_next() -> void:
	_narration.visible_characters += 1
	if _narration.visible_characters >= _narration.get_total_character_count():
		_on_typing_done()


func _on_typing_done() -> void:
	_typing = false
	_type_timer.stop()
	_narration.visible_characters = -1
	_advance_timer.start()


func _handle_advance() -> void:
	if _finished or _transitioning:
		return
	if _typing:
		# Primera pulsación: completa el texto de golpe.
		_on_typing_done()
		return
	_next_panel()


func _next_panel() -> void:
	if _finished:
		return
	_advance_timer.stop()
	if _panel_index >= IntroConfig.PANELS.size() - 1:
		_finish()
		return
	_panel_index += 1
	_transitioning = true
	_tween_fade(1.0).finished.connect(_show_panel)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	_type_timer.stop()
	_advance_timer.stop()
	_horn_timer.stop()
	_tween_fade(1.0).finished.connect(func() -> void: get_tree().change_scene_to_file(PLAY_SCENE))


func _tween_fade(to_alpha: float) -> Tween:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = _fade.create_tween()
	_fade_tween.tween_property(_fade, "color:a", to_alpha, IntroConfig.FADE_S)
	return _fade_tween


func _rect(r: Rect2, color: Color) -> ColorRect:
	var c := ColorRect.new()
	c.position = r.position
	c.size = r.size
	c.color = color
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
