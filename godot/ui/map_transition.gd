class_name MapTransition
extends CanvasLayer
## Paso de la ciudad al campo: carretera de montaña al atardecer (imagen de Ara) y la furgo
## alejándose; el motor rompe el silencio y suelta onomatopeyas que se encogen con la distancia.
## Corre con el juego en pausa. `covered`: la pantalla ya tapa el mapa (cargar el siguiente);
## `finished`: vuelve a negro y se va.

signal covered
signal finished

var _stage := Node2D.new() # en píxeles de la imagen
var _van := Sprite2D.new()
var _words := Control.new() # textos en píxeles de pantalla, nítidos
var _fade := ColorRect.new()
var _engine := AudioStreamPlayer.new()
var _wind := AudioStreamPlayer.new()
var _bird := AudioStreamPlayer.new()
var _birds: Array[AudioStreamWAV] = []
var _engine_base_hz: float
var _depth := TransitionConfig.VAN_DEPTH_FROM
var _rpm := AudioConfig.ENGINE_IDLE_RPM
var _driving := false
var _gone := false
var _ending := false
var _covered := false
var _main: Tween
var _time := 0.0
var _word_wait := 0.0
var _bird_wait := 0.0
var _skip_rect: Rect2


static func create() -> MapTransition:
	var t := MapTransition.new()
	t.layer = TransitionConfig.LAYER
	t.process_mode = Node.PROCESS_MODE_ALWAYS
	return t


func _ready() -> void:
	var screen := get_viewport().get_visible_rect().size
	var bg := Sprite2D.new()
	bg.texture = load(TransitionConfig.BACKGROUND)
	bg.centered = false
	var img := bg.texture.get_size()
	# La imagen cubre toda la pantalla; lo que sobra se recorta.
	var s := maxf(screen.x / img.x, screen.y / img.y)
	_stage.scale = Vector2.ONE * s
	_stage.position = Vector2((screen.x - img.x * s) / 2,
		clampf(screen.y / 2 - TransitionConfig.FOCUS_Y * img.y * s, screen.y - img.y * s, 0.0))
	_stage.add_child(bg)

	_van.texture = load(TransitionConfig.VAN_TEXTURE)
	_van.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_van.centered = false
	# El origen del sprite es su apoyo en el suelo (centro abajo).
	_van.offset = Vector2(-_van.texture.get_width() / 2.0, -_van.texture.get_height())
	_stage.add_child(_van)
	add_child(_stage)

	_words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_words)

	var skip_text := TransitionConfig.SKIP_TEXT_TOUCH if DisplayServer.is_touchscreen_available() else TransitionConfig.SKIP_TEXT_KEYS
	var skip := UiKit.label(skip_text, UiKit.fredoka(), TransitionConfig.SKIP_FONT_SIZE, Color.WHITE, TransitionConfig.WORD_OUTLINE,
		Vector2(screen.x - TransitionConfig.SKIP_PADDING_X, GameConfig.TAP_MIN_HEIGHT / 2.0), Vector2(1, 0.5))
	skip.modulate.a = TransitionConfig.SKIP_ALPHA
	add_child(skip)
	_skip_rect = Rect2(skip.position.x - TransitionConfig.SKIP_PADDING_X, 0,
		skip.size.x + TransitionConfig.SKIP_PADDING_X * 2, GameConfig.TAP_MIN_HEIGHT)

	_fade.color = GameConfig.MAP_FADE_COLOR
	_fade.size = screen
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

	_engine.stream = Synth.engine_loop()
	_engine_base_hz = float(AudioConfig.MIX_RATE) / AudioConfig.ENGINE_PERIOD_SAMPLES
	_engine.volume_db = TransitionConfig.ENGINE_SILENT_DB
	_wind.stream = Synth.wind_loop()
	_wind.volume_db = TransitionConfig.WIND_DB
	for i in AudioConfig.BIRD_VARIANTS:
		_birds.append(Synth.bird(randi_range(AudioConfig.BIRD_CHIRPS.x, AudioConfig.BIRD_CHIRPS.y)))
	for p in [_engine, _wind, _bird]:
		add_child(p)
	_wind.play()
	_bird_wait = randf_range(0.0, TransitionConfig.BIRD_DELAY_S.x)

	_place_van()
	var t := create_tween()
	_main = t
	t.tween_property(_fade, "color:a", 0.0, TransitionConfig.FADE_S).from(1.0)
	t.tween_callback(_cover)
	t.tween_interval(TransitionConfig.SILENCE_S)
	t.tween_callback(_start_engine)
	t.tween_property(self, "_depth", TransitionConfig.VAN_DEPTH_TO, TransitionConfig.DRIVE_S) \
		.set_trans(TransitionConfig.DRIVE_TRANS).set_ease(TransitionConfig.DRIVE_EASE)
	t.tween_callback(func() -> void: _gone = true)
	t.tween_interval(TransitionConfig.HOLD_S)
	t.tween_callback(_end)


func _unhandled_input(event: InputEvent) -> void:
	var skip := false
	if event is InputEventKey and event.pressed and not event.echo:
		skip = event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]
	elif event is InputEventScreenTouch and event.pressed:
		skip = _skip_rect.has_point(event.position)
	elif event is InputEventMouseButton and event.pressed:
		skip = _skip_rect.has_point(event.position)
	if skip:
		get_viewport().set_input_as_handled()
		_end()


## Escala de la furgo en la imagen (1 = como la pintó Ara).
func van_scale() -> float:
	return 1.0 / _depth


