class_name Soundscape
extends Node
## Ambiente: de la ciudad caótica (tráfico y bocinas) al campo, donde solo suenan el motor y los pájaros.

## 0 = plena ciudad, 1 = campo. Lo fija la escena según dónde está la furgo.
var countryside := 0.0
## Mezcla aplicada (sigue a `countryside` sin saltos).
var mix := 0.0

var _city := AudioStreamPlayer.new()
var _horn := AudioStreamPlayer.new()
var _bird := AudioStreamPlayer.new()
var _plane := AudioStreamPlayer.new()
var _horns: Array[AudioStreamWAV] = []
var _birds: Array[AudioStreamWAV] = []
var _horn_wait := 0.0
var _bird_wait := 0.0
var _plane_wait := 0.0


func _ready() -> void:
	_city.stream = Synth.city_loop()
	for i in AudioConfig.HORN_VARIANTS:
		_horns.append(Synth.horn(randf_range(AudioConfig.HORN_S.x, AudioConfig.HORN_S.y)))
	for i in AudioConfig.BIRD_VARIANTS:
		_birds.append(Synth.bird(randi_range(AudioConfig.BIRD_CHIRPS.x, AudioConfig.BIRD_CHIRPS.y)))
	_plane.stream = Synth.plane()
	for p in [_city, _horn, _bird, _plane]:
		add_child(p)
	mix = countryside
	_apply_mix()
	_city.play()
	_horn_wait = randf_range(AudioConfig.HORN_DELAY_S.x, AudioConfig.HORN_DELAY_S.y)
	_bird_wait = randf_range(AudioConfig.BIRD_DELAY_S.x, AudioConfig.BIRD_DELAY_S.y)
	_plane_wait = randf_range(AudioConfig.PLANE_DELAY_S.x, AudioConfig.PLANE_DELAY_S.y)


func _process(delta: float) -> void:
	mix = move_toward(mix, countryside, AudioConfig.AMBIENT_LERP * delta)
	_apply_mix()
	_horn_wait -= delta
	if _horn_wait <= 0.0:
		_horn_wait = randf_range(AudioConfig.HORN_DELAY_S.x, AudioConfig.HORN_DELAY_S.y)
		# Cuanto más campo, menos bocinas.
		if randf() < 1.0 - mix:
			_one_shot(_horn, _horns.pick_random(), AudioConfig.HORN_DB, AudioConfig.HORN_PITCH, 1.0 - mix)
	_plane_wait -= delta
	if _plane_wait <= 0.0:
		_plane_wait = randf_range(AudioConfig.PLANE_DELAY_S.x, AudioConfig.PLANE_DELAY_S.y)
		_one_shot(_plane, _plane.stream, AudioConfig.PLANE_DB, AudioConfig.PLANE_PITCH, 1.0 - mix)
	_bird_wait -= delta
	if _bird_wait <= 0.0:
		_bird_wait = randf_range(AudioConfig.BIRD_DELAY_S.x, AudioConfig.BIRD_DELAY_S.y)
		if randf() < mix:
			_one_shot(_bird, _birds.pick_random(), AudioConfig.BIRD_DB, AudioConfig.BIRD_PITCH, mix)


func _apply_mix() -> void:
	var city := 1.0 - mix
	_city.volume_db = AudioConfig.CITY_DB + linear_to_db(maxf(city, AudioConfig.LAYER_SILENT))
	_city.stream_paused = city <= AudioConfig.LAYER_SILENT


func _one_shot(player: AudioStreamPlayer, stream: AudioStreamWAV, db: float, pitch: Vector2, level: float) -> void:
	if level <= AudioConfig.LAYER_SILENT:
		return
	player.stream = stream
	player.volume_db = db + linear_to_db(level)
	player.pitch_scale = randf_range(pitch.x, pitch.y)
	player.play()
