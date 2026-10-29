class_name MapTransition
extends CanvasLayer
## Paso de la ciudad al campo: carretera de montaña al atardecer (imagen de Ara) y la furgo
## alejándose, que gira en la curva y se pierde tras el rasante; la cámara sube del suelo. El motor rompe el silencio y suelta onomatopeyas que se encogen con la distancia.
## Corre con el juego en pausa: el juego se funde a negro, `covered` (cargar el siguiente mapa
## a oscuras), sale la escena y al acabar se funde dejando ver el campo; `finished`: reanudar.

signal covered
signal finished

var _stage := Node2D.new() # en píxeles de la imagen
var _van := Sprite2D.new()
var _smoke: CPUParticles2D
var _lights: Array[Sprite2D] = []
var _side := Polygon2D.new() # costado derecho que asoma al girar en la curva
var _side_window := Polygon2D.new()
var _side_skirt := Polygon2D.new()
var _side_outline := Line2D.new()
var _crest := Sprite2D.new() # asfalto del rasante, por delante de la furgo cuando lo pasa
var _screen: Vector2
var _img_size: Vector2
var _base_pos: Vector2
var _base_scale: float
## 0 = cámara a ras de suelo, 1 = plano completo.
var _crane := 0.0
## 0 = antes del rasante, 1 = ya hundida tras él.
var _sink := 0.0
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
	_screen = screen
	var bg := Sprite2D.new()
	bg.texture = load(TransitionConfig.BACKGROUND)
	bg.centered = false
	var img := bg.texture.get_size()
	_img_size = img
	# La imagen cubre toda la pantalla; lo que sobra se recorta.
	_base_scale = maxf(screen.x / img.x, screen.y / img.y)
	_base_pos = Vector2((screen.x - img.x * _base_scale) / 2,
		clampf(screen.y / 2 - TransitionConfig.FOCUS_Y * img.y * _base_scale, screen.y - img.y * _base_scale, 0.0))
	_apply_camera()
	_stage.add_child(bg)
	_stage.visible = false

	_van.texture = load(TransitionConfig.VAN_TEXTURE)
	_van.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_van.centered = false
	# El origen del sprite es su apoyo en el suelo (centro abajo).
	_van.offset = Vector2(-_van.texture.get_width() / 2.0, -_van.texture.get_height())
	_stage.add_child(_van)
	_add_side()
	_add_tail_lights()
	_smoke = UiKit.particles(UiKit.circle_texture(TransitionConfig.SMOKE_TEXTURE_RADIUS), TransitionConfig.SMOKE_FREQUENCY_S,
		TransitionConfig.SMOKE_LIFE_S, TransitionConfig.SMOKE_DIRECTION, TransitionConfig.SMOKE_SPREAD_DEG,
		TransitionConfig.SMOKE_SPEED, TransitionConfig.SMOKE_SCALE, TransitionConfig.SMOKE_ALPHA, TransitionConfig.SMOKE_TINTS)
	_smoke.position = TransitionConfig.SMOKE_OFFSET
	_smoke.emitting = false
	_van.add_child(_smoke)
	_crest.texture = bg.texture
	_crest.centered = false
	_crest.region_enabled = true
	_crest.region_rect = TransitionConfig.CREST_RECT
	_crest.position = TransitionConfig.CREST_RECT.position
	_crest.visible = false
	_stage.add_child(_crest)
	add_child(_stage)

	_words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_words.visible = false
	add_child(_words)

	var skip_text := TransitionConfig.SKIP_TEXT_TOUCH if DisplayServer.is_touchscreen_available() else TransitionConfig.SKIP_TEXT_KEYS
	var skip := UiKit.label(skip_text, UiKit.fredoka(), TransitionConfig.SKIP_FONT_SIZE, Color.WHITE, TransitionConfig.WORD_OUTLINE,
		Vector2(screen.x - TransitionConfig.SKIP_PADDING_X, GameConfig.TAP_MIN_HEIGHT / 2.0), Vector2(1, 0.5))
	skip.modulate.a = TransitionConfig.SKIP_ALPHA
	_words.add_child(skip)
	_skip_rect = Rect2(skip.position.x - TransitionConfig.SKIP_PADDING_X, 0,
		skip.size.x + TransitionConfig.SKIP_PADDING_X * 2, GameConfig.TAP_MIN_HEIGHT)

	_fade.color = GameConfig.MAP_FADE_COLOR
	_fade.size = screen
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.color.a = 0.0
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
	_bird_wait = randf_range(0.0, TransitionConfig.BIRD_DELAY_S.x)

	_place_van()
	var t := create_tween()
	_main = t
	# El juego se va a negro; a oscuras se carga el mapa siguiente y aparece la carretera.
	t.tween_property(_fade, "color:a", 1.0, TransitionConfig.GAME_FADE_OUT_S)
	t.tween_callback(_cover)
	t.tween_callback(_show_scene)
	t.tween_property(_fade, "color:a", 0.0, TransitionConfig.FADE_S)
	t.tween_interval(TransitionConfig.SILENCE_S)
	t.tween_callback(_start_engine)
	t.tween_property(self, "_depth", TransitionConfig.VAN_DEPTH_TO, TransitionConfig.DRIVE_S) \
		.set_trans(TransitionConfig.DRIVE_TRANS).set_ease(TransitionConfig.DRIVE_EASE)
	# Pasa el rasante: desde aquí el asfalto la tapa mientras se hunde y sigue la curva.
	t.tween_callback(func() -> void: _crest.visible = true)
	t.tween_property(self, "_sink", 1.0, TransitionConfig.SINK_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
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


func _show_scene() -> void:
	_stage.visible = true
	_words.visible = true
	_wind.play()
	create_tween().tween_property(self, "_crane", 1.0, TransitionConfig.CRANE_S) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _add_side() -> void:
	var shade := Color(TransitionConfig.SIDE_SHADE, TransitionConfig.SIDE_SHADE, TransitionConfig.SIDE_SHADE)
	_side.color = TransitionConfig.SIDE_BODY_COLOR * shade
	_side_window.color = TransitionConfig.SIDE_WINDOW_COLOR
	_side_skirt.color = TransitionConfig.SIDE_SKIRT_COLOR
	_side_outline.default_color = TransitionConfig.SIDE_SKIRT_COLOR
	_side_outline.width = GameConfig.LINE_WIDTH
	_side_outline.closed = true
	for n: CanvasItem in [_side, _side_window, _side_skirt, _side_outline]:
		n.show_behind_parent = true
		_van.add_child(n)


## Costado según el giro: un cuadrilátero que sale del borde derecho de la trasera hacia el
## fondo, más bajo y pequeño en el extremo lejano. Coordenadas del sprite sin aplastar.
func _update_side(yaw: float) -> void:
	var visible_side := yaw > 0.0
	for n: CanvasItem in [_side, _side_window, _side_skirt, _side_outline]:
		n.visible = visible_side
	if not visible_side:
		return
	var x0 := _van.texture.get_width() / 2.0
	var length := TransitionConfig.SIDE_LENGTH * tan(yaw)
	var bottom := TransitionConfig.SIDE_BOTTOM_Y
	var top := TransitionConfig.SIDE_TOP_Y
	var mid := (top + bottom) / 2
	var rise := TransitionConfig.SIDE_FAR_RISE * (bottom - top)
	var shrink := TransitionConfig.SIDE_FAR_SHRINK
	var far_top := mid + (top - mid) * shrink - rise
	var far_bottom := mid + (bottom - mid) * shrink - rise
	var at := func(u: float, v: float) -> Vector2:
		return Vector2(x0 + length * u, lerpf(lerpf(bottom, top, v), lerpf(far_bottom, far_top, v), u))
	var quad := func(v0: float, v1: float) -> PackedVector2Array:
		return PackedVector2Array([at.call(0.0, v0), at.call(1.0, v0), at.call(1.0, v1), at.call(0.0, v1)])
	_side.polygon = quad.call(0.0, 1.0)
	_side_outline.points = _side.polygon
	_side_window.polygon = quad.call(TransitionConfig.SIDE_WINDOW.x, TransitionConfig.SIDE_WINDOW.y)
	_side_skirt.polygon = quad.call(0.0, TransitionConfig.SIDE_SKIRT_H / (bottom - top))


## Pilotos encendidos: brillo rojo suave que se suma a la imagen.
func _add_tail_lights() -> void:
	var glow := GradientTexture2D.new()
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(1.0, 0.5)
	glow.width = TransitionConfig.TAIL_LIGHT_RADIUS * 2
	glow.height = TransitionConfig.TAIL_LIGHT_RADIUS * 2
	var g := Gradient.new()
	g.set_color(0, TransitionConfig.TAIL_LIGHT_COLOR)
	g.set_color(1, Color(TransitionConfig.TAIL_LIGHT_COLOR, 0.0))
	glow.gradient = g
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for at: Vector2 in TransitionConfig.TAIL_LIGHTS:
		var light := Sprite2D.new()
		light.texture = glow
		light.material = add
		light.position = _van.offset + at
		_van.add_child(light)
		_lights.append(light)


## Cámara que sube: de cerca del asfalto (más zoom, mirando abajo) al plano completo.
func _apply_camera() -> void:
	var s := _base_scale * lerpf(TransitionConfig.CRANE_ZOOM_FROM, 1.0, _crane)
	var full_focus := (_screen / 2 - _base_pos) / _base_scale
	var focus := TransitionConfig.CRANE_FOCUS_FROM.lerp(full_focus, _crane)
	var pos := _screen / 2 - focus * s
	# Sin dejar ver el borde de la imagen.
	pos = pos.clamp(_screen - _img_size * s, Vector2.ZERO)
	_stage.scale = Vector2.ONE * s
	_stage.position = pos


## Escala de la furgo en la imagen (1 = como la pintó Ara).
func van_scale() -> float:
	return 1.0 / _depth


func _place_van() -> void:
	var k := van_scale()
	var bob := sin(TAU * TransitionConfig.VAN_BOB_HZ * _time) * TransitionConfig.VAN_BOB_PX * k if _driving else 0.0
	# Al acercarse al rasante entra en la curva: gira y se abre a la derecha.
	var turn := smoothstep(TransitionConfig.YAW_FROM_DEPTH, TransitionConfig.VAN_DEPTH_TO, _depth)
	var yaw := lerpf(0.0, TransitionConfig.YAW_AT_CREST, turn) + (TransitionConfig.YAW_END - TransitionConfig.YAW_AT_CREST) * _sink
	var shift := TransitionConfig.TURN_SHIFT_PX * turn * turn + TransitionConfig.SINK_DRIFT_PX * _sink
	# Tras el rasante se hunde su alto entero: el asfalto de delante la va tapando.
	var sink := _sink * _van.texture.get_height() * k
	_van.position = TransitionConfig.VANISH + (TransitionConfig.VAN_REF_FOOT - TransitionConfig.VANISH) * k + Vector2(shift, bob + sink)
	_van.scale = Vector2(k * cos(yaw), k)
	_update_side(yaw)
	_van.visible = not _gone
	var pulse := 1.0 - TransitionConfig.TAIL_LIGHT_PULSE * (0.5 + 0.5 * sin(TAU * TransitionConfig.TAIL_LIGHT_PULSE_HZ * _time))
	for light in _lights:
		light.modulate.a = pulse


func _start_engine() -> void:
	_driving = true
	_smoke.emitting = true
	_engine.play()
	_rpm = TransitionConfig.ENGINE_START_RPM
	_spawn_word(TransitionConfig.START_WORD)
	_word_wait = TransitionConfig.WORD_EVERY_S


func _process(delta: float) -> void:
	_time += delta
	_apply_camera()
	_place_van()
	_smoke.emitting = _driving and _sink < 0.5
	# El humo va en coordenadas de pantalla (se queda atrás): su tamaño y velocidad se ajustan
	# a la distancia de la furgo a mano.
	var f := van_scale() * _stage.scale.x
	_smoke.scale_amount_min = TransitionConfig.SMOKE_SCALE.x * f
	_smoke.scale_amount_max = _smoke.scale_amount_min
	_smoke.initial_velocity_min = TransitionConfig.SMOKE_SPEED.x * f
	_smoke.initial_velocity_max = TransitionConfig.SMOKE_SPEED.y * f
	if _driving and not _gone:
		_rpm = lerpf(_rpm, TransitionConfig.ENGINE_CRUISE_RPM, 1.0 - exp(-delta / TransitionConfig.ENGINE_REV_S))
		_engine.pitch_scale = _rpm / 60.0 * AudioConfig.FIRES_PER_REV / _engine_base_hz
		# El sonido baja con la distancia (≈ 6 dB cada vez que se dobla).
		# Tras el rasante el monte se come el sonido.
		var behind := maxf(1.0 - _sink, AudioConfig.LAYER_SILENT)
		var db := TransitionConfig.ENGINE_DB + linear_to_db(TransitionConfig.VAN_DEPTH_FROM / _depth) + linear_to_db(behind)
		_engine.volume_db = maxf(db, TransitionConfig.ENGINE_SILENT_DB)
		_word_wait -= delta
		if _word_wait <= 0.0:
			_word_wait = TransitionConfig.WORD_EVERY_S
			if _sink == 0.0:
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
	# La carretera se funde y deja ver el campo, ya cargado detrás.
	var t := create_tween().set_parallel()
	t.tween_property(_fade, "color:a", 0.0, TransitionConfig.REVEAL_S)
	t.tween_property(_stage, "modulate:a", 0.0, TransitionConfig.REVEAL_S)
	t.tween_property(_words, "modulate:a", 0.0, TransitionConfig.REVEAL_S)
	t.tween_property(_engine, "volume_db", TransitionConfig.ENGINE_SILENT_DB, TransitionConfig.REVEAL_S)
	t.tween_property(_wind, "volume_db", TransitionConfig.ENGINE_SILENT_DB, TransitionConfig.REVEAL_S)
	t.chain().tween_callback(func() -> void:
		finished.emit()
		queue_free())