func _place_van() -> void:
	var k := van_scale()
	var bob := sin(TAU * TransitionConfig.VAN_BOB_HZ * _time) * TransitionConfig.VAN_BOB_PX * k if _driving else 0.0
	_van.position = TransitionConfig.VANISH + (TransitionConfig.VAN_REF_FOOT - TransitionConfig.VANISH) * k + Vector2(0, bob)
	_van.scale = Vector2.ONE * k
	var hide := inverse_lerp(TransitionConfig.VAN_HIDE_FROM_DEPTH, TransitionConfig.VAN_DEPTH_TO, _depth)
	_van.modulate.a = 1.0 - clampf(hide, 0.0, 1.0)
	_van.visible = not _gone


func _start_engine() -> void:
	_driving = true
	_engine.play()
	_rpm = TransitionConfig.ENGINE_START_RPM
	_spawn_word(TransitionConfig.START_WORD)
	_word_wait = TransitionConfig.WORD_EVERY_S


func _process(delta: float) -> void:
	_time += delta
	_place_van()
	if _driving and not _gone:
		_rpm = lerpf(_rpm, TransitionConfig.ENGINE_CRUISE_RPM, 1.0 - exp(-delta / TransitionConfig.ENGINE_REV_S))
		_engine.pitch_scale = _rpm / 60.0 * AudioConfig.FIRES_PER_REV / _engine_base_hz
		# El sonido baja con la distancia (≈ 6 dB cada vez que se dobla).
		var db := TransitionConfig.ENGINE_DB + linear_to_db(TransitionConfig.VAN_DEPTH_FROM / _depth) + linear_to_db(maxf(_van.modulate.a, AudioConfig.LAYER_SILENT))
		_engine.volume_db = maxf(db, TransitionConfig.ENGINE_SILENT_DB)
		_word_wait -= delta
		if _word_wait <= 0.0:
			_word_wait = TransitionConfig.WORD_EVERY_S
			if _van.modulate.a > TransitionConfig.WORD_MIN_VAN_ALPHA:
				_spawn_word(TransitionConfig.ENGINE_WORDS.pick_random())
	elif _gone:
		_engine.stop()
	_bird_wait -= delta
	if _bird_wait <= 0.0:
		_bird_wait = randf_range(TransitionConfig.BIRD_DELAY_S.x, TransitionConfig.BIRD_DELAY_S.y)
		# Mientras ruge de cerca, los pájaros callan.
		if not _driving or _gone or van_scale() < 1.0:
			_sing()


## Onomatopeya del motor en el tubo de escape, del tamaño que toca a esa distancia.
func _spawn_word(word: String) -> void:
	var k := van_scale()
	var at := _to_screen(_van.position + TransitionConfig.EXHAUST_OFFSET * k)
	var size := clampi(roundi(TransitionConfig.WORD_FONT_SIZE * k), TransitionConfig.WORD_MIN_FONT_SIZE, TransitionConfig.WORD_MAX_FONT_SIZE)
	if size <= TransitionConfig.WORD_MIN_FONT_SIZE:
		word = word.to_lower()
	_float_word(word, at, size, TransitionConfig.WORD_COLOR, minf(k, 1.0), Vector2(1, 1))


func _sing() -> void:
	_bird.stream = _birds.pick_random()
	_bird.volume_db = TransitionConfig.BIRD_DB
	_bird.pitch_scale = randf_range(AudioConfig.BIRD_PITCH.x, AudioConfig.BIRD_PITCH.y)
	_bird.play()
	var zone := TransitionConfig.BIRD_ZONE
	var at := _to_screen(Vector2(randf_range(zone.position.x, zone.end.x), randf_range(zone.position.y, zone.end.y)))
	_float_word(TransitionConfig.BIRD_WORDS.pick_random(), at, TransitionConfig.BIRD_WORD_FONT_SIZE,
		TransitionConfig.BIRD_WORD_COLOR, 1.0, Vector2(0.5, 1))


## `origin` como en UiKit.label: qué punto del texto queda en `at`.
func _float_word(word: String, at: Vector2, size: int, color: Color, travel: float, origin: Vector2) -> void:
	var outline := maxi(1, roundi(TransitionConfig.WORD_OUTLINE * size / float(TransitionConfig.WORD_FONT_SIZE)))
	var label := UiKit.label(word, UiKit.fredoka(true), size, color, outline, at, origin)
	_words.add_child(label)
	var to := label.position + Vector2(randf_range(-1.0, 1.0) * TransitionConfig.WORD_DRIFT_PX, -TransitionConfig.WORD_RISE_PX) * travel
	var t := label.create_tween().set_parallel()
	t.tween_property(label, "position", to, TransitionConfig.WORD_LIFE_S)
	t.tween_property(label, "modulate:a", 0.0, TransitionConfig.WORD_LIFE_S).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(label.queue_free)


func _to_screen(p: Vector2) -> Vector2:
	return _stage.position + p * _stage.scale


func _cover() -> void:
	if not _covered:
		_covered = true
		covered.emit()


func _end() -> void:
	if _ending:
		return
	_ending = true
	_main.kill()
	# Si se salta antes de taparlo todo, el mapa se cambia igual.
	_cover()
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, TransitionConfig.FADE_S)
	t.parallel().tween_property(_engine, "volume_db", TransitionConfig.ENGINE_SILENT_DB, TransitionConfig.FADE_S)
	t.parallel().tween_property(_wind, "volume_db", TransitionConfig.ENGINE_SILENT_DB, TransitionConfig.FADE_S)
	t.tween_callback(func() -> void:
		finished.emit()
		queue_free())
